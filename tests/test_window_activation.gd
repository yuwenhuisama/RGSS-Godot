extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	driver.Initialize(host)
	var output := ProjectSettings.globalize_path("res://.omo/evidence/rmva-compatibility/godot")
	var code := "require 'color'; require 'tone'; require 'rect'; require 'font'; require 'bitmap'; require 'sprite'; require 'viewport'; require 'window'; require 'graphics'; $rgss_compat_output=" + JSON.stringify(output) + "\n"
	code += "$reference_fiber=Fiber.new do\n" + FileAccess.get_file_as_string("res://tests/fixtures/window_activation_reference.rb").trim_suffix("exit\n") + "\nend"
	var ok: bool = driver.RunRuby(code)
	for frame in range(150):
		driver.UpdateRenderManager()
		ok = driver.RunRuby("$reference_fiber.resume if $reference_fiber.alive?") and ok
		await process_frame
		await RenderingServer.frame_post_draw
	ok = driver.RunRuby("raise 'activation fixture did not finish' if $reference_fiber.alive?") and ok
	if ok:
		var actual := FileAccess.get_file_as_string(output.path_join("window_activation_reference.tsv")).replace("\r\n", "\n").strip_edges()
		ok = actual.sha256_text() == "23527906891aa740bf442c2e88f69f4cc6ad4ccbe9eb38615ffbbfa7a55e31b4"
	# Original RGSS300 subtracts lost contents opacity from cursor brightness.
	ok = driver.RunRuby("$opacity_background=Bitmap.new(544,416); $opacity_background.fill_rect($opacity_background.rect,Color.new(0,0,0)); $opacity_sprite=Sprite.new; $opacity_sprite.bitmap=$opacity_background; $opacity_sprite.z=-1000; $opacity_skin=Bitmap.new(128,128); $opacity_skin.fill_rect(64,64,32,32,Color.new(255,255,255)); $opacity_window=Window.new(0,0,120,72); $opacity_window.windowskin=$opacity_skin; $opacity_window.padding=12; $opacity_window.cursor_rect.set(0,0,96,24); $opacity_window.active=false") and ok
	for sample in [[255,127],[254,126],[192,64],[128,0],[64,0],[1,0],[0,0],[255,127]]:
		ok = driver.RunRuby("$opacity_window.contents_opacity=%d; $opacity_window.update" % sample[0]) and ok
		for frame in range(2):
			driver.UpdateRenderManager()
			await process_frame
			await RenderingServer.frame_post_draw
		var value := int(round(root.get_texture().get_image().get_pixel(20,20).r * 255.0))
		if value != sample[1]:
			push_error("CURSOR_CONTENTS_OPACITY_FAIL:%d expected %d got %d" % [sample[0],sample[1],value])
			ok = false
	ok = driver.RunRuby("$opacity_window.dispose; $opacity_skin.dispose; $opacity_sprite.dispose; $opacity_background.dispose") and ok
	driver.Shutdown()
	print("WINDOW_ACTIVATION_PASS" if ok else "WINDOW_ACTIVATION_FAIL")
	quit(0 if ok else 1)
