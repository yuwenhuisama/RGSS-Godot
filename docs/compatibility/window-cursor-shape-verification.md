# Window cursor shape

Correction: the final cursor shader's background coefficient is `256-alpha`.
Earlier screen-cache inference used `255-alpha`, leading to an incorrect claim
that Window differed from Bitmap#blt. With the correct coefficient, the actual
original Bitmap cache explains black/white outputs. GPU straight-alpha cache
reproduction now leaves two black-background blue-channel differences and five
white-background one-level differences. The same CPU Bitmap#blt fixture is
being run on Godot to determine whether its existing path is reusable.

White-background original Alpha-gradient fixture exited 0. Combined black/
white outputs constrain the 3x3 cached alpha to 252/253/254 by column and its
straight RGB values independently; the current premultiplied accumulation
model still differs at three black-background red-channel pixels. White
variant runs through the same runner with `--alpha --white`. The remaining
cache quantization is not diagnosed and is not accepted as parity.

Direct original Bitmap#blt corner-cache probe exited 0 and records different
RGBA from the window's black/white inferred cache, establishing that the window
does not simply reuse Bitmap#blt composition. A staged fixture now enables
corners one at a time and captures 72 black/white rows to identify the first
divergent accumulation step. Original run completed exit 0; shader formulas remain
unchanged until this evidence decides the cause.

The 72 stage rows do not fit the current accumulation contract. Small-size
semi-transparent parity remains red and D05 is open. Work also resumes C12
physical presentation while this cache mechanism is unresolved; no pixel
tolerance or special-case coordinate patch was introduced.

Alpha-gradient follow-up: all ordinary sizes matched; only 3x3 nine pixels
remained different by 1-2 channel levels. Small-corner accumulation is
premultiplied and must composite once with the background. A fragment early
return produced a shader compile error and that run is invalid for numeric
comparison; it was replaced by conditional output. The valid rerun is active.

Final matrix result: WINDOW_CURSOR_SHAPE_PASS, exit 0, for all 3529 original
rows. The center interpolates across 23 pixel intervals, while edge strips
sample a 24-pixel span with truncated 16.16 steps. Small overlapping corners
accumulate in row/column order. The runner is registered under `--rendered`.

Fresh D05 paired captures retained 29 choice-window pixels above channel delta
8. Coordinates identify cursor corners and outer window corners; the pause
triangle was not the cause of these significant differences.

The shared cursor-shape fixture uses a nonuniform 32x32 cursor texture and
records every pixel at sizes 96x24, 24x48, 8x8 and 3x3: 3529 rows. Original
RGSS300 exited 0. Normalized SHA256:
`0d6fc5d1f01cb6047fa482e5572598498b412dce224ce8c91ddaf857518220d6`.
The Godot comparison failed before the change.

Original first-row sampling retains four source pixels at each corner before
stretching the center; Godot used two-pixel NinePatch margins. The margin is
now four. Build and the same full matrix are pending; small-size overlapping
corner behavior remains to be verified. No pixel-parity claim is made yet.

Runner: `godot --path . -s tests/test_window_cursor_shape.gd`. Its independent
hash is pinned and does not depend on retaining the temporary original project.

Four-pixel margin build passed, but 3081 matrix rows still differed: 2048
at 96x24, 1024 at 24x48 and 9 at 3x3; 8x8 matched exactly. The stretched
center interpolated intermediate RGB values while original rows repeat source
pixel values. Explicit nearest-neighbor filtering is now being built. The
3x3 overlapping-corner case remains distinct and unverified.

Nearest filtering alone still mapped target pixel centers differently from
original left-edge truncation. The cursor shader now maps integer local
positions explicitly into fixed 4-pixel corners and a 24-pixel center, and
accumulates overlapping corner pieces for dimensions below 8. A shader compile
error from assigning a fragment varying was corrected to a local variable;
the same 3529-row probe is running. No failed run is counted as a pass.

The fixed-step run showed that original edge strips use nearest sampling while
the center fill interpolates channels. The shader now uses those distinct
paths. A 3x3 NinePatch node's enforced minimum size also masked the requested
size; the shader now receives the original cursor_rect dimensions. Build and
the same matrix are pending.
