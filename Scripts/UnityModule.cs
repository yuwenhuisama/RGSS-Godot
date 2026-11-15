using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.InteropServices;
using Godot;
using ICSharpCode.SharpZipLib.Zip.Compression.Streams;
using MRuby.Library.Language;
using MRuby.Library.Mapper;
using RGSSGodot;

namespace RGSSUnity.RubyClasses;

[RbModule("Unity", "")]
public static class UnityModule
{
    public static RbValue? UpdateFiber;

    public static RbState State = null!;

    private static readonly List<(long ScriptId, string ScriptName, string ScriptContent)> RmvaScripts = new();

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct FindData
    {
        public uint Attributes;
        public System.Runtime.InteropServices.ComTypes.FILETIME CreationTime, AccessTime, WriteTime;
        public uint SizeHigh, SizeLow, ReparseTag, Reserved;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)] public string Filename;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 14)] public string AlternateFilename;
    }

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern IntPtr FindFirstFileW(string filename, out FindData data);

    [DllImport("kernel32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool FindClose(IntPtr handle);

    [RbClassMethod("file_symlink?")]
    private static RbValue FileSymlink(RbState state, RbValue self, RbValue path)
    {
        var filename = path.ToStringUnchecked();
        if (OperatingSystem.IsWindows())
        {
            var handle = FindFirstFileW(filename, out var data);
            if (handle == new IntPtr(-1))
                return state.RbFalse;
            try
            {
                return (data.ReparseTag == 0xA000000C).ToValue(state);
            }
            finally
            {
                FindClose(handle);
            }
        }
        try
        {
            return ((File.GetAttributes(filename) & FileAttributes.ReparsePoint) != 0).ToValue(state);
        }
        catch (FileNotFoundException)
        {
            return state.RbFalse;
        }
        catch (DirectoryNotFoundException)
        {
            return state.RbFalse;
        }
    }

    [RbInitEntryPoint]
    public static void Init(RbClass cls)
    {
        RmvaScripts.Clear();
        resetRequested = false;
        State = RubyScriptManager.Instance.State;
    }

    public static void Update()
    {
        if (UpdateFiber is not null && State.CheckFiberAlive(UpdateFiber).IsTrue)
        {
            bool error = false;
            var res = State.Protect((_, _, _) => State.FiberResume(UpdateFiber), ref error);

            if (error)
            {
                RGSSLogger.LogError("Failed to resume update fiber");
                RGSSLogger.LogError(SafeClassName(res));
            }
        }
    }

    public static void ReleaseUpdateFiber(RbState state)
    {
        if (UpdateFiber is not null)
        {
            state.GcUnregister(UpdateFiber);
            UpdateFiber = null;
        }
    }

    [RbClassMethod("register_update_fiber")]
    private static RbValue RegisterUpdateFiber(RbState state, RbValue self, RbValue fiber)
    {
        if (!fiber.IsFiber)
            return state.RbNil;

        if (UpdateFiber is not null)
            state.GcUnregister(UpdateFiber);

        UpdateFiber = fiber;
        state.GcRegister(fiber);
        return state.RbNil;
    }

    [RbClassMethod("unregister_update_fiber")]
    private static RbValue UnregisterUpdateFiber(RbState state, RbValue self)
    {
        ReleaseUpdateFiber(state);

        return state.RbNil;
    }

    [RbClassMethod("rmva_project_path")]
    private static RbValue GetRmvaProjectPath(RbState state, RbValue self)
        => RMProjectPath.BaseDir.ToValue(state);

    [RbClassMethod("on_top_exception")]
    private static RbValue OnTopExceptionHappened(RbState state, RbValue self, RbValue exceptionString)
    {
        var traceStr = exceptionString.CallMethod("to_s");
        var message = traceStr.IsString ? traceStr.ToStringUnchecked() : SafeClassName(traceStr);
        RGSSLogger.LogError($"Unhandled Ruby exception happened in script:\n {message}");
        return state.RbNil;
    }

    [RbClassMethod("msgbox")]
    private static RbValue MessageBox(RbState state, RbValue self, RbValue[] args)
    {
        foreach (var arg in args)
        {
            var str = arg.CallMethod("to_s");
            RGSSLogger.Log(str.IsString ? str.ToStringUnchecked() : SafeClassName(str));
        }

        return state.RbNil;
    }

    [RbClassMethod("rtp_path")]
    private static RbValue GetRtpPath(RbState state, RbValue self)
        => string.IsNullOrEmpty(GlobalConfig.Instance.RtpPath) ? state.RbNil : GlobalConfig.Instance.RtpPath.ToValue(state);

    [RbClassMethod("cn_ver_rmva")]
    private static RbValue GetChineseRmvaVersion(RbState state, RbValue self)
        => GlobalConfig.Instance.CnVerRmva.ToValue(state);

    private static bool resetRequested;

    public static void RequestReset() => resetRequested = true;

    [RbClassMethod("rgss_reset_requested?")]
    private static RbValue ConsumeResetRequest(RbState state, RbValue self)
    {
        var requested = resetRequested;
        resetRequested = false;
        return requested.ToValue(state);
    }

    [RbClassMethod("reset_rgss_resources")]
    private static RbValue ResetRgssResources(RbState state, RbValue self)
    {
        // SceneManager restarts the stock scene loop; its terminate path owns
        // disposal. Keep the default viewport alive across callback retries.
        InputStateRecorder.Instance.Init();
        return state.RbNil;
    }

    [RbClassMethod("exit_game")]
    private static RbValue ExitGame(RbState state, RbValue self)
    {
        if (Engine.GetMainLoop() is SceneTree tree)
            Callable.From(() => GameManager.QuitGame(tree)).CallDeferred();
        return state.RbNil;
    }

    [RbClassMethod("register_rmva_script")]
    private static RbValue RegisterRmvaScript(RbState state, RbValue self, RbValue scriptId, RbValue scriptName, RbValue scriptContent)
    {
        var id = scriptId.ToIntUnchecked();
        var name = scriptName.IsString ? scriptName.ToStringUnchecked() ?? string.Empty : string.Empty;
        var bytes = RbHelper.GetRawBytesFromRbStringObject(scriptContent);

        if (bytes.Length == 0)
        {
            RmvaScripts.Add((id, name, string.Empty));
            return state.RbNil;
        }

        try
        {
            using var inputStream = new MemoryStream(bytes);
            using var inflaterStream = new InflaterInputStream(inputStream);
            using var outputStream = new MemoryStream();
            inflaterStream.CopyTo(outputStream);

            var scriptString = System.Text.Encoding.UTF8.GetString(outputStream.ToArray());
            RmvaScripts.Add((id, name, scriptString));
        }
        catch (Exception ex)
        {
            RGSSLogger.LogError($"Failed to inflate script '{name}' (id={id}): {ex.Message}");
            RmvaScripts.Add((id, name, string.Empty));
        }

        return state.RbNil;
    }

    [RbClassMethod("run_rmva_scripts")]
    private static RbValue RunRmvaScripts(RbState state, RbValue self)
    {
        var inst = RubyScriptManager.Instance;

        var res = inst.LoadAllScriptInResources("ext", out var error);
        if (error)
        {
            state.Raise(res);
            return res;
        }

        res = inst.LoadAllScriptInResources("rpg", out error);
        if (error)
        {
            state.Raise(res);
            return res;
        }

        var scripts = state.NewArray();
        foreach (var (_, scriptName, scriptContent) in RmvaScripts)
        {
            RGSSLogger.Log($"run rmva script: {scriptName}");
            res = inst.LoadScriptContentWithFileName(scriptName, "proc do\n" + scriptContent + "\nend", out error);

            if (error)
            {
                state.Raise(res);
                return res;
            }
            scripts.Push(res);
        }

        return scripts.Value;
    }

    private static string SafeClassName(RbValue value)
    {
        try { return value.GetClassName() ?? "RubyException"; }
        catch { return "RubyException"; }
    }
}
