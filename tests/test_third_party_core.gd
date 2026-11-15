extends SceneTree

const TestPaths = preload("res://tools/test_paths.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	TestPaths.required("game_project")
	var game: Node = load("res://Scenes/Boot.tscn").instantiate()
	root.add_child(game)
	for frame in range(180):
		await process_frame
	var output := TestPaths.output("third-party-core")
	DirAccess.make_dir_recursive_absolute(output)
	var code := "$third_party_core_host=true; $rgss_compat_output=" + JSON.stringify(output) + "\n" + TestPaths.ruby_setup() + FileAccess.get_file_as_string(TestPaths.fixture("third_party/Ace_Core_Engine.rb")) + "\n" + FileAccess.get_file_as_string(TestPaths.fixture("third_party_core_reference.rb"))
	var ok: bool = driver.RunRuby(code)
	var actual := FileAccess.get_file_as_string(output.path_join("third_party_core_reference.tsv")).replace("\r\n","\n").strip_edges()
	var expected := FileAccess.get_file_as_string(TestPaths.fixture("third_party_core_original.tsv")).replace("\r\n","\n").strip_edges()
	print(actual)
	ok = not expected.is_empty() and actual == expected and ok
	if "--ui" in OS.get_cmdline_user_args() or "--ruby-exit" in OS.get_cmdline_user_args() or "--immediate-free" in OS.get_cmdline_user_args():
		ok = driver.RunRuby("DataManager.setup_new_game; Window_MenuCommand.init_command_position; SceneManager.goto(Scene_Map)") and ok
		for frame in range(120):
			await process_frame
			await RenderingServer.frame_post_draw
		if "--ruby-exit" not in OS.get_cmdline_user_args():
			var map_capture := root.get_texture().get_image()
			map_capture.save_png(output.path_join("yea-map.png"))
		if "--map-close" in OS.get_cmdline_user_args():
			game.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
			print("THIRD_PARTY_CORE_PASS" if ok else "THIRD_PARTY_CORE_FAIL")
			return
		ok = driver.RunRuby("SceneManager.call(Scene_Menu)") and ok
		for frame in range(90):
			await process_frame
			await RenderingServer.frame_post_draw
		ok = driver.RunRuby("raise 'YEA menu scene' unless SceneManager.scene.is_a?(Scene_Menu)") and ok
		ok = driver.RunRuby("raise 'YEA status window missing' unless SceneManager.scene.instance_variable_get(:@status_window).is_a?(Window_MenuStatus); raise 'YEA gold window missing' unless SceneManager.scene.instance_variable_get(:@gold_window).is_a?(Window_Gold)") and ok
		ok = driver.RunRuby("File.open(" + JSON.stringify(output.path_join("menu-windows.tsv")) + ",'w') { |file| SceneManager.scene.instance_variables.each { |name| value=SceneManager.scene.instance_variable_get(name); file.puts [name,value.class,value.x,value.y,value.width,value.height,value.visible,value.openness,value.z].join(\"\\t\") if value.is_a?(Window) } }") and ok
		if "--ruby-exit" not in OS.get_cmdline_user_args():
			var menu_capture := root.get_texture().get_image()
			menu_capture.save_png(output.path_join("yea-menu.png"))
		if "--menu-close" in OS.get_cmdline_user_args():
			game.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
			print("THIRD_PARTY_CORE_PASS" if ok else "THIRD_PARTY_CORE_FAIL")
			return
		ok = driver.RunRuby("SceneManager.goto(Scene_Base)") and ok
		for frame in range(90):
			await process_frame
			await RenderingServer.frame_post_draw
	if "--ruby-exit" in OS.get_cmdline_user_args():
		ok = driver.RunRuby("Unity.exit_game") and ok
		print("THIRD_PARTY_CORE_PASS" if ok else "THIRD_PARTY_CORE_FAIL")
		return
	if "--close" in OS.get_cmdline_user_args():
		game.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		print("THIRD_PARTY_CORE_PASS" if ok else "THIRD_PARTY_CORE_FAIL")
		return
	if "--immediate-free" in OS.get_cmdline_user_args():
		game.free()
		print("SHUTDOWN_LIVE_BITMAPS:%d" % driver.GetLiveBitmapCount())
		ok = driver.GetLiveBitmapCount() == 0 and ok
		print("THIRD_PARTY_CORE_PASS" if ok else "THIRD_PARTY_CORE_FAIL")
		quit(0 if ok else 1)
		return
	game.queue_free()
	var drain_frames := 1 if "--render-drain" in OS.get_cmdline_user_args() else 6
	for frame in range(drain_frames):
		await process_frame
	if "--render-drain" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		await process_frame
		await RenderingServer.frame_post_draw
	print("SHUTDOWN_LIVE_BITMAPS:%d" % driver.GetLiveBitmapCount())
	if driver.GetLiveBitmapCount() != 0:
		push_error("Closed VM retained live bitmap resources")
		ok = false
	print("THIRD_PARTY_CORE_PASS" if ok else "THIRD_PARTY_CORE_FAIL")
	quit(0 if ok else 1)
