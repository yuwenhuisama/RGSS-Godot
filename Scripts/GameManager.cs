using System;
using Godot;
using RGSSGodot;
using RGSSUnity.RubyClasses;

namespace RGSSUnity;

public partial class GameManager : Node
{
    public override void _Ready()
    {
        Engine.MaxFps = 60;

        try
        {
            GlobalConfig.Initialize();
            RMProjectPath.Initialize();
            GD.Print($"CONFIG:{GlobalConfig.Instance.LegacyMode},{GlobalConfig.Instance.LegacyModeWidth}x{GlobalConfig.Instance.LegacyModeHeight}");

            GameRenderManager.Instance.Initialize(this);
            GameAudioManager.Instance.Initialize(this);

            // Input subsystem: allocate the double-buffered recorder, register the
            // 20 RGSS actions in Godot's InputMap, and attach the per-frame poller
            // as a child node. Mirrors the Unity boot order (render -> input -> ruby).
            InputStateRecorder.Instance.Init();
            RegisterInputActions();
            AddChild(new GameInputManager { Name = "GameInputManager" });

            RubyScriptManager.Instance.Initialize();
            GD.Print("SCRIPTS_LOADED:OK");

            RubyScriptManager.Instance.LoadMainScript();
        }
        catch (Exception ex)
        {
            GD.PrintErr($"SCRIPTS_LOADED:FAIL:{ex.GetType().Name}:{ex.Message}");
        }
    }

    public override void _Process(double delta)
    {
        // Swap the input double-buffer BEFORE the fiber pump so Ruby reads a
        // stable snapshot this frame (preserves the Unity frame ordering and the
        // RMVA repeat cadence).
        InputStateRecorder.Instance.Update();
        GameRenderManager.Instance.Update();
        UnityModule.Update();
        RGSSLogger.FlushPendingMessages();
    }

    // Registers the 20 RGSS actions in Godot's InputMap, binding each to the same
    // physical keyboard key declared in Assets/RGSSInput.inputactions. Idempotent:
    // safe to call once at startup. The action/key table is the single source of
    // truth on GameInputManager so registration and polling can never drift.
    private static void RegisterInputActions()
    {
        foreach (var (_, action, keycode) in GameInputManager.ActionTable)
        {
            if (!InputMap.HasAction(action))
                InputMap.AddAction(action);

            InputMap.ActionEraseEvents(action);
            InputMap.ActionAddEvent(action, new InputEventKey { Keycode = keycode });
        }
    }

    public override void _ExitTree()
    {
        GameRenderManager.Instance.Dispose();
        GameAudioManager.Instance.Dispose();
        RubyScriptManager.Instance.Destroy();
    }

    public override void _Notification(int what)
    {
        if (what != NotificationWMCloseRequest)
            return;

        GameRenderManager.Instance.Dispose();
        GameAudioManager.Instance.Dispose();
        RubyScriptManager.Instance.Destroy();
        GetTree().Quit();
    }
}
