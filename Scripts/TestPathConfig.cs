using System;
using System.IO;
using System.Text.Json;
using Godot;

namespace RGSSUnity;

internal static class TestPathConfig
{
    internal static void Apply(GlobalConfig config)
    {
        var file = System.Environment.GetEnvironmentVariable("RGSS_TEST_PATHS_FILE");
        if (string.IsNullOrEmpty(file))
            file = ProjectSettings.GlobalizePath("res://.test-paths.local.json");
        if (!System.IO.File.Exists(file))
        {
            config.SetTestPaths(ProjectSettings.GlobalizePath("res://"), string.Empty);
            return;
        }
        using var values = JsonDocument.Parse(System.IO.File.ReadAllText(file).TrimStart('\uFEFF'));
        var directory = Path.GetDirectoryName(Path.GetFullPath(file))!;
        string ReadPath(string key)
        {
            if (!values.RootElement.TryGetProperty(key, out var item) || item.GetString() is not { Length: > 0 } path)
                return string.Empty;
            return Path.IsPathRooted(path) ? path : Path.GetFullPath(Path.Combine(directory, path));
        }
        var game = ReadPath("game_project");
        config.SetTestPaths(string.IsNullOrEmpty(game) ? ProjectSettings.GlobalizePath("res://") : game, ReadPath("rtp"));
    }
}
