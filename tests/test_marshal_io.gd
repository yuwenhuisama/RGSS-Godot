extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	driver.Initialize(host)
	var output := ProjectSettings.globalize_path("res://.omo/evidence/rmva-compatibility/godot")
	DirAccess.make_dir_recursive_absolute(output)
	var path := output.path_join("marshal_io_reference.tsv")
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var code := "$rgss_compat_output=" + JSON.stringify(output) + "\n" + FileAccess.get_file_as_string("res://tests/fixtures/marshal_io_reference.rb")
	var ok: bool = driver.RunRuby(code)
	if ok:
		var actual := FileAccess.get_file_as_string(path).replace("\r\n", "\n").strip_edges()
		ok = actual.sha256_text() == "188be7f92851f02f5be75af296e1d39c321eab353c8662d3a9f88bef26ebcfa0"
		if not ok:
			push_error("Marshal IO/depth differs from seven original RGSS300 contracts")
	driver.Shutdown()
	print("MARSHAL_IO_PASS" if ok else "MARSHAL_IO_FAIL")
	quit(0 if ok else 1)
