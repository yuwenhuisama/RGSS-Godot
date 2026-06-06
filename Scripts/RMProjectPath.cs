using System.Diagnostics;
using System.IO;
using Godot;

namespace RGSSUnity;

public static class RMProjectPath
{
    public static string BaseDir { get; private set; } = string.Empty;

    public static string RMProjectDir => Path.Combine(BaseDir, "RMProject");

    public static void Initialize()
    {
        BaseDir = ResolveBaseDir();
        BaseDir = NormalizePath(BaseDir);
        GD.Print($"RMPROJECT_PATH:{BaseDir}");
    }

    public static string Resolve(string relativePath)
    {
        var path = Path.Combine(RMProjectDir, relativePath);
        return NormalizePath(path);
    }

    public static bool Exists(string relativePath)
        => File.Exists(Resolve(relativePath));

    public static byte[] ReadAllBytes(string relativePath)
        => File.ReadAllBytes(Resolve(relativePath));

    public static void WriteAllBytes(string relativePath, byte[] data)
        => File.WriteAllBytes(Resolve(relativePath), data);

    private static string ResolveBaseDir()
    {
        var configuredProjectPath = GlobalConfig.Instance.ProjectPath;
        if (!string.IsNullOrWhiteSpace(configuredProjectPath))
            return ResolveConfiguredPath(configuredProjectPath);

        var exePath = Process.GetCurrentProcess().MainModule?.FileName;
        var exeDir = string.IsNullOrWhiteSpace(exePath) ? string.Empty : Path.GetDirectoryName(exePath) ?? string.Empty;
        if (!string.IsNullOrWhiteSpace(exeDir) && Directory.Exists(Path.Combine(exeDir, "RMProject")))
            return exeDir;

        var cwd = Directory.GetCurrentDirectory();
        if (!string.IsNullOrWhiteSpace(cwd))
            return cwd;

        return ProjectSettings.GlobalizePath("res://");
    }

    private static string ResolveConfiguredPath(string configuredProjectPath)
    {
        var path = Path.IsPathRooted(configuredProjectPath)
            ? configuredProjectPath
            : Path.Combine(GetExeDirectory(), configuredProjectPath);

        path = NormalizePath(path);

        var fileName = Path.GetFileName(path.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar));
        if (string.Equals(fileName, "RMProject", System.StringComparison.OrdinalIgnoreCase))
            return Directory.GetParent(path)?.FullName ?? path;

        return path;
    }

    private static string GetExeDirectory()
    {
        var exePath = Process.GetCurrentProcess().MainModule?.FileName;
        var exeDir = string.IsNullOrWhiteSpace(exePath) ? string.Empty : Path.GetDirectoryName(exePath) ?? string.Empty;
        return NormalizePath(exeDir);
    }

    private static string NormalizePath(string path)
        => string.IsNullOrWhiteSpace(path)
            ? string.Empty
            : Path.GetFullPath(path).TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
}
