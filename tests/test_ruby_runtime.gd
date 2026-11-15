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
	var output := TestPaths.output("ruby-runtime")
	DirAccess.make_dir_recursive_absolute(output)
	var code := "$ruby_runtime_host=true; $rgss_compat_output=" + JSON.stringify(output) + "\n" + TestPaths.ruby_setup() + FileAccess.get_file_as_string(TestPaths.fixture("ruby_runtime_reference.rb"))
	var ok: bool = driver.RunRuby(code)
	var actual := FileAccess.get_file_as_string(output.path_join("ruby_runtime_reference.tsv")).replace("\r\n", "\n").strip_edges()
	var expected := FileAccess.get_file_as_string(TestPaths.fixture("ruby_runtime_original.tsv")).strip_edges()
	print(actual)
	ok = not expected.is_empty() and actual == expected and ok
	print("RUBY_RUNTIME_PASS" if ok else "RUBY_RUNTIME_FAIL")
	quit(0 if ok else 1)
