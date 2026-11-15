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
	var path := output.path_join("event_page_reference.tsv")
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var code := "$rgss_compat_output=" + JSON.stringify(output) + "\n" + FileAccess.get_file_as_string("res://tests/fixtures/event_page_reference.rb")
	var ok: bool = driver.RunRuby(code)
	if ok:
		var actual := FileAccess.get_file_as_string(path).replace("\r\n", "\n").strip_edges()
		ok = actual.sha256_text() == "8c93121eeba15180c992cc0c70597d5e9b0d07c0314bee3637e7a79f9a91d454"
		if not ok:
			push_error("Event page conditions/triggers differ from 80 original RGSS300 rows")
	print("EVENT_PAGE_PASS" if ok else "EVENT_PAGE_FAIL")
	quit(0 if ok else 1)
