using System;
using Godot;
using RGSSUnity;

namespace RGSSGodot;

public partial class BootManager : Node
{
    public override void _Ready()
    {
        try
        {
            GlobalConfig.Initialize();
            GD.Print($"CONFIG:{GlobalConfig.Instance.LegacyMode},{GlobalConfig.Instance.LegacyModeWidth}x{GlobalConfig.Instance.LegacyModeHeight}");
            RubyScriptManager.Instance.Initialize();
            GD.Print("SCRIPTS_LOADED:OK");
            RGSSLogger.Log("LOGGER_TEST:queued");
            RGSSLogger.FlushPendingMessages();
            // Future per-frame location: call RGSSLogger.FlushPendingMessages() from the game manager node's _Process().
        }
        catch (Exception ex)
        {
            GD.PrintErr($"SCRIPTS_LOADED:FAIL:{ex.GetType().Name}:{ex.Message}");
        }
        finally
        {
            GetTree().Quit();
        }
    }

    public override void _ExitTree()
    {
        RubyScriptManager.Instance.Destroy();
    }
}
