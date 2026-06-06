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
        private readonly List<AudioStreamPlayer> sePlayers = new();
        private int seNext;
        private const int SePoolSize = 8;

        private string? bgmPausedFile;
        private float bgmPausedVolume = 1f;
        private float bgmPausedPitch = 1f;

        private Node? parent;

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
            if (player is null) { onLoaded(false); return; }

            var stream = LoadStream(filename);
            if (stream is null)
            {
                RGSSLogger.Log($"AUDIO_LOAD_FAIL:{filename}");
                onLoaded(false);
                return;
            }

            if (type == PlayType.Bgm)
            {
                this.bgmPausedFile   = filename;
                this.bgmPausedVolume = volume;
                this.bgmPausedPitch  = pitch;
            }

            SetLoop(stream, type is PlayType.Bgm or PlayType.Bgs);
            player.Stream = stream;
            player.VolumeDb = Mathf.LinearToDb(Math.Max(0.001f, volume));
            player.PitchScale = Math.Max(0.01f, pitch);
            player.Play(pos);
            onLoaded(true);
        }

        internal void Stop(PlayType type)
        {
            var player = GetPlayer(type);
            player?.Stop();
            if (type == PlayType.Se)
                foreach (var p in this.sePlayers) p.Stop();
        }

        internal void Fade(PlayType type, long milliseconds)
        {
            var player = GetPlayer(type);
            if (player is null || !player.Playing) return;
            var tween = this.parent?.CreateTween();
            tween?.TweenProperty(player, "volume_db", -80f, milliseconds / 1000.0)
                  .SetTrans(Tween.TransitionType.Linear);
            tween?.TweenCallback(Callable.From(player.Stop));
        }

        internal float Pos(PlayType type)
        {
            var player = GetPlayer(type);
            return player?.GetPlaybackPosition() ?? 0f;
        }

        public void Dispose()
        {
            this.bgmPlayer?.QueueFree();
            this.bgsPlayer?.QueueFree();
            this.mePlayer?.QueueFree();
            foreach (var p in this.sePlayers) p.QueueFree();
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
            else if (stream is AudioStreamWav wav)
                wav.LoopMode = loop ? AudioStreamWav.LoopModeEnum.Forward : AudioStreamWav.LoopModeEnum.Disabled;
        }

        private static AudioStream? LoadStream(string filename)
        {
            if (string.IsNullOrEmpty(filename)) return null;
            var ext = System.IO.Path.GetExtension(filename).ToLowerInvariant();
            if (ext == ".wma")
            {
                RGSSLogger.Log($"AUDIO_WMA_SKIP:{filename}");
                return null;
            }

            // Try absolute path first, then RMProject-relative
            var absPath = RMProjectPath.Resolve(filename);
            if (!System.IO.File.Exists(absPath))
            {
                // RTP fallback
                var rtpBase = GlobalConfig.Instance?.RtpPath;
                if (!string.IsNullOrEmpty(rtpBase))
                    absPath = System.IO.Path.Combine(rtpBase, filename);
            }

            if (!System.IO.File.Exists(absPath)) return null;

            try
            {
                return ext switch
                {
                    ".ogg" => AudioStreamOggVorbis.LoadFromFile(absPath),
                    ".wav" => AudioStreamWav.LoadFromFile(absPath),
                    ".mp3" => AudioStreamMP3.LoadFromFile(absPath),
                    _ => null,
                };
            }
            catch (Exception ex)
            {
                RGSSLogger.Log($"AUDIO_LOAD_ERR:{filename}:{ex.Message}");
                return null;
            }
        }

        private AudioStreamPlayer? GetPlayer(PlayType type)
        {
            return type switch
            {
                PlayType.Bgm => this.bgmPlayer,
                PlayType.Bgs => this.bgsPlayer,
                PlayType.Me  => this.mePlayer,
                PlayType.Se  => this.sePlayers.Count > 0
                    ? this.sePlayers[this.seNext++ % this.sePlayers.Count]
                    : null,
                _ => null,
            };
        }

        private void OnMeFinished()
        {
            if (this.bgmPausedFile is null) return;
            Play(PlayType.Bgm, this.bgmPausedFile, this.bgmPausedVolume, this.bgmPausedPitch, 0f, _ => { });
        }
    }
}
