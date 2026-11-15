extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game: Node = load("res://Scenes/Boot.tscn").instantiate()
	root.add_child(game)
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	for i in range(90):
		await process_frame
	var title_viewports: int = driver.GetViewportCount()
	var title_sprites: int = driver.GetSpriteCount()
	var title_windows: int = driver.GetWindowCount()
	var ok := true
	for cycle in range(3):
		ok = driver.RunRuby("$reset_scene_before = SceneManager.scene; DataManager.setup_new_game; SceneManager.goto(Scene_Map)") and ok
		for i in range(90):
			await process_frame
		var event := InputEventKey.new()
		event.keycode = KEY_F12
		event.pressed = true
		Input.parse_input_event(event)
		await process_frame
		event = InputEventKey.new()
		event.keycode = KEY_F12
		event.pressed = false
		Input.parse_input_event(event)
		for i in range(90):
			await process_frame
		ok = driver.RunRuby("raise 'F12 must restart title' unless SceneManager.scene.is_a?(Scene_Title); raise 'old scene retained' if SceneManager.scene.equal?($reset_scene_before)") and ok
		var same_resources: bool = title_viewports == driver.GetViewportCount() and title_sprites == driver.GetSpriteCount() and title_windows == driver.GetWindowCount()
		print("RESET_RESOURCES:%d:" % cycle, title_viewports, ",", title_sprites, ",", title_windows, " -> ", driver.GetViewportCount(), ",", driver.GetSpriteCount(), ",", driver.GetWindowCount())
		ok = ok and same_resources
	print("GAME_RESET_PASS" if ok else "GAME_RESET_FAIL")
	quit(0 if ok else 1)
