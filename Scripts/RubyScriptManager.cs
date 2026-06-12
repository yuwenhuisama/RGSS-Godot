using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Runtime.InteropServices;
using Godot;
using MRuby.Library;
using MRuby.Library.Language;
using MRuby.Library.Mapper;

namespace RGSSGodot;

public class RubyScriptManager
{
    public static readonly RubyScriptManager Instance = new();

    public RbState State { get; private set; } = null!;
    private RbClass unityModule;
    private RbContext? context;
    private RbCompiler? compiler;

    [DllImport("libmruby_marshal_c_ext_x64", CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Unicode)]
    private static extern void mrb_mruby_marshal_c_gem_init(IntPtr mrb);

    [DllImport("libmruby_dir_glob_ext_x64", CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Unicode)]
    private static extern void mrb_mruby_dir_glob_gem_init(IntPtr mrb);

    [DllImport("libmruby_onig_regexp_ext_x64", CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Unicode)]
    private static extern void mrb_mruby_onig_regexp_gem_init(IntPtr mrb);

    [DllImport("libmruby_zlib_ext_x64", CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Unicode)]
    private static extern void mrb_mruby_zlib_gem_init(IntPtr mrb);

    [DynamicDependency(DynamicallyAccessedMemberTypes.All, typeof(RubyScriptManager))]
    [DynamicDependency(DynamicallyAccessedMemberTypes.All, typeof(RbTypeRegisterHelper))]
    public void Initialize()
    {
        ConfigureNativeDllPath();

        this.State = Ruby.Open();
        this.context = this.State.NewCompileContext();
        this.compiler = this.State.NewCompiler();

        InitGem("marshal_c", mrb_mruby_marshal_c_gem_init);
        InitGem("onig_regexp", mrb_mruby_onig_regexp_gem_init);
        InitGem("dir_glob", mrb_mruby_dir_glob_gem_init);
        InitGem("zlib", mrb_mruby_zlib_gem_init);

        this.unityModule = this.State.DefineModule("Unity");
        this.State.DefineModule("RPG");

        Kernel.Init(this);
        RbTypeRegisterHelper.Init(this.State, new[] { typeof(RubyScriptManager).Assembly });
    }

    public RbClass GetClassUnderUnityModule(string className) => this.unityModule.GetConst(className).ToClass();

    public void LoadMainScript()
    {
        var path = Path.Combine(GetRgssDir(), "main.rb");
        if (!File.Exists(path))
        {
            GD.PrintErr($"MAIN_LOADED:FAIL:not found:{path}");
            return;
        }

        string content;
        try { content = File.ReadAllText(path); }
        catch (Exception ex)
        {
            GD.PrintErr($"MAIN_LOADED:FAIL:{ex.GetType().Name}:{ex.Message}");
            return;
        }

        _ = LoadScriptContent("main", content, out var error);
        if (error)
            GD.PrintErr("MAIN_LOADED:FAIL");
        else
            GD.Print("MAIN_LOADED:OK");
    }

    public RbValue LoadScriptInResources(string fileName, out bool error)
    {
        var rgssDir = GetRgssDir();
        // Try exact path first (e.g. "ext/dir_glob"), then with .rb extension
        var candidates = new[]
        {
            Path.Combine(rgssDir, fileName + ".rb"),
            Path.Combine(rgssDir, fileName),
        };

        error = false;
        foreach (var path in candidates)
        {
            if (!File.Exists(path)) continue;

            string scriptContent;
            try { scriptContent = File.ReadAllText(path); }
            catch (Exception ex)
            {
                GD.PrintErr($"Failed to read script file: {path}: {ex.Message}");
                error = true;
                return this.State.RbNil;
            }

            GD.Print($"Loaded script: {fileName}");
            return LoadScriptContent(fileName, scriptContent, out error);
        }

        GD.PrintErr($"Failed to load script (not found): {fileName}");
        error = true;
        return this.State.RbNil;
    }

    public RbValue LoadAllScriptInResources(string subPath, out bool error)
    {
        var dirPath = Path.Combine(GetRgssDir(), subPath);
        error = false;

        if (!Directory.Exists(dirPath))
        {
            GD.Print($"Script dir not found (skipping): {subPath}");
            return this.State.RbNil;
        }

        var files = Directory.GetFiles(dirPath, "*.rb").OrderBy(f => f).ToArray();
        foreach (var file in files)
        {
            var scriptName = subPath + "/" + Path.GetFileNameWithoutExtension(file);
            if (Kernel.IsScriptLoaded(scriptName)) continue;

            Kernel.AddPath(scriptName);
            string scriptContent;
            try { scriptContent = File.ReadAllText(file); }
            catch (Exception ex)
            {
                GD.PrintErr($"Failed to read {file}: {ex.Message}");
                error = true;
                return this.State.RbNil;
            }

            GD.Print($"Loaded script: {scriptName}");
            var res = LoadScriptContent(scriptName, scriptContent, out error);
            if (error) return res;
        }

        return this.State.RbNil;
    }

    public RbValue LoadScriptContentWithFileName(string fileName, string scriptContent, out bool error)
    {
        error = false;
        if (string.IsNullOrWhiteSpace(scriptContent))
            return this.State.RbNil;

        GD.Print($"Loaded RMVA script: {fileName}");
        this.context!.Value.SetFilename($"{fileName}.rmvascript");
        this.compiler!.SetFilename($"{fileName}.rmvascript");

        // MRuby.Library >= 0.1.8 marshals the script string to the native loader as UTF-8
        // (LPUTF8Str). Earlier versions used the platform ANSI codepage (cp936/GBK on a
        // Chinese Windows locale), which re-encoded UTF-8 RGSS string literals to GBK
        // inside mruby and rendered them as mojibake. Keep the package at >= 0.1.8.
        var result = this.State.Protect(
            (_, _, _) => this.compiler.LoadString(scriptContent, this.context.Value),
            ref error);

        if (error)
            GD.PrintErr($"Error in RMVA script {fileName}: {SafeClassName(result)}");

        return result;
    }

    public void Destroy()
    {
        if (this.State is null)
            return;

        this.compiler?.Dispose();
        this.compiler = null;
        if (this.context is not null) this.context.Value.Dispose();
        this.context = null;
        Ruby.Close(this.State);
        this.State = null!;
        Kernel.Reset();
    }

    // ── private helpers ────────────────────────────────────────────────────────

    private RbValue LoadScriptContent(string fileName, string scriptContent, out bool error)
    {
        error = false;
        this.context!.Value.SetFilename($"{fileName}.rb");
        this.compiler!.SetFilename($"{fileName}.rb");

        var result = this.State.Protect(
            (_, _, _) => this.compiler.LoadString(scriptContent, this.context.Value),
            ref error);

        if (error)
            GD.PrintErr($"Error in script {fileName}: {SafeClassName(result)}");

        return result;
    }

    private void InitGem(string gemName, Action<IntPtr> init)
    {
        try { init(this.State.NativeHandler); }
        catch (DllNotFoundException ex) { GD.PrintErr($"GEM_INIT_FAIL:{gemName}:{ex.Message}"); }
    }

    private static string SafeClassName(RbValue v)
    {
        try { return v.GetClassName() ?? "RubyException"; }
        catch { return "RubyException"; }
    }

    private static string GetRgssDir()
    {
        var projectDir = ProjectSettings.GlobalizePath("res://");
        var inProject = Path.Combine(projectDir, "RGSS");
        if (Directory.Exists(inProject)) return inProject;
        var exeDir = Path.GetDirectoryName(
            System.Diagnostics.Process.GetCurrentProcess().MainModule?.FileName) ?? "";
        return Path.Combine(exeDir, "RGSS");
    }

    private static void ConfigureNativeDllPath()
    {
        var baseDir = AppContext.BaseDirectory;
        var projectDir = ProjectSettings.GlobalizePath("res://");
        var exeDir = Path.GetDirectoryName(
            System.Diagnostics.Process.GetCurrentProcess().MainModule?.FileName) ?? baseDir;
        var assemblyName = Assembly.GetExecutingAssembly().GetName().Name ?? "RGSS-Godot";

        string dataDirSuffix;
        string pluginSubdir;
        if (OperatingSystem.IsWindows())
        {
            dataDirSuffix = "windows_x86_64";
            pluginSubdir = "windows";
        }
        else if (OperatingSystem.IsMacOS())
        {
            dataDirSuffix = "macos";
            pluginSubdir = "macos";
        }
        else
        {
            dataDirSuffix = "linuxbsd_x86_64";
            pluginSubdir = "linux";
        }

        var dataDir = Path.Combine(exeDir, $"data_{assemblyName}_{dataDirSuffix}");

        var candidateDirs = new[]
        {
            baseDir,
            exeDir,
            projectDir,
            Path.Combine(projectDir, "Plugins", pluginSubdir),
            Path.Combine(exeDir, "Plugins", pluginSubdir),
            Path.Combine(dataDir, "Plugins", pluginSubdir),
            Path.Combine(projectDir, ".godot", "mono", "temp", "bin", "Debug"),
            Path.Combine(projectDir, ".godot", "mono", "temp", "bin", "Release"),
        };

        NativeLibrary.SetDllImportResolver(Assembly.GetExecutingAssembly(), ResolveLib);
        NativeLibrary.SetDllImportResolver(typeof(Ruby).Assembly, ResolveLib);

        var existingPath = System.Environment.GetEnvironmentVariable("PATH") ?? string.Empty;
        var prefix = string.Join(Path.PathSeparator, candidateDirs.Where(Directory.Exists));
        System.Environment.SetEnvironmentVariable("PATH", $"{prefix}{Path.PathSeparator}{existingPath}");

        IntPtr ResolveLib(string libName, Assembly asm, DllImportSearchPath? sp)
        {
            var candidates = GetLibCandidateNames(libName);
            foreach (var dir in candidateDirs.Where(Directory.Exists))
            {
                foreach (var candidate in candidates)
                {
                    var path = Path.Combine(dir, candidate);
                    if (File.Exists(path) && NativeLibrary.TryLoad(path, out var h)) return h;
                }
            }
            return IntPtr.Zero;
        }
    }

    private static IEnumerable<string> GetLibCandidateNames(string libName)
    {
        yield return libName;
        if (OperatingSystem.IsWindows())
        {
            if (!libName.EndsWith(".dll", StringComparison.OrdinalIgnoreCase))
                yield return libName + ".dll";
        }
        else if (OperatingSystem.IsMacOS())
        {
            if (!libName.EndsWith(".dylib", StringComparison.OrdinalIgnoreCase))
                yield return libName + ".dylib";
            if (!libName.StartsWith("lib", StringComparison.Ordinal))
                yield return "lib" + libName + ".dylib";
        }
        else
        {
            if (!libName.EndsWith(".so", StringComparison.OrdinalIgnoreCase))
                yield return libName + ".so";
            if (!libName.StartsWith("lib", StringComparison.Ordinal))
                yield return "lib" + libName + ".so";
        }
    }
}
