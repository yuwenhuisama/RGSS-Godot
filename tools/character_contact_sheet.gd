extends SceneTree

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 3:
		push_error("Usage: -- ORIGINAL_DIRECTORY GODOT_DIRECTORY OUTPUT.png")
		quit(1)
		return
	var canvas := Image.create(544 * 4, 416 * 4, false, Image.FORMAT_RGBA8)
	canvas.fill(Color.BLACK)
	var frames := [0, 4, 8, 12, 16, 24, 32]
	for index in range(frames.size()):
		for engine in range(2):
			var bytes := FileAccess.get_file_as_bytes(args[engine].path_join("character_frame_%d.rgba" % frames[index]))
			if bytes.size() != 544 * 416 * 4:
				push_error("Incomplete character frame")
				quit(1)
				return
			var image := Image.create_from_data(544, 416, false, Image.FORMAT_RGBA8, bytes)
			canvas.blit_rect(image, Rect2i(0, 0, 544, 416), Vector2i((index % 4) * 544, (index / 4 * 2 + engine) * 416))
	var ok := canvas.save_png(args[2]) == OK
	print("CHARACTER_CONTACT_SHEET_PASS" if ok else "CHARACTER_CONTACT_SHEET_FAIL")
	quit(0 if ok else 1)
