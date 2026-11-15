extends SceneTree

const TestPaths = preload("res://tools/test_paths.gd")

# Exercise the real close notification followed by SceneTree shutdown/ExitTree.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	TestPaths.required("game_project")
	var game: Node = load("res://Scenes/Boot.tscn").instantiate()
	root.add_child(game)
	for frame in range(90):
		await process_frame
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	if "--menu" in OS.get_cmdline_user_args():
		if not driver.RunRuby("DataManager.setup_new_game; Window_MenuCommand.init_command_position; SceneManager.goto(Scene_Map)"):
			quit(1)
			return
		for frame in range(120):
			await process_frame
		if not driver.RunRuby("SceneManager.call(Scene_Menu)"):
			quit(1)
			return
		for frame in range(90):
			await process_frame
	var tone := TestPaths.fixture("audio/tone.wav")
	var ok: bool = driver.RunRuby("Audio.bgm_play(" + JSON.stringify(tone) + "); Audio.se_play(" + JSON.stringify(tone) + "); raise 'shutdown fixture error'") == false
	if not ok:
		push_error("Shutdown probe did not observe its deliberate Ruby exception")
		quit(1)
		return
	print("GAME_CLOSE_EXCEPTION_OBSERVED")
	game.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	print("GAME_CLOSE_PASS")
