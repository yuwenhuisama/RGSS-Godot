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
	var path := output.path_join("event_control_reference.tsv")
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var code := "$rgss_compat_output=" + JSON.stringify(output) + "\n" + FileAccess.get_file_as_string("res://tests/fixtures/event_control_reference.rb")
	var ok: bool = driver.RunRuby(code)
	if ok:
		var actual := FileAccess.get_file_as_string(path).replace("\r\n", "\n").strip_edges()
		ok = actual.sha256_text() == "12fad83c90883e0176aaf975695d01e90e89a61bb0253979f2a21facc5b1b9b7"
		if not ok:
			push_error("Event control differs from 45 original RGSS300 scenarios")
	var key := InputEventKey.new()
	key.keycode = KEY_SHIFT
	key.pressed = true
	Input.parse_input_event(key)
	await process_frame
	ok = driver.RunRuby("Input.update; old_variables=$game_variables; old_message=$game_message; begin; $game_variables=Game_Variables.new; $game_message=Game_Message.new; list=[RPG::EventCommand.new(111,0,[11,:A]),RPG::EventCommand.new(122,1,[1,1,0,0,1]),RPG::EventCommand.new(411,0,[]),RPG::EventCommand.new(122,1,[1,1,0,0,0]),RPG::EventCommand.new(412,0,[]),RPG::EventCommand.new]; interpreter=Game_Interpreter.new; interpreter.setup(list); 3.times { interpreter.update }; raise 'input branch must take pressed Shift' unless $game_variables[1] == 1; ensure; $game_variables=old_variables; $game_message=old_message; end") and ok
	key = InputEventKey.new()
	key.keycode = KEY_SHIFT
	key.pressed = false
	Input.parse_input_event(key)
	await process_frame
	ok = driver.RunRuby("Input.update; old_variables=$game_variables; old_message=$game_message; begin; $game_variables=Game_Variables.new; $game_message=Game_Message.new; list=[RPG::EventCommand.new(111,0,[11,:A]),RPG::EventCommand.new(122,1,[1,1,0,0,1]),RPG::EventCommand.new(411,0,[]),RPG::EventCommand.new(122,1,[1,1,0,0,0]),RPG::EventCommand.new(412,0,[]),RPG::EventCommand.new]; interpreter=Game_Interpreter.new; interpreter.setup(list); 3.times { interpreter.update }; raise 'input branch must take released Shift else' unless $game_variables[1] == 0; ensure; $game_variables=old_variables; $game_message=old_message; end") and ok
	print("EVENT_CONTROL_PASS" if ok else "EVENT_CONTROL_FAIL")
	quit(0 if ok else 1)
