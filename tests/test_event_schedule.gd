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
	var path := output.path_join("event_schedule_reference.tsv")
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var code := "$rgss_compat_output=" + JSON.stringify(output) + "\n" + TestPaths.ruby_setup() + FileAccess.get_file_as_string(TestPaths.fixture("event_schedule_reference.rb"))
	var ok: bool = driver.RunRuby(code)
	if ok:
		var actual := FileAccess.get_file_as_string(path).replace("\r\n", "\n").strip_edges()
		ok = actual.sha256_text() == "46c22fd6f1e12d0bdd7f79ae50744e98efcb8e673df1f3334c621b64d744fd8a"
		if not ok:
			push_error("Map event scheduling differs from 24 original RGSS300 frames")
	print("EVENT_SCHEDULE_PASS" if ok else "EVENT_SCHEDULE_FAIL")
	quit(0 if ok else 1)
