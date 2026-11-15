extends SceneTree

# Real-renderer map-screen contract: stock Spriteset_Map, Game_Screen,
# Sprite_Picture and Spriteset_Weather through the live Godot renderer.
# Requires a real GPU renderer; do not run with --headless.
#
# Deterministic rows and pixels are pinned to the original RGSS300 capture.
# Weather particle coordinates use Kernel#rand, whose sequence differs between
# the original and mruby, so those rows are checked as invariants instead.

const DETERMINISTIC_TSV_SHA := "7ba6afeafb5cba0ecfe228b7dd776ce89243eb42dfdacf89e8f52dd815933887"
const DETERMINISTIC_ROW_COUNT := 147
const DETERMINISTIC_FRAMES := {
	"map_screen_opacity_control_float.rgba": "6b51d36e778c7a02348255f1970bce181f686fec9241a3bb97c0465bd5213b98",
	"map_screen_opacity_control_int.rgba": "6b51d36e778c7a02348255f1970bce181f686fec9241a3bb97c0465bd5213b98",
	"map_screen_picture_erase.rgba": "7c7e3cf1d7c868bdfa621b5fd3e004b06be2a182b8abbf97841cd7bdc65d01a3",
	"map_screen_picture_move_0.rgba": "9cfe8a39ed7da3aabb04589e32c560d1c54b80dade3957133348cd56a19a88d3",
	"map_screen_picture_move_1.rgba": "b5a529a8191c30a1cf62aca2feaef21f1e7561b856f73db144146aa7cf665600",
	"map_screen_picture_move_2.rgba": "6c21c88fe6dee10e97f7efb0c7e575ebcb0dc6f3e9348c49efe5915c351e5726",
	"map_screen_picture_move_3.rgba": "1ce296b4320a650c7e2cb074000958bf33e626d2aac401c6efbfff04152b4bf9",
	"map_screen_picture_origin.rgba": "23afcd051c0e2e93c3f32e6bfada9c702163654c4d520730cf2779b6ae4083b2",
	"map_screen_picture_plain.rgba": "c49a677d1d43fbbba3ad77b96e9eeb8360c75acb41453391cf8ba43f7cc14693",
	"map_screen_picture_rotate.rgba": "d3aa4c91dcf834092e4f9f866d9f2dd5deea4f30bdae889a770f915ddccd3680",
	"map_screen_picture_tone_0.rgba": "16dcf671723fb9559f86a010e8d27decd1cb109a1ef342f19bb0757cc8dc602b",
	"map_screen_picture_tone_1.rgba": "90d41bad9573ddb805d9645e979d11a1860fd1c822846a6ee39fc615d113234a",
	"map_screen_picture_tone_2.rgba": "f8535184c5bd7d13c46d64bebd042f0ec4d131128c8d5e90e85b593e584d10dc",
	"map_screen_screen_fadein_0.rgba": "02a6ef1b9eafa4b8ef95bb41bdc83623314e0707b61e8e6aeab73c062e5443a6",
	"map_screen_screen_fadein_1.rgba": "20cda78e3dc798ae2c51cc66f2b079ce910847b583080b9885606ecc5916cb13",
	"map_screen_screen_fadein_2.rgba": "bcc1e3b58cd512a78acba69fb484e504464f17480bd7e6329f3c4ed6ab6ee0cc",
	"map_screen_screen_fadein_3.rgba": "7c7e3cf1d7c868bdfa621b5fd3e004b06be2a182b8abbf97841cd7bdc65d01a3",
	"map_screen_screen_fadeout_0.rgba": "bcc1e3b58cd512a78acba69fb484e504464f17480bd7e6329f3c4ed6ab6ee0cc",
	"map_screen_screen_fadeout_1.rgba": "20cda78e3dc798ae2c51cc66f2b079ce910847b583080b9885606ecc5916cb13",
	"map_screen_screen_fadeout_2.rgba": "02a6ef1b9eafa4b8ef95bb41bdc83623314e0707b61e8e6aeab73c062e5443a6",
	"map_screen_screen_fadeout_3.rgba": "d9eee58fe19566cf6cd1ad8c9d9a04d4933307a10c1dfe35140337dcb65b2c9f",
	"map_screen_screen_flash_0.rgba": "15213c44670ff532a37b3e6f9c736d2f097b80017dd5026972f5d6a5822a90ce",
	"map_screen_screen_flash_1.rgba": "d4fde74dab8c3190135856d5b20649d55d37b58037622c48ac8ef827298f14b5",
	"map_screen_screen_flash_2.rgba": "4cf91d49eca692d9d307f0d02b483b48a156153a725275b998617543092982b1",
	"map_screen_screen_flash_3.rgba": "477646a959aaffdc74cc7b41045cebb1bec530c9fefcead9aa10b3d8e081c63c",
	"map_screen_screen_tone_0.rgba": "061b3c4945d1e2dffe82d233675fe0f8265c3f571b5ff519f11edb77b082058d",
	"map_screen_screen_tone_1.rgba": "6c34a9949b4fc5ceb68ba70527ab78c963adb6c10e94410ea53191789af013a5",
	"map_screen_screen_tone_2.rgba": "89d4fdfcef5e96572bb94688f89a4ad36585969742861b8bce3c83933ed6f773",
	"map_screen_screen_tone_3.rgba": "d480bc184c10611765d3865fb35eb770ac8b646caaa2da87c3055c9ef13abdeb",
	"map_screen_weather_clear.rgba": "7c7e3cf1d7c868bdfa621b5fd3e004b06be2a182b8abbf97841cd7bdc65d01a3",
}
const WEATHER_MOTION := {
	"rain": [-1.0, 6.0, -12.0],
	"storm": [-3.0, 6.0, -12.0],
	"snow": [-1.0, 3.0, -12.0],
}
const WEATHER_SPRITE_MAX := {"rain": 60, "storm": 90, "snow": 30, "clear": 0}
const WEATHER_DIMNESS := {"rain": 36.0, "storm": 54.0, "snow": 18.0, "clear": 0.0}

func _initialize() -> void:
	call_deferred("_run")

func _frames(count: int) -> void:
	for frame in range(count):
		await process_frame
		await RenderingServer.frame_post_draw

func _sha256(path: String) -> String:
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	hashing.update(FileAccess.get_file_as_bytes(path))
	return hashing.finish().hex_encode()

func _bright_pixels(path: String) -> int:
	var bytes := FileAccess.get_file_as_bytes(path)
	var count := 0
	for index in range(0, bytes.size(), 4):
		if bytes[index] > 100 and bytes[index + 1] > 100 and bytes[index + 2] > 100:
			count += 1
	return count

func _run() -> void:
	var ok := true
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	root.add_child(load("res://Scenes/Boot.tscn").instantiate())
	await _frames(180)
	var output := ProjectSettings.globalize_path("res://.omo/evidence/rmva-compatibility/godot/map-screen-render")
	DirAccess.make_dir_recursive_absolute(output)
	var tsv := output.path_join("map_screen_render_reference.tsv")
	var weather_tsv := output.path_join("map_screen_weather_reference.tsv")
	for stale in [tsv, weather_tsv, output.path_join("map_screen_render_error.txt")]:
		if FileAccess.file_exists(stale):
			DirAccess.remove_absolute(stale)
	var code := "$rgss_compat_output=" + JSON.stringify(output) + "\n$map_screen_fiber=Fiber.new do\n" + FileAccess.get_file_as_string("res://tests/fixtures/map_screen_render_reference.rb") + "\nend"
	ok = driver.RunRuby(code) and ok
	for frame in range(160):
		driver.UpdateRenderManager()
		ok = driver.RunRuby("$map_screen_fiber.resume if $map_screen_fiber.alive?") and ok
		await process_frame
		await RenderingServer.frame_post_draw
	ok = driver.RunRuby("raise 'map screen render unfinished' if $map_screen_fiber.alive?") and ok
	if not ok:
		push_error("Map screen fixture did not complete")
	if FileAccess.file_exists(output.path_join("map_screen_render_error.txt")):
		push_error(FileAccess.get_file_as_string(output.path_join("map_screen_render_error.txt")))
		ok = false
	if not FileAccess.file_exists(tsv) or not FileAccess.file_exists(weather_tsv):
		push_error("Map screen fixture produced no TSV")
		ok = false
	if ok:
		var actual := FileAccess.get_file_as_string(tsv).replace("\r\n", "\n").strip_edges()
		var rows := actual.split("\n")
		if rows.size() != DETERMINISTIC_ROW_COUNT:
			push_error("Map screen row count %d differs from original %d" % [rows.size(), DETERMINISTIC_ROW_COUNT])
			ok = false
		if actual.sha256_text() != DETERMINISTIC_TSV_SHA:
			push_error("Map screen deterministic rows differ from original RGSS300")
			ok = false
		for name in DETERMINISTIC_FRAMES:
			var path := output.path_join(name)
			if not FileAccess.file_exists(path):
				push_error("Missing capture " + name)
				ok = false
				continue
			var actual_hash := _sha256(path)
			if actual_hash != DETERMINISTIC_FRAMES[name]:
				push_error("%s differs from original RGSS300: %s" % [name, actual_hash])
				ok = false
		# The stock Sprite_Picture assigns Game_Picture#opacity, which is a Float.
		# Original Sprite#opacity= accepts Float; a port that truncates it to 1
		# makes every picture nearly invisible. Name that cause explicitly.
		for line in rows:
			var fields := line.split("\t")
			if fields.size() >= 4 and fields[0] == "opacity_control" and fields[2] == "getter":
				if fields[3] != "255.000000000":
					push_error("Sprite#opacity= lost Float %s -> %s (Sprite_Picture assigns Float opacity)" % [fields[1], fields[3]])
					ok = false
	if ok:
		var weather_rows := FileAccess.get_file_as_string(weather_tsv).replace("\r\n", "\n").strip_edges().split("\n")
		var particle := {}
		for line in weather_rows:
			var fields := line.split("\t")
			if fields.size() < 3 or fields[0] != "weather_particle":
				push_error("Unexpected weather row: " + line)
				ok = false
				continue
			var kind := fields[1]
			particle[kind] = true
			if fields[2] == "first":
				var x := fields[3].to_float()
				var y := fields[4].to_float()
				var opacity := fields[5].to_float()
				# A surviving particle can inherit storm motion after a type switch.
				# Rebirth opacity is at most255; each update subtracts12 until <64.
				var age_max := floori((255.0 - opacity) / 12.0)
				if x < -100.0 - 3.0 * age_max or x > 543.0 or y < -200.0 or y > 415.0 + 6.0 * age_max:
					push_error("%s particle out of RGSS bounds: %s" % [kind, line])
					ok = false
				if opacity < 64.0 or opacity > 255.0:
					push_error("%s particle opacity out of range: %s" % [kind, line])
					ok = false
			elif fields[2] == "opacity_min" or fields[2] == "opacity_max":
				var value := fields[3].to_float()
				if value < 64.0 or value > 255.0:
					push_error("%s particle opacity out of range: %s" % [kind, line])
					ok = false
		for kind in WEATHER_MOTION:
			if not particle.has(kind):
				push_error("Missing weather particle rows for " + kind)
				ok = false
		var edge_code := "$weather_bounds_host=true; $rgss_compat_output=" + JSON.stringify(output) + "\n" + FileAccess.get_file_as_string("res://tests/fixtures/weather_bounds_reference.rb")
		ok = driver.RunRuby(edge_code) and ok
		var edge_actual := FileAccess.get_file_as_string(output.path_join("weather_bounds_reference.tsv")).replace("\r\n", "\n").strip_edges()
		var edge_original := FileAccess.get_file_as_string("res://tests/fixtures/weather_bounds_original.tsv").replace("\r\n", "\n").strip_edges()
		if edge_actual != edge_original or edge_original.is_empty():
			push_error("Weather lifetime/type-switch edge differs from original RGSS300")
			ok = false
		var deterministic := FileAccess.get_file_as_string(tsv)
		for kind in WEATHER_SPRITE_MAX:
			var expected := "\t%s\tsprite_max\t%d.000000000" % [kind, WEATHER_SPRITE_MAX[kind]]
			if not (expected in deterministic):
				push_error("Weather %s sprite_max differs from original" % kind)
				ok = false
			var dim := "\t%s\tdimness\t%.9f" % [kind, WEATHER_DIMNESS[kind]]
			if not (dim in deterministic):
				push_error("Weather %s dimness differs from original" % kind)
				ok = false
		for kind in WEATHER_MOTION:
			var motion: Array = WEATHER_MOTION[kind]
			var expected := "\t%s\tmotion\t%.9f\t%.9f\t%.9f" % [kind, motion[0], motion[1], motion[2]]
			if not (expected in deterministic):
				push_error("Weather %s motion differs from original" % kind)
				ok = false
		for kind in ["rain", "storm", "snow"]:
			var path := output.path_join("map_screen_weather_%s.rgba" % kind)
			if not FileAccess.file_exists(path):
				push_error("Missing weather capture " + kind)
				ok = false
			elif _bright_pixels(path) <= 0:
				push_error("Weather %s is not visibly rendered" % kind)
				ok = false
		var clear_path := output.path_join("map_screen_weather_clear.rgba")
		if not FileAccess.file_exists(clear_path):
			push_error("Missing clear-weather capture")
			ok = false
		elif _bright_pixels(clear_path) != 0:
			push_error("Clear weather must not render particles")
			ok = false
	print("MAP_SCREEN_RENDER_PASS" if ok else "MAP_SCREEN_RENDER_FAIL")
	quit(0 if ok else 1)
