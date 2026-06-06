
## F1 plan compliance audit - 2026-06-06
- Ruby layer diff is clean: only RGSS/patch_rmva.rb differs from Unity baseline, exactly 5 include?('\\.') -> include?('.') lines (108, 121, 134, 147, 164).
- Godot C# guardrails checked clean for Unity module name, no renamed Godot/RGSS module, no Tilemap binding, no UnityEngine namespace, no C# finalizer/destructor patterns, and no QueueFree/Free inside finalizers.
- All 3 State.Protect calls have immediate GC.KeepAlive(func): Scripts/UnityModule.cs:38-39 and Scripts/RubyScriptManager.cs:162-165,195-198.
- Required evidence files requested by F1 are present and dotnet build succeeds with 0 warnings / 0 errors.
- Final verdict remains REJECT for plan completeness because top-level plan TODOs are 26/33 checked; open tasks include T6, T27, T28, F1-F4 and final user-approval gates.

## F2 Code Quality Review (2026-06-06)
- BUILD 0/0, GUT 1/1 pass.
- Color.cs round-trip bugs (REJECT): blue= (L126) and alpha= (L142) use *255 instead of /255 (red=/green= correctly use /255). set_rgba (L75-78) stores raw 0..255 while new_rgba/CreateColor store 0..1; getters multiply by 255 assuming 0..1 -> broken read-back after blue=/alpha=/set.
- Minor: Sprite/Plane dispose null node fields but leave Tone/Color/SrcRect set (harmless, kept by live-keeper). Viewport dispose leaves Tone/FlashColor.
- Minor: Color.cs catch blocks use Console.Error.WriteLine (convention is RGSSLogger), but they are C# catches (not Ruby rescue) and rethrow.
- Warning: namespace split - RubyScriptManager/Kernel/BootManager/StressDisposeTestDriver use RGSSGodot, rest use RGSSUnity[.RubyClasses].
- Warning: GameAudioManager.CreatePlayer 'loop' param unused; Graphics.Freezing never read; GameInputManager L19 comment claims Escape bound to rgss_b but RegisterInputActions never adds it.
- Warning: GUT coverage is just a 1+1 sample; test_stress_dispose.gd ignored (does not extend GutTest).
