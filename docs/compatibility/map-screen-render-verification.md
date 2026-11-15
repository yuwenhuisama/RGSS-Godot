# Map screen render verification (Sprite_Picture / Game_Screen / Weather)

Current result: `MAP_SCREEN_RENDER_PASS`, exit 0. All 147 deterministic rows
and 30 full RGBA captures match original RGSS300 after numeric Float opacity
conversion, fractional zoom raster sampling and tone-byte quantization fixes.
Weather bitmap/state and particle bounds/visibility checks pass. The existing
Sprite effect reference also passed after the shader change. The runner is
registered under `--events`; independent visual inspection is pending.
Independent task st_01a1d38f inspected eight paired picture/flash/weather frames:
8/8 PASS, no clipping or blank output. It independently confirmed 30 identical
RGBA captures and only RNG-dependent rain/storm/snow placement differences.
D06 is accepted locally; other platforms remain unmeasured.
The failed runs below are historical root-cause evidence.

Lead follow-up: Sprite.SetOpacity now converts Float numerically before
truncating/clamping, matching the original's recorded 255.0 -> 255 contract.
Managed build exited 0. The same 147-row and 30-frame real-renderer regression
is running; the historical red results below remain the root-cause evidence.

That regression finished exit 1: picture plain/origin/rotation and float control
now match, but move frames 0/1/2 and picture tone frames 0/1 still differ.
No TSV mismatch was reported. The Float opacity defect is fixed; remaining
five partial-opacity/tone composition frames require a separate diagnosis.

Move-frame byte inspection showed quadrant and marker displacement, not only
channel rounding. Fractional zoom with angle zero bypassed SpriteRotationRaster
and relied on Godot sampling; the render manager now uses the existing original
scanline rasterizer for fractional zoom as well. Build and the same fixture
are pending. Picture-tone fractional channel differences remain separately
unexplained until the rerun.

The rerun still failed five frames. Byte decomposition: move frames differed
at 139/201/195 pixels, chiefly quadrant boundaries; tone frames differed at
2304/3056 pixels by at most one channel level. Zero-angle horizontal zoom now
uses a truncated 16.16 step instead of repeated double division, and sprite
tone channels are truncated toward zero to bytes before addition. Build and
the original fixture are pending. These hypotheses are not passing receipts.

The next run matched tone frame 0; move differences reduced to 80/120/112
pixels concentrated on row boundaries, and tone frame 1 retained 1504 pixels
at maximum channel delta 1. The zero-angle vertical mapping now uses the same
truncated 16.16 step, and grayscale alpha truncates the original numeric byte
rather than rounding it. Managed build passed; the full fixture rerun is active.

Baseline: installed Chinese RGSS300 3.0.0.1, measured 2026-11-13 on Windows.
Port: Godot 4.6.1 mono, real Forward+ renderer (not `--headless`).

`tests/fixtures/map_screen_render_reference.rb` runs the installed stock
`Spriteset_Map`, `Game_Screen`, `Game_Picture`, `Sprite_Picture` and
`Spriteset_Weather` on both engines. It builds the map, player, party, timer and
temp singletons through the original data classes, constructs a real
`Spriteset_Map`, and then drives the stock `Scene_Map` update order
(`$game_map.update(true)`, `$game_player.update`, `$game_timer.update`,
`spriteset.update`, `Graphics.update`). No `Input`, `update` or draw method is
replaced or stubbed.

Fixture-only state: a 64x48 four-quadrant bitmap injected into `Cache` under
both engines' picture keys, and a backdrop sprite added to the spriteset's own
`@viewport1`. Weather particle bitmaps are the stock ones created by
`Spriteset_Weather`; no art is generated.

`tests/test_map_screen_render.gd` runs the same fixture through
`StressDisposeTestDriver`, waits for the fiber to finish, and compares the
captured rows and raw RGBA frames against the original capture pinned below.
It is not registered in `tools/run_tests.gd` (that file was outside this unit's
scope); run it directly.

## Result: 2 of 3 clusters match, 1 root cause is red

| Cluster | Rows | Frames | Verdict |
|---|---|---|---|
| Screen tone | 12 | 4 | 12/12 rows, 4/4 frames byte-identical |
| Screen fade out / in | 24 | 8 | 24/24 rows, 8/8 frames byte-identical |
| Screen flash | 16 | 4 | 4/4 backdrop rows equal; frames differ only inside the picture rectangle (3072 px each) |
| Weather bitmaps | 22 | - | 22/22 rows byte-identical |
| Weather state | 27 | - | 27/27 rows byte-identical; particle rows asserted as invariants |
| Weather clear | - | 1 | frame byte-identical |
| Picture erase | 3 | 1 | 3/3 rows, frame byte-identical |
| Picture plain / origin / rotate / move / tone | 39 | 11 | **red**: 31/39 rows differ, every picture pixel sample reads the backdrop |
| Opacity control | 4 | 2 | Integer frame matches outside the picture; Float frame also loses the control sprite |

Deterministic TSV: 147 rows, original SHA256
`7ba6afeafb5cba0ecfe228b7dd776ce89243eb42dfdacf89e8f52dd815933887`
(raw file `c503fb81c32b8690fdb7d396cf90df58bf4684b4d67d92a3bca56b370d1692be`).
A second independent isolated original project reproduced that raw hash and
four sampled frames byte-for-byte, so the original capture is deterministic.
Godot produces the same 147 rows but a different hash
(`7a2d5208fa3bade59308a8b3d6e9f8558d531db1fb0bfeabc03ae6fa934ca8c6`):
110 rows are identical and 37 differ, all in the picture cluster (31), the two
Float-opacity control rows, and the four picture-overlapping flash samples.
Every screen-tone, fade and weather row is identical. Of the 30 pinned frames
14 are byte-identical and 16 differ; the three weather frames are not pinned.

## Red root cause: `Sprite#opacity=` truncates Float to 1

Stock `Sprite_Picture#update_other` assigns `@picture.opacity`, and
`Game_Picture` stores that value as a Float (`255.0`, and interpolated values
such as `223.0`, `191.0`). The fixture records a control sprite driven with
Integer then Float opacity in the same run:

| Engine | `opacity = 255` getter | pixel | `opacity = 255.0` getter | pixel |
|---|---|---|---|---|
| original RGSS300 | 255 | `220,60,40,255` | 255 | `220,60,40,255` |
| Godot port | 255 | `220,60,40,255` | **1** | backdrop `41,60,89,255` |

The Integer control frame differs from the original only inside the picture
rectangle (3072 px, the picture the port fails to draw); the control sprite
itself is byte-identical. The Float control frame differs by 6144 px: those
same 3072 plus the 3072 control-sprite pixels the port loses.

`Scripts/RubyClasses/Sprite.cs` `SetOpacity` uses
`(int)value.ToIntUnchecked()`, which reads the mruby Float's raw integer slot
instead of its numeric value. `RGSS/sprite.rb` also declares the setter as
`check_arguments([opacity], [Integer])`, so `sprite.opacity = 255.0` is a
separate Ruby-level rejection path. The fixture's `opacity_control` rows and
`map_screen_opacity_control_int.rgba` / `_float.rgba` make this self-diagnosing:
on the original both captures are byte-identical; on the port the Float capture
loses the sprite.

This is reported, not patched: production code was outside this unit. The same
truncation shape should be checked on the sibling integer-backed properties
(`blend_type`, `bush_opacity`) before fixing. Note the Ruby wrapper's
`check_arguments([opacity], [Integer])` did not raise for `255.0` in this run,
so the C# conversion is the observable cause; whether the wrapper also needs a
Float branch is for the owning fix to settle.

## Screen tone / flash / fade

All 12 tone frames and all 8 fade frames are byte-identical
(`map_screen_screen_tone_0..3`, `map_screen_screen_fadeout_0..3`,
`map_screen_screen_fadein_0..3`). Screen tone reaches viewport1 as the exact
Ruby-visible channel values, and fade drives viewport3 alpha
`255 - brightness` (`64/128/192/255`). Sample background pixel `(50,50)` over
`40,60,90`:

| Frame | Tone (R,G,B,Gray) | Pixel |
|---|---|---|
| 0 | 20,-10,5,15 | 61,49,92 |
| 1 | 40,-20,10,30 | 82,39,96 |
| 2 | 60,-30,15,45 | 103,29,99 |
| 3 | 80,-40,20,60 | 124,19,102 |

Flash over viewport2 is exact on backdrop pixels, which are outside the picture
rectangle: `115,69,66` -> `90,66,74` -> `65,63,81` -> `40,60,90` as alpha decays
`120,80,40,0`. The `pixel` rows sampled inside the picture rectangle differ only
because the picture itself is not drawn (the red cause above), so flash
compositing itself is not implicated.

## Weather

Stock `Spriteset_Weather` state is deterministic and matches:

| Type | power | sprite_max | dimness | viewport tone | motion per frame |
|---|---|---|---|---|---|
| rain | 6 | 60 | 36 | -36,-36,-36 | -1,+6,-12 |
| storm | 9 | 90 | 54 | -54,-54,-54 | -3,+6,-12 |
| snow | 3 | 30 | 18 | -18,-18,-18 | -1,+3,-12 |
| clear | 0 | 0 | 0 | 0,0,0 | - |

Particle spawn positions come from `Kernel#rand`, whose sequence is
engine-specific; `srand(1234)` yields `92975,58067,34086` on the original and
`31255,31202,18814` on mruby, so those rows are recorded in
`map_screen_weather_reference.tsv` and asserted as invariants (bounds
`-110..550` x `-205..420`, opacity `64..255`) rather than pinned.

Visibility is asserted from pixels, not from state: bright pixels (>100 on all
channels) in the full 544x416 capture are rain 920, storm 909, snow 24, clear 0
on the original, and rain 1282, storm 1156, snow 90, clear 0 on the port. The
counts differ because particle positions are RNG-driven; the invariant is
"weather draws bright particles, clear draws none". Weather frame hashes are not
pinned for the same reason.

## Runner behavior

`tests/test_map_screen_render.gd` prints `MAP_SCREEN_RENDER_PASS` or
`MAP_SCREEN_RENDER_FAIL` and exits 0/1. It also fails loudly, by name, when
the opacity control is lost, a weather type is missing, a particle leaves the
RGSS bounds, a weather capture has no bright pixel, or clear weather draws
particles. On the current port it exits 1 because of the picture cluster.

## Reproduce

Original, in an owned isolated project (source game untouched). Note the
fixture project needs an RTP entry; `prepare_original_fixture.rb` writes
`RTP=` empty, which fails on `Graphics/System/Shadow`:

```sh
ruby tools/prepare_original_fixture.rb E:/Projects/RMProject \
  .omo/compatibility-run-tmp/d06-map-screen-original \
  tests/fixtures/map_screen_render_reference.rb --stock-scripts
# set RTP=RPGVXAce in the generated Game.ini, then run Game.exe there
```

The generated `Game.ini` needs the runtime's registry RTP name
(`RTP=RPGVXAce`); an absolute path or an empty value fails on
`Graphics/System/Shadow`.

Godot (real renderer, no `--headless`):

```sh
godot --path . -s tests/test_map_screen_render.gd
```

## Gaps and limits

- Picture cluster is red; the port does not pass this runner today. The runner
  exits 1 and names the opacity cause.
- `Sprite_Picture` rotation is exercised at 90 degrees only (speed 180, one
  update). Other angles inherit C03's separate rotation coverage.
- Weather RNG is not pinned; only invariants and visibility are asserted.
- Captures under `.omo/compatibility-run-tmp/d06-map-screen-original` and
  `.omo/evidence/rmva-compatibility/godot/map-screen-render` are left unviewed
  for an independent inspector; no visual acceptance is claimed here.
- Local dirty-worktree measurement only; no CI, export or cross-platform
  evidence.
- The isolated original project still contains copied `Game.exe` /
  `System/RGSS300.dll`; delete
  `.omo/compatibility-run-tmp/d06-map-screen-original*` once the picture cause
  is fixed and the captures are no longer needed.
