extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	driver.Initialize(host)
	var initialized: bool = driver.RunRuby("require 'color'; require 'tone'; require 'rect'; require 'font'; require 'graphics'; require 'bitmap'; require 'table'; require 'viewport'; require 'sprite'; require 'plane'; require 'window'; require 'tilemap'")
	var fixture := "primitive_reference.rb"
	if "--width" in OS.get_cmdline_user_args():
		fixture = "text_width_reference.rb"
	if "--variants" in OS.get_cmdline_user_args():
		fixture = "font_variants_reference.rb"
	if "--styles" in OS.get_cmdline_user_args():
		fixture = "font_style_reference.rb"
	if "--values" in OS.get_cmdline_user_args():
		fixture = "value_semantics_reference.rb"
	if "--lifecycle" in OS.get_cmdline_user_args():
		fixture = "lifecycle_reference.rb"
	if "--input" in OS.get_cmdline_user_args():
		fixture = "input_reference.rb"
		driver.RunRuby("require 'kernel'; require 'input'")
	if "--bitmaps" in OS.get_cmdline_user_args():
		fixture = "bitmap_operations_reference.rb"
	if "--layout" in OS.get_cmdline_user_args():
		fixture = "text_layout_reference.rb"
	var code := FileAccess.get_file_as_string("res://tests/fixtures/" + fixture)
	var output := ProjectSettings.globalize_path("res://.omo/evidence/rmva-compatibility/godot")
	DirAccess.make_dir_recursive_absolute(output)
	# Host controls process termination so shutdown always runs.
	code = code.trim_suffix("exit\n")
	code = "$rgss_compat_output = " + JSON.stringify(output) + "\n" + code
	var ok: bool = initialized and driver.RunRuby(code)
	if ok and fixture == "text_layout_reference.rb":
		for name in ["left", "center", "right", "narrow", "clipped", "short_height", "mixed", "linebreak", "zero", "spaces", "narrow_left", "short_height_tall"]:
			var expected := FileAccess.get_file_as_bytes("res://tests/fixtures/rgss300-text-layout/text_layout_" + name + ".rgba")
			var actual := FileAccess.get_file_as_bytes(output.path_join("text_layout_" + name + ".rgba"))
			if expected.size() != actual.size():
				ok = false
				push_error("Original text layout dimensions differ: " + name)
				continue
			for pixel in range(3, expected.size(), 4):
				if expected[pixel] != actual[pixel]:
					ok = false
					push_error("Original text layout alpha differs: " + name)
					break
	if ok and fixture == "bitmap_operations_reference.rb":
		var expected := FileAccess.get_file_as_string("res://tests/fixtures/rgss300-radial-reference.tsv").strip_edges().replace("\r\n", "\n")
		var actual := FileAccess.get_file_as_string(output.path_join("bitmap_operations_reference.tsv")).replace("\r\n", "\n")
		for row in expected.split("\n"):
			if not row in actual.split("\n"):
				ok = false
				push_error("Original radial blur pixels differ: " + row.get_slice("\t", 0))
		var hue_expected := FileAccess.get_file_as_string("res://tests/fixtures/rgss300-hue-reference.tsv").strip_edges().replace("\r\n", "\n")
		for row in hue_expected.split("\n"):
			if not row in actual.split("\n"):
				ok = false
				push_error("Original hue pixels differ: " + row.get_slice("\t", 0))
		var blur_expected := FileAccess.get_file_as_string("res://tests/fixtures/rgss300-blur-reference.tsv").strip_edges()
		if not blur_expected in actual.split("\n"):
			ok = false
			push_error("Original colored transparent blur kernel differs")
	if ok and fixture == "font_variants_reference.rb" and OS.get_name() == "Windows":
		var expected := FileAccess.get_file_as_string("res://tests/fixtures/rgss300-font-variants.tsv").replace("\r\n", "\n")
		var actual := FileAccess.get_file_as_string(output.path_join("font_variants_reference.tsv")).replace("\r\n", "\n")
		ok = actual == expected
		if not ok:
			push_error("Font variants differ from the independently captured RGSS300 reference")
	if ok and fixture == "font_style_reference.rb" and OS.get_name() == "Windows":
		for style in ["normal", "bold", "italic", "shadow", "outline"]:
			for index in range(7):
				var filename := "font_style_%s_%d.rgba" % [style, index]
				var expected := FileAccess.get_file_as_bytes("res://tests/fixtures/rgss300-font-styles/" + filename)
				var actual := FileAccess.get_file_as_bytes(output.path_join(filename))
				if actual.size() != expected.size():
					ok = false
					push_error("Font style capture dimensions differ: " + filename)
					continue
				for pixel in range(0, actual.size(), 4):
					if actual[pixel + 3] != expected[pixel + 3]:
						ok = false
						push_error("Original font style alpha mismatch: " + filename)
						break
	driver.Shutdown()
	print("GODOT_PRIMITIVE_REFERENCE_PASS" if ok else "GODOT_PRIMITIVE_REFERENCE_FAIL")
	quit(0 if ok else 1)
