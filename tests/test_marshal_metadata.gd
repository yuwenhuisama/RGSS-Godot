extends SceneTree

const TestPaths = preload("res://tools/test_paths.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	driver.Initialize(host)
	var output := TestPaths.output("marshal-metadata")
	DirAccess.make_dir_recursive_absolute(output)
	var code := "$marshal_metadata_host=true; $rgss_compat_output=" + JSON.stringify(output) + "\n" + TestPaths.ruby_setup() + FileAccess.get_file_as_string(TestPaths.fixture("marshal_metadata_reference.rb"))
	var ok: bool = driver.RunRuby(code)
	var text := FileAccess.get_file_as_string(output.path_join("marshal_metadata_reference.tsv")).replace("\r\n", "\n").strip_edges()
	print(text)
	var original := FileAccess.get_file_as_string(TestPaths.fixture("marshal_metadata_original.tsv")).replace("\r\n", "\n").strip_edges()
	ok = not original.is_empty() and text == original and ok
	var frozen := FileAccess.get_file_as_string(output.path_join("marshal_frozen_encoding.tsv")).replace("\r\n", "\n").strip_edges()
	var frozen_original := FileAccess.get_file_as_string(TestPaths.fixture("marshal_frozen_original.tsv")).replace("\r\n", "\n").strip_edges()
	print(frozen)
	ok = not frozen_original.is_empty() and frozen == frozen_original and ok
	driver.Shutdown()
	print("MARSHAL_METADATA_PASS" if ok else "MARSHAL_METADATA_FAIL")
	quit(0 if ok else 1)
