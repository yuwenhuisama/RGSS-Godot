extends SceneTree

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 4:
		push_error("Usage: -- INPUT OUTPUT WIDTH HEIGHT")
		quit(1)
		return
	var width := args[2].to_int()
	var height := args[3].to_int()
	var data := FileAccess.get_file_as_bytes(args[0])
	if width <= 0 or height <= 0 or data.size() != width * height * 4:
		push_error("RGBA dimensions do not match the input bytes")
		quit(1)
		return
	var image := Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, data)
	var error := image.save_png(args[1])
	print("RGBA_PNG_PASS" if error == OK else "RGBA_PNG_FAIL")
	quit(0 if error == OK else 1)
