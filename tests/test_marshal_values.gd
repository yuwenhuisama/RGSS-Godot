extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	driver.Initialize(host)
	var output := ProjectSettings.globalize_path("res://.omo/evidence/rmva-compatibility/godot/marshal-values")
	DirAccess.make_dir_recursive_absolute(output)
	var peer_hex := FileAccess.get_file_as_string("res://tests/fixtures/marshal_values_original.hex").strip_edges()
	var code := "$marshal_values_host=true; $marshal_values_peer_bytes=[" + JSON.stringify(peer_hex) + "].pack('H*'); $rgss_compat_output=" + JSON.stringify(output) + "\n" + FileAccess.get_file_as_string("res://tests/fixtures/marshal_values_reference.rb")
	var ok: bool = driver.RunRuby(code)
	var text := FileAccess.get_file_as_string(output.path_join("marshal_values_reference.tsv")).replace("\r\n", "\n").strip_edges()
	print(text)
	var original := FileAccess.get_file_as_string("res://tests/fixtures/marshal_values_original.tsv").strip_edges()
	ok = not original.is_empty() and text == original and ok
	driver.Shutdown()
	print("MARSHAL_VALUES_PASS" if ok else "MARSHAL_VALUES_FAIL")
	quit(0 if ok else 1)
