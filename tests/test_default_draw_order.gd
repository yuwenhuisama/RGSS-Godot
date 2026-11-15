extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	driver.Initialize(host)
	var output := ProjectSettings.globalize_path("res://.omo/evidence/rmva-compatibility/godot/default-order")
	DirAccess.make_dir_recursive_absolute(output)
	var code := "require 'color'; require 'tone'; require 'rect'; require 'font'; require 'bitmap'; require 'sprite'; require 'viewport'; require 'graphics'; $default_draw_order_host=true; $rgss_compat_output=" + JSON.stringify(output) + "\n$draw_order_probe=Fiber.new do\n" + FileAccess.get_file_as_string("res://tests/fixtures/default_draw_order_reference.rb") + "\nend"
	var ok: bool = driver.RunRuby(code)
	for frame in range(5):
		driver.UpdateRenderManager()
		ok = driver.RunRuby("$draw_order_probe.resume if $draw_order_probe.alive?") and ok
		await process_frame
		await RenderingServer.frame_post_draw
	ok = driver.RunRuby("raise 'draw order unfinished' if $draw_order_probe.alive?") and ok
	var text := FileAccess.get_file_as_string(output.path_join("default_draw_order_reference.tsv")).replace("\r\n", "\n").strip_edges()
	ok = text == "default-z\t0\t0\t0\npixel\t0\t255\t0" and ok
	driver.Shutdown()
	print("DEFAULT_DRAW_ORDER_PASS" if ok else "DEFAULT_DRAW_ORDER_FAIL")
	quit(0 if ok else 1)
