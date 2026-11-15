extends SceneTree

const TestPaths = preload("res://tools/test_paths.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	TestPaths.required("game_project")
	root.add_child(load("res://Scenes/Boot.tscn").instantiate())
	for frame in range(180):
		await process_frame
		await RenderingServer.frame_post_draw
	var output := TestPaths.output()
	var path := output.path_join("event_message_reference.tsv")
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var code := "$rgss_compat_output=" + JSON.stringify(output) + "\n" + TestPaths.ruby_setup() + FileAccess.get_file_as_string(TestPaths.fixture("event_message_reference.rb"))
	var ok: bool = driver.RunRuby(code)
	if ok:
		var actual := FileAccess.get_file_as_string(path).replace("\r\n", "\n").strip_edges()
		ok = actual.sha256_text() == "ebc7e23b73e34734aa0c70225a3ef1c860265fa1dd22be02ac8a9218d35cdd04"
		if not ok:
			push_error("Event message differs from 71 original RGSS300 protocol rows")
	print("EVENT_MESSAGE_PASS" if ok else "EVENT_MESSAGE_FAIL")
	quit(0 if ok else 1)
