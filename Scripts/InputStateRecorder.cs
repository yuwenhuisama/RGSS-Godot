using System;
using Godot;

namespace RGSSUnity
{
    internal class InputStateRecorder
    {
        // RGSS3 key-repeat timing at 60fps (matches mkxp-z / RPG Maker VX Ace):
        //   initial delay = 23 frames, then fires every 6 frames while held.
        private const int RepeatStartFrames = 23;
        private const int RepeatIntervalFrames = 6;

        internal enum InputKey
        {
            DOWN = 0, LEFT, RIGHT, UP,
            A, B, C, X, Y, Z, L, R,
            SHIFT, CTRL, ALT,
            F5, F6, F7, F8, F9,
        }

        [Flags]
        internal enum Direction
        {
            None = 0,
            L    = 1,
            R    = 2,
            U    = 4,
            D    = 8,
        }

        private struct InputState
        {
            public bool Triggered;
            public bool Pressed;
            public bool Repeated;
            public int  RepeatCount;
        }

        public static readonly InputStateRecorder Instance = new();

        // Single published buffer. Queries read this directly; edge detection uses the
        // previous frame's Pressed flag stored in the same struct. The state is recomputed
        // in place by Update(), which is driven once per frame by Ruby's Input.update
        // (RMVA Scene_Base#update_basic) so poll -> compute -> publish -> Ruby-read all
        // happen within the same frame (no off-by-one).
        private InputState[] keyState = Array.Empty<InputState>();

        internal void Init()
        {
            var count = Enum.GetValues(typeof(InputKey)).Length;
            this.keyState = new InputState[count];
        }

        internal void Update()
        {
            for (var i = 0; i < this.keyState.Length; i++)
            {
                ref var s = ref this.keyState[i];

                var wasPressed = s.Pressed;
                var nowPressed = PollPressed((InputKey)i);

                if (!nowPressed)
                {
                    s.Pressed     = false;
                    s.Triggered   = false;
                    s.Repeated    = false;
                    s.RepeatCount = 0;
                    continue;
                }

                s.Pressed = true;

                if (!wasPressed)
                {
                    // RGSS3 PATH A: a fresh press triggers AND repeats immediately, with no
                    // threshold math. This is the behaviour that makes a single tap move the
                    // cursor (process_cursor_move gates movement on Input.repeat?).
                    s.Triggered   = true;
                    s.Repeated    = true;
                    s.RepeatCount = 0;
                }
                else
                {
                    // RGSS3 PATH B: held key -- repeat after the initial delay, then on the
                    // fixed interval.
                    s.Triggered = false;
                    ++s.RepeatCount;
                    s.Repeated = (s.RepeatCount >= RepeatStartFrames)
                              && (((s.RepeatCount + 1) % RepeatIntervalFrames) == 0);
                }
            }
        }

        // Polls Godot's held action state for the given RGSS key. Aggregates every binding
        // mapped to the key (multiple actions / multiple events) with OR, so one released
        // binding never clears another that is still held.
        private static bool PollPressed(InputKey key)
        {
            var pressed = false;
            foreach (var (recKey, action, _) in GameInputManager.ActionTable)
            {
                if (recKey != key)
                    continue;
                if (InputMap.HasAction(action) && Godot.Input.IsActionPressed(action))
                {
                    pressed = true;
                    break;
                }
            }

            return pressed;
        }

        internal bool IsTriggered(InputKey key) => this.keyState[(int)key].Triggered;
        internal bool IsPressed  (InputKey key) => this.keyState[(int)key].Pressed;
        internal bool IsRepeated (InputKey key) => this.keyState[(int)key].Repeated;

        internal Direction GetDir4()
        {
            if (IsPressed(InputKey.UP))    return Direction.U;
            if (IsPressed(InputKey.DOWN))  return Direction.D;
            if (IsPressed(InputKey.LEFT))  return Direction.L;
            if (IsPressed(InputKey.RIGHT)) return Direction.R;
            return Direction.None;
        }

        internal Direction GetDir8()
        {
            bool u = IsPressed(InputKey.UP),   d = IsPressed(InputKey.DOWN);
            bool l = IsPressed(InputKey.LEFT),  r = IsPressed(InputKey.RIGHT);
            if (u && l) return Direction.U | Direction.L;
            if (u && r) return Direction.U | Direction.R;
            if (d && l) return Direction.D | Direction.L;
            if (d && r) return Direction.D | Direction.R;
            if (u) return Direction.U;
            if (d) return Direction.D;
            if (l) return Direction.L;
            if (r) return Direction.R;
            return Direction.None;
        }
    }
}
