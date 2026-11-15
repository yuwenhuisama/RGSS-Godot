extends SceneTree

func _initialize() -> void:
	for name in ["Arial", "VL Gothic", "Courier New", "nsimsun"]:
		var font := SystemFont.new()
		font.font_names = PackedStringArray([name])
		font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		for size in [20, 21, 22, 24]:
			for text in ["Hello", "iiii", "WWWW", "12345", "", "H", "e", "l", "o", "i", "W", "1", "AV"]:
				print("FONT_PROBE:", name, ":", size, ":", text, ":", font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size))
	quit()
