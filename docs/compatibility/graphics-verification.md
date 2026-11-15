# Graphics verification evidence

## C10 effects, snapshots and transitions

The installed original baseline is RGSS300 on Windows. The shared inputs are
`tests/fixtures/graphics_reference.rb` and
`tests/fixtures/graphics_transition_reference.rb`.

Actual commands:

```text
Godot --path . -s tests/run_render_reference.gd -- --graphics
Godot --path . -s tests/run_render_reference.gd -- --graphics-transition
Godot --path . -s tests/run_render_reference.gd -- --graphics-transition --transition-render
```

All three completed with `RENDER_REFERENCE_PASS`. The first checks brightness
and the final rendered fade frame. The second rejects a masked transition that
ends on black instead of the new scene. That regression failed before the fix.
The ordinary transition previously adjusted brightness without crossfading;
both paths now reveal the current scene from the frozen frame.

Dynamic evidence is retained under
`.omo/evidence/rmva-compatibility/godot/graphics-transition-full.apng`:
544x416, 120 frames at 60 fps. Its raw capture contains 108,625,920 bytes.
The original window video is currently retained under the owned run directory
`c10-transition-record/original-transition-full.mp4`.

Independent inspection found matching center (272.1, 208.0), circular reveal,
radius rates of approximately 385 versus 387 pixels/second, and soft edge widths
of 47-52 versus 46-50 pixels. Uniform crossfades are monotonic and spatially
uniform. There are no black frames during either transition. Original timing
precision is limited by its 30 fps capture, approximately 33 milliseconds.

An apparent stronger mask modulation in Godot was investigated rather than
smoothed away. Godot output correlates with raw BattleStart mask bytes at
-1.0000, gain 6.39 versus the formula's 6.40 for vague=40, and zero angular
offset. Re-encoding the Godot frames reproduced attenuation seen in the original
h264 recording. The independent inspector retracted that renderer finding as
a codec artifact. This evidence does not claim lossless original per-frame
equality or compatibility with encrypted mask archives.

## C11 frame loop, waits and scene changes

`tests/fixtures/rgss300-graphics-frame-reference.tsv` pins eleven rows captured
from the original. `--graphics-frames` checks exact normalized TSV equality.
Durations 0, 1, 4 and -1 match; zero-duration fades complete immediately.
`frame_reset` preserves script-visible frame_count: 123 remains 123. The prior
clear-to-zero failed the corrected API regression before being removed.

`tests/test_frame_loop.gd` passed thirty loop iterations and four waiting frames
through actual render barriers, checking each frame count and final Fiber
completion. It is included in the unified rendered suite, which passed all
18 runners after this increment. The API suite passed 83 cases.

Scene lifecycle evidence is shared with C09: `tests/test_menu_round_trip.gd`
completed three map/menu round trips and six submenu transitions, with resource
counts restored and no disposed background use. Scene coverage beyond these
transitions belongs to the remaining map and battle checklist items.

## C12 current scope

The eight-row original resize reference matches after updating logical content
size as well as physical window size. Original clamps to 1..640 by 1..480.
The GPU allocates a minimum 2x2 target, so a 1x1 logical screenshot returns the
logical region. New default-sized Viewports use the same logical dimensions.

`tests/test_resize_surface.gd --physical-capture` passed native, double,
fullscreen and restored states. All logical images are pixel-identical at
640x480 with complete four-pixel borders. Physical gdigrab calls returned zero
for all states using the actual title, but independent inspection found that
those window captures omit the GPU client surface. They are invalid physical
presentation evidence. The next capture reads the composited desktop instead.
C12 remains open until physical scaling and fullscreen framing are inspected.
Subsequent native screen captures revealed the Windows lock screen, including
its clock, rather than the game window. The workstation must be unlocked before
physical presentation can be verified. A user question is pending; logical
render-target evidence remains valid, while all lock-screen captures are invalid
for window presentation.
