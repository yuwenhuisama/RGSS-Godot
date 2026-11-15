# Window activation cursor phase

The default D05 windows showed different cursor brightness after identical
40-step updates. An isolated 67-frame original RGSS300 fixture measures
12 inactive updates, 24 active, 7 inactive and 24 active again, against a
white cursor on black. Original process exited 0. Normalized TSV SHA256:
`23527906891aa740bf442c2e88f69f4cc6ad4ccbe9eb38615ffbbfa7a55e31b4`.

The Godot probe failed before the fix. Original inactive updates produce 127;
reactivation starts 119, 111, 103, 95, 103, ..., 255, independently of the
length of the preceding inactive interval. This proves a cursor clock distinct
from the continuously advancing pause animation clock. Inactive updates reset
cursor phase to 16 on the measured 40-frame triangular cycle.

WindowData now retains CursorTick; Window.update advances it only while active
and resets it to 16 while inactive. Pause AnimationTick is unchanged. The
render manager uses CursorTick for cursor alpha. Build and 67-frame regression
are pending; D05 is not yet accepted.

Runner: `godot --path . -s tests/test_window_activation.gd`. The independent
hash is pinned; the owned original project is not a runtime dependency.

Final result: managed build exited 0; WINDOW_ACTIVATION_PASS exited 0 for all
67 original rows. Existing 273-row window-animation fixture also returned
RENDER_REFERENCE_PASS, exit 0. The activation runner joins `--rendered` in the
unified suite. Fresh default-window captures and input regression are next.
