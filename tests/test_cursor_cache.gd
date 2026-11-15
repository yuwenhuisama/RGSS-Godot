extends SceneTree

const TestPaths = preload("res://tools/test_paths.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	driver.Initialize(host)
	var code := "require 'color'; require 'tone'; require 'rect'; require 'font'; require 'bitmap';\n"
	var output := TestPaths.output().path_join("cursor_cache_reference.tsv")
	code += "$rgss_compat_output=" + JSON.stringify(TestPaths.output()) + ";"
	code += TestPaths.ruby_setup() + FileAccess.get_file_as_string(TestPaths.fixture("cursor_cache_reference.rb")).trim_suffix("exit\n")
	var ok: bool = driver.RunRuby(code)
	if ok:
		var actual := FileAccess.get_file_as_string(output).replace("\r\n", "\n").strip_edges()
		var expected := FileAccess.get_file_as_string(TestPaths.fixture("cursor_cache_original.tsv")).replace("\r\n", "\n").strip_edges()
		ok = actual == expected and not expected.is_empty()
	driver.Shutdown()
	print("CURSOR_CACHE_PASS" if ok else "CURSOR_CACHE_FAIL")
	quit(0 if ok else 1)
