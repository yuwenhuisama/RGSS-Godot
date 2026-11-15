extends SceneTree

# Requires a real GPU renderer. Saves the same fixture's RGBA as original RMVA.
var _driver

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	_driver.Initialize(host)
	var ok: bool = _driver.RunRuby("require 'color'; require 'tone'; require 'rect'; require 'font'; require 'bitmap'; require 'graphics'; require 'viewport'; require 'sprite'; require 'window'; require 'plane'")
	var output := ProjectSettings.globalize_path("res://.omo/evidence/rmva-compatibility/godot")
	DirAccess.make_dir_recursive_absolute(output)
	var fixture := "render_reference.rb"
	if "--text" in OS.get_cmdline_user_args():
		fixture = "text_render_reference.rb"
	if "--bitmaps" in OS.get_cmdline_user_args():
		fixture = "bitmap_render_reference.rb"
	if "--layout" in OS.get_cmdline_user_args():
		fixture = "text_layout_render_reference.rb"
	if "--sprites" in OS.get_cmdline_user_args():
		fixture = "sprite_transform_reference.rb"
	if "--sort" in OS.get_cmdline_user_args():
		fixture = "sprite_sort_reference.rb"
	if "--region" in OS.get_cmdline_user_args():
		fixture = "sprite_region_reference.rb"
	if "--sampling" in OS.get_cmdline_user_args():
		fixture = "sprite_sampling_reference.rb"
	if "--rotation-update" in OS.get_cmdline_user_args():
		fixture = "sprite_rotation_update_reference.rb"
	if "--effects" in OS.get_cmdline_user_args():
		fixture = "sprite_effect_reference.rb"
	if "--opacity" in OS.get_cmdline_user_args():
		fixture = "sprite_opacity_reference.rb"
	if "--layers" in OS.get_cmdline_user_args():
		fixture = "sprite_layer_reference.rb"
	if "--wave" in OS.get_cmdline_user_args():
		fixture = "sprite_wave_reference.rb"
	if "--rotated-effects" in OS.get_cmdline_user_args():
		fixture = "sprite_rotated_effect_reference.rb"
	if "--flash-duration" in OS.get_cmdline_user_args():
		fixture = "sprite_flash_duration_reference.rb"
	if "--wave-boundary" in OS.get_cmdline_user_args():
		fixture = "sprite_wave_boundary_reference.rb"
	if "--effect-render" in OS.get_cmdline_user_args():
		fixture = "sprite_effect_render_reference.rb"
	if "--rotwave-fresh" in OS.get_cmdline_user_args():
		fixture = "sprite_rotated_wave_fresh_reference.rb"
	if "--viewports" in OS.get_cmdline_user_args():
		fixture = "viewport_reference.rb"
	if "--viewport-sort" in OS.get_cmdline_user_args():
		fixture = "viewport_sort_reference.rb"
	if "--viewport-flash" in OS.get_cmdline_user_args():
		fixture = "viewport_flash_reference.rb"
	if "--viewport-render" in OS.get_cmdline_user_args():
		fixture = "viewport_render_reference.rb"
	if "--viewport-values" in OS.get_cmdline_user_args():
		fixture = "viewport_value_reference.rb"
	if "--viewport-layers" in OS.get_cmdline_user_args():
		fixture = "viewport_layer_reference.rb"
	if "--viewport-overlap" in OS.get_cmdline_user_args():
		fixture = "viewport_overlap_reference.rb"
	if "--planes" in OS.get_cmdline_user_args():
		fixture = "plane_reference.rb"
	if "--plane-sampling" in OS.get_cmdline_user_args():
		fixture = "plane_sampling_reference.rb"
	if "--plane-precision" in OS.get_cmdline_user_args():
		fixture = "plane_precision_reference.rb"
	if "--plane-render" in OS.get_cmdline_user_args():
		fixture = "plane_render_reference.rb"
	if "--windows" in OS.get_cmdline_user_args():
		fixture = "window_reference.rb"
	if "--window-border" in OS.get_cmdline_user_args():
		fixture = "window_border_reference.rb"
	if "--window-render" in OS.get_cmdline_user_args():
		fixture = "window_render_reference.rb"
	if "--window-animation" in OS.get_cmdline_user_args():
		fixture = "window_animation_reference.rb"
	if "--window-cursor" in OS.get_cmdline_user_args():
		fixture = "window_cursor_reference.rb"
	if "--window-arrows" in OS.get_cmdline_user_args():
		fixture = "window_arrows_reference.rb"
	if "--window-animation-render" in OS.get_cmdline_user_args():
		fixture = "window_animation_render_reference.rb"
	if "--graphics" in OS.get_cmdline_user_args():
		fixture = "graphics_reference.rb"
	if "--graphics-transition" in OS.get_cmdline_user_args():
		fixture = "graphics_transition_reference.rb"
	if "--graphics-frames" in OS.get_cmdline_user_args():
		fixture = "graphics_frame_reference.rb"
	if "--graphics-resize" in OS.get_cmdline_user_args():
		fixture = "graphics_resize_reference.rb"
	if "--tiles" in OS.get_cmdline_user_args():
		fixture = "tilemap_reference.rb"
		ok = _driver.RunRuby("require 'table'; require 'tilemap'") and ok
	var code := FileAccess.get_file_as_string("res://tests/fixtures/" + fixture).trim_suffix("exit\n")
	if "--tile-scroll" in OS.get_cmdline_user_args():
		fixture = "tilemap_scroll_reference.rb"
		ok = _driver.RunRuby("require 'table'; require 'tilemap'") and ok
		code = FileAccess.get_file_as_string("res://tests/fixtures/" + fixture).trim_suffix("exit\n")
	if "--record-transition" in OS.get_cmdline_user_args():
		Engine.max_fps = 60
	if "--tile-table-edge" in OS.get_cmdline_user_args():
		fixture = "tilemap_table_edge_reference.rb"
		ok = _driver.RunRuby("require 'table'; require 'tilemap'") and ok
		code = FileAccess.get_file_as_string("res://tests/fixtures/" + fixture).trim_suffix("exit\n")
	if "--tile-occlusion" in OS.get_cmdline_user_args():
		fixture = "tilemap_occlusion_reference.rb"
		ok = _driver.RunRuby("require 'table'; require 'tilemap'") and ok
		code = FileAccess.get_file_as_string("res://tests/fixtures/" + fixture).trim_suffix("exit\n")
	if "--record-transition" in OS.get_cmdline_user_args():
		Engine.max_fps = 60
		code = "$record_transition_video=true\n" + code
	if "--transition-render" in OS.get_cmdline_user_args():
		var raw := FileAccess.open(output.path_join("graphics_transition_frames.rgba"), FileAccess.WRITE)
		raw.close()
		code = "$capture_transition_pixels=true\n" + code
	if "--tile-animation" in OS.get_cmdline_user_args():
		code = "$tilemap_probe_animation=true\n" + code
	if "--tile-tables" in OS.get_cmdline_user_args():
		code = "$tilemap_probe_tables=true\n" + code
	if "--tile-render" in OS.get_cmdline_user_args():
		code = "$tilemap_probe_render=true\n" + code
	code = "$rgss_compat_output = " + JSON.stringify(output) + "\n$reference_fiber = Fiber.new do\n" + code + "\nend"
	ok = ok and _driver.RunRuby(code)
	var graphics_frames := 140 if fixture == "tilemap_scroll_reference.rb" else 120 if fixture in ["tilemap_reference.rb", "tilemap_table_edge_reference.rb", "tilemap_occlusion_reference.rb"] else 1930 if "--record-transition" in OS.get_cmdline_user_args() else 130 if "--transition-render" in OS.get_cmdline_user_args() else 40 if fixture in ["graphics_reference.rb", "graphics_transition_reference.rb", "graphics_frame_reference.rb", "graphics_resize_reference.rb"] else 0
	for i in range(graphics_frames if graphics_frames > 0 else 552 if fixture == "window_animation_reference.rb" else 170 if fixture == "window_cursor_reference.rb" else 140 if fixture == "plane_reference.rb" else 100 if fixture in ["sprite_effect_reference.rb", "sprite_opacity_reference.rb", "sprite_flash_duration_reference.rb"] else 86 if fixture == "window_animation_render_reference.rb" else 68 if fixture == "viewport_reference.rb" else 62 if fixture in ["plane_sampling_reference.rb", "window_reference.rb"] else 52 if fixture in ["viewport_sort_reference.rb", "viewport_flash_reference.rb"] else 44 if fixture in ["sprite_wave_reference.rb", "sprite_wave_boundary_reference.rb"] else 36 if fixture in ["sprite_region_reference.rb", "sprite_rotation_update_reference.rb", "sprite_layer_reference.rb", "viewport_layer_reference.rb", "sprite_rotated_effect_reference.rb"] else 30 if fixture == "window_border_reference.rb" else 20 if fixture in ["sprite_sort_reference.rb", "viewport_value_reference.rb", "viewport_overlap_reference.rb", "plane_precision_reference.rb", "window_arrows_reference.rb"] else 10):
		_driver.UpdateRenderManager()
		ok = ok and _driver.RunRuby("$reference_fiber.resume if $reference_fiber.alive?")
		await process_frame
		await RenderingServer.frame_post_draw
	ok = ok and _driver.RunRuby("raise 'render reference did not finish' if $reference_fiber.alive?")
	_driver.Shutdown()
	if ok and fixture == "tilemap_occlusion_reference.rb":
		var actual := FileAccess.get_file_as_string(output.path_join("tilemap_occlusion_reference.tsv"))
		ok = actual.replace("\r\n", "\n").strip_edges().sha256_text() == "ae8433d5b199832ceaf763b80b7fb53dfc9129d5516e2cf3a8d2a7caa3a112f0"
		if not ok:
			push_error("Tilemap ground and upper-star priority must match original RGSS300")
	if ok and fixture == "tilemap_scroll_reference.rb":
		var actual := FileAccess.get_file_as_string(output.path_join("tilemap_scroll_reference.tsv"))
		ok = "mutation_after\t20,180,80,255\t20,180,80,255\t20,180,80,255\t20,180,80,255" in actual
		if not ok:
			push_error("In-place map Table writes must update rendered tiles")
		if "flash_after\t200,160,60,255\t200,160,60,255\t200,160,60,255\t200,160,60,255" not in actual:
			ok = false
			push_error("Tile flash brightness must match original RGSS300")
		ok = actual.replace("\r\n", "\n").strip_edges().sha256_text() == "70fa16fad024a75bbf69994727389a6a1886c86759a51c54505a6671697e2fb2" and ok
	if ok and fixture == "tilemap_reference.rb" and "--tile-animation" in OS.get_cmdline_user_args():
		var actual := FileAccess.get_file_as_string(output.path_join("tilemap_reference.tsv")).split("\n")
		var first := actual[2].split("\t")[1]
		for row in actual:
			if row.begins_with("animation\t") and row.split("\t")[4] != first:
				ok = false
		if not ok:
			push_error("Static A1 slot 2 must not change during tilemap updates")
		var before := actual[44].split("\t")[2]
		var boundary := actual[45].split("\t")[2]
		if before == boundary:
			ok = false
			push_error("A1 animation must change on update 30 like original RGSS300")
		ok = "\n".join(actual).replace("\r\n", "\n").strip_edges().sha256_text() == "cd9527a383616bdf59013f00b4ede1d9261fce28416c033d1e6da57688b233f5" and ok
	if ok and fixture == "tilemap_reference.rb" and "--tile-animation" not in OS.get_cmdline_user_args() and "--tile-tables" not in OS.get_cmdline_user_args():
		var actual := FileAccess.get_file_as_string(output.path_join("tilemap_reference.tsv"))
		ok = actual.replace("\r\n", "\n").strip_edges().sha256_text() == "ef707ca84b82d76d7633ba72881e71f0b8f60b7514996429aba069042d39ceec"
		if not ok:
			push_error("Tilemap source quarters differ from the 7296 original RGSS300 rows")
	if ok and fixture == "graphics_resize_reference.rb":
		var actual := FileAccess.get_file_as_string(output.path_join("graphics_resize_reference.tsv"))
		var expected := FileAccess.get_file_as_string("res://tests/fixtures/rgss300-graphics-resize-reference.tsv")
		ok = actual.replace("\r\n", "\n") == expected
		if not ok:
			push_error("Graphics resize differs from original RGSS300")
	if ok and fixture == "graphics_frame_reference.rb":
		var actual := FileAccess.get_file_as_string(output.path_join("graphics_frame_reference.tsv"))
		var expected := FileAccess.get_file_as_string("res://tests/fixtures/rgss300-graphics-frame-reference.tsv")
		ok = actual.replace("\r\n", "\n") == expected
		if not ok:
			push_error("Graphics frame timing differs from original RGSS300")
	if ok and fixture == "graphics_transition_reference.rb":
		var actual := FileAccess.get_file_as_string(output.path_join("graphics_transition_reference.tsv"))
		ok = "mask_end\t20.0\t180.0\t240.0\t255.0" in actual
		if not ok:
			push_error("Graphics masked transition must reveal the current scene")
	if ok and fixture == "graphics_reference.rb":
		var actual := FileAccess.get_file_as_string(output.path_join("graphics_reference.tsv"))
		ok = "fadeout_end\t0\t0.0\t0.0\t0.0\t0.0" in actual and "fadein_end\t255\t20.0\t180.0\t240.0\t255.0" in actual
		if not ok:
			push_error("Graphics fade completion must include the rendered final frame")
	if ok and fixture == "window_animation_reference.rb":
		var actual := FileAccess.get_file_as_string(output.path_join("window_animation_reference.tsv")).replace("\r\n", "\n").strip_edges()
		ok = actual.sha256_text() == "707f0e1428232db43b9afa9bd3092ff514e2212f1ef5453333099b587e507fdc"
		if not ok:
			push_error("Window animation and opacity differ from original RGSS300 timeline")
	if ok and fixture == "window_arrows_reference.rb":
		var actual := FileAccess.get_file_as_string(output.path_join("window_arrows_reference.tsv")).replace("\r\n", "\n").strip_edges()
		ok = actual.sha256_text() == "5cd5fa3ffe9e3a6c3993a5beffdbaf44e5cc8c92b5983b3c6259605ff038e004"
		if not ok:
			push_error("Window arrows differ from original RGSS300 capture")
	if ok and fixture == "window_arrows_reference.rb":
		var actual := FileAccess.get_file_as_string(output.path_join("window_arrows_reference.tsv"))
		ok = "40\t40\ttrue\t0\t40.0,180.0,220.0,255.0" in actual
		if not ok:
			push_error("Window scroll arrows must remain independent of window opacity")
	if ok and fixture == "window_animation_reference.rb":
		var actual := FileAccess.get_file_as_string(output.path_join("window_animation_reference.tsv"))
		ok = "opacity\t0\t48.0,48.0,48.0,255.0\t134.0,44.0,74.0,255.0" in actual
		if not ok:
			push_error("Window contents_opacity must modulate the contents independently")
	if ok and fixture == "window_render_reference.rb":
		var hash := HashingContext.new()
		hash.start(HashingContext.HASH_SHA256)
		hash.update(FileAccess.get_file_as_bytes(output.path_join("window_render_reference.rgba")))
		ok = hash.finish().hex_encode() == "7fa827f911e7196271f8fc5f752c046cfaf933fce482451b18e732b46c49d370"
		if not ok:
			push_error("Window composition and clipping differ from original RGSS300 pixels")
	if ok and fixture == "window_border_reference.rb":
		var actual := FileAccess.get_file_as_string(output.path_join("window_border_reference.tsv")).replace("\r\n", "\n").strip_edges()
		ok = actual.sha256_text() == "58fe7ac95c1c495c6a47d6ff0d671dd084e0a435e593aa76c29d018bba66930f"
		if not ok:
			push_error("Window border dimensions and alpha differ from original RGSS300 capture")
	if ok and fixture == "window_border_reference.rb":
		var actual := FileAccess.get_file_as_string(output.path_join("window_border_reference.tsv"))
		ok = "16\t16\t160.0,80.0,40.0,255.0" in actual
		if not ok:
			push_error("Small Window corners must overlap in original drawing order")
	if ok and fixture == "window_reference.rb":
		var actual := FileAccess.get_file_as_string(output.path_join("window_reference.tsv"))
		ok = "full\t80.0,200.0,20.0,255.0\t80.0,200.0,20.0,255.0\t80.0,200.0,20.0,255.0\t240.0,180.0,20.0,255.0" in actual
		if not ok:
			push_error("Window contents must draw at the upper padding boundary")
	if ok and fixture in ["plane_precision_reference.rb", "plane_sampling_reference.rb"]:
		var name := fixture.trim_suffix(".rb") + ".tsv"
		var actual := FileAccess.get_file_as_string(output.path_join(name)).replace("\r\n", "\n").strip_edges()
		var expected := "32b3a608eb7f3589828e8db558212614c1ef3100d7068bda27fe8f6a9ea96d13" if fixture == "plane_precision_reference.rb" else "0b3bf5a66ad749c7cdc4db7f25975b52ed511390bf91ea5ac33db206900104b8"
		ok = actual.sha256_text() == expected
		if not ok:
			push_error("Plane source sampling differs from fixed original RGSS300 capture")
	if ok and fixture == "plane_reference.rb":
		var actual := FileAccess.get_file_as_string(output.path_join("plane_reference.tsv"))
		ok = "opacity\t104.0,64.0,43.0,255.0" in actual and "tone\t169.0,69.0,129.0,255.0" in actual and "color\t89.0,140.0,70.0,255.0" in actual and "viewport_scroll\t20.0,180.0,240.0,255.0\t160.0,80.0,40.0,255.0" in actual
		if not ok:
			push_error("Plane must apply opacity and original integer tone/color blending")
	if ok and fixture == "viewport_overlap_reference.rb":
		var actual := FileAccess.get_file_as_string(output.path_join("viewport_overlap_reference.tsv"))
		ok = "false\t61.0,132.0,71.0,255.0\t84.0,20.0,79.0,255.0" in actual and "true\t61.0,132.0,71.0,255.0\t65.0,120.0,76.0,255.0" in actual
		if not ok:
			push_error("Overlapping Viewports must filter the current screen in dynamic z order")
	if ok and fixture == "viewport_layer_reference.rb":
		var rows := FileAccess.get_file_as_string(output.path_join("viewport_layer_reference.tsv")).replace("\r\n", "\n").strip_edges().split("\n")
		ok = rows == PackedStringArray(["0\t61.0\t122.0\t142.0\t255.0", "1\t114.0\t154.0\t163.0\t255.0", "2\t94.0\t0.0\t0.0\t255.0"])
		if not ok:
			push_error("Viewport sprite layers must blend against the preceding screen")
	if ok and fixture == "viewport_value_reference.rb":
		var actual := FileAccess.get_file_as_string(output.path_join("viewport_value_reference.tsv"))
		ok = "0\t0\t0\t0" in actual and "-1\t12\t-1\t12" in actual
		if not ok:
			push_error("Viewport construction must preserve nonpositive rectangle dimensions")
	if ok and fixture == "viewport_render_reference.rb":
		var pixels := FileAccess.get_file_as_bytes(output.path_join("viewport_render_reference.rgba"))
		var index := (248 * 544 + 416) * 4
		ok = pixels[index] == 140 and pixels[index+1] == 47 and pixels[index+2] == 64
		if not ok:
			push_error("Viewport partial-alpha content is multiplied twice")
	if ok and fixture == "viewport_sort_reference.rb":
		var actual := FileAccess.get_file_as_string(output.path_join("viewport_sort_reference.tsv"))
		ok = "0\t-1\t160.0\t80.0\t40.0\t255.0" in actual and "200\t100\t160.0\t80.0\t40.0\t255.0" in actual
		if not ok:
			push_error("Nil-viewport objects must interleave with Viewport z")
	if ok and fixture == "viewport_reference.rb":
		var actual := FileAccess.get_file_as_string(output.path_join("viewport_reference.tsv"))
		ok = "color\t33.0,124.0,74.0,255.0\t89.0,140.0,70.0,255.0" in actual and "hide\t48.0,48.0,48.0,255.0\t48.0,48.0,48.0,255.0" in actual
		if not ok:
			push_error("Viewport effects are missing from actual composition")
	if ok and fixture == "sprite_effect_render_reference.rb":
		var hash := HashingContext.new()
		hash.start(HashingContext.HASH_SHA256)
		hash.update(FileAccess.get_file_as_bytes(output.path_join("sprite_effect_render_reference.rgba")))
		ok = hash.finish().hex_encode() == "25e75a80430ed409ea34ff4cd4b6f440446cfc80ab4d5900ac04b8c41b61b3b1"
		if not ok:
			push_error("Sprite effect panel differs from fixed original RGSS300 pixels")
	if ok and fixture == "sprite_wave_boundary_reference.rb":
		var actual := FileAccess.get_file_as_string(output.path_join("sprite_wave_boundary_reference.tsv"))
		ok = "32\t30\t2\t41.25\t85,86,87" in actual
		if not ok:
			push_error("Sprite wave amplitude must remain in screen pixels when zoomed")
	if ok and fixture == "sprite_flash_duration_reference.rb":
		var actual := FileAccess.get_file_as_string(output.path_join("sprite_flash_duration_reference.tsv"))
		ok = "0\tfalse\t0\t220.0\t34.0\t85.0\t255.0" in actual and "0\ttrue\t0\t48.0\t48.0\t48.0\t255.0" in actual
		if not ok:
			push_error("Zero-duration Sprite flash must remain active until update")
	if ok and fixture == "sprite_rotated_effect_reference.rb":
		var actual := FileAccess.get_file_as_string(output.path_join("sprite_rotated_effect_reference.tsv"))
		ok = "bush\t160.0,80.0,40.0,255.0\t160.0,80.0,40.0,255.0" in actual and "wave\t160.0,80.0,40.0,255.0\t48.0,48.0,48.0,255.0\t160.0,80.0,40.0,255.0" in actual
		if not ok:
			push_error("Sprite rotated bush/wave ordering differs from original")
	if ok and fixture == "sprite_wave_reference.rb":
		var actual := FileAccess.get_file_as_string(output.path_join("sprite_wave_reference.tsv"))
		ok = "amp_zero_update\t92.0\t" in actual and "phase90\t90.0\t88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119\t" in actual
		if not ok:
			push_error("Sprite wave phase/band extent differs from original")
	if ok and fixture == "sprite_effect_reference.rb":
		var actual := FileAccess.get_file_as_string(output.path_join("sprite_effect_reference.tsv"))
		if not ("add\t208.0,128.0,88.0,255.0" in actual and "subtract\t0.0,0.0,8.0,255.0" in actual):
			ok = false
			push_error("Sprite add/subtract blending differs from original")
		ok = ok and "hide_flash\t48.0,48.0,48.0,255.0\t48.0,48.0,48.0,255.0" in actual and "bush\t160.0,80.0,40.0,255.0\t104.0,64.0,43.0,255.0" in actual
		if not ok:
			push_error("Sprite nil flash/bush pixels differ from original")
	if ok and fixture == "sprite_rotation_update_reference.rb":
		var rows := FileAccess.get_file_as_string(output.path_join("sprite_rotation_update_reference.tsv")).replace("\r\n", "\n").strip_edges().split("\n")
		ok = rows == PackedStringArray(["0\t240.0\t40.0\t20.0\t255.0", "1\t20.0\t180.0\t240.0\t255.0", "2\t20.0\t180.0\t240.0\t255.0", "3\t20.0\t180.0\t240.0\t255.0"])
		if not ok:
			push_error("Sprite rotation bitmap/geometry updates differ from original")
	if ok and fixture == "sprite_sampling_reference.rb":
		var pixels := FileAccess.get_file_as_bytes(output.path_join("sprite_sampling_reference.rgba"))
		for sample in [[254,114,240,40,20], [394,116,20,180,240], [114,274,240,40,20], [296,274,20,180,240]]:
			var index: int = (sample[1] * 544 + sample[0]) * 4
			if pixels[index] != sample[2] or pixels[index+1] != sample[3] or pixels[index+2] != sample[4]:
				ok = false
				push_error("Sprite rotation sampling differs from original")
	if ok and fixture == "sprite_region_reference.rb":
		var actual := FileAccess.get_file_as_string(output.path_join("sprite_region_reference.tsv"))
		ok = "1\t0\t24\t48.0,48.0,48.0,255.0" in actual and "2\t24\t24\t48.0,48.0,48.0,255.0" in actual and "3\t24\t24\t20.0,180.0,240.0,255.0\t48.0,48.0,48.0,255.0" in actual
		if not ok:
			push_error("Sprite source rectangle empty/outside pixels differ from original")
	if ok and fixture == "sprite_sort_reference.rb":
		var actual := FileAccess.get_file_as_string(output.path_join("sprite_sort_reference.tsv")).replace("\r\n", "\n")
		ok = "184\t92\t240.0\t40.0\t20.0" in actual and "changed_y\t240.0\t40.0\t20.0" in actual
		if not ok:
			push_error("Sprite same-z y ordering differs from original")
	if ok and fixture == "sprite_transform_reference.rb":
		var pixels := FileAccess.get_file_as_bytes(output.path_join("sprite_transform_reference.rgba"))
		for sample in [[148,56,240,40,20], [179,56,240,40,20], [180,56,20,180,240], [210,102,20,180,240], [64,212,20,180,240], [126,258,240,40,20], [160,220,48,48,48]]:
			var index: int = (sample[1] * 544 + sample[0]) * 4
			if pixels[index] != sample[2] or pixels[index+1] != sample[3] or pixels[index+2] != sample[4]:
				ok = false
				push_error("Sprite transform differs from original at %d,%d" % [sample[0], sample[1]])
	print("RENDER_REFERENCE_PASS" if ok else "RENDER_REFERENCE_FAIL")
	quit(0 if ok else 1)

func _finalize() -> void:
	if _driver != null:
		_driver.Shutdown()
