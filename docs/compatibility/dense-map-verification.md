# D09 dense-event and long-running map verification

F11 temporal profile completed exit0, DENSE_MAP_RUNTIME_PASS:36000frames in
621015ms (10m21s). All eleven samples retain5/107/7 drawables,358 nodes and
15294779 texture bytes. Objects2162 initially then2161; managed bytes end
25149296 (range21075864..38425024), static bytes end42441371
(range42167379..43446235), sampled FPS55..60. No forced GC was used.
Each64 parallel event increments exactly1125, eachremaining32 event once;
scene recreation retains5/107/7 and stock-map restoration returns5/11/7.
This closes the temporal resource measurement for this local10m21s workload.
F11 remains open for clean installation, exported package and other-platform
conditions. Full raw measurements are in
`.omo/evidence/rmva-compatibility/godot/dense-map/soak/resource-profile/resources.tsv`.

F11 follow-up adds `--resource-profile` to the same live owner. Existing D09
results below remain settled. The new mode records eleven samples at0..36000
frames, retaining the full96-event exact counts and teardown checks. Each
sample asserts viewport/sprite/window counts remain at the dense baseline;
node/object counts, managed/static/texture bytes and FPS are measurements,
not an invented memory threshold. No forced GC is added. It writes separate
`soak/resource-profile/resources.tsv` evidence and runs in window mode.
The new run is active. GDScript LSP is unavailable; actual Godot parsing and
execution are the verification surface. F11 remains open, including clean
installation and exported-package scope.

Interim seven samples through21600frames/371602ms: drawable counts5/107/7,
node count358 and texture bytes15294779 stay fixed. Object count2162 at start
then2161 at every later sample. Managed bytes range21075864..35956984 and
fall again between rises; static bytes range42167379..43393871. Sampled FPS
55..60. These observations show no monotonic growth in this measured portion;
the remaining14400frames and final event/teardown assertions are still pending.

Stall-check inspection confirms the monitor process is running with successive
samples through32400frames/558661ms. All ten samples retain5/107/7 drawables,
358 nodes and15294779 texture bytes. Objects remain2161 after the initial2162.
Managed memory reaches38425024 at28800 then falls to30716088 at32400;
this is bounded observed fluctuation, not a claim of unlimited leak freedom.
The final3600frames and teardown are still pending; no duplicate run started.

Status: complete for this measured scope. Live 96-event contract passes; the
shared 24-event trace is byte-identical between original RGSS300 and the Godot
port.

Lead follow-up: D09 remains open on the requested long-run requirement.
The same runner now supports --soak: 36000 parallel frames with max_fps 60,
an explicit minimum elapsed time of 600000 ms, and exactly 1125 increments
for each of the 64 parallel events. It writes a separate soak evidence directory
and retains scene recreation/stock-map resource restoration checks. This
ten-minute run is active; the earlier 620-frame and 3001-row results are settled.

Long-run gate passed DENSE_MAP_RUNTIME_PASS, exit 0: 36000 parallel frames,
838994 ms (13m59s), each of 64 parallel counters exactly1125 and all remaining
32 events exactly1. Resource counts baseline5/11/7, dense5/107/7, recreated
5/107/7, restored5/11/7. Independent soak image inspection is active.
Short live and original-fixture variants are registered in --events; --soak
remains an explicit long-run command. No unlimited duration/leak-rate claim.

Independent final soak image inspection passed: populated terrain, dense
character grid, no missing textures, unintended overlays or edge clipping.
D09 local finite long-run acceptance is complete for 96 events over 13m59s
plus original 3001-row parity and exact resource restoration. Fresh release,
other platforms and unlimited-duration behavior remain their separate F gates.

No desktop, fullscreen or physical-display capture is used by this task. Evidence
is an in-engine root render capture plus numeric traces, per the C12 display-mode
hold.

## Current result (last confirmed)

| probe | command | exit | marker |
|---|---|---|---|
| live 96-event contract | `godot --path . -s tests/test_dense_map_runtime.gd` | 0 | `DENSE_MAP_RUNTIME_PASS` |
| shared trace vs original | `godot --path . -s tests/test_dense_map_runtime.gd -- --fixture` | 0 | `DENSE_MAP_FIXTURE_PASS` |
| original RGSS300 capture | `powershell -NoProfile -File tools/run_original_dense_map.ps1` | 0 | `ORIGINAL_EXIT:0`, `ORIGINAL_DENSE_MAP_READY rows=3001` |

Recorded markers from those runs:

```
DENSE_MAP_GROUPS:parallel=64:[20..20] expected 20,autorun=8:[1..1] expected 1,
  action=8:[1..1] expected 1,player_touch=8:[1..1] expected 1,event_touch=8:[1..1] expected 1
DENSE_MAP_FRAMES:parallel=620,autorun=40,action=8x14,player_touch=210,event_touch=8x14,settle=180
DENSE_MAP_RESOURCES:baseline=(5, 11, 7),dense=(5, 107, 7),recreated=(5, 107, 7),restored=(5, 11, 7)
```

Settled artifact hashes (verified without re-running the probes):

```
7aef3191923a57ee7b0656420319698abad1bc88dc9d164b139660b620b147b0  tests/fixtures/dense_map_original.tsv
7aef3191923a57ee7b0656420319698abad1bc88dc9d164b139660b620b147b0  .omo/evidence/rmva-compatibility/godot/dense-map/dense_map_reference.tsv
d5fe4199c0c827dc32e50bf2d0cf87c03a2bba6f1e3effa5c87fdb2b9518e0f1  tests/test_dense_map_runtime.gd
9ef42f74312a2ae0c8e70d66f8136c084197936a652c8dde40d34969300f3d99  tests/fixtures/dense_map_reference.rb
8bfb0a99c068dd6d8ac80a434b5471281dfb064d0bdebc5fece3329f89aa926b  tools/run_original_dense_map.ps1
```

No production defect was found. The three failures observed during development
were defects in this task's own fixture (missing 230 wait, autorun page gated on
its own latch, direction numbers used where stock route codes belong) and each
was fixed before the passing runs above.

## Named remaining gaps

- The live contract is not registered in `tools/run_tests.gd`; aggregator edits
  were outside this task's allowed paths. It must be run explicitly.
- The original trace covers parallel, autorun and event-touch only. Action and
  player-touch are covered by the live contract alone, not by original parity.
- The original trace is 120 frames on a synthetic 20x15 map; the live contract is
  620 frames on the installed `Map001`. Neither is an unbounded soak.
- No macOS/Linux, fresh-release, or third-party-plugin coverage.

## Live 96-event contract

`tests/test_dense_map_runtime.gd` boots the real game, enters `Scene_Map` with the
installed `Map001`, injects 96 simultaneous events, and drives them through the
real stock loop (`Scene_Map#update` -> `Game_Map#update` -> every
`Game_Event#update`) and the real input path for action and player-touch triggers.

Measured run, exit 0, `DENSE_MAP_RUNTIME_PASS`:

| group | trigger | events | exact count each | marker |
|---|---|---|---|---|
| parallel | 4 | 64 | 20 | `parallel=64:[20..20]` |
| autorun | 3 | 8 | 1 | `autorun=8:[1..1]` |
| action | 0 | 8 | 1 | `action=8:[1..1]` |
| player-touch | 1 | 8 | 1 | `player_touch=8:[1..1]` |
| event-touch | 2 | 8 | 1 | `event_touch=8:[1..1]` |

Every event is asserted individually against its own exact count; a missing event
is named by id. No lower bounds. `DENSE_MAP_GROUPS` prints the observed min..max
per group so a partial loss is visible even when one event is off.

Finite durations (exact frames, not wall clock):

- parallel window: 620 map updates, expected 20 increments each.
- autorun settle: 40 frames.
- action: 8 x (2 settle + 4 key-down + 8 key-up) = 112 frames.
- player-touch: 200 frames of held Right plus 10 release frames.
- event-touch: 8 x 12 frames, driven one at a time because stock gates
  event-touch starts on `$game_map.interpreter.running?`.
- scene settle after each `SceneManager.goto(Scene_Map)`: 180 frames.

Teardown/recreation resource counts:

```
DENSE_MAP_RESOURCES:baseline=(5, 11, 7),dense=(5, 107, 7),recreated=(5, 107, 7),restored=(5, 11, 7)
```

- baseline: stock map before injection.
- dense: +96 sprites, exactly one `Sprite_Character` per injected event.
- recreated: a fresh `Scene_Map` with the dense load still present keeps exactly
  the same counts, so recreation neither leaks nor drops live objects.
- restored: after restoring the stock event table and map data, counts return to
  the baseline exactly.

Post-window state: scene `Scene_Map`, map 1, player at 8,8 facing down, main
interpreter not running, event table = 1 stock event + 96 injected.

## Original RGSS300 parity

`tests/fixtures/dense_map_reference.rb` runs unchanged on both engines and drives
`$game_map.update(true)` + `$game_player.update` directly, so the frame index is
exact and independent of host frame pacing.

Fixture: 24 simultaneous events on a 20x15 map.

- 16 parallel with a 30-frame wait; event 1 also carries a forced non-skippable
  move route so route progress and `real_x`/`real_y` are traced.
- 4 autorun with a per-event latch switch.
- 4 event-touch forced one step into the player at frames 40/60/80/100.

Output is 3001 rows (120 frames x (1 player row + 24 event rows) + header).

Result:

- `tools/run_original_dense_map.ps1` -> `ORIGINAL_EXIT:0`,
  `ORIGINAL_DENSE_MAP_READY rows=3001`.
- `-- --fixture` on Godot -> `DENSE_MAP_FIXTURE_PASS`, exit 0.
- Independent `cmp` and SHA256 of both files:
  `7aef3191923a57ee7b0656420319698abad1bc88dc9d164b139660b620b147b0`,
  identical.

Mutation proof: changing one original row (frame 60, event 1 counter 9 -> 10)
made the run fail with

```
ERROR: Dense map scheduling differs from original at row 1502:
  original: 60	1	10	3	12	3.000000000	12.000000000	false	false	0	6	27
  godot:    60	1	2	3	12	3.000000000	12.000000000	false	false	0	6	27
```

The fixture was then restored byte for byte (same SHA256) and the run returned to
`DENSE_MAP_FIXTURE_PASS`. The comparison is therefore not vacuous.

## Mechanism measured

Stock RMVA update order (`docs/rmva-scripts/`):

- `Scene_Map#update`: `super` (Graphics.update barrier, Input.update, windows),
  `$game_map.update(true)`, `$game_player.update`, `$game_timer.update`,
  `@spriteset.update`.
- `Game_Map#update`: interpreter, scroll, `@events.each_value(&:update)`,
  `@common_events.each(&:update)`, vehicles, parallax, screen.
- `Game_Event#update`: character update, `check_event_trigger_auto`, then its
  parallel interpreter `setup`/`update`.
- `Game_Interpreter#wait(n)` yields exactly n times; command 122 increments a
  variable; command 230 is the wait.
- `Spriteset_Map#create_characters` creates one `Sprite_Character` per event at
  scene start, so events injected before `Scene_Map` starts are really rendered.

Measured cadence: a parallel event with `[122][230 wait 30][end]` increments on
map updates 1, 33, 65, 97, ... (32-update cycle). The smallest experiment
(8 events, 140 updates) returned exactly 5 each; the 96-event run returned
exactly 20 over 620 updates; the original fixture returned 4 each over 120
updates. Same cadence at all three scales.

## Files

- `tests/test_dense_map_runtime.gd` - live 96-event contract, plus `--fixture`
  mode that runs the shared Ruby and compares against the original TSV.
- `tests/fixtures/dense_map_reference.rb` - shared trace (both engines).
- `tests/fixtures/dense_map_original.tsv` - original-only capture, 3001 rows,
  SHA256 `7aef3191923a57ee7b0656420319698abad1bc88dc9d164b139660b620b147b0`.
- `tools/run_original_dense_map.ps1` - isolated original fixture: copies the
  installed game into `.omo/compatibility-run-tmp/d09-dense-map-original`, swaps
  `Scripts.rvdata2`, runs `Game.exe`, copies the TSV into `tests/fixtures/`.
  The user's game `Data` directory is never written.
- `.omo/evidence/rmva-compatibility/godot/dense-map/` - `dense-map-live.png`,
  `dense_map_live.tsv`, `dense_map_live_state.tsv`, `dense_map_reference.tsv`.

## Commands

```sh
# Live 96-event contract (needs the real renderer; not headless)
godot --path . -s tests/test_dense_map_runtime.gd

# Shared numeric trace on Godot, compared to the original TSV
godot --path . -s tests/test_dense_map_runtime.gd -- --fixture

# Original RGSS300 capture into an owned isolated fixture
powershell -NoProfile -File tools/run_original_dense_map.ps1
```

## Limits

- Finite measured coverage, not an unbounded soak. Every duration above is an
  exact frame count, not a wall-clock claim.
- The live contract runs the installed project's `Map001` in memory and restores
  it; it does not write game data.
- The original fixture uses the stock scripts plus the shared Ruby; it does not
  exercise third-party plugins.
- Random-based behavior (random move routes, encounters) is deliberately absent
  from the traced fixture because the two engines' `Kernel#rand` sequences differ.
- No claim extends to macOS/Linux or fresh release builds.
- The live contract is not registered in `tools/run_tests.gd`; aggregator edits
  were outside this task's allowed paths. Run it explicitly as shown above.
