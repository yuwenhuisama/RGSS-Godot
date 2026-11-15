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
	var path := output.path_join("event_screen_reference.tsv")
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var code := "$rgss_compat_output=" + JSON.stringify(output) + "\n" + FileAccess.get_file_as_string("res://tests/fixtures/event_screen_reference.rb")
	var ok: bool = driver.RunRuby(code)
	if ok:
		var actual := FileAccess.get_file_as_string(path).replace("\r\n", "\n").strip_edges()
		ok = actual.sha256_text() == "9b507a15cc34e3bc0040c6f12cc709cf00fea82d65fbadc605b7b7024bc425e4"
		if not ok:
			push_error("Event screen differs from 224 original RGSS300 frame rows")
	print("EVENT_SCREEN_PASS" if ok else "EVENT_SCREEN_FAIL")
	quit(0 if ok else 1)
