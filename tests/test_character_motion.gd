extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	root.add_child(load("res://Scenes/Boot.tscn").instantiate())
	for frame in range(180):
		await process_frame
		await RenderingServer.frame_post_draw
	var output := ProjectSettings.globalize_path("res://.omo/evidence/rmva-compatibility/godot")
	var actual_path := output.path_join("character_motion_reference.tsv")
	if FileAccess.file_exists(actual_path):
		DirAccess.remove_absolute(actual_path)
	var code := "$rgss_compat_output=" + JSON.stringify(output) + "\n" + FileAccess.get_file_as_string("res://tests/fixtures/character_motion_reference.rb")
	var ok: bool = driver.RunRuby(code)
	ok = driver.RunRuby("probe=Sprite.new; begin; raise 'Sprite default bush opacity must be 128' unless probe.bush_opacity == 128; ensure; probe.dispose; end") and ok
	var shift := InputEventKey.new()
	shift.keycode = KEY_SHIFT
	shift.pressed = true
	Input.parse_input_event(shift)
	await process_frame
	ok = driver.RunRuby("Input.update; player=$game_player; map=$game_map; saved_map=map.instance_variable_get(:@map); data=RPG::Map.new(24,20); begin; map.instance_variable_set(:@map,data); data.disable_dashing=false; raise 'Shift must enable player dash' unless player.dash? && player.real_move_speed == player.move_speed + 1; data.disable_dashing=true; raise 'map must disable dash' if player.dash?; data.disable_dashing=false; player.instance_variable_set(:@move_route_forcing,true); raise 'forced route must disable dash' if player.dash?; ensure; map.instance_variable_set(:@map,saved_map); player.instance_variable_set(:@move_route_forcing,false); end") and ok
	shift = InputEventKey.new()
	shift.keycode = KEY_SHIFT
	shift.pressed = false
	Input.parse_input_event(shift)
	await process_frame
	ok = driver.RunRuby("Input.update; map=$game_map; saved_map=map.instance_variable_get(:@map); begin; map.instance_variable_set(:@map,RPG::Map.new(24,20)); raise 'released Shift must disable dash' if $game_player.dash?; ensure; map.instance_variable_set(:@map,saved_map); end") and ok
	if ok:
		ok = FileAccess.file_exists(actual_path)
		if ok:
			var actual := FileAccess.get_file_as_string(actual_path).replace("\r\n", "\n").strip_edges()
			ok = actual.sha256_text() == "16ca207573e1aec16cdd00c733efee63e070d27b7a72b86ab32012ca61177e3d"
			if not ok:
				push_error("Character motion differs from the 1890 original RGSS300 rows")
		else:
			push_error("Character motion reference output missing")
	print("CHARACTER_MOTION_PASS" if ok else "CHARACTER_MOTION_FAIL")
	quit(0 if ok else 1)
