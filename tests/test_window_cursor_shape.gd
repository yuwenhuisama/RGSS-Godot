extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	driver.Initialize(host)
	var output := ProjectSettings.globalize_path("res://.omo/evidence/rmva-compatibility/godot")
	var alpha_probe := "--alpha" in OS.get_cmdline_user_args()
	var white_probe := "--white" in OS.get_cmdline_user_args()
	var code := "require 'color'; require 'tone'; require 'rect'; require 'font'; require 'bitmap'; require 'sprite'; require 'viewport'; require 'window'; require 'graphics'; $rgss_compat_output=" + JSON.stringify(output) + "\n"
	if alpha_probe:
		code += "$cursor_alpha_probe=true\n"
	if white_probe:
		code += "$cursor_white_probe=true\n"
	code += "$reference_fiber=Fiber.new do\n" + FileAccess.get_file_as_string("res://tests/fixtures/window_cursor_shape_reference.rb").trim_suffix("exit\n") + "\nend"
	var ok: bool = driver.RunRuby(code)
	for frame in range(12):
		driver.UpdateRenderManager()
		ok = driver.RunRuby("$reference_fiber.resume if $reference_fiber.alive?") and ok
		await process_frame
		await RenderingServer.frame_post_draw
	ok = driver.RunRuby("raise 'cursor shape fixture did not finish' if $reference_fiber.alive?") and ok
	if ok:
		var actual := FileAccess.get_file_as_string(output.path_join("window_cursor_alpha_white_reference.tsv" if white_probe else "window_cursor_alpha_reference.tsv" if alpha_probe else "window_cursor_shape_reference.tsv")).replace("\r\n", "\n").strip_edges()
		if alpha_probe:
			var expected_path := "res://.omo/compatibility-run-tmp/window-cursor-alpha-white-original/window_cursor_alpha_white_reference.tsv" if white_probe else "res://.omo/compatibility-run-tmp/window-cursor-alpha-original/window_cursor_alpha_reference.tsv"
			var expected := FileAccess.get_file_as_string(expected_path).replace("\r\n", "\n").strip_edges()
			ok = not expected.is_empty() and actual == expected
		else:
			ok = actual.sha256_text() == "0d6fc5d1f01cb6047fa482e5572598498b412dce224ce8c91ddaf857518220d6"
	driver.Shutdown()
	print("WINDOW_CURSOR_SHAPE_PASS" if ok else "WINDOW_CURSOR_SHAPE_FAIL")
	quit(0 if ok else 1)
