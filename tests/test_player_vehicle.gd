extends SceneTree

# D03 player/vehicle interaction contract. The fixture runs the stock
# Game_Player/Game_Followers/Game_Follower/Game_Vehicle/Game_Map/Game_Event
# classes on both engines; this runner replays it inside the booted game VM
# (Boot.tscn loads the configured source game's stock scripts) and pins the
# independently captured original RGSS300 output hash.
const EXPECTED_HASH := "5ec3ef9342ba604c48068e31ef74f4054f70e5fe286b29fe2d2622565a65a012"
const EXPECTED_ROWS := 568

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	root.add_child(load("res://Scenes/Boot.tscn").instantiate())
	for frame in range(180):
		await process_frame
		await RenderingServer.frame_post_draw
	var output := ProjectSettings.globalize_path("res://.omo/evidence/d03-player-vehicle/godot")
	DirAccess.make_dir_recursive_absolute(output)
	var actual_path := output.path_join("player_vehicle_reference.tsv")
	if FileAccess.file_exists(actual_path):
		DirAccess.remove_absolute(actual_path)
	var error_path := output.path_join("player_vehicle_error.txt")
	if FileAccess.file_exists(error_path):
		DirAccess.remove_absolute(error_path)
	var code := "$rgss_compat_output=" + JSON.stringify(output) + "\n" + FileAccess.get_file_as_string("res://tests/fixtures/player_vehicle_reference.rb")
	var ok: bool = driver.RunRuby(code)
	if ok:
		ok = FileAccess.file_exists(actual_path)
		if ok:
			var actual := FileAccess.get_file_as_string(actual_path).replace("\r\n", "\n").strip_edges()
			var rows := 0
			for line in actual.split("\n"):
				if not line.is_empty():
					rows += 1
			var actual_hash := actual.sha256_text()
			print("PLAYER_VEHICLE_ROWS:%d" % rows)
			print("PLAYER_VEHICLE_HASH:%s" % actual_hash)
			ok = actual_hash == EXPECTED_HASH and rows == EXPECTED_ROWS
			if not ok:
				push_error("Player/vehicle interaction differs from the pinned original RGSS300 rows")
		else:
			push_error("Player/vehicle reference output missing")
	else:
		push_error("Player/vehicle fixture raised; see player_vehicle_error.txt")
	ok = driver.RunRuby("$pv_input_saved=[$game_map,$game_player,$game_party,$game_actors,$game_system,$game_message,$game_temp,$game_switches,$game_variables,$game_self_switches,$data_system,$data_tilesets,$data_actors,$data_classes,$data_states,$data_items,$data_weapons,$data_armors,$data_skills,$data_common_events]; pv_build_world; $game_map.boat.set_location(1,11,10); $game_player.set_direction(6)") and ok
	var confirm := InputEventKey.new()
	confirm.keycode = KEY_ENTER
	confirm.pressed = true
	Input.parse_input_event(confirm)
	await process_frame
	ok = driver.RunRuby("Input.update; $game_map.update(true); $game_player.update; raise 'confirm key must start boat boarding' unless $game_player.in_boat?") and ok
	confirm = InputEventKey.new()
	confirm.keycode = KEY_ENTER
	confirm.pressed = false
	Input.parse_input_event(confirm)
	await process_frame
	ok = driver.RunRuby("Input.update; 80.times { $game_map.update(true); $game_player.update }; raise 'input boarding must complete' unless $game_player.in_boat? && $game_player.transparent && $game_map.boat.driving") and ok
	confirm = InputEventKey.new()
	confirm.keycode = KEY_ENTER
	confirm.pressed = true
	Input.parse_input_event(confirm)
	await process_frame
	ok = driver.RunRuby("Input.update; $game_map.update(true); $game_player.update; raise 'confirm key must start dismount' unless $game_player.instance_variable_get(:@vehicle_getting_off)") and ok
	confirm = InputEventKey.new()
	confirm.keycode = KEY_ENTER
	confirm.pressed = false
	Input.parse_input_event(confirm)
	await process_frame
	ok = driver.RunRuby("Input.update; 80.times { $game_map.update(true); $game_player.update }; raise 'input dismount must complete' unless $game_player.normal_walk? && !$game_player.transparent; $game_map,$game_player,$game_party,$game_actors,$game_system,$game_message,$game_temp,$game_switches,$game_variables,$game_self_switches,$data_system,$data_tilesets,$data_actors,$data_classes,$data_states,$data_items,$data_weapons,$data_armors,$data_skills,$data_common_events=$pv_input_saved") and ok
	print("PLAYER_VEHICLE_PASS" if ok else "PLAYER_VEHICLE_FAIL")
	quit(0 if ok else 1)
