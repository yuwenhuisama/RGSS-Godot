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
	var base := ProjectSettings.globalize_path("user://event_audio_fixture")
	for bus in ["BGM", "BGS", "ME", "SE"]:
		var folder := base.path_join("RMProject/Audio/" + bus)
		DirAccess.make_dir_recursive_absolute(folder)
		DirAccess.copy_absolute(TestPaths.fixture("audio/tone.ogg"), folder.path_join("tone.ogg"))
	var path := output.path_join("event_audio_reference.tsv")
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var code := "$event_audio_base=" + JSON.stringify(base) + "\n$rgss_compat_output=" + JSON.stringify(output) + "\n" + TestPaths.ruby_setup() + FileAccess.get_file_as_string(TestPaths.fixture("event_audio_reference.rb"))
	var ok: bool = driver.RunRuby(code)
	if ok:
		var actual := FileAccess.get_file_as_string(path).replace("\r\n", "\n").strip_edges()
		ok = actual.sha256_text() == "74ff72c205bd0c33137b56e998ac41a97f17c3fbeb33cc5b16ca0295c348a6ba"
		if not ok:
			push_error("Event audio differs from 12 original RGSS300 protocol rows")
	print("EVENT_AUDIO_PASS" if ok else "EVENT_AUDIO_FAIL")
	quit(0 if ok else 1)
