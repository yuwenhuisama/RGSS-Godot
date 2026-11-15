extends SceneTree

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2 or args.size() > 3:
		push_error("Usage: -- INPUT_DIRECTORY OUTPUT_PREFIX [PAGE_COUNT]")
		quit(1)
		return
	var page_count := args[2].to_int() if args.size() == 3 else 34
	var frames := FileAccess.open(args[0], FileAccess.READ) if args[0].ends_with(".rgba") else null
	if frames != null and frames.get_length() != page_count * 544 * 416 * 4:
		push_error("Frame count does not match raw capture size")
		quit(1)
		return
	for sheet in range(ceili(page_count / 17.0)):
		var canvas := Image.create(544 * 4, 416 * 5, false, Image.FORMAT_RGBA8)
		canvas.fill(Color.BLACK)
		for cell in range(17):
			var page := sheet * 17 + cell
			if page >= page_count:
				break
			var bytes := frames.get_buffer(544 * 416 * 4) if frames != null else FileAccess.get_file_as_bytes(args[0].path_join("tilemap_page_%d.rgba" % page))
			if bytes.size() != 544 * 416 * 4:
				push_error("Missing or incomplete tilemap page %d" % page)
				quit(1)
				return
			var image := Image.create_from_data(544, 416, false, Image.FORMAT_RGBA8, bytes)
			canvas.blit_rect(image, Rect2i(0,0,544,416), Vector2i((cell % 4)*544,(cell / 4)*416))
		if canvas.save_png(args[1] + "-%d.png" % sheet) != OK:
			quit(1)
			return
	print("TILEMAP_CONTACT_SHEET_PASS:%d" % page_count)
	quit(0)
