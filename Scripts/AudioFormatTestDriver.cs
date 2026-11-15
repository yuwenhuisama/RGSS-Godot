using System;
using System.Reflection;
using Godot;
using RGSSUnity;

namespace RGSSGodot;

// Test-only bridge for tests/test_audio_formats.gd. It drives the real
// GameAudioManager loader/playback entry points (no parallel reimplementation)
// and the config values the audio path contract depends on.
[GlobalClass]
public partial class AudioFormatTestDriver : RefCounted
{
    private static readonly MethodInfo? LoadStreamMethod =
        typeof(GameAudioManager).GetMethod("LoadStream", BindingFlags.Static | BindingFlags.NonPublic);

    private static readonly MethodInfo? ResolveAudioPathMethod =
        typeof(GameAudioManager).GetMethod("ResolveAudioPath", BindingFlags.Static | BindingFlags.NonPublic);

    private static readonly MethodInfo? WmaCachePathMethod =
        typeof(GameAudioManager).GetMethod("WmaCachePath", BindingFlags.Static | BindingFlags.NonPublic);

    private static readonly PropertyInfo? LastDiagnosticProperty =
        typeof(GameAudioManager).GetProperty("LastLoadDiagnostic", BindingFlags.Static | BindingFlags.NonPublic | BindingFlags.Public);

    private static readonly FieldInfo? BgmPlayerField =
        typeof(GameAudioManager).GetField("bgmPlayer", BindingFlags.Instance | BindingFlags.NonPublic);

    private bool initialized;

    public void Initialize(Node parent)
    {
        if (this.initialized)
            return;

        GlobalConfig.Initialize();
        RMProjectPath.Initialize();
        GameAudioManager.Instance.Initialize(parent);
        this.initialized = true;
    }

    public AudioStream? LoadStream(string filename)
    {
        if (LoadStreamMethod is null)
            return null;

        return (AudioStream?)LoadStreamMethod.Invoke(null, new object?[] { filename });
    }

    public string ResolveAudioPath(string filename)
    {
        if (ResolveAudioPathMethod is null)
            return string.Empty;

        return (string?)ResolveAudioPathMethod.Invoke(null, new object?[] { filename }) ?? string.Empty;
    }

    public string GetWmaCachePath(string absPath)
    {
        if (WmaCachePathMethod is null)
            return string.Empty;

        return (string?)WmaCachePathMethod.Invoke(null, new object?[] { absPath }) ?? string.Empty;
    }

    public string GetLastLoadDiagnostic()
        => (string?)LastDiagnosticProperty?.GetValue(null) ?? string.Empty;

    public bool PlayBgm(string filename)
    {
        var loaded = false;
        GameAudioManager.Instance.Play(GameAudioManager.PlayType.Bgm, filename, 1f, 1f, 0f, ok => loaded = ok);
        return loaded;
    }

    public AudioStream? GetBgmStream()
        => (BgmPlayerField?.GetValue(GameAudioManager.Instance) as AudioStreamPlayer)?.Stream;

    public bool GetBgmPlaying()
        => BgmPlayerField?.GetValue(GameAudioManager.Instance) is AudioStreamPlayer { Playing: true };

    public void StopBgm()
        => GameAudioManager.Instance.Stop(GameAudioManager.PlayType.Bgm);

    public string GetRtpPath()
        => GlobalConfig.Instance.RtpPath;

    public string GetProjectAudioDir()
        => System.IO.Path.Combine(RMProjectPath.RMProjectDir, "Audio");

    public void SetFfmpegPath(string path)
        => System.Environment.SetEnvironmentVariable("RGSS_FFMPEG_PATH", string.IsNullOrEmpty(path) ? null : path);

    public void FlushLog()
        => RGSSLogger.FlushPendingMessages();

    public void Shutdown()
    {
        if (!this.initialized)
            return;

        // Release the player's stream/playback before freeing the nodes; otherwise
        // Godot reports AudioStreamWAV + AudioStreamPlaybackWAV as leaked at exit.
        GameAudioManager.Instance.Stop(GameAudioManager.PlayType.Bgm);
        if (BgmPlayerField?.GetValue(GameAudioManager.Instance) is AudioStreamPlayer bgm)
            bgm.Stream = null;
        GameAudioManager.Instance.Dispose();
        this.initialized = false;
    }
}
