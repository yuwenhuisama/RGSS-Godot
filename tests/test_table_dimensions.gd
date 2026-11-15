extends SceneTree

const TestPaths = preload("res://tools/test_paths.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	driver.Initialize(host)
	var output := TestPaths.output("table-dimensions")
	DirAccess.make_dir_recursive_absolute(output)
	var code := "require 'table'; $table_dimensions_host=true; $rgss_compat_output=" + JSON.stringify(output) + "\n" + TestPaths.ruby_setup() + FileAccess.get_file_as_string(TestPaths.fixture("table_dimensions_reference.rb"))
	var ok: bool = driver.RunRuby(code)
	var actual := FileAccess.get_file_as_string(output.path_join("table_dimensions_reference.tsv")).replace("\r\n", "\n").strip_edges()
	ok = actual.sha256_text() == "6fe80f02baba72c7fd437dfcc4a0cb63ca73155b0f0229478773794e44ab0e8b" and ok
	driver.Shutdown()
	print("TABLE_DIMENSIONS_PASS" if ok else "TABLE_DIMENSIONS_FAIL")
	quit(0 if ok else 1)
