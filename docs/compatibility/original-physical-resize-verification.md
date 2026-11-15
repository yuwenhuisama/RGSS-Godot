# Original RGSS300 physical resize verification (C12)

Independent original-runtime track for C12. The Godot port's physical states
were already measured; this document records what the **original RGSS300
player** actually does with the same 640x480 logical surface, so the port can
be compared against a real contract instead of an assumed one.

Measured 2026-11-13 on the workstation desktop (primary monitor 3840x2160,
144 Hz, Windows display scaling 150%, virtual desktop origin -2160,-2160).
Nothing in `E:/Projects/RMProject` was modified; the fixture is an isolated
copy under `.omo/compatibility-run-tmp/c12-original-physical`.

## Fixture

`tests/fixtures/original_physical_resize_reference.rb`, prepared with
`tools/prepare_original_fixture.rb` (copies `Game.exe`, `System\RGSS300.dll`
and a one-entry `Scripts.rvdata2`; the source game's own scripts are not used).

The fixture requests `Graphics.resize_screen(640, 480)`, paints the same
logical surface the Godot runner uses (background `20,80,120`, four 4-pixel
borders red/yellow/green/blue, and an 8x8 one-pixel checkerboard at
`(300,220)`), writes a logical TSV plus `ready.txt`, then presents frames until
the harness writes `stop.signal`. It can also request an alternate logical size
through `logical_size.txt` and dump an in-engine `Graphics.snap_to_bitmap`
RGBA on `snapshot.request`.

Logical evidence is identical in every run and every state:

```text
logical  640 480 640 480
border   0 0   255 255 0 255      (top-left yellow)
border   639 0 0 255 0 255        (top-right green)
border   0 479 255 255 0 255      (bottom-left yellow)
border   639 479 0 0 255 255      (bottom-right blue)
border   2 240 255 255 0 255
border   637 240 0 255 0 255
border   320 2 255 0 0 255
border   320 477 0 0 255 255
checker  300 220 / 301 220 / 300 221 / 307 227 = white, black, black, white
```

In-engine snapshots are byte-identical between native and fullscreen
(`e11c5af941f65a51…` for 640x480, `c1f8bf65b366e449…` for 544x416), all pixels
exact, alpha 255. The render target never changes with the physical state.

## Native window

The original's own window is **DPI-unaware** (measured window awareness 0,
`GetDpiForWindow` 96) when launched normally. On this 150%-scaled desktop that
means Windows virtualizes it, so the physical client is 1.5x the logical size:

| launch | window awareness | client (physical) | window rect | style | display mode |
|---|---|---|---|---|---|
| default | 0 (unaware) | 960x720 | 1436,662..2405,1426 | 0x14CA0000 | 3840x2160@144 |
| `HIGHDPIAWARE` compat layer | 2 (per-monitor) | 640x480 | 1597,784..2243,1304 | 0x14CA0000 | 3840x2160@144 |

The DPI-unaware launch is stretched by the OS to 1.5x; the high-DPI launch is
1:1. Both show the same 640x480 logical content. The original therefore has no
DPI awareness of its own — it asks for a 640x480 client and the OS decides the
physical size. (`GetProcessDpiAwareness` read 0 in both launches because it was
queried on the handle before the window's awareness was applied; the window
awareness values above are read from the live window.)

## Fullscreen (Alt+Enter)

Alt+Enter is a **real exclusive display-mode switch**, not a borderless window.
Measured on both launches:

| state | client | window rect | style / exstyle | display mode |
|---|---|---|---|---|
| native | 640x480 (or 960x720 virtualized) | windowed | 0x14CA0000 / 0x100 | 3840x2160@144 |
| fullscreen | 640x480 | 0,0..640,480 | 0x94080000 / 0x8 | **640x480@144** |
| restored | 640x480 | windowed again | 0x14CA0000 / 0x100 | 3840x2160@144 |

- The display mode changes to 640x480 (the logical size), and the window
  becomes `WS_POPUP` + `WS_EX_TOPMOST` covering the whole display.
- The fullscreen content is **1:1 with no scaling and no letterboxing** when
  the logical size is 640x480: desktop capture is exactly 640x480 and every
  border/checker pixel is exact.
- Exiting while still fullscreen (`stop.signal` → `exit 0`) restores the
  desktop mode to 3840x2160 automatically. The process exits 0.
- Restore (second Alt+Enter) returns to the previous windowed client and the
  desktop mode; the logical surface is unchanged.

Alt+Enter is only honored while the game window truly holds keyboard focus.
A posted `WM_KEYDOWN`/`WM_KEYUP` pair or a synthetic `keybd_event` sent while
another window is foreground is silently ignored; the harness therefore
verifies `GetForegroundWindow() == game hwnd` before each send.

## Fullscreen follows the logical size, centered 1:1

The display mode is set to the **logical** size, and the content is centered
without scaling:

| requested logical | native client | fullscreen display mode | fullscreen content geometry |
|---|---|---|---|
| 640x480 | 640x480 | 640x480 | full 640x480, no bars |
| 544x416 | 544x416 | 640x480 | 544x416 centered at (48,32), black bars |
| 320x240 | 320x240 | 640x480 | 320x240 centered at (160,120), black bars |

So the original's fullscreen contract is: switch the display to the logical
size when the driver supports it, otherwise keep 640x480 and center the
logical surface 1:1 with black bars. It never scales the logical surface up to
fill the screen. (The 544x416 and 320x240 rows come from the alternate
`logical_size.txt` runs; border and checker pixels are exact inside the
centered content.)

## External window resize: the original does NOT reflow, it stretches

The original accepts an external `SetWindowPos` resize of its window. The
client grows, and the 640x480 logical surface is **stretched to fill it with
nearest-neighbour sampling** — no letterboxing, no aspect preservation, and no
new logical resolution:

| client | aspect | content | nearest-neighbour mismatches (outside DWM corners) |
|---|---|---|---|
| 640x480 | 1.333 | 640x480 | 0 |
| 960x720 | 1.333 | 960x720 | 303 (mouse cursor over the checker) |
| 1280x960 | 1.333 | 1280x960 | **0** — exact 2x2 replication |
| 1000x700 | 1.429 | 1000x700 | 12 |
| 1016x716 | 1.419 | 1016x716 | **0** |
| 1296x976 | 1.328 | 1296x976 | **0** |
| 1616x616 | 2.623 | 1616x616 | **0** |
| 336x256 | 1.313 | 336x256 | **0** |

The exact 2x case is a pure 2x2 replication of every logical pixel, and every
border thickness doubles exactly (4 → 8 pixels). The fitted rule for
non-integer ratios is the source-edge rounding model: each source pixel `s`
occupies destination columns `round(s*w/640) .. round((s+1)*w/640)-1`. This is
nearest-neighbour, not bilinear: no blended colours appear anywhere except the
DWM-rounded bottom corners and the mouse cursor.

`Graphics.width/height` and `snap_to_bitmap` stay at the logical size in every
external-resize state, so the stretch is presentation-only. The original has no
API for a caller to request a larger *logical* surface; `resize_screen` remains
clamped to 1..640 x 1..480 (already recorded by the eight-row resize fixture).

## What this means for the port (C12)

The port and the original differ in contract, not just in pixels:

| aspect | original RGSS300 | Godot port (measured earlier) |
|---|---|---|
| native client | 640x480 logical; OS-scaled 1.5x when DPI-unaware | 640x480 |
| Alt+Enter fullscreen | exclusive display mode at the logical size, content 1:1, no bars | fullscreen display mode, content 2560x1920 (4x) with 640/120 bars |
| fullscreen scaling | none; centered 1:1 when the display is larger than the logical size | aspect-preserving 4x nearest-neighbour |
| external window resize | stretches the logical surface to fill, nearest-neighbour | not measured at a non-4:3 client; the measured 2x state is 1280x960 |
| logical size after resize | unchanged | unchanged |

The port's fullscreen is a scaled presentation; the original's is an unscaled
display-mode switch. The original also stretches on an external window resize,
while the port's non-4:3 external-resize behavior has not been measured (its
recorded 2x state is an exact 1280x960 client). Neither behavior is "wrong" as
a product choice, but they are **not parity**, and C12 should be described as a
documented divergence rather than as verified parity with the original.

## Evidence

Owned artifacts: `.omo/evidence/rmva-compatibility/c12-original-physical/`
(captures, in-engine RGBA snapshots, harness logs, verification scripts) and
disposable run directory `.omo/compatibility-run-tmp/c12-original-physical`.

Key hashes (SHA-256, first 16 hex):

```text
default-native-desktop.png              fcca5fd5434f9323
default-fullscreen-desktop.png          f5dfa1339e6593a2
default-restored-desktop.png            42aa46c33dac722a
highdpi-native-desktop.png              efce563d6d34f03b
highdpi-fullscreen-desktop.png          f5dfa1339e6593a2
highdpi-restored-desktop.png            87a2e33f697959d5
letterbox-544x416-fullscreen-desktop.png 4d5b712b32a493cc
logical-320x240-fullscreen.png          1f82377c17dc5444
scale-exact-1280x960.png                3a3d9c7f13c0460a
scale-exact-960x720.png                 5d890ecb11414c74
scale-noninteger-1000x700.png           ab29e3d124f8399f
snapshot-640x480-native.rgba            e11c5af941f65a51
snapshot-fullscreen.rgba                e11c5af941f65a51
snapshot-544x416-native.rgba            c1f8bf65b366e449
snapshot-544x416-fullscreen.rgba        c1f8bf65b366e449
```

The fullscreen desktop captures from the two launches are byte-identical
(`f5dfa133…`), and the in-engine 640x480 snapshot is identical between native
and fullscreen. The native desktop capture is a 3840x2160 screen frame with the
windowed game at 960x720 (DPI-virtualized) or 640x480 (high-DPI); the
fullscreen capture is the 640x480 exclusive mode, so the two are not expected
to match as images.

## Gaps and caveats

- **Foreign always-on-top overlay.** Every fullscreen capture contains a
  96x30 dark box with an olive icon at screen (540..635, 35..64). A
  `WindowFromPoint` hit test in fullscreen returns the game's own `RGSS Player`
  window, and the box does not appear in the in-engine snapshot
  (`snap_to_bitmap` is 100% exact), so it is composited above the game by
  another process (the desktop host), not drawn by the original. Border and
  checker pixels are exact everywhere outside that box; the box itself is not
  game content.
- **DWM bottom-corner rounding.** 62 pixels along the bottom ~10 rows are
  blended by the desktop compositor at the window's rounded corners. The count
  is constant at 1x, 2x and 1.5625x, and zero in exclusive fullscreen, so it is
  a compositor artifact rather than game scaling. In-engine snapshots have zero
  non-exact pixels.
- **Mouse cursor.** The 1.5x capture has the pointer over the checkerboard
  (303 mismatches in one 142x82 blob). It is not a scaling difference.
- **3x capture occluded.** The 1920x1440 client extends below the 2160-pixel
  screen and is partly covered; that capture is not used as scale evidence. The
  2x case is the exact-replication proof.
- **No arbitrary "double-size window" API in the original.** The original has
  no Ruby API to request a larger logical surface or a scaled window; a double
  or arbitrary client only exists via an external `SetWindowPos`, which
  stretches rather than reflows. Reported as capability, not parity.
- **Single machine, single monitor.** All numbers are from this workstation's
  3840x2160 primary display at 150% scaling. Display-mode switching, DPI
  virtualization and exclusive fullscreen are OS/driver behaviors; other
  configurations (different scaling, multi-monitor primary, remote session)
  were not measured.
- **Alt+Enter focus requirement.** Synthetic keys are ignored unless the game
  window is genuinely foreground; the harness asserts that before every send.
  A run that reports "fullscreen unchanged" without that assertion is not
  evidence of the original's behavior.

## Reproduce

```powershell
# fixture project (isolated copy; source untouched)
ruby tools/prepare_original_fixture.rb E:/Projects/RMProject `
  .omo/compatibility-run-tmp/c12-original-physical `
  tests/fixtures/original_physical_resize_reference.rb

# native -> fullscreen -> restored, plus external resize capability
powershell -NoProfile -ExecutionPolicy Bypass `
  -File .omo/compatibility-run-tmp/c12-original-tools/run_physical_harness.ps1
```

The harness starts the fixture with `Start-Process`, waits for `ready.txt`,
resolves the window by the fixture's own PID, asserts foreground before each
Alt+Enter, captures the desktop at the current display mode, then writes
`stop.signal` and waits for a real exit (exit code 0). It restores the desktop
display mode if the game leaves it changed.

Helper scripts used for the capability rows live in the same owned directory:
`run_aspect_probe.ps1` (non-4:3 external clients), `run_integer_scale_probe.ps1`
(exact 2x/3x/1.5x clients), `run_letterbox_probe.ps1` (544x416 fullscreen),
and `run_fullscreen_snapshot_probe.ps1` (in-engine snapshot during exclusive
fullscreen). Copies are stored beside the captures in the evidence directory.

Verification scripts in the evidence directory (`snapshot_verify.py`,
`filter_test.py`, `model_fit.py`, `exactness.py`, `scale_verify.py`,
`letterbox_analyze.py`) recompute the pixel claims from the stored captures;
`python snapshot_verify.py` reports zero non-exact pixels for all four
in-engine snapshots, and `python model_fit.py` prints the nearest-neighbour
mismatch counts quoted above.
