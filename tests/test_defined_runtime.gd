extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	driver.Initialize(host)
	var output := ProjectSettings.globalize_path("res://.omo/evidence/f05-godot-defined")
	DirAccess.make_dir_recursive_absolute(output)
	var path := output.path_join("defined_yield_super_reference.tsv")
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var ok: bool = driver.RunRuby("require 'ext/onig_regexp'; module Kernel; module_function :eval; end; $ruby_runtime_host=true; $rgss_compat_output=" + JSON.stringify(output))
	ok = driver.RunRuby("begin; 'abc' =~ 'b'; raise 'String match must reject a String pattern'; rescue TypeError; end") and ok
	ok = driver.RunRuby(FileAccess.get_file_as_string("res://tools/defined-compiler/defined_yield_super_reference.rb")) and ok
	var actual := FileAccess.get_file_as_string(path).replace("\r\n", "\n").strip_edges()
	var expected := FileAccess.get_file_as_string("res://tools/defined-compiler/defined_yield_super_original.tsv").replace("\r\n", "\n").strip_edges()
	if actual != expected:
		var actual_rows := actual.split("\n")
		var expected_rows := expected.split("\n")
		for index in range(mini(actual_rows.size(), expected_rows.size())):
			if actual_rows[index] != expected_rows[index]:
				push_error("Defined runtime row %d differs: original=%s actual=%s" % [index, expected_rows[index], actual_rows[index]])
		ok = false
	if expected.is_empty() or actual.split("\n").size() != 77:
		push_error("Defined runtime reference must contain77 measured rows")
		ok = false
	driver.Shutdown()
	print("DEFINED_RUNTIME_PASS:77" if ok else "DEFINED_RUNTIME_FAIL")
	quit(0 if ok else 1)
