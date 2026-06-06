using MRuby.Library.Language;
using MRuby.Library.Mapper;

namespace RGSSUnity.RubyClasses
{
    [RbModule("Audio", "Unity")]
    public static class Audio
    {
        private static GameAudioManager Instance_ = null!;

        [RbInitEntryPoint]
        public static void Init(RbClass cls)
        {
            Instance_ = GameAudioManager.Instance;
        }

        [RbModuleMethod("setup_midi")]
        public static RbValue SetupMidi(RbState state, RbValue self)
        {
            state.RaiseNotImplementError();
            return state.RbNil;
        }

        [RbModuleMethod("bgm_play")]
        public static RbValue BgmPlay(RbState state, RbValue self,
            RbValue filename, RbValue volume, RbValue pitch, RbValue pos, RbValue onLoadedProc)
        {
            var vol   = (float)(volume.ToIntUnchecked() / 100.0);
            var pit   = (float)(pitch.ToIntUnchecked()  / 100.0);
            var posV  = pos.IsInt ? (float)pos.ToIntUnchecked() : (float)pos.ToFloatUnchecked();
            var file  = filename.ToStringUnchecked() ?? string.Empty;
            state.GcRegister(onLoadedProc);
            Instance_.Play(GameAudioManager.PlayType.Bgm, file, vol, pit, posV, succ =>
            {
                if (!succ && !onLoadedProc.IsNil) onLoadedProc.CallMethod("call");
                state.GcUnregister(onLoadedProc);
            });
            return state.RbNil;
        }

        [RbModuleMethod("bgm_stop")]
        public static RbValue BgmStop(RbState state, RbValue self)
        {
            Instance_.Stop(GameAudioManager.PlayType.Bgm);
            return state.RbNil;
        }

        [RbModuleMethod("bgm_pos")]
        public static RbValue BgmPos(RbState state, RbValue self)
            => Instance_.Pos(GameAudioManager.PlayType.Bgm).ToValue(state);

        [RbModuleMethod("bgm_fade")]
        public static RbValue BgmFade(RbState state, RbValue self, RbValue time)
        {
            Instance_.Fade(GameAudioManager.PlayType.Bgm, time.ToIntUnchecked());
            return state.RbNil;
        }

        [RbModuleMethod("bgs_play")]
        public static RbValue BgsPlay(RbState state, RbValue self,
            RbValue filename, RbValue volume, RbValue pitch, RbValue pos, RbValue onLoadedProc)
        {
            var vol  = (float)(volume.ToIntUnchecked() / 100.0);
            var pit  = (float)(pitch.ToIntUnchecked()  / 100.0);
            var posV = pos.IsInt ? (float)pos.ToIntUnchecked() : (float)pos.ToFloatUnchecked();
            var file = filename.ToStringUnchecked() ?? string.Empty;
            state.GcRegister(onLoadedProc);
            Instance_.Play(GameAudioManager.PlayType.Bgs, file, vol, pit, posV, succ =>
            {
                if (!succ && !onLoadedProc.IsNil) onLoadedProc.CallMethod("call");
                state.GcUnregister(onLoadedProc);
            });
            return state.RbNil;
        }

        [RbModuleMethod("bgs_stop")]
        public static RbValue BgsStop(RbState state, RbValue self)
        {
            Instance_.Stop(GameAudioManager.PlayType.Bgs);
            return state.RbNil;
        }

        [RbModuleMethod("bgs_pos")]
        public static RbValue BgsPos(RbState state, RbValue self)
            => Instance_.Pos(GameAudioManager.PlayType.Bgs).ToValue(state);

        [RbModuleMethod("bgs_fade")]
        public static RbValue BgsFade(RbState state, RbValue self, RbValue time)
        {
            Instance_.Fade(GameAudioManager.PlayType.Bgs, time.ToIntUnchecked());
            return state.RbNil;
        }

        [RbModuleMethod("me_play")]
        public static RbValue MePlay(RbState state, RbValue self,
            RbValue filename, RbValue volume, RbValue pitch, RbValue onLoadedProc)
        {
            var vol  = (float)(volume.ToIntUnchecked() / 100.0);
            var pit  = (float)(pitch.ToIntUnchecked()  / 100.0);
            var file = filename.ToStringUnchecked() ?? string.Empty;
            state.GcRegister(onLoadedProc);
            Instance_.Play(GameAudioManager.PlayType.Me, file, vol, pit, 0, succ =>
            {
                if (!succ && !onLoadedProc.IsNil) onLoadedProc.CallMethod("call");
                state.GcUnregister(onLoadedProc);
            });
            return state.RbNil;
        }

        [RbModuleMethod("me_stop")]
        public static RbValue MeStop(RbState state, RbValue self)
        {
            Instance_.Stop(GameAudioManager.PlayType.Me);
            return state.RbNil;
        }

        [RbModuleMethod("me_fade")]
        public static RbValue MeFade(RbState state, RbValue self, RbValue time)
        {
            Instance_.Fade(GameAudioManager.PlayType.Me, time.ToIntUnchecked());
            return state.RbNil;
        }

        [RbModuleMethod("se_play")]
        public static RbValue SePlay(RbState state, RbValue self,
            RbValue filename, RbValue volume, RbValue pitch, RbValue onLoadedProc)
        {
            var vol  = (float)(volume.ToIntUnchecked() / 100.0);
            var pit  = (float)(pitch.ToIntUnchecked()  / 100.0);
            var file = filename.ToStringUnchecked() ?? string.Empty;
            state.GcRegister(onLoadedProc);
            Instance_.Play(GameAudioManager.PlayType.Se, file, vol, pit, 0, succ =>
            {
                if (!succ && !onLoadedProc.IsNil) onLoadedProc.CallMethod("call");
                state.GcUnregister(onLoadedProc);
            });
            return state.RbNil;
        }

        [RbModuleMethod("se_stop")]
        public static RbValue SeStop(RbState state, RbValue self)
        {
            Instance_.Stop(GameAudioManager.PlayType.Se);
            return state.RbNil;
        }

        [RbClassMethod("__set_exception_handler__")]
        public static RbValue SetExceptionHandler(RbState state, RbValue self, RbValue handler)
        {
            // mruby-side error callback; no-op for now (Ruby exception handling covers this)
            state.GcRegister(handler);
            return state.RbNil;
        }
    }
}
