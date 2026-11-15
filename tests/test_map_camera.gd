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
	var code := "$rgss_compat_output=" + JSON.stringify(output) + "\n" + TestPaths.ruby_setup() + FileAccess.get_file_as_string(TestPaths.fixture("map_camera_reference.rb"))
	var ok: bool = driver.RunRuby(code)
	if ok:
		var actual := FileAccess.get_file_as_string(output.path_join("map_camera_reference.tsv"))
		ok = actual.replace("\r\n", "\n").strip_edges().sha256_text() == "342899eac911723a17f53e4c4aa1cc92948e1b38c81e371cee4eae2aea597f45"
		if not ok:
			push_error("Game_Map camera differs from the 64 original RGSS300 rows")
	print("MAP_CAMERA_PASS" if ok else "MAP_CAMERA_FAIL")
	quit(0 if ok else 1)
