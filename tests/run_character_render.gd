extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	root.add_child(load("res://Scenes/Boot.tscn").instantiate())
	for frame in range(180):
		await process_frame
		await RenderingServer.frame_post_draw
	var output := ProjectSettings.globalize_path("res://.omo/evidence/rmva-compatibility/godot")
	var code := FileAccess.get_file_as_string("res://tests/fixtures/character_render_reference.rb")
	code = "$rgss_compat_output=" + JSON.stringify(output) + "\n$character_render_fiber=Fiber.new do\n" + code + "\nend"
	var ok: bool = driver.RunRuby(code)
	for frame in range(30):
		driver.UpdateRenderManager()
		ok = driver.RunRuby("$character_render_fiber.resume if $character_render_fiber.alive?") and ok
		await process_frame
		await RenderingServer.frame_post_draw
	ok = driver.RunRuby("raise 'character render unfinished' if $character_render_fiber.alive?") and ok
	var hashes := {
		0: "856c47b11333bfe354fce47caa781bfd8ade70cc6dcad72492b5e1b3c12d251f",
		4: "daa49eed3b7a0a4609469c761b4c0d6347971de2b2d05f8b8b7d5062db77f1dd",
		8: "212af5f9289720cd11c60ed738c2b16a85aa9c64ca84b0b5cc234ec6d7c43fdd",
		12: "c342c7412063acb2391aa44af8b74090fe67926ad901a15ea0ea9718d770ae0e",
		16: "40093ae796176fefc134ea02ac8fbe2614940f8f01f210df6a436f34aab49df8",
		24: "7b61db155cffee2c2d398e526557e57fbafef6cb8b452c99f64d1534362efa5e",
		32: "7b61db155cffee2c2d398e526557e57fbafef6cb8b452c99f64d1534362efa5e",
	}
	for frame in hashes:
		var bytes := FileAccess.get_file_as_bytes(output.path_join("character_frame_%d.rgba" % frame))
		var hashing := HashingContext.new()
		hashing.start(HashingContext.HASH_SHA256)
		hashing.update(bytes)
		if hashing.finish().hex_encode() != hashes[frame]:
			push_error("Character frame %d differs from original RGSS300" % frame)
			ok = false
	print("CHARACTER_RENDER_PASS" if ok else "CHARACTER_RENDER_FAIL")
	quit(0 if ok else 1)
