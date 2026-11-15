extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	root.add_child(load("res://Scenes/Boot.tscn").instantiate())
	for frame in range(180):
		await process_frame
		await RenderingServer.frame_post_draw
	var scene_ready: bool = driver.RunRuby("SceneManager.goto(Scene_Base)")
	for frame in range(90):
		await process_frame
		await RenderingServer.frame_post_draw
	var output := ProjectSettings.globalize_path("res://.omo/evidence/rmva-compatibility/godot/battle-animation-pixels")
	DirAccess.make_dir_recursive_absolute(output)
	var code := "$battle_animation_pixels_host=true; $rgss_compat_output=" + JSON.stringify(output) + "; $animation_pixel_probe=Fiber.new do\n" + FileAccess.get_file_as_string("res://tests/fixtures/battle_animation_pixels_reference.rb") + "\nend"
	var ok: bool = driver.RunRuby(code) and scene_ready
	for frame in range(34):
		ok = driver.RunRuby("$animation_pixel_probe.resume if $animation_pixel_probe.alive?") and ok
		await process_frame
		await RenderingServer.frame_post_draw
		if "--record-playback" in OS.get_cmdline_user_args() and frame < 16:
			var capture := root.get_texture().get_image().get_region(Rect2i(176,128,160,160))
			capture.save_png(output.path_join("playback-%02d.png" % frame))
	ok = driver.RunRuby("raise 'animation pixel probe unfinished' if $animation_pixel_probe.alive?") and ok
	var bytes := FileAccess.get_file_as_bytes(output.path_join("battle_animation_pixels.rgba"))
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(bytes)
	ok = bytes.size() == 160*160*4*4 and hash.finish().hex_encode() == "af3f6284edd7f05f0cb6d282ca4739ae55a224d63ade4a87c5a018d4c2134f46" and ok
	for frame in range(4):
		if bytes.size() == 160*160*4*4:
			Image.create_from_data(160,160,false,Image.FORMAT_RGBA8,bytes.slice(frame*160*160*4,(frame+1)*160*160*4)).save_png(output.path_join("frame-%d.png" % frame))
	var log_bytes := FileAccess.get_file_as_bytes(output.path_join("battle_log_pixels.rgba"))
	hash.start(HashingContext.HASH_SHA256)
	hash.update(log_bytes)
	ok = log_bytes.size() == 544*96*4 and hash.finish().hex_encode() == "fa9568e62ea6f0cc92442baac1974b60deb776c347beeaff6d211275c20b4488" and ok
	if log_bytes.size() == 544*96*4:
		Image.create_from_data(544,96,false,Image.FORMAT_RGBA8,log_bytes).save_png(output.path_join("battle-log.png"))
	print("BATTLE_ANIMATION_PIXELS_PASS" if ok else "BATTLE_ANIMATION_PIXELS_FAIL")
	quit(0 if ok else 1)
