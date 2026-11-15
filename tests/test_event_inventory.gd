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
	var path := output.path_join("event_inventory_reference.tsv")
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var code := "$rgss_compat_output=" + JSON.stringify(output) + "\n" + TestPaths.ruby_setup() + FileAccess.get_file_as_string(TestPaths.fixture("event_inventory_reference.rb"))
	var ok: bool = driver.RunRuby(code)
	if ok:
		var actual := FileAccess.get_file_as_string(path).replace("\r\n", "\n").strip_edges()
		ok = actual.sha256_text() == "ce12de31638a37813881e3d8deee2a666919631b087d70ae5991e35cdf1d2ddc"
		if not ok:
			push_error("Event inventory differs from 43 original RGSS300 scenarios")
	print("EVENT_INVENTORY_PASS" if ok else "EVENT_INVENTORY_FAIL")
	quit(0 if ok else 1)
