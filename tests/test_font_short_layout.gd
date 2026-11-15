extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	driver.Initialize(host)
	var output := ProjectSettings.globalize_path("res://.omo/evidence/rmva-compatibility/godot")
	var code := "require 'color'; require 'tone'; require 'rect'; require 'font'; require 'bitmap'; $rgss_compat_output=" + JSON.stringify(output) + "\n"
	code += FileAccess.get_file_as_string("res://tests/fixtures/font_short_layout_reference.rb").trim_suffix("exit\n")
	var ok: bool = driver.RunRuby(code)
	if ok:
		var actual := FileAccess.get_file_as_string(output.path_join("font_short_layout_reference.tsv")).replace("\r\n", "\n").strip_edges()
		ok = actual.sha256_text() == "db13e123dabad6326453693c77c21cbacb63a95706c09f3ab441f8ae8bb0deb0"
		if not ok:
			push_error("Font short-line placement differs from original RGSS300")
	driver.Shutdown()
	print("FONT_SHORT_LAYOUT_PASS" if ok else "FONT_SHORT_LAYOUT_FAIL")
	quit(0 if ok else 1)
