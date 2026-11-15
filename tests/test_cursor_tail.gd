extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	driver.Initialize(host)
	var output := ProjectSettings.globalize_path("res://.omo/evidence/rmva-compatibility/godot/cursor-tail")
	DirAccess.make_dir_recursive_absolute(output)
	var path := output.path_join("cursor_tail_reference.tsv")
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var code := "require 'color'; require 'tone'; require 'rect'; require 'font'; require 'bitmap'; require 'sprite'; require 'viewport'; require 'window'; require 'graphics'; $cursor_tail_host=true; $rgss_compat_output=" + JSON.stringify(output) + "\n$cursor_tail_fiber=Fiber.new do\n" + FileAccess.get_file_as_string("res://tests/fixtures/cursor_tail_reference.rb") + "\nend"
	var ok: bool = driver.RunRuby(code)
	for frame in range(148):
		driver.UpdateRenderManager()
		ok = driver.RunRuby("$cursor_tail_fiber.resume if $cursor_tail_fiber.alive?") and ok
		await process_frame
		await RenderingServer.frame_post_draw
	ok = driver.RunRuby("raise 'cursor tail fixture incomplete' if $cursor_tail_fiber.alive?") and ok
	var actual := FileAccess.get_file_as_string(path).replace("\r\n", "\n").strip_edges()
	var expected := FileAccess.get_file_as_string("res://tests/fixtures/cursor_tail_original.tsv").replace("\r\n", "\n").strip_edges()
	ok = ok and not expected.is_empty() and actual == expected
	driver.Shutdown()
	print("CURSOR_TAIL_PASS" if ok else "CURSOR_TAIL_FAIL")
	quit(0 if ok else 1)
