extends SceneTree

var driver

func _initialize() -> void:
	call_deferred("_run")

func frames() -> void:
	for frame in range(4):
		driver.UpdateRenderManager()
		await process_frame
		await RenderingServer.frame_post_draw

func _run() -> void:
	driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	driver.Initialize(host)
	var initialized: bool = driver.RunRuby("require 'color'; require 'tone'; require 'rect'; require 'font'; require 'rgss_reset'")
	var original_mode := root.mode
	root.title = "RGSS Resize Surface QA"
	print("RESIZE_WINDOW_INITIAL:visible=%s:mode=%s:position=%s" % [root.visible,root.mode,root.position])
	root.show()
	root.always_on_top = true
	root.exclude_from_capture = false
	root.current_screen = DisplayServer.get_primary_screen()
	root.position = DisplayServer.screen_get_position(root.current_screen) + Vector2i(100,100)
	var output := ProjectSettings.globalize_path("res://.omo/evidence/rmva-compatibility/godot/resize")
	DirAccess.make_dir_recursive_absolute(output)
	var ok: bool = driver.RunRuby("require 'graphics'; require 'bitmap'; require 'sprite'; require 'viewport'; require 'color'; Graphics.resize_screen(640,480); $resize_bitmap=Bitmap.new(640,480); $resize_bitmap.fill_rect($resize_bitmap.rect,Color.new(20,80,120)); $resize_bitmap.fill_rect(0,0,640,4,Color.new(255,0,0)); $resize_bitmap.fill_rect(636,0,4,480,Color.new(0,255,0)); $resize_bitmap.fill_rect(0,476,640,4,Color.new(0,0,255)); $resize_bitmap.fill_rect(0,0,4,480,Color.new(255,255,0)); $resize_sprite=Sprite.new; $resize_sprite.bitmap=$resize_bitmap; $resize_viewport=Viewport.new; raise 'new viewport dimensions' unless $resize_viewport.rect.width==640 && $resize_viewport.rect.height==480")
	await frames()
	ok = driver.RunRuby("8.times { |y| 8.times { |x| $resize_bitmap.set_pixel(300+x,220+y,(x+y)%2==0 ? Color.new(255,255,255) : Color.new(0,0,0)) } }") and ok
	var states := ["native", "double", "restored"]
	if "--fullscreen" in OS.get_cmdline_user_args():
		states.insert(2, "fullscreen")
	for state in states:
		if state == "double":
			root.size = Vector2i(1280,960)
		elif state == "fullscreen":
			root.mode = Window.MODE_FULLSCREEN
		elif state == "restored":
			root.mode = Window.MODE_WINDOWED
			root.size = Vector2i(640,480)
		await frames()
		var image := root.get_texture().get_image()
		ok = image.get_size() == Vector2i(640,480) and ok
		ok = root.content_scale_size == Vector2i(640,480) and ok
		var logical: bool = driver.RunRuby("raise 'physical resize changed logical size' unless Graphics.width==640 && Graphics.height==480; b=Graphics.snap_to_bitmap; raise 'snapshot size' unless b.width==640 && b.height==480; b.dispose")
		ok = logical and ok
		ok = image.get_pixel(638,240).g > 0.9 and image.get_pixel(320,478).b > 0.9 and ok
		print("RESIZE_SURFACE_BORDER:%s:%s:%s:logical=%s" % [state,image.get_pixel(638,240),image.get_pixel(320,478),logical])
		image.save_png(output.path_join(state + ".png"))
		if "--physical-capture" in OS.get_cmdline_user_args():
			root.show()
			root.grab_focus()
			root.move_to_foreground()
			await frames()
			var screen := DisplayServer.screen_get_image(root.current_screen)
			print("RESIZE_SCREEN_GEOMETRY:window=%s:screen=%s:origin=%s:size=%s" % [root.position,root.current_screen,DisplayServer.screen_get_position(root.current_screen),DisplayServer.screen_get_size(root.current_screen)])
			var captured := screen != null and not screen.is_empty()
			if captured:
				var scale := mini(root.size.x / 640, root.size.y / 480)
				var origin := root.position - DisplayServer.screen_get_position(root.current_screen) + (root.size - Vector2i(640,480) * scale) / 2
				for y in range(8):
					for x in range(8):
						var expected := Color.WHITE if (x+y)%2 == 0 else Color.BLACK
						for sy in range(scale):
							for sx in range(scale):
								var actual := screen.get_pixelv(origin + Vector2i(300+x,220+y)*scale + Vector2i(sx,sy))
								ok = actual == expected and ok
				print("RESIZE_PHYSICAL_PIXELS:%s:scale=%d:origin=%s" % [state,scale,origin])
				captured = screen.save_png(output.path_join(state + "-screen.png")) == OK
			print("RESIZE_PHYSICAL_CAPTURE:%s:%s" % [state,captured])
			ok = captured and ok
		print("RESIZE_SURFACE_STATE:%s:%s:%s:%s" % [state,root.size,image.get_size(),root.get_stretch_transform().get_scale()])
	ok = initialized and ok
	root.mode = original_mode
	var disposed: bool = driver.RunRuby("$resize_viewport.dispose; $resize_sprite.dispose; $resize_bitmap.dispose; Graphics.resize_screen(544,416)")
	ok = disposed and ok
	driver.Shutdown()
	print("RESIZE_SURFACE_PASS" if ok else "RESIZE_SURFACE_FAIL")
	quit(0 if ok else 1)
