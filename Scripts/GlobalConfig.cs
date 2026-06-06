using System;
using System.IO;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using Godot;

namespace RGSSUnity;

public sealed class GlobalConfig
{
    private const string ConfigFileName = "rm_conf.json";
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = false
    };

    public static GlobalConfig Instance { get; private set; } = new();

    public string RtpPath { get; private set; } = string.Empty;
    public string ProjectPath { get; private set; } = string.Empty;
    public bool LegacyMode { get; private set; }
    public int LegacyModeWidth { get; private set; } = 544;
    public int LegacyModeHeight { get; private set; } = 416;
    public bool CnVerRmva { get; private set; }

    public static void Initialize()
    {
        Instance = Load();
    }

    private static GlobalConfig Load()
    {
        var candidatePaths = GetCandidatePaths();

        foreach (var path in candidatePaths)
        {
            if (!File.Exists(path))
                continue;

            try
            {
                var bytes = File.ReadAllBytes(path);
                if (HasUtf8Bom(bytes))
                    bytes = bytes[3..];

                var config = JsonSerializer.Deserialize<RmConfig>(bytes, JsonOptions);
                if (config is null)
                    break;

                return new GlobalConfig
                {
                    RtpPath = config.RtpPath ?? string.Empty,
                    ProjectPath = config.ProjectPath ?? string.Empty,
                    LegacyMode = config.LegacyMode,
                    LegacyModeWidth = config.LegacyModeWidth,
                    LegacyModeHeight = config.LegacyModeHeight,
                    CnVerRmva = config.CnVerRmva,
                };
            }
            catch (Exception ex)
            {
                GD.PrintErr($"GlobalConfig failed to load {path}: {ex.Message}");
                break;
            }
        }

        GD.PrintErr($"GlobalConfig warning: {ConfigFileName} not found or unreadable; using defaults.");
        return new GlobalConfig();
    }

    private static bool HasUtf8Bom(byte[] bytes)
        => bytes.Length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF;

    private static string[] GetCandidatePaths()
    {
        var exePath = OS.GetExecutablePath();
        var exeDir = string.IsNullOrWhiteSpace(exePath) ? string.Empty : Path.GetDirectoryName(exePath) ?? string.Empty;
        var projectDir = ProjectSettings.GlobalizePath("res://");
        var cwd = Directory.GetCurrentDirectory();

        return new[]
        {
            Path.Combine(exeDir, ConfigFileName),
            Path.Combine(projectDir, ConfigFileName),
            Path.Combine(cwd, ConfigFileName),
        };
    }

    private sealed record RmConfig
    {
        [JsonPropertyName("rtp_path")]
        public string? RtpPath { get; init; }

        [JsonPropertyName("project_path")]
        public string? ProjectPath { get; init; }

        [JsonPropertyName("legacy_mode")]
        public bool LegacyMode { get; init; }

        [JsonPropertyName("legacy_mode_width")]
        public int LegacyModeWidth { get; init; } = 544;

        [JsonPropertyName("legacy_mode_height")]
        public int LegacyModeHeight { get; init; } = 416;

        [JsonPropertyName("cn_ver_rmva")]
        public bool CnVerRmva { get; init; }
    }
}
