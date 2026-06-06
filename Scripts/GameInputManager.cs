using Godot;

namespace RGSSUnity
{
    // Polls Godot's InputMap each _Process and feeds InputStateRecorder.
    // 20 RGSS actions mapped from RGSSInput.inputactions keyboard bindings.
    public partial class GameInputManager : Node
    {
        // (recorder_key, godot_action_name, primary_keycode)
        // GameManager.RegisterInputActions uses this as the single source of truth
        // for both registration and polling.
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

        public override void _Process(double delta)
        {
            var recorder = InputStateRecorder.Instance;
            foreach (var (recKey, action, _) in ActionTable)
            {
                if (!InputMap.HasAction(action)) continue;
                if (Godot.Input.IsActionJustPressed(action))
                    recorder.SetPress(recKey);
                else if (Godot.Input.IsActionJustReleased(action))
                    recorder.SetRelease(recKey);
            }
        }
    }
}
