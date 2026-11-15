extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	driver.Initialize(host)
	var output := ProjectSettings.globalize_path("res://.omo/evidence/rmva-compatibility/godot/zlib-stream")
	DirAccess.make_dir_recursive_absolute(output)
	var path := output.path_join("zlib_stream_reference.tsv")
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var ok: bool = driver.RunRuby("$zlib_stream_host=true; $rgss_compat_output=" + JSON.stringify(output) + "\n" + FileAccess.get_file_as_string("res://tests/fixtures/zlib_stream_reference.rb"))
	var actual := FileAccess.get_file_as_string(path).replace("\r\n", "\n").strip_edges()
	var expected := FileAccess.get_file_as_string("res://tests/fixtures/zlib_stream_original.tsv").replace("\r\n", "\n").strip_edges()
	print(actual)
	ok = ok and not expected.is_empty() and actual == expected
	driver.Shutdown()
	print("ZLIB_STREAM_PASS" if ok else "ZLIB_STREAM_FAIL")
	quit(0 if ok else 1)
