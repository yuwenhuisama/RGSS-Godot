extends SceneTree

const TestPaths = preload("res://tools/test_paths.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	driver.Initialize(host)
	var output := TestPaths.output("rpg-defaults")
	DirAccess.make_dir_recursive_absolute(output)
	var code := "require 'color'; require 'tone'; require 'table'; module RPG; end\n"
	var files := DirAccess.get_files_at("res://RGSS/rpg")
	files.sort()
	for file in files:
		if file.ends_with(".rb"):
			code += "require " + JSON.stringify("rpg/" + file.trim_suffix(".rb")) + "\n"
	code += "$rpg_defaults_host=true; $rgss_compat_output=" + JSON.stringify(output) + "\n" + TestPaths.ruby_setup() + FileAccess.get_file_as_string(TestPaths.fixture("rpg_defaults_reference.rb"))
	var ok: bool = driver.RunRuby(code)
	var actual := FileAccess.get_file_as_string(output.path_join("rpg_defaults_reference.tsv")).replace("\r\n", "\n").strip_edges()
	ok = actual.sha256_text() == "2fc84c88c692213cd627c5d7c292628f873f36275ad88d6888aa8a3fcb71b987" and ok
	driver.Shutdown()
	print("RPG_DEFAULTS_PASS" if ok else "RPG_DEFAULTS_FAIL")
	quit(0 if ok else 1)
