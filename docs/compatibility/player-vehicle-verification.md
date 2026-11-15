# Player/vehicle interaction verification (D03)

Baseline: installed Chinese RGSS300 3.0.0.1 (`E:/Projects/RMProject`, `System/RGSS300.dll`),
measured 2026-11-13. Godot: `Godot_v4.6.1-stable_mono_win64_console`, assembly built 2026-11-13 10:19.

`tests/fixtures/player_vehicle_reference.rb` runs the real stock `Game_Player`,
`Game_Followers`, `Game_Follower`, `Game_Vehicle`, `Game_Map` and `Game_Event` classes
on both engines. It builds an in-memory 24x20 map, tileset flags, four actors with
`Game_Actor` instances, and an event table populated only by the collision cases; it
replaces no movement, boarding, dismount or follower method. Each frame is a real
`Scene_Map` step
(`$game_map.update(true)` then `$game_player.update`), so `update_vehicle`,
`update_nonmoving`, `@followers.update` and `Game_Vehicle#update_airship_altitude`
all run from stock code.

## Result

The completed original and Godot outputs are byte-identical: **568 TSV rows, 0 differing rows**.
Normalized SHA256 (CR removed, outer whitespace trimmed) for both files:
`5ec3ef9342ba604c48068e31ef74f4054f70e5fe286b29fe2d2622565a65a012`.
`tests/test_player_vehicle.gd` pins that hash and the row count; it printed
`PLAYER_VEHICLE_ROWS:568`, `PLAYER_VEHICLE_HASH:5ec3ef…a012`, `PLAYER_VEHICLE_PASS`, exit 0.

Commands (original first, waited to exit before comparing):

```sh
ruby tools/prepare_original_fixture.rb E:/Projects/RMProject \
  .omo/tmp/d03-player-vehicle-original tests/fixtures/player_vehicle_reference.rb --stock-scripts
# ORIGINAL_FIXTURE_READY:E:/Projects/RGSS-Godot/.omo/tmp/d03-player-vehicle-original
# run DESTINATION/Game.exe from that directory; ORIGINAL_EXIT:0
godot --path . -s tests/test_player_vehicle.gd
```

The original writes `player_vehicle_reference.tsv` into its own project directory
(`output = $rgss_compat_output || '.'`); the Godot runner writes to
`.omo/evidence/d03-player-vehicle/godot/`. Per-case rows are flushed before the frame
advances, so a hang leaves the last written phase visible.

## Covered contracts (each contributes rows to the pinned hash)

Boarding (`Game_Player#get_on_vehicle` → `update_vehicle_get_on` → `Game_Vehicle#get_on`):

- Boat: board from `(11,10)` onto water at `(12,10)`, `get_on_vehicle` returns 1, player
  `force_move_forward` to `(12,10)`, then `transparent=1`, `move_speed=4`, `in_boat?=1`,
  vehicle `driving=1`, `walk_anime=1`, `step_anime=1`, `screen_z=100`. 31 board rows.
- Ship: same shape at `(13,10)`→`(14,10)`, `move_speed=5`, `screen_z=100`. 31 board rows.
- Airship: board in place at `(16,10)` (no forward move), `through=1`, altitude ascends
  0→32 one point per frame only while `followers.gather?` is true; `movable?` stays 0 until
  altitude 32; `priority_type` rises 0→2 and `screen_z` 0→200; `screen_y` = `super - altitude`
  (220 → 188 at full altitude). 59 board rows.

Dismount and landing rejection (`Game_Player#get_off_vehicle` → `Game_Vehicle#land_ok?`):

- Boat/ship over water: `land_ok?` checks the tile *ahead* (`round_*_with_direction` then
  `passable?(x2,y2,reverse_dir(d))`), so facing water returns 0 and nothing changes
  (`boat-reject-water-return-0`, `ship-reject-water-return-0`).
- Boat over water with a normal-priority event on the landing tile: `collide_with_characters?`
  rejects (`boat-event-reject-event-return-0`); after `event.erase` the same call returns 1.
- Airship over water: `airship_land_ok?` fails on the `0x0800`/`0x0f` flags
  (`airship-reject-water-return-0`). Airship over an event: `events_xy(x,y)` non-empty
  (`airship-reject-event-return-0`). Airship over plain land returns 1, then `set_direction(2)`,
  speed resets to 4, altitude descends 32→0 one point per frame (33 rows: f=0 `alt=32`,
  f=31 `alt=1`, f=32 `@vehicle_getting_off` clears). From that frame the player's `vehicle`
  is nil because `@vehicle_type` is back to `:walk`, so the vehicle columns read `-`
  (`airship-dismount-return-1`, `airship-landed`).
- Boat/ship dismount: `force_move_forward` to the shore tile, `transparent=0`,
  `@move_speed=4`, `@through=0`, `@vehicle_type` back to `:walk`. `@vehicle_getting_off`
  does **not** clear immediately: `update_vehicle_get_off` requires
  `!@followers.gathering? && vehicle.altitude == 0`, so the flag stays 1 for 50 frames while
  the scattered followers walk back, then clears on the frame `gather?` becomes 1
  (`boat-dismount` f=0 `off=1 gathering=1`, f=49 `off=1 gather=1`, f=50 `off=0 in_boat=0`).
  51 dismount rows each.

Followers (`Game_Followers#gather`/`gather?`/`synchronize`, `Game_Follower#chase_preceding_character`):

- `gather` sets `@gathering=1`; `Game_Player#update_vehicle` returns early while gathering,
  so boarding cannot complete until followers arrive. `gather?` requires every visible
  follower to be `!moving? && pos?(preceding.x, preceding.y)`. 26 gather rows ending at
  `gathering?=0`, `gather?=1` with all three followers stacked on the leader.
- `Game_Player#moveto` calls `@followers.synchronize(x, y, direction)`, which moves every
  follower onto the leader and adopts the leader's direction (6 in the `follower-sync` rows).
- Chase movement is stock: `follower-chase` rows show diagonal `move_diagonal(4/6, 2/8)`
  and straight `move_straight` steps with `real_x/real_y` interpolation at the leader's
  `real_move_speed`.

## Gaps

- No `Sprite_Character` rendering/bitmap rows: this lane is numeric interaction state only.
  The lead's separate seven-frame `Sprite_Character` capture and visual PASS cover pixels.
- `Input`-driven paths (`move_by_input`, `dash?`, `Input.trigger?(:C)` in `update_nonmoving`)
  are not exercised; the fixture calls `get_on_vehicle`/`get_off_vehicle` and
  `move_straight` directly, which is the same public entry point the input path uses.
- Encounter counting (`make_encounter_count` uses `rand`) is not asserted; it is
  deliberately excluded so the fixture is deterministic.
- `Game_Event` movement types, common events and transfer (`Scene_Map` transfer) are out of
  scope; only event collision in `land_ok?` is covered.
- Terrain damage (`on_damage_floor?`) is not asserted; tile `0x0100` is configured but no
  actor HP row is recorded.
- Original run used RGSS300 only; RGSS301 is not installed locally.

The lead extended `test_player_vehicle.gd` with real Enter key events. Stock
update_nonmoving started boarding, driving/transparent state completed, a second
confirmation started dismount, and normal walking was restored. The 568-row
reference and input assertions passed PLAYER_VEHICLE_PASS exit0. Shift dash
input is covered by `test_character_motion.gd`.

The lead subsequently extended `test_player_vehicle.gd` with real Enter key
events. Stock `update_nonmoving` started boarding, vehicle driving/transparent
state completed, a second confirmation started dismount, and normal walking
was restored. The568-row pinned reference and these input assertions passed
PLAYER_VEHICLE_PASS with exit0. This closes the confirmation-input gap above;
Shift dash input is covered by `test_character_motion.gd`.
