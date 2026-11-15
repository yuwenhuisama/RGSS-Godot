# Original runtime baseline

## Sprite transforms and ordering (C03, in progress)

The shared six-case Sprite transform capture revealed the original pivot is
transformed with scale and rotation. The port formerly subtracted ox/oy from
world position; it now positions the node at x/y and uses local offset -ox/-oy.
Original positive angles rotate opposite to Godot's positive canvas angles;
non-positive zoom hides the original sprite. Those paths now have rendered
pixel assertions. Independent comparison initially passed five cases and failed
mirror: node FlipH and shader mirror were both active and cancelled each other.
The shader mirror flag is now zero for Sprite nodes, leaving FlipH as its owner.

Original same-z overlap sorts by y, then creation order; later y changes reorder
the sprite. The port's creation-only ordering failed both reversed-y and dynamic
cases. Viewport roots now enable Godot y sorting. Actual sorting/transform
regressions are pending after the fix; C03 is not accepted yet.

The actual same-z/dynamic-y and mirror tests now pass. The full existing suite
passes 17 groups, and independent transform visual review passes six cases.
Exact zoomed-color boundary probes then reveal another cause: Sprite nodes inherit
linear texture filtering, mixing red/blue across two enlarged edge columns.
Original pixels stay sharp. The added boundary assertions first failed; Sprite
creation now explicitly selects nearest texture filtering. Its build is pending.

Nearest filtering now passes actual enlarged boundary probes; unrotated base,
scaled and mirrored rectangles match the original pixels exactly. Source-rectangle
tests then exposed a zero-width fallback to the full bitmap and texture-clamped
out-of-range pixels. Getters preserve explicit zero dimensions, zero regions are
hidden, and fragment UVs outside the actual texture are discarded. Both negative
source-x and overflow cases now match the original fixed-background pixel rows;
the real renderer compiles the shader and exits 0. Rotated raster-edge coverage
is still under independent numerical diagnosis, so C03 remains open.

The rotation cause is now traced in the running original RGSS300: its software
renderer samples integer screen coordinates from a rounded bounding rectangle,
then increments double source coordinates across each row. A GPU-transformed
quad samples a different grid and does not preserve that accumulation. Actual
row tracing confirms the tiny negative source-v at the leading 90-degree edge;
no fixed offset or angle exception explains the rule. The port now reproduces
that raster in a cached texture, invalidated by bitmap texture revision and
geometry. Six checkerboard angles and the entire eight-transform capture match
the original RGBA pixel-exactly. Independent final visual review passes 8/8.
Dynamic bitmap/rectangle/angle update and the final suite are pending; C03 is
still not counted complete.

The final suite passes all 17 groups after the rotation implementation. Dynamic
bitmap edits, zero-angle source-rectangle cropping and return to a rotated/moved
sprite match four original RGSS300 pixel rows, including a content pixel in the
last case. C03 is accepted for the local original baseline. Sprite effects and
their interaction with this raster are the separate C04 gate; other platform
renderers remain F10 evidence.

## Sprite effects (C04, in progress)

The original 12-mode pixel probe establishes plain/opacity/color/tone/gray/bush,
add/subtract, four-frame flash and nil flash behavior. It exposed absent Sprite
blend-type wiring, bush depth normalized to 255 instead of source height, an
inverted bush threshold, nil flash staying visible, and flash interpolation
changing alpha as well as RGB. The latter three structural fixes are rendered;
nil flash now matches, bush and colored flash still have one-channel rounding
differences. Blend variants are compiled and their actual rendering is pending.
No effect is counted complete while the original pixel assertions fail.

The 12 effect rows and 11 opacity boundary rows now match the original exactly.
Original opacity uses byte arithmetic with nonzero coverage `(opacity+1)/256`
and channel truncation; gray/color/flash also truncate intermediate colors.
Explicit background copies before each affected Sprite preserve actual stacking;
three overlapping half-opacity normal/add/subtract rows match the original.
Wave phase and full eight-pixel band extents match five original rows, including
phase updates at zero amplitude. Rotated effect probes exposed two additional
ordering errors: bush uses the rotated texture's bottom and height, and wave
shifts the already-rotated raster. These are fixed and their actual regression
is pending. C04 remains open until combination and duration coverage is finished.

Thirty colored/nil flash rows now match the original, including duration zero,
which stays active until the first Sprite.update. The larger multi-color panel
also confirms byte alpha weights and grayscale coefficients 77/150/29; its
color/gray/flash regions now match exactly. Bush depth and wave amplitude are
screen pixels after zoom, rather than source pixels multiplied by zoom.

Invalid wave parameters have separate evidence: original wavelength zero hung
the owned fixture and required stopping its process. Disassembly of the original
wave lookup uses a signed phase remainder directly as a table index, so negative
phases can read outside its sine table. These outcomes do not provide a stable
pixel contract to reproduce. Positive-wavelength rotated wave still differs in
the full panel and remains under runtime tracing; C04 is not complete.

The positive-wavelength rotation/wave cause is now verified: eight-pixel bands
align to screen coordinates, use integer phase lookup, and stretch the entire
padded rotation cache using a 16-bit fixed-point step. Changing amplitude after
the first rotation render changes the logical source span but preserves the
cached image and its initial sampling history. A fresh 90-degree wave and one
enabled after a plain render intentionally have different edge pixels in the
original; both paths now match their original rows. The complete ten-effect
544x416 capture matches pixel-exactly, with fixed SHA256
`25e75a80430ed409ea34ff4cd4b6f440446cfc80ab4d5900ac04b8c41b61b3b1`.
Independent visual review passes 10/10, flash duration has 30 matching rows,
opacity has 11, and overlapping blend modes have three. The final existing suite
passes 17 groups. The new fixed-capture assertion is pending its actual run.

## Audio format coverage (B09, partial)

Real WAV, Ogg Vorbis, MP3 and WMA fixtures now all decode and start/stop through
the actual BGM player in `tests/test_audio_formats.gd` (`AUDIO_FORMATS_PASS`,
exit 0). MP3's missing fixture first produced a failing test before the fixture
was generated from the existing tone WAV. WMA uses the bundled Windows decoder
with no environment override; an explicitly missing decoder still fails.
This verifies local file loading and player lifecycle, not audible output parity,
clean release provenance or macOS/Linux packaged execution. Those gates remain
open, so B09 is not counted complete.

## Bitmap operation evidence (C01, partial)

The original runs in `c01-bitmaps-original`, `c01-bitmaps-expanded` and
`c01-bitmaps-diagnostic` each exited with code 0. Their TSV files preserve
independent public API pixel results from `bitmap_operations_reference.rb`.

Transparent stretching must preserve straight RGB: `(20,150,200,128)` remains
that value on a cleared destination. New, cleared and cleared-rectangle pixels
have RGBA `(0,0,0,0)`. The former port used transparent white and an alpha-over
formula that assumed an opaque destination. Both causes now have regression
assertions; new-bitmap regression was observed failing before the constructor
fix. The full existing rendered/font suite passed 16 groups after that fix.

Radial blur of a single opaque pixel at `(6,3)` on an 8x8 image, angle 30 and
division 5, produces alpha 51 at `(6,2)`, 204 at `(6,3)` and 51 at `(6,4)`.
Division 1 produces 127 at each of those pixels; a negative angle leaves the
image unchanged. These results identify symmetric angles around zero, both
endpoints involved and a minimum of two divisions. A proposed inclusive sum
normalized by divisions matched this impulse but made a colored image too
bright. That algorithm was withdrawn. Independent numerical diagnosis identified
D taps at angles `-A/2 + i*A/(D-1)`, center `(width/2,height/2)`, and byte sums
truncated after division by D. The corrected implementation passes the original
four complete impulse grids, uniform and low-brightness cases, and two 16x16
corner grids at 90 and 120 degrees with zero pixel differences. The fixed
reference is `tests/fixtures/rgss300-radial-reference.tsv`; `--bitmaps` now
checks these actual output rows. The full existing suite passes 16 groups.

C01 remains open for the remaining interface and visual checks. Colored hue
conversion now uses the observed integer HSL contract: byte lightness and
saturation, nearest integer hue, a lightness branch at 128, and truncated byte
output. The actual output matches all seven 64-pixel palettes and nine additional
color probes. `rgss300-hue-reference.tsv` preserves the independently captured
reference. The public regression failed before the HSV replacement and now
passes with exit 0. Pixel evidence does not replace independent visual review.

Zero width, negative width and zero height each raise `RGSSError` in the original.
The public constructor now raises at the Ruby boundary so scripts can rescue
the original exception class; a native callback raise instead became RuntimeError
and failed the test. The native constructor also rejects invalid dimensions.

Further gradient diagnosis: clipping `(-2,0,8,8)` retains the requested length
8 when calculating the gradient, although only six columns are written. The
former port used clipped length 6 and incorrectly changed the color slope.
The original interpolates an integer channel delta with truncation toward zero:
blue from 100 to 0 at row 1 of 8 is 86, not 85. Both differences were first
observed failing in the real Ruby API regression. The fixes have compiled;
all three sampled gradient rows now match the independently captured original
exactly. The public regression now passes both its gradient and radial assertions.

The real rendered six-panel comparison exposed an overload distinction that
diagonal samples missed. Original numeric `gradient_fill_rect(x,y,w,h,c1,c2)`
is horizontal when the optional argument is omitted, but supplying a seventh
argument selects vertical for false, true and nil alike. The Rect overload uses
the supplied boolean normally (false/nil horizontal, true vertical). Independent
visual review failed all six panels on this shared axis difference while finding
matching placement and centered content. The arity contract is being fixed at
the Ruby wrapper; rendered comparison must be repeated after that change.

After the numeric-overload arity fix, independent visual review passes all six
panels. Exact pixel comparison still finds stretch-edge differences up to 57
channel levels, so visual acceptance is not treated as exact compatibility.
A 4x4 coordinate-colored source stretched to 6x6 produces source columns
`0,0,1,1,2,3` in the original. The port's bilinear resize fails this public API
regression. Integer enlargement gives duplicated source columns, while 4-to-3
shrinking uses columns 0,1,2. Truncated fixed-point steps reproduce these inputs;
the corrected direct sampling passes enlargement/shrinking regressions. On the
fresh rendered stretch panel, the maximum difference has dropped from 57 to 1,
with no channel difference above 20. Final visual and full-suite checks are pending.

The subsequent full existing suite passed 16 groups, and independent visual
review passed all six panels. A stronger 16x16 colored radial coordinate grid
then isolated 25 border-pixel differences: mirrored source indices reproduce
all 256 original pixels, while clamping, centered reflection and wrapping do
not. The radial sampler now reflects around the pixel edges. Its public border
regression first failed, then passed with exit 0; the full fixed radial/hue/blur
reference entry also passes. Fresh rendering reduces radial maximum difference
from 19 to 1. Independent visual review confirms all six panels still pass, and
the full existing 16-group suite passes with exit 0 after this last code change.

Final C01 boundary probes: overlapping self-blt copies in-place in the original
and port, producing red values `0,30,0,30,0,30,0,30`; negative fill dimensions
write no pixels in both. These shared probes exited 0. C01's local RGSS300
bitmap operation acceptance is complete: constructors, transparent composition,
fill/clear/gradient, hue/blur/radial, stretching, boundary behavior and six-panel
visual output have executable evidence. Text layout continues in C02, and
encrypted game assets/platform portability remain explicit F-series gates.

Current local reference is the Chinese RMVA 1.00 runtime:

- Source game: `E:/Projects/RMProject`
- Player: `Game.exe`, version 3.0.0.1
- Runtime: `System/RGSS300.dll`, version 3.0.0.1
- RTP: `F:/Softwares/RPG Maker VX Ace/RTP`

This proves behavior of this installed original. RGSS301 differences remain
unverified until that version is available; they must not invalidate or replace
the existing RGSS300 observations.

## Independent primitive fixture

### Text layout diagnosis (C02, in progress)

Original and Godot default left/center/right, CJK mixed text and zero-width
captures match alpha exactly. Short-height original glyphs keep their normal
top origin and are clipped rather than moved upward; the negative vertical
alignment offset has been corrected. Compressed-width and clipping cases remain
under investigation; the fixed independent captures are in
`tests/fixtures/rgss300-text-layout`.

Control characters are glyphs, not replacement spaces or line splitting.
Actual GDI probes show LF glyph advance 24 and CR advance 14 for nsimsun 24,
while `GetTextExtentPoint32W` returns zero for either. Ordinary A/B give 12 from
both APIs. Original character-pair captures show those exact advances. The port
used text extent while placing glyphs, causing overlap; raster placement now
uses `GlyphMetrics.AdvanceX`, including the final raster buffer width. After
both changes, the fixed original linebreak alpha capture matches exactly. The
layout test now fails only for narrow/narrow-left and compressed clipped text;
those remaining failures are retained while font-width selection is diagnosed.

The original compression mechanism is now directly verified by read-only Frida
tracing of the isolated Game.exe. RGSS300's draw call computes
`max(0.6, available_width / measured_width - 0.15)`. The font constructor reads
an unselected compatible DC (actual height 16, average width 7 here), then sets
`lfWidth = trunc(font_size * scale * reference_average / reference_height)`.
Runtime constants are exactly 0.15 and 0.6; this is not inferred from a fit.
The port previously used the selected font's average width, producing the wrong
discrete widths for nsimsun. It now follows the actual compatible-DC mechanism.

All twelve fixed original layout alpha captures pass with exit 0 after the fix.
All nineteen available-width probes, including the 78/79 and 87/88 boundaries,
match the original alpha bytes exactly. Fresh real rendering has completed;
final independent visual and full existing-suite results are pending.

Create a new destination (the tool refuses existing destinations):

```text
ruby tools/prepare_original_fixture.rb E:/Projects/RMProject .omo/compatibility-run-tmp/a06-original tests/fixtures/primitive_reference.rb
```

Run the copied `Game.exe` with its fixture directory as working directory. The
fixture writes `primitive_reference.tsv` and exits. No source game file is edited.
The equivalent Godot invocation is:

```text
godot --headless --path . -s tests/run_primitive_reference.gd
```

Both execute the same public API inputs from
`tests/fixtures/primitive_reference.rb`. The Godot host supplies the result path
and performs shutdown; original runs directly and exits itself.

2026-11-12 original run exited 0. Bitmap dimensions/pixel and Table Marshal
roundtrip match the expected contracts. Actual Arial size 24 measurements:
Hello 46x24, iiii 20x24, WWWW 84x24, 12345 60x24, empty 0x0.
Installed fallback for unavailable VL Gothic measured Hello 60x24, iiii 48x24,
WWWW 48x24, 12345 60x24. Font availability must be recorded with later comparisons.

This first fixture covers primitive numerical behavior, not visual, audio,
event, battle or real-game compatibility. Those remain separate acceptance gates.

## Deterministic render capture

`tests/fixtures/render_reference.rb` runs on both engines, waits eight frames,
then writes `Graphics.snap_to_bitmap` pixels to raw RGBA. Original fixture is
prepared with the same builder into a new destination. Godot executes it with:

```text
godot --path . -s tests/run_render_reference.gd
godot --headless --path . -s tools/rgba_to_png.gd -- INPUT.rgba OUTPUT.png 544 416
```

2026-11-12 both captures succeeded, original exit 0 and Godot
`RENDER_REFERENCE_PASS`. Independent image inspection: capture integrity PASS,
visual equivalence FAIL confined to window background opacity. At (100,100),
original RGB is (20,94,110), Godot (20,67,145); untouched background (10,10)
matches exactly at (20,150,40). With `back_opacity=128`, original applies one
background opacity after combining windowskin layers, while current Godot
layers compound opacity. This is a C07/C08 regression to fix, not a capture fault.

The earlier synthetic `test_window_transparency.gd` expectation compounded two
alphas, so it proved translucency but not original parity. Replace that expectation
with the independently captured original behavior when repairing window composition.

## Installed font behavior

The original Chinese RGSS300 build reports `Font.default_name == "nsimsun"`,
`Font.default_size == 24`. This differs from the Japanese reference's VL Gothic
default. Arial exists; VL Gothic and a deliberately nonexistent family do not.
Use the installed runtime and `cn_ver_rmva` when choosing the compatibility
default; do not replace it blindly with the Japanese documentation value.

The original width includes each glyph's right ink extent when it exceeds its
advance: Arial A at cell height 24 has advance 13, gray glyph origin -1 and width
15, hence original text_size(A)=14. Original text_size(AV)=27. Current Windows
measurement now reproduces these and the initial widths through real GDI glyph
metrics. Full draw_text and non-Windows parity remain unverified.

Font.name retains the assigned type in the original: assigning "Arial" returns
a String; assigning ["CompatibilityMissingFont", "Arial"] returns that Array
and measures using Arial. Current Bitmap.font now retains the same wrapper on
repeated access, preventing style resets and name-type loss.

`tests/fixtures/text_render_reference.rb` provides actual original text output
for normal text, a constrained width, bold, italic, shadow and outline. Execute
the Godot side with `tests/run_render_reference.gd -- --text`. These captures
will establish measure/render consistency and style parity separately from
Font property roundtrips.

Windows font measurement now matches 220 independently captured combinations
of Arial/nsimsun, sizes 12/18/24/32/48, regular/bold, English, Chinese, mixed,
space, empty and numeric input. Reference data is
`tests/fixtures/rgss300-font-variants.tsv`; run
`tests/run_primitive_reference.gd -- --variants` to check it. Width-constrained
drawing is checked against original stepwise native average-width compression,
including the 60% lower bound. These do not establish non-Windows parity.

Transparent per-glyph captures from `font_style_reference.rb` isolate visual
styles from the background. Original and current Windows normal/bold alpha
rasters match on H/A/g; italic individual glyphs match after negative-bearing
compensation. Long-string italic placement and outline compositing remain
under investigation and must not be counted as complete style parity.

Italic glyphs use their own native advances while text_size excludes italic
overhang. With this separation all four transparent italic samples match
original alpha exactly. Original outline is four diagonal shifted alpha passes
and moves the fill one pixel upward, rather than eight-neighbor dilation.
Original H outline corners alpha128 and vertical outside edges alpha191
distinguish the four-pass behavior. Verification of the repaired outline is
still pending the fresh captures.
