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
	var path := output.path_join("event_transfer_reference.tsv")
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var base := ProjectSettings.globalize_path("user://event_transfer_fixture")
	DirAccess.make_dir_recursive_absolute(base.path_join("RMProject/Data"))
	var code := "$event_transfer_base=" + JSON.stringify(base) + "\n$rgss_compat_output=" + JSON.stringify(output) + "\n" + FileAccess.get_file_as_string("res://tests/fixtures/event_transfer_reference.rb")
	var ok: bool = driver.RunRuby(code)
	if ok:
		var actual := FileAccess.get_file_as_string(path).replace("\r\n", "\n").strip_edges()
		ok = actual.sha256_text() == "f09f51f085d0149eee3a7d25d1c748acf1c39f06876847ed1f901296ceca400e"
		if not ok:
			push_error("Event transfer/scroll differs from 90 original RGSS300 frame rows")
	print("EVENT_TRANSFER_PASS" if ok else "EVENT_TRANSFER_FAIL")
	quit(0 if ok else 1)
