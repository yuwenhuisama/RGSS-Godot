using System;

namespace RGSSUnity
{
    internal class InputStateRecorder
    {
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

        private InputState[] keyState         = Array.Empty<InputState>();
        private InputState[] previousKeyState = Array.Empty<InputState>();

        internal void Init()
        {
            var count = Enum.GetValues(typeof(InputKey)).Length;
            this.keyState         = new InputState[count];
            this.previousKeyState = new InputState[count];
        }

        internal void SetPress(InputKey key)
        {
            ref var s = ref this.keyState[(int)key];
            s.Pressed  = true;
            s.Repeated = true;
            if (!this.previousKeyState[(int)key].Pressed)
                s.Triggered = true;
        }

        internal void SetRelease(InputKey key)
        {
            ref var s = ref this.keyState[(int)key];
            s.Pressed      = false;
            s.Repeated     = false;
            s.RepeatCount  = 0;
            s.Triggered    = false;
        }

        internal void Update()
        {
            Array.Copy(this.keyState, this.previousKeyState, this.keyState.Length);
            Refresh();
        }

        internal bool IsTriggered(InputKey key) => this.previousKeyState[(int)key].Triggered;
        internal bool IsPressed  (InputKey key) => this.previousKeyState[(int)key].Pressed;
        internal bool IsRepeated (InputKey key) => this.previousKeyState[(int)key].Repeated;

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

        private void Refresh()
        {
            for (var i = 0; i < this.keyState.Length; i++)
            {
                ref var s = ref this.keyState[i];
                s.Triggered = false;
                if (s.Pressed)
                {
                    ++s.RepeatCount;
                    s.Repeated = (s.RepeatCount >= 23) && ((s.RepeatCount + 1) % 6 == 0);
                }
            }
        }
    }
}
