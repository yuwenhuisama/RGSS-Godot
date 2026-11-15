extends SceneTree

const TestPaths = preload("res://tools/test_paths.gd")

# D09 dense-event / long-running map acceptance, live Scene_Map path.
#
# 96 simultaneous map events injected into the live map, then exercised through
# the real stock update loop (Scene_Map#update -> Game_Map#update -> every
# Game_Event#update) and the real input path for action/player-touch triggers.
#
# Composition and exact expectations:
#   64 parallel (trigger 4): own counter + stock 30-frame wait, activated last.
#      Measured cadence is 32 map updates per increment (1 increment frame + 30
#      wait yields + the end-of-list frame), so 620 updates give exactly 20.
#   8 autorun (trigger 3): page gated on its own latch switch; the list
#      increments once and turns that switch off, so each runs exactly once.
#   8 action (trigger 0): own counter; Enter is pressed with the player standing
#      on the event tile, so the stock check_action_event path dispatches each.
#   8 player-touch (trigger 1): own counter; the player really walks over them.
#   8 event-touch (trigger 2): own counter; each event is forced one step into
#      the player, the stock move is blocked, and check_event_trigger_touch
#      starts it. Stock gates this on `$game_map.interpreter.running?`, so these
#      are driven one at a time.
#
# Every event is asserted individually against its own exact count; a missing
# event is named. No lower bounds. Then the scene is torn down and recreated
# with the dense load (counts must be identical) and after restoring the stock
# map (counts must return to the pre-injection baseline).
#
# Requires a real renderer for the in-engine root capture. Do not run headless.
# No desktop/fullscreen/physical-display capture is used.

const PARALLEL_COUNT := 64
const AUTORUN_COUNT := 8
const ACTION_COUNT := 8
const TOUCH_COUNT := 8
const EVENT_TOUCH_COUNT := 8
const TOTAL_COUNT := 96
const PARALLEL_FRAMES := 620
const PARALLEL_EXPECTED := 20
const EVENT_TOUCH_IDS := [9089, 9090, 9091, 9092, 9093, 9094, 9095, 9096]
# Stock move-route codes: 1 down, 2 left, 3 right, 4 up (not direction numbers).
const EVENT_TOUCH_ROUTE_CODES := [1, 3, 2, 4, 1, 3, 2, 4]
const FIXTURE_ROWS := 120 * 25 + 1

func _initialize() -> void:
	call_deferred("_run")

func frames(count: int) -> void:
	for frame in range(count):
		await process_frame
		await RenderingServer.frame_post_draw

func counts(driver) -> Vector3i:
	return Vector3i(driver.GetViewportCount(), driver.GetSpriteCount(), driver.GetWindowCount())

func _fixture_run(driver) -> void:
	var output := TestPaths.output("dense-map")
	DirAccess.make_dir_recursive_absolute(output)
	var path := output.path_join("dense_map_reference.tsv")
	for stale in [path, output.path_join("dense_map_reference_error.txt")]:
		if FileAccess.file_exists(stale):
			DirAccess.remove_absolute(stale)
	var code := "$rgss_compat_output=" + JSON.stringify(output) + "\n" + TestPaths.ruby_setup() + FileAccess.get_file_as_string(TestPaths.fixture("dense_map_reference.rb"))
	var ok: bool = driver.RunRuby(code)
	if not ok:
		push_error("Dense map fixture raised")
	if FileAccess.file_exists(output.path_join("dense_map_reference_error.txt")):
		push_error(FileAccess.get_file_as_string(output.path_join("dense_map_reference_error.txt")))
		ok = false
	if not FileAccess.file_exists(path):
		push_error("Dense map fixture produced no TSV")
		ok = false
	else:
		var actual := FileAccess.get_file_as_string(path).replace("\r\n", "\n").strip_edges()
		var rows := actual.split("\n")
		if rows.size() != FIXTURE_ROWS:
			push_error("Dense map fixture wrote %d rows, expected %d" % [rows.size(), FIXTURE_ROWS])
			ok = false
		var original := TestPaths.fixture("dense_map_original.tsv")
		if not FileAccess.file_exists(original):
			push_error("Missing original dense map fixture tests/fixtures/dense_map_original.tsv")
			ok = false
		else:
			var expected := FileAccess.get_file_as_string(original).replace("\r\n", "\n").strip_edges()
			if actual.sha256_text() != expected.sha256_text():
				var actual_rows := actual.split("\n")
				var expected_rows := expected.split("\n")
				var first := -1
				for index in range(mini(actual_rows.size(), expected_rows.size())):
					if actual_rows[index] != expected_rows[index]:
						first = index
						break
				if first >= 0:
					push_error("Dense map scheduling differs from original at row %d:\n  original: %s\n  godot:    %s" % [first, expected_rows[first], actual_rows[first]])
				else:
					push_error("Dense map row count differs from original: %d vs %d" % [actual_rows.size(), expected_rows.size()])
				ok = false
	print("DENSE_MAP_FIXTURE_PASS" if ok else "DENSE_MAP_FIXTURE_FAIL")
	quit(0 if ok else 1)

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Dense map runtime contract needs the real renderer for its root capture")
		print("DENSE_MAP_RUNTIME_FAIL")
		quit(1)
		return
	var ok := true
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	TestPaths.required("game_project")
	root.add_child(load("res://Scenes/Boot.tscn").instantiate())
	await frames(180)
	if "--fixture" in OS.get_cmdline_user_args():
		_fixture_run(driver)
		return
	var profile := "--resource-profile" in OS.get_cmdline_user_args()
	var soak := "--soak" in OS.get_cmdline_user_args() or profile
	var parallel_frames := 36000 if soak else PARALLEL_FRAMES
	var parallel_expected := (parallel_frames + 31) / 32 if soak else PARALLEL_EXPECTED
	if soak:
		Engine.max_fps = 60
	var output := TestPaths.output("dense-map")
	if soak:
		output = output.path_join("soak")
	if profile:
		output = output.path_join("resource-profile")
	DirAccess.make_dir_recursive_absolute(output)
	var tsv := output.path_join("dense_map_live.tsv")
	var state_tsv := output.path_join("dense_map_live_state.tsv")
	var error_path := output.path_join("dense_map_live_error.txt")
	for stale in [tsv, state_tsv, error_path]:
		if FileAccess.file_exists(stale):
			DirAccess.remove_absolute(stale)

	ok = driver.RunRuby("raise 'title not ready' unless SceneManager.scene.is_a?(Scene_Title); DataManager.setup_new_game; SceneManager.goto(Scene_Map)") and ok
	await frames(180)
	ok = driver.RunRuby("raise 'map not ready' unless SceneManager.scene.is_a?(Scene_Map)") and ok
	var baseline := counts(driver)

	var setup := """
begin
  raise 'map not ready' unless SceneManager.scene.is_a?(Scene_Map)
  $dense_map_saved_events = $game_map.events.dup
  $dense_map_saved_event_count = $game_map.events.size
  $dense_map_saved_encounter = $game_system.encounter_disabled
  $dense_map_tileset_id = $game_map.instance_variable_get(:@tileset_id)
  $data_system.switches << 'D09 dense parallel'
  $dense_map_parallel_switch = $data_system.switches.size - 1
  $data_system.switches << 'D09 dense main'
  $dense_map_main_switch = $data_system.switches.size - 1
  $dense_map_autorun_switches = []
  8.times do |i|
    $data_system.switches << 'D09 dense autorun ' + (i + 1).to_s
    $dense_map_autorun_switches << ($data_system.switches.size - 1)
  end
  $dense_map_var_base = $data_system.variables.size
  96.times { |i| $data_system.variables << 'D09 dense event ' + (i + 1).to_s }
  $dense_map_saved_tiles = []
  (3..12).each do |x|
    3.times do |z|
      $dense_map_saved_tiles << [x, 50, z, $game_map.data[x, 50, z]]
      $game_map.data[x, 50, z] = z == 0 ? 1 : 0
    end
  end
  $dense_map_saved_flag = $data_tilesets[$dense_map_tileset_id].flags[1]
  $data_tilesets[$dense_map_tileset_id].flags[1] = 0
  $dense_map_rows = []
  build = lambda do |id, x, y, group, trigger, priority, switch1, variable_id, list|
    data = RPG::Event.new(x, y)
    data.id = id
    idle = data.pages[0]
    idle.trigger = 0
    idle.priority_type = 0
    idle.graphic.character_name = 'Actor1'
    idle.graphic.character_index = (id - 9001) % 8
    idle.list = [RPG::EventCommand.new]
    active = RPG::Event::Page.new
    active.condition.switch1_valid = true
    active.condition.switch1_id = switch1
    active.trigger = trigger
    active.priority_type = priority
    active.graphic.character_name = 'Actor1'
    active.graphic.character_index = (id - 9001) % 8
    active.list = list
    data.pages << active
    $game_map.events[id] = Game_Event.new($game_map.map_id, data)
    $dense_map_rows << [id, group, variable_id]
  end
  counter = lambda do |variable_id|
    [RPG::EventCommand.new(122, 0, [variable_id, variable_id, 1, 0, 1]),
      RPG::EventCommand.new(230, 0, [30]), RPG::EventCommand.new]
  end
  single = lambda do |variable_id|
    [RPG::EventCommand.new(122, 0, [variable_id, variable_id, 1, 0, 1]), RPG::EventCommand.new]
  end
  index = 0
  64.times do |i|
    variable_id = $dense_map_var_base + index
    # Kept inside the 544x416 viewport centred on the player at 8,8 so the
    # captured frame actually shows the dense grid.
    build.call(9001 + index, 2 + (i % 8), 3 + (i / 8), 'parallel', 4, 0,
      $dense_map_parallel_switch, variable_id, counter.call(variable_id))
    index += 1
  end
  8.times do |i|
    variable_id = $dense_map_var_base + index
    list = [RPG::EventCommand.new(122, 0, [variable_id, variable_id, 1, 0, 1]),
      RPG::EventCommand.new(121, 0, [$dense_map_autorun_switches[i], $dense_map_autorun_switches[i], 1]),
      RPG::EventCommand.new]
    build.call(9001 + index, 2 + i, 12, 'autorun', 3, 0,
      $dense_map_autorun_switches[i], variable_id, list)
    index += 1
  end
  8.times do |i|
    variable_id = $dense_map_var_base + index
    build.call(9001 + index, 4 + i, 40, 'action', 0, 0,
      $dense_map_main_switch, variable_id, single.call(variable_id))
    index += 1
  end
  8.times do |i|
    variable_id = $dense_map_var_base + index
    build.call(9001 + index, 4 + i, 50, 'player_touch', 1, 0,
      $dense_map_main_switch, variable_id, single.call(variable_id))
    index += 1
  end
  positions = [[20, 19], [19, 20], [21, 20], [20, 21], [30, 29], [29, 30], [31, 30], [30, 31]]
  positions.each do |x, y|
    variable_id = $dense_map_var_base + index
    build.call(9001 + index, x, y, 'event_touch', 2, 1,
      $dense_map_main_switch, variable_id, single.call(variable_id))
    index += 1
  end
  raise 'dense event count' unless index == 96
  $game_system.encounter_disabled = true
rescue Exception => error
  File.open(File.join($dense_map_output, 'dense_map_live_error.txt'), 'w') { |file| file.puts(error.class.to_s, error.message, error.backtrace) }
  raise
end
"""
	ok = driver.RunRuby("$dense_map_output=" + JSON.stringify(output) + "\n" + setup) and ok
	ok = driver.RunRuby("SceneManager.goto(Scene_Map)") and ok
	await frames(180)
	var dense := counts(driver)
	if dense != baseline + Vector3i(0, TOTAL_COUNT, 0):
		push_error("Dense load did not add exactly %d live sprites: %s -> %s" % [TOTAL_COUNT, baseline, dense])
		ok = false

	ok = driver.RunRuby("$game_switches[$dense_map_main_switch] = true; $dense_map_autorun_switches.each { |id| $game_switches[id] = true }") and ok
	await frames(40)
	ok = driver.RunRuby("raise 'autorun latch still active' if $dense_map_autorun_switches.any? { |id| $game_switches[id] }; raise 'main interpreter busy before input phase' if $game_map.interpreter.running?") and ok

	for index in range(ACTION_COUNT):
		ok = driver.RunRuby("$game_player.moveto(%d, 40); $game_player.set_direction(6)" % (4 + index)) and ok
		await frames(2)
		var action_key := InputEventKey.new()
		action_key.keycode = KEY_ENTER
		action_key.pressed = true
		Input.parse_input_event(action_key)
		await frames(4)
		action_key = InputEventKey.new()
		action_key.keycode = KEY_ENTER
		action_key.pressed = false
		Input.parse_input_event(action_key)
		await frames(8)

	ok = driver.RunRuby("raise 'player-touch corridor not passable' unless (3..12).all? { |x| $game_map.passable?(x, 50, 6) }; $game_player.moveto(3, 50); $game_player.set_direction(6)") and ok
	await frames(2)
	var walk_key := InputEventKey.new()
	walk_key.keycode = KEY_RIGHT
	walk_key.pressed = true
	Input.parse_input_event(walk_key)
	await frames(200)
	walk_key = InputEventKey.new()
	walk_key.keycode = KEY_RIGHT
	walk_key.pressed = false
	Input.parse_input_event(walk_key)
	await frames(10)

	ok = driver.RunRuby("$game_player.moveto(20, 20); $game_player.set_direction(2)") and ok
	await frames(2)
	for index in range(4):
		ok = driver.RunRuby("raise 'interpreter busy before event-touch %d' if $game_map.interpreter.running?; event=$game_map.events[%d]; route=RPG::MoveRoute.new; route.repeat=false; route.skippable=true; route.wait=false; route.list=[RPG::MoveCommand.new(%d),RPG::MoveCommand.new]; event.force_move_route(route)" % [EVENT_TOUCH_IDS[index], EVENT_TOUCH_IDS[index], EVENT_TOUCH_ROUTE_CODES[index]]) and ok
		await frames(12)
	ok = driver.RunRuby("$game_player.moveto(30, 30); $game_player.set_direction(2)") and ok
	await frames(2)
	for index in range(4, 8):
		ok = driver.RunRuby("raise 'interpreter busy before event-touch %d' if $game_map.interpreter.running?; event=$game_map.events[%d]; route=RPG::MoveRoute.new; route.repeat=false; route.skippable=true; route.wait=false; route.list=[RPG::MoveCommand.new(%d),RPG::MoveCommand.new]; event.force_move_route(route)" % [EVENT_TOUCH_IDS[index], EVENT_TOUCH_IDS[index], EVENT_TOUCH_ROUTE_CODES[index]]) and ok
		await frames(12)

	ok = driver.RunRuby("$game_player.moveto(8, 8); raise 'main interpreter busy before parallel window' if $game_map.interpreter.running?") and ok
	await frames(2)
	ok = driver.RunRuby("$game_switches[$dense_map_parallel_switch] = true") and ok
	var started := Time.get_ticks_msec()
	if profile:
		var measurements := FileAccess.open(output.path_join("resources.tsv"), FileAccess.WRITE)
		if measurements == null:
			push_error("Cannot write dense-map resource measurements")
			quit(1)
			return
		measurements.store_line("frames\telapsed_ms\tviewports\tsprites\twindows\tnodes\tobjects\tmanaged_bytes\tstatic_bytes\ttexture_bytes\tfps")
		for sample in range(11):
			if sample > 0:
				await frames(3600)
			var live := counts(driver)
			measurements.store_line("%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%.3f" % [sample * 3600, Time.get_ticks_msec() - started, live.x, live.y, live.z, Performance.get_monitor(Performance.OBJECT_NODE_COUNT), Performance.get_monitor(Performance.OBJECT_COUNT), driver.GetManagedMemory(), Performance.get_monitor(Performance.MEMORY_STATIC), Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED), Performance.get_monitor(Performance.TIME_FPS)])
			measurements.flush()
			print("DENSE_RESOURCE_SAMPLE:frames=%d:counts=%s" % [sample * 3600, live])
			if live != dense:
				push_error("Dense run retained drawable owners: expected=%s actual=%s frame=%d" % [dense, live, sample * 3600])
				ok = false
		measurements.close()
	else:
		await frames(parallel_frames)
	var elapsed := Time.get_ticks_msec() - started
	if soak and elapsed < 600000:
		push_error("Dense soak ran fewer than ten minutes: %d ms" % elapsed)
		ok = false

	var dump := """
begin
  File.open(File.join($dense_map_output, 'dense_map_live.tsv'), 'w') do |file|
    $dense_map_rows.each do |id, group, variable_id|
      event = $game_map.events[id]
      file.puts([id, group, variable_id, $game_variables[variable_id],
        event.x, event.y, event.real_x, event.real_y,
        event.starting, event.move_route_forcing].join("\t"))
    end
  end
  File.open(File.join($dense_map_output, 'dense_map_live_state.tsv'), 'w') do |file|
    file.puts(['scene', SceneManager.scene.class.to_s].join("\t"))
    file.puts(['map_id', $game_map.map_id].join("\t"))
    file.puts(['player', $game_player.x, $game_player.y, $game_player.direction].join("\t"))
    file.puts(['interpreter', $game_map.interpreter.running?].join("\t"))
    file.puts(['event_count', $game_map.events.size].join("\t"))
    file.puts(['saved_event_count', $dense_map_saved_event_count].join("\t"))
  end
rescue Exception => error
  File.open(File.join($dense_map_output, 'dense_map_live_error.txt'), 'w') { |file| file.puts(error.class.to_s, error.message, error.backtrace) }
  raise
end
"""
	ok = driver.RunRuby(dump) and ok

	var expected := {
		"parallel": [PARALLEL_COUNT, parallel_expected],
		"autorun": [AUTORUN_COUNT, 1],
		"action": [ACTION_COUNT, 1],
		"player_touch": [TOUCH_COUNT, 1],
		"event_touch": [EVENT_TOUCH_COUNT, 1],
	}
	var group_entries := {}
	var total := 0
	if FileAccess.file_exists(tsv):
		for line in FileAccess.get_file_as_string(tsv).replace("\r\n", "\n").strip_edges().split("\n"):
			var fields := line.split("\t")
			if fields.size() < 10:
				push_error("Malformed dense row: " + line)
				ok = false
				continue
			var id := int(fields[0])
			var group := fields[1]
			total += 1
			if not group_entries.has(group):
				group_entries[group] = []
			group_entries[group].append([id, int(fields[3])])
			if int(fields[6]) != int(fields[4]) or int(fields[7]) != int(fields[5]):
				push_error("Dense event %d moved unexpectedly: %s,%s -> %s,%s" % [id, fields[4], fields[5], fields[6], fields[7]])
				ok = false
			if fields[8] != "false" or fields[9] != "false":
				push_error("Dense event %d did not settle: starting=%s forcing=%s" % [id, fields[8], fields[9]])
				ok = false
	else:
		push_error("Dense map measurement produced no TSV")
		ok = false
	if total != TOTAL_COUNT:
		push_error("Dense map measured %d events, expected %d" % [total, TOTAL_COUNT])
		ok = false
	var summary := []
	for group in expected:
		var expected_rows: int = expected[group][0]
		var expected_count: int = expected[group][1]
		if not group_entries.has(group):
			push_error("Dense group %s produced no events" % group)
			ok = false
			continue
		if group_entries[group].size() != expected_rows:
			push_error("Dense group %s produced %d events, expected %d" % [group, group_entries[group].size(), expected_rows])
			ok = false
		var observed_min: int = group_entries[group][0][1]
		var observed_max: int = observed_min
		for entry in group_entries[group]:
			observed_min = mini(observed_min, entry[1])
			observed_max = maxi(observed_max, entry[1])
			if entry[1] != expected_count:
				push_error("Dense event %d (%s) ran %d times, expected exactly %d" % [entry[0], group, entry[1], expected_count])
				ok = false
		summary.append("%s=%d:[%d..%d] expected %d" % [group, group_entries[group].size(), observed_min, observed_max, expected_count])
	print("DENSE_MAP_GROUPS:%s" % ",".join(summary))

	if FileAccess.file_exists(state_tsv):
		var state := {}
		for line in FileAccess.get_file_as_string(state_tsv).replace("\r\n", "\n").strip_edges().split("\n"):
			var fields := line.split("\t")
			state[fields[0]] = fields.slice(1)
		if state.get("scene", [""])[0] != "Scene_Map":
			push_error("Dense map left scene %s" % state.get("scene", ["?"])[0])
			ok = false
		if int(state.get("map_id", ["0"])[0]) != 1:
			push_error("Dense map left map %s" % state.get("map_id", ["?"])[0])
			ok = false
		var player: Array = state.get("player", ["-1", "-1", "-1"])
		if [int(player[0]), int(player[1]), int(player[2])] != [8, 8, 2]:
			push_error("Dense map left player at %s,%s dir %s" % [player[0], player[1], player[2]])
			ok = false
		if state.get("interpreter", ["true"])[0] != "false":
			push_error("Dense map left the main interpreter running")
			ok = false
		var expected_events: int = int(state.get("saved_event_count", ["-1"])[0]) + TOTAL_COUNT
		if int(state.get("event_count", ["0"])[0]) != expected_events:
			push_error("Dense map holds %s events, expected %d" % [state.get("event_count", ["?"])[0], expected_events])
			ok = false
	else:
		push_error("Dense map produced no state TSV")
		ok = false

	root.get_texture().get_image().save_png(output.path_join("dense-map-live.png"))

	ok = driver.RunRuby("SceneManager.goto(Scene_Map)") and ok
	await frames(180)
	var recreated := counts(driver)
	if recreated != dense:
		push_error("Dense scene recreation changed live counts: %s -> %s" % [dense, recreated])
		ok = false

	var restore := """
begin
  $game_map.events.clear
  $dense_map_saved_events.each { |id, event| $game_map.events[id] = event }
  $dense_map_saved_tiles.each { |x, y, z, tile| $game_map.data[x, y, z] = tile }
  $data_tilesets[$dense_map_tileset_id].flags[1] = $dense_map_saved_flag
  96.times { $data_system.variables.pop }
  10.times { $data_system.switches.pop }
  $game_system.encounter_disabled = $dense_map_saved_encounter
  $game_map.need_refresh = true
rescue Exception => error
  File.open(File.join($dense_map_output, 'dense_map_live_error.txt'), 'w') { |file| file.puts(error.class.to_s, error.message, error.backtrace) }
  raise
end
"""
	ok = driver.RunRuby(restore) and ok
	ok = driver.RunRuby("SceneManager.goto(Scene_Map)") and ok
	await frames(180)
	var restored := counts(driver)
	if restored != baseline:
		push_error("Dense teardown did not return live counts to baseline: %s -> %s" % [baseline, restored])
		ok = false
	if FileAccess.file_exists(error_path):
		push_error(FileAccess.get_file_as_string(error_path))
		ok = false
	print("DENSE_MAP_FRAMES:parallel=%d,elapsed_ms=%d,autorun=40,action=8x14,player_touch=210,event_touch=8x14,settle=180" % [parallel_frames,elapsed])
	print("DENSE_MAP_RESOURCES:baseline=%s,dense=%s,recreated=%s,restored=%s" % [baseline, dense, recreated, restored])
	print("DENSE_MAP_RUNTIME_PASS" if ok else "DENSE_MAP_RUNTIME_FAIL")
	quit(0 if ok else 1)
