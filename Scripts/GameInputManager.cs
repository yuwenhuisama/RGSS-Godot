using Godot;

namespace RGSSUnity
{
    // Single source of truth for the RGSS action/key bindings, used by
    // GameManager.RegisterInputActions (to populate Godot's InputMap) and by
    // InputStateRecorder.Update (to poll held action state each frame).
    //
    // Input polling itself lives in InputStateRecorder.Update, which is driven once per
    // frame by Ruby's Input.update (RMVA Scene_Base#update_basic). Polling there -- rather
    // than in a separate node's _Process -- guarantees the press is observed in the same
    // frame the scene reads it (Godot runs a parent's _Process before its children, so a
    // child poll would land one frame late).
    public static class GameInputManager
    {
        // (recorder_key, godot_action_name, primary_keycode)
        internal static readonly (InputStateRecorder.InputKey recorderKey, string action, Key keycode)[] ActionTable =
        {
            (InputStateRecorder.InputKey.DOWN,  "rgss_down",  Key.Down),
            (InputStateRecorder.InputKey.LEFT,  "rgss_left",  Key.Left),
            (InputStateRecorder.InputKey.RIGHT, "rgss_right", Key.Right),
            (InputStateRecorder.InputKey.UP,    "rgss_up",    Key.Up),
            (InputStateRecorder.InputKey.A,     "rgss_a",     Key.X),
            (InputStateRecorder.InputKey.B,     "rgss_b",     Key.X),      // escape also added in RegisterInputActions
            (InputStateRecorder.InputKey.C,     "rgss_c",     Key.Z),
            (InputStateRecorder.InputKey.X,     "rgss_x",     Key.A),
            (InputStateRecorder.InputKey.Y,     "rgss_y",     Key.S),
            (InputStateRecorder.InputKey.Z,     "rgss_z",     Key.C),
            (InputStateRecorder.InputKey.L,     "rgss_l",     Key.L),
            (InputStateRecorder.InputKey.R,     "rgss_r",     Key.R),
            (InputStateRecorder.InputKey.SHIFT, "rgss_shift", Key.Shift),
            (InputStateRecorder.InputKey.CTRL,  "rgss_ctrl",  Key.Ctrl),
            (InputStateRecorder.InputKey.ALT,   "rgss_alt",   Key.Alt),
            (InputStateRecorder.InputKey.F5,    "rgss_f5",    Key.F5),
            (InputStateRecorder.InputKey.F6,    "rgss_f6",    Key.F6),
            (InputStateRecorder.InputKey.F7,    "rgss_f7",    Key.F7),
            (InputStateRecorder.InputKey.F8,    "rgss_f8",    Key.F8),
            (InputStateRecorder.InputKey.F9,    "rgss_f9",    Key.F9),
        };
    }
}
