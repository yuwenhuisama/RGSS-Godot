# Character motion verification

Baseline: installed Chinese RGSS300 3.0.0.1, measured 2026-11-13.
`tests/fixtures/character_motion_reference.rb` runs the real stock
Game_Character, Game_Map, Game_Player and Game_Vehicle classes on both engines.
It configures an in-memory map and empty party without replacing movement logic.

The completed original and Godot outputs contain 1890 identical TSV rows.
Normalized SHA256 (CR removed, outer whitespace trimmed):
`16ca207573e1aec16cdd00c733efee63e070d27b7a72b86ab32012ca61177e3d`.
`tests/test_character_motion.gd` pins this independently captured hash.

Coverage: speeds 1-6 in all four directions; four diagonal directions;
zero/positive/negative jumps; idle and step animation; bush, ladder and blocked
tiles; four map loop modes at the bottom-right edge; boat/ship/airship speeds,
boarding state, animation, altitude, screen position, visibility and dismount.
Each row is flushed before advancing the character, preserving partial evidence
if a case fails. Global fixture state is restored after execution.

The first original run failed before producing TSV because the cold in-memory
Game_Map lacked its separate `@tileset_id`. The fixture now sets that field.
The first Godot comparison ran before the original finished writing, producing
a false failure against a partial reference. After original exit 0, both outputs
matched and the comparison passed with exit 0. The pinned hash removes that
temporary-file timing dependency from future regressions.

Reproduce the original in a new owned destination:
```sh
ruby tools/prepare_original_fixture.rb E:/Projects/RMProject DESTINATION tests/fixtures/character_motion_reference.rb --stock-scripts
```
Run `DESTINATION/Game.exe` from that directory and wait for process exit before
reading `character_motion_reference.tsv`. Source game files are untouched.

Godot comparison requires the configured source game's stock scripts:
```sh
godot --path . -s tests/test_character_motion.gd
```

D03 acceptance combines the initial motion reference with the later rendered,
input and player-vehicle evidence below; the motion fixture alone was insufficient.

The fixed-hash numerical regression passed with exit 0. A separate shared
`character_render_reference.rb` now captures seven full frames through the real
Sprite_Character class, including four directions, step animation, bush depth
and a moving jump. `run_character_render.gd` is a capture driver, not yet a
parity assertion. The original capture and player/vehicle interaction probe
are running; no visual acceptance is claimed yet.

The first Godot capture failed while loading the synthetic character atlas.
Its fixture cache key used the original relative filename, while the live
Cache patch resolves an RTP path and `.png` extension before accessing the
cache. The fixture now uses that existing path method on the Godot side; no
production loading behavior was changed. A new capture is running.

The completed initial seven-frame comparison exposed a production defect:
660-900 differing RGB bytes per frame (maximum delta92), exclusively in bush
pixels. Example original(106,244)=(105,47,42,255), Godot=(180,60,40,255).
Sprite geometry/source rectangles agree; bush depth differs only in TSV numeric
format (8 versus8.0). The shader threshold used the entire atlas bottom instead
of the current Sprite2D region bottom, leaving upper atlas rows fully opaque.
RenderSprite now computes the threshold from RegionRect.End.Y and texture height,
preserving existing screen-depth scaling. Build exit0; seven pre-existing warnings
remain (obsolete Image.Create and nullable bindings/Variant values). Fresh capture
completed but retained all660-900 differing bytes. This disproved the threshold
change as a sufficient fix. A second cause is SpriteData.BushOpacity default255,
where the original pixels establish128. The older effect panel explicitly set
128 and therefore missed the default contract. Default128 and an explicit new
Ruby regression assertion are now added; build/capture verification is pending.

After both repairs, every byte of all seven544x416 captures matches the original
(905216bytes/frame, zero differing bytes). The default128 and motion regression
passed exit0. `run_character_render.gd` now checks independently captured SHA256
for every frame, so capture success alone no longer yields PASS. The paired
contact sheet was generated with `tools/character_contact_sheet.gd`; independent
visual inspection and the affected unified18-runner suite are running.

Seven-frame pinned-hash runner subsequently passed with exit0. The exact frame
hashes and frame indexes are kept in `tests/run_character_render.gd`; original
captures remain under `.omo/compatibility-run-tmp/d03-character-render` until
the overall evidence cleanup task. After the final production changes, the
unified rendered/Windows-font suite passed all18 runners with exit0. The contact sheet pairs each original row
with its Godot row at native scale, with no alignment or retouching.

Independent visual task st_01a1d2b5 accepted capture integrity and visual
equivalence for all seven pairs: matching anchors, silhouettes, colors, jumper
offset and bush-dimmed feet; no blank populated cells, clipping or overlap.
The full-sheet display reduced sprites to about10pixels tall, so individual
step-pose detail was below its visual resolution. Exact full-frame hashes cover
that detail numerically; this static contact sheet is not a playback verdict.

The motion runner now also injects real Shift key events and asserts player
dash speed, map disable-dash, forced-route suppression and key-release behavior.
The initial assertion hit the title scene's absent Game_Map data after the
numeric fixture correctly restored globals. The input probe now installs and
restores its own RPG::Map for this check; no gameplay failure is inferred from
that fixture dependency error. The corrected input test passed with exit0.

The original render monitor later hit its deadline after all seven captures and
all35 geometry rows had been flushed. Game.exe PID66872 still pointed to the
owned d03-character-render fixture; it was explicitly stopped after path
verification. Its complete pixel artifacts remain usable, but original process
exit success is not claimed for this capture. The numerical original fixture
did exit0. No user-game process was stopped.

Final player-vehicle acceptance: original and Godot 568 rows agree exactly,
normalized SHA256
`5ec3ef9342ba604c48068e31ef74f4054f70e5fe286b29fe2d2622565a65a012`.
`tests/test_player_vehicle.gd` additionally injects actual Enter confirmation
events into the stock Game_Player loop and verifies boat boarding and dismount
start and finish. PLAYER_VEHICLE_PASS exit0 after this addition. Detailed
vehicle/follower cases are in `player-vehicle-verification.md`.

D03 accepted against the installed original baseline: 1890 motion rows,
568 vehicle/follower rows, seven exact complete frames with independent visual
inspection, actual Shift/Enter input contracts, build exit0 and final production
unified suite18PASS. Static frames do not establish continuous playback quality.
Encounter randomness, terrain damage, event movement and transfer remain owned
by later map/battle items; other runtimes remain unverified.
