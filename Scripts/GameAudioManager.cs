using System;
using System.Collections.Generic;
using Godot;

namespace RGSSUnity
{
    public sealed class GameAudioManager : IDisposable
    {
        public static readonly GameAudioManager Instance = new();

        internal enum PlayType { Bgm = 0, Bgs, Me, Se }

        private AudioStreamPlayer? bgmPlayer;
        private AudioStreamPlayer? bgsPlayer;
        private AudioStreamPlayer? mePlayer;
        private string? bgmFile;
        private string? bgsFile;
        private readonly Dictionary<PlayType, float> positionByteRates = new();
        private readonly Dictionary<PlayType, float> stoppedPositions = new();
        private readonly Dictionary<PlayType, float> positionOrigins = new();
        private readonly Dictionary<PlayType, Tween> fades = new();
        private readonly List<AudioStreamPlayer> sePlayers = new();
        private const int SePoolSize = 8;

        private static readonly string[] AudioExtensions = { ".ogg", ".wav", ".mp3", ".wma" };
        private const string FfmpegEnvVar = "RGSS_FFMPEG_PATH";

        // Last loader outcome, for diagnostics and the audio format contract test.
        private static string LastLoadDiagnostic { get; set; } = string.Empty;

        private Node? parent;
        internal bool MePlaying => this.mePlayer is { Playing: true };

        public void SetEnabled(bool music, bool sound)
        {
            GameMidiPlayer.SetMuted(!music);
            var musicBus = AudioServer.GetBusIndex("RGSSMusic");
            if (musicBus < 0)
            {
                AudioServer.AddBus();
                musicBus = AudioServer.BusCount - 1;
                AudioServer.SetBusName(musicBus, "RGSSMusic");
            }
            var soundBus = AudioServer.GetBusIndex("RGSSSound");
            if (soundBus < 0)
            {
                AudioServer.AddBus();
                soundBus = AudioServer.BusCount - 1;
                AudioServer.SetBusName(soundBus, "RGSSSound");
            }
            AudioServer.SetBusMute(musicBus, !music);
            AudioServer.SetBusMute(soundBus, !sound);
            if (this.bgmPlayer is not null) this.bgmPlayer.Bus = "RGSSMusic";
            if (this.bgsPlayer is not null) this.bgsPlayer.Bus = "RGSSSound";
            if (this.mePlayer is not null) this.mePlayer.Bus = "RGSSMusic";
            foreach (var player in this.sePlayers) player.Bus = "RGSSSound";
        }

        private GameAudioManager() { }

        public void Initialize(Node parent)
        {
            this.parent = parent;

            this.bgmPlayer = CreatePlayer("BGM", parent, loop: true);
            this.bgsPlayer = CreatePlayer("BGS", parent, loop: true);
            this.mePlayer  = CreatePlayer("ME",  parent, loop: false);

            for (var i = 0; i < SePoolSize; i++)
            {
                var p = CreatePlayer($"SE_{i}", parent, loop: false);
                this.sePlayers.Add(p);
            }

            this.mePlayer.Finished += OnMeFinished;
        }

        internal void Play(PlayType type, string filename, float volume, float pitch, float pos, Action<bool> onLoaded)
        {
            var player = GetPlayer(type);
            if (type == PlayType.Se && this.parent is not null)
            {
                player = this.sePlayers.Find(candidate => !candidate.Playing);
                if (player is null)
                {
                    player = CreatePlayer($"SE_{this.sePlayers.Count}", this.parent, loop: false);
                    player.Bus = "RGSSSound";
                    this.sePlayers.Add(player);
                }
            }
            if (player is null) { onLoaded(false); return; }

            if (type is PlayType.Bgm or PlayType.Bgs && player.HasStreamPlayback()
                && player.PitchScale == Math.Max(0.01f, pitch)
                && filename == (type == PlayType.Bgm ? this.bgmFile : this.bgsFile))
            {
                if (this.fades.Remove(type, out var previousFade)) previousFade.Kill();
                player.VolumeDb = volume > 0 ? (volume - 1f) * 35f : -80f;
                player.PitchScale = Math.Max(0.01f, pitch);
                onLoaded(true);
                return;
            }

            var stream = LoadStream(filename);
            if (stream is null)
            {
                RGSSLogger.Log(string.IsNullOrEmpty(LastLoadDiagnostic)
                    ? $"AUDIO_LOAD_FAIL:{filename}"
                    : LastLoadDiagnostic);
                onLoaded(false);
                return;
            }

            if (this.fades.Remove(type, out var fade)) fade.Kill();
            if (type == PlayType.Me && this.bgmPlayer is not null)
            {
                this.bgmPlayer.StreamPaused = true;
                GameMidiPlayer.SetPaused(true);
            }

            SetLoop(stream, type is PlayType.Bgm or PlayType.Bgs);
            if (type == PlayType.Bgm) this.bgmFile = filename;
            if (type == PlayType.Bgs) this.bgsFile = filename;
            player.Stream = stream;
            player.VolumeDb = volume > 0 ? (volume - 1f) * 35f : -80f;
            player.PitchScale = Math.Max(0.01f, pitch);
            var byteRate = 0f;
            if (stream is AudioStreamOggVorbis vorbis)
            {
                var header = vorbis.PacketSequence.PacketData[0][0].AsByteArray();
                byteRate = vorbis.PacketSequence.SamplingRate * header[11] * 2;
            }
            this.positionByteRates[type] = byteRate;
            this.stoppedPositions[type] = 0f;
            player.Play(byteRate > 0 ? pos / byteRate : 0f);
            this.positionOrigins[type] = byteRate > 0 ? player.GetPlaybackPosition() * byteRate - pos : 0f;
            if (type == PlayType.Bgm)
                player.StreamPaused = this.mePlayer is { Playing: true };
            onLoaded(true);
        }

        internal void Stop(PlayType type)
        {
            if (this.fades.Remove(type, out var fade)) fade.Kill();
            var player = GetPlayer(type);
            this.stoppedPositions[type] = Pos(type);
            player?.Stop();
            if (type == PlayType.Me)
                OnMeFinished();
            if (type == PlayType.Se)
                foreach (var p in this.sePlayers) p.Stop();
        }

        internal void Fade(PlayType type, long milliseconds)
        {
            if (milliseconds == 0) return;
            var player = GetPlayer(type);
            if (player is null || !player.Playing) return;
            if (this.fades.Remove(type, out var previousFade)) previousFade.Kill();
            var tween = this.parent?.CreateTween();
            if (tween is not null) this.fades[type] = tween;
            tween?.TweenProperty(player, "volume_db", Math.Min(player.VolumeDb, -35f), milliseconds / 1000.0)
                  .SetTrans(Tween.TransitionType.Linear);
            tween?.TweenCallback(Callable.From(() =>
            {
                this.stoppedPositions[type] = Pos(type);
                this.fades.Remove(type);
                player.Stop();
                if (type == PlayType.Me)
                    ResumeStreamedBgm();
            }));
        }

        internal float Pos(PlayType type)
        {
            var player = GetPlayer(type);
            var byteRate = this.positionByteRates.GetValueOrDefault(type);
            if (player is not { Playing: true })
                return this.stoppedPositions.GetValueOrDefault(type);
            if (byteRate == 0) return 0f;
            var position = player.GetPlaybackPosition() * byteRate - this.positionOrigins.GetValueOrDefault(type);
            if (position < 0) position += (float)player.Stream.GetLength() * byteRate;
            return position;
        }

        public void Dispose()
        {
            foreach (var fade in this.fades.Values) fade.Kill();
            this.fades.Clear();
            this.bgmPlayer?.QueueFree();
            this.bgsPlayer?.QueueFree();
            this.mePlayer?.QueueFree();
            foreach (var p in this.sePlayers) p.QueueFree();
            this.sePlayers.Clear();
            this.bgmPlayer = null;
            this.bgsPlayer = null;
            this.mePlayer = null;
            this.bgmFile = null;
            this.bgsFile = null;
            this.parent = null;
            this.positionByteRates.Clear();
            this.stoppedPositions.Clear();
            this.positionOrigins.Clear();
        }

        // ── helpers ──────────────────────────────────────────────────────────

        private static AudioStreamPlayer CreatePlayer(string name, Node parent, bool loop)
        {
            var p = new AudioStreamPlayer { Name = name, Autoplay = false };
            parent.AddChild(p);
            return p;
        }

        private static void SetLoop(AudioStream stream, bool loop)
        {
            if (stream is AudioStreamOggVorbis ogg) ogg.Loop = loop;
            else if (stream is AudioStreamMP3 mp3) mp3.Loop = loop;
            else if (stream is AudioStreamWav wav)
            {
                if (loop && wav.LoopEnd <= wav.LoopBegin)
                    wav.LoopEnd = (int)Math.Round(wav.GetLength() * wav.MixRate);
                wav.LoopMode = loop ? AudioStreamWav.LoopModeEnum.Forward : AudioStreamWav.LoopModeEnum.Disabled;
            }
        }

        private static AudioStream? LoadStream(string filename)
        {
            LastLoadDiagnostic = string.Empty;
            if (string.IsNullOrEmpty(filename)) return null;

            var absPath = ResolveAudioPath(filename);
            if (string.IsNullOrEmpty(absPath) || !System.IO.File.Exists(absPath))
            {
                LastLoadDiagnostic = $"AUDIO_LOAD_FAIL:{filename}";
                return null;
            }

            var ext = System.IO.Path.GetExtension(absPath).ToLowerInvariant();
            try
            {
                return ext switch
                {
                    ".ogg" => AudioStreamOggVorbis.LoadFromFile(absPath),
                    ".wav" => AudioStreamWav.LoadFromFile(absPath),
                    ".mp3" => AudioStreamMP3.LoadFromFile(absPath),
                    // WMA uses the bundled platform decoder unless explicitly overridden.
                    ".wma" => LoadWma(absPath),
                    _ => null,
                };
            }
            catch (Exception ex)
            {
                LastLoadDiagnostic = $"AUDIO_LOAD_ERR:{filename}:{ex.Message}";
                RGSSLogger.LogError(LastLoadDiagnostic);
                return null;
            }
        }

        // RGSS3 resolves audio as project-first, then RTP, and accepts a filename
        // with the extension omitted. patch_rmva.rb appends ".ogg" before calling
        // here, so a project asset that is really .wav/.wma/.mp3 only loads if the
        // sibling extensions are probed. patch_rmva.rb also passes ABSOLUTE
        // project paths; the previous Path.Combine(rtp, absolute) returned the
        // absolute path unchanged, so RTP was never consulted (E08).
        private static string ResolveAudioPath(string filename)
        {
            if (string.IsNullOrEmpty(filename)) return string.Empty;

            if (System.IO.Path.IsPathRooted(filename))
            {
                var direct = System.IO.Path.GetFullPath(filename);
                if (System.IO.File.Exists(direct)) return direct;
                return ProbeAudioExtensions(direct) ?? ResolveRtpPath(filename);
            }

            var projectPath = RMProjectPath.Resolve(filename);
            if (System.IO.File.Exists(projectPath)) return projectPath;
            return ProbeAudioExtensions(projectPath) ?? ResolveRtpPath(filename);
        }

        private static string ResolveRtpPath(string filename)
        {
            var rtpBase = GlobalConfig.Instance?.RtpPath;
            if (string.IsNullOrEmpty(rtpBase)) return string.Empty;

            var relative = filename;
            if (System.IO.Path.IsPathRooted(filename))
            {
                relative = System.IO.Path.GetRelativePath(RMProjectPath.RMProjectDir, System.IO.Path.GetFullPath(filename));
                // Outside the project tree there is no RTP-relative counterpart.
                if (System.IO.Path.IsPathRooted(relative) || relative.StartsWith("..")) return string.Empty;
            }

            var rtpPath = System.IO.Path.GetFullPath(System.IO.Path.Combine(rtpBase, relative));
            if (System.IO.File.Exists(rtpPath)) return rtpPath;
            return ProbeAudioExtensions(rtpPath) ?? string.Empty;
        }

        private static string? ProbeAudioExtensions(string path)
        {
            var ext = System.IO.Path.GetExtension(path);
            var stem = ext.Length > 0 ? path[..^ext.Length] : path;
            foreach (var candidateExt in AudioExtensions)
            {
                if (string.Equals(candidateExt, ext, System.StringComparison.OrdinalIgnoreCase)) continue;
                var candidate = stem + candidateExt;
                if (System.IO.File.Exists(candidate)) return candidate;
            }

            return null;
        }

        private static AudioStream? LoadWma(string absPath)
        {
            var ffmpeg = System.Environment.GetEnvironmentVariable(FfmpegEnvVar);
            if (string.IsNullOrWhiteSpace(ffmpeg))
            {
                var platform = OperatingSystem.IsWindows() ? "windows" : OperatingSystem.IsMacOS() ? "macos" : "linux";
                var executable = OperatingSystem.IsWindows() ? "ffmpeg.exe" : "ffmpeg";
                var projectDecoder = ProjectSettings.GlobalizePath($"res://Plugins/{platform}/audio/{executable}");
                var exportedDecoder = System.IO.Path.Combine(AppContext.BaseDirectory, "Plugins", platform, "audio", executable);
                ffmpeg = System.IO.File.Exists(projectDecoder) ? projectDecoder : exportedDecoder;
            }
            if (string.IsNullOrWhiteSpace(ffmpeg) || !System.IO.File.Exists(ffmpeg))
            {
                LastLoadDiagnostic = $"AUDIO_WMA_NO_DECODER:{absPath}";
                RGSSLogger.Log(LastLoadDiagnostic);
                return null;
            }

            var cachePath = WmaCachePath(absPath);
            if (cachePath is null)
            {
                LastLoadDiagnostic = $"AUDIO_WMA_CACHE_ERR:{absPath}";
                return null;
            }

            if (!System.IO.File.Exists(cachePath) && !ConvertWma(ffmpeg, absPath, cachePath))
            {
                LastLoadDiagnostic = $"AUDIO_WMA_DECODE_FAIL:{absPath}";
                return null;
            }

            try
            {
                var stream = AudioStreamWav.LoadFromFile(cachePath);
                LastLoadDiagnostic = $"AUDIO_WMA_DECODED:{absPath}";
                return stream;
            }
            catch (Exception ex)
            {
                LastLoadDiagnostic = $"AUDIO_WMA_LOAD_ERR:{absPath}:{ex.Message}";
                RGSSLogger.LogError(LastLoadDiagnostic);
                return null;
            }
        }

        // Stable per-source cache name: invalidates when the source changes.
        private static string? WmaCachePath(string absPath)
        {
            try
            {
                var info = new System.IO.FileInfo(absPath);
                var stamp = $"{info.FullName}|{info.Length}|{info.LastWriteTimeUtc.Ticks}";
                var hash = System.Security.Cryptography.SHA256.HashData(System.Text.Encoding.UTF8.GetBytes(stamp));
                var name = System.Convert.ToHexString(hash)[..16].ToLowerInvariant() + ".wav";
                var dir = ProjectSettings.GlobalizePath("user://audio_cache/wma");
                System.IO.Directory.CreateDirectory(dir);
                return System.IO.Path.Combine(dir, name);
            }
            catch (Exception ex)
            {
                RGSSLogger.LogError($"AUDIO_WMA_CACHE_ERR:{absPath}:{ex.Message}");
                return null;
            }
        }

        private static bool ConvertWma(string ffmpeg, string source, string target)
        {
            var temp = target + ".tmp.wav";
            try
            {
                var startInfo = new System.Diagnostics.ProcessStartInfo
                {
                    FileName = ffmpeg,
                    UseShellExecute = false,
                    CreateNoWindow = true,
                    RedirectStandardError = true,
                    RedirectStandardOutput = true,
                };
                foreach (var arg in new[] { "-hide_banner", "-loglevel", "error", "-y", "-i", source, "-vn", "-acodec", "pcm_s16le", temp })
                    startInfo.ArgumentList.Add(arg);

                using var process = System.Diagnostics.Process.Start(startInfo);
                if (process is null) return false;

                var stderr = process.StandardError.ReadToEndAsync();
                var stdout = process.StandardOutput.ReadToEndAsync();
                if (!process.WaitForExit(30_000))
                {
                    try { process.Kill(entireProcessTree: true); } catch { }
                    RGSSLogger.LogError($"AUDIO_WMA_DECODE_TIMEOUT:{source}");
                    return false;
                }

                var stderrText = stderr.GetAwaiter().GetResult();
                _ = stdout.GetAwaiter().GetResult();
                if (process.ExitCode != 0 || !System.IO.File.Exists(temp) || new System.IO.FileInfo(temp).Length == 0)
                {
                    RGSSLogger.LogError($"AUDIO_WMA_DECODE_FAIL:{source}:exit={process.ExitCode}:{stderrText}");
                    return false;
                }

                System.IO.File.Move(temp, target, overwrite: true);
                return true;
            }
            catch (Exception ex)
            {
                RGSSLogger.LogError($"AUDIO_WMA_DECODE_ERR:{source}:{ex.Message}");
                return false;
            }
            finally
            {
                try { if (System.IO.File.Exists(temp)) System.IO.File.Delete(temp); } catch { }
            }
        }

        private AudioStreamPlayer? GetPlayer(PlayType type)
        {
            return type switch
            {
                PlayType.Bgm => this.bgmPlayer,
                PlayType.Bgs => this.bgsPlayer,
                PlayType.Me  => this.mePlayer,
                PlayType.Se  => null,
                _ => null,
            };
        }

        private void OnMeFinished()
        {
            GameMidiPlayer.SetPaused(false);
            ResumeStreamedBgm();
        }

        private void ResumeStreamedBgm()
        {
            if (this.bgmPlayer is not null)
                this.bgmPlayer.StreamPaused = false;
        }
    }
}
