extends SceneTree

const TestPaths = preload("res://tools/test_paths.gd")

# Standalone contract and physical-mode harness runner for C12 Windows original fullscreen.
#
# Modes:
#   Default (self-test):
#     godot --path . -s tests/test_original_fullscreen.gd -- --output-dir .omo/evidence/c12-host-godot
#   Interactive file-signaled mode (driven by tools/test_original_fullscreen.ps1):
#     godot --path . -s tests/test_original_fullscreen.gd -- --interactive --control-dir .omo/compatibility-run-tmp/c12-host-run --logical-size 544x416
#   Legacy red reproduction (pre-C12 Godot WindowMode.Fullscreen without Win32 CDS_FULLSCREEN):
#     godot --path . -s tests/test_original_fullscreen.gd -- --legacy-godot-fullscreen --interactive --control-dir .omo/compatibility-run-tmp/c12-host-red --logical-size 640x480

var driver
var settings

func _initialize() -> void:
	call_deferred("_run")

func _frames(count: int = 6) -> void:
	for _i in range(count):
		driver.UpdateRenderManager()
		await process_frame
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw

func _arg_value(flag: String, default_value: String) -> String:
	var args := OS.get_cmdline_user_args()
	for i in range(args.size()):
		if args[i] == flag and i + 1 < args.size():
			return args[i + 1]
		if args[i].begins_with(flag + "="):
			return args[i].substr(flag.length() + 1)
	return default_value

func _parse_size(spec: String, fallback: Vector2i) -> Vector2i:
	var parts := spec.to_lower().split("x")
	if parts.size() != 2:
		return fallback
	var w := parts[0].to_int()
	var h := parts[1].to_int()
	if w <= 0 or h <= 0:
		return fallback
	return Vector2i(w, h)

func _checker_origin(logical_size: Vector2i) -> Vector2i:
	if logical_size.x >= 308 and logical_size.y >= 228:
		return Vector2i(300, 220)
	return Vector2i(maxi(4, logical_size.x / 2 - 4), maxi(4, logical_size.y / 2 - 4))

func _paint_pattern(logical_size: Vector2i) -> bool:
	var checker := _checker_origin(logical_size)
	var script := """
require 'graphics'
require 'bitmap'
require 'sprite'
require 'viewport'
require 'color'
$c12_viewport.dispose if $c12_viewport && !$c12_viewport.disposed?
$c12_sprite.dispose if $c12_sprite && !$c12_sprite.disposed?
$c12_bitmap.dispose if $c12_bitmap && !$c12_bitmap.disposed?
Graphics.resize_screen(%d, %d)
w = Graphics.width
h = Graphics.height
raise "unexpected logical #{w}x#{h}" unless w == %d && h == %d
$c12_bitmap = Bitmap.new(w, h)
$c12_bitmap.fill_rect($c12_bitmap.rect, Color.new(20, 80, 120))
$c12_bitmap.fill_rect(0, 0, w, 4, Color.new(255, 0, 0))
$c12_bitmap.fill_rect(w - 4, 0, 4, h, Color.new(0, 255, 0))
$c12_bitmap.fill_rect(0, h - 4, w, 4, Color.new(0, 0, 255))
$c12_bitmap.fill_rect(0, 0, 4, h, Color.new(255, 255, 0))
8.times do |y|
  8.times do |x|
    c = ((x + y) %% 2 == 0) ? Color.new(255, 255, 255) : Color.new(0, 0, 0)
    $c12_bitmap.set_pixel(%d + x, %d + y, c)
  end
end
$c12_sprite = Sprite.new
$c12_sprite.bitmap = $c12_bitmap
$c12_viewport = Viewport.new
raise 'viewport size mismatch' unless $c12_viewport.rect.width == w && $c12_viewport.rect.height == h
""" % [logical_size.x, logical_size.y, logical_size.x, logical_size.y, checker.x, checker.y]
	return driver.RunRuby(script)

func _verify_logical(logical_size: Vector2i) -> bool:
	var script := """
raise 'logical size drifted' unless Graphics.width == %d && Graphics.height == %d
snap = Graphics.snap_to_bitmap
raise 'snapshot size drifted' unless snap.width == %d && snap.height == %d
snap.dispose
""" % [logical_size.x, logical_size.y, logical_size.x, logical_size.y]
	return driver.RunRuby(script)

func _send_alt_enter() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ENTER
	event.alt_pressed = true
	event.pressed = true
	Input.parse_input_event(event)

func _set_f1_fullscreen(enabled: bool) -> bool:
	var open_event := InputEventKey.new()
	open_event.keycode = KEY_F1
	open_event.pressed = true
	Input.parse_input_event(open_event)
	await process_frame
	await process_frame
	var layer: CanvasLayer = settings.get_child(0)
	if layer.get_child_count() == 0:
		return false
	var dialog: AcceptDialog = layer.get_child(0)
	var tabs: TabContainer = dialog.get_child(0)
	var general: VBoxContainer = tabs.get_child(0)
	var fullscreen_check: CheckBox = general.get_child(0)
	fullscreen_check.button_pressed = enabled
	dialog.emit_signal("confirmed")
	await _frames(4)
	var saved := ConfigFile.new()
	var saved_ok := saved.load("user://rgss_settings.cfg") == OK
	var saved_fullscreen: bool = saved.get_value("general", "fullscreen", false) if saved_ok else false
	print("C12_F1_COMMIT:expected=%s:saved=%s:requested=%s:native=%s" % [enabled, saved_fullscreen, settings.IsFullscreenRequested, settings.IsNativeFullscreenActive])
	return saved_ok and saved_fullscreen == enabled and settings.IsFullscreenRequested == enabled

func _write_status(path: String, label: String, logical_size: Vector2i) -> void:
	var screen := DisplayServer.window_get_current_screen()
	var screen_size := DisplayServer.screen_get_size(screen)
	var screen_pos := DisplayServer.screen_get_position(screen)
	var win_mode := DisplayServer.window_get_mode()
	var text := "\n".join([
		"label=%s" % label,
		"logical=%dx%d" % [logical_size.x, logical_size.y],
		"window_size=%dx%d" % [root.size.x, root.size.y],
		"window_pos=%d,%d" % [root.position.x, root.position.y],
		"window_mode=%d" % win_mode,
		"screen=%d" % screen,
		"screen_size=%dx%d" % [screen_size.x, screen_size.y],
		"screen_pos=%d,%d" % [screen_pos.x, screen_pos.y],
		"settings_requested=%s" % (str(settings.IsFullscreenRequested) if settings != null else "legacy"),
		"settings_native=%s" % (str(settings.IsNativeFullscreenActive) if settings != null else "false"),
	]) + "\n"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(text)
		file.close()

func _color_matches(actual: Color, r8: int, g8: int, b8: int, tol: int = 2) -> bool:
	var ar := int(round(actual.r * 255.0))
	var ag := int(round(actual.g * 255.0))
	var ab := int(round(actual.b * 255.0))
	return absi(ar - r8) <= tol and absi(ag - g8) <= tol and absi(ab - b8) <= tol

func _verify_physical_screen_640x480(screen_img: Image, logical_size: Vector2i, state_tag: String) -> bool:
	if screen_img == null or screen_img.is_empty():
		print("ORIGINAL_FULLSCREEN_CHECK:%s:FAIL:empty_screen_image" % state_tag)
		return false
	if screen_img.get_size() != Vector2i(640, 480):
		print("ORIGINAL_FULLSCREEN_CHECK:%s:FAIL:physical_size=%s_expected_640x480" % [state_tag, screen_img.get_size()])
		return false
	var ox := (640 - logical_size.x) / 2
	var oy := (480 - logical_size.y) / 2
	var ok := true
	if ox > 0:
		var left_bar := screen_img.get_pixel(ox / 2, 240)
		var right_bar := screen_img.get_pixel(640 - 1 - ox / 2, 240)
		ok = _color_matches(left_bar, 0, 0, 0, 0) and _color_matches(right_bar, 0, 0, 0, 0) and ok
	if oy > 0:
		var top_bar := screen_img.get_pixel(320, oy / 2)
		var bottom_bar := screen_img.get_pixel(320, 480 - 1 - oy / 2)
		ok = _color_matches(top_bar, 0, 0, 0, 0) and _color_matches(bottom_bar, 0, 0, 0, 0) and ok

	var top_red := screen_img.get_pixel(ox + logical_size.x / 2, oy + 2)
	var right_green := screen_img.get_pixel(ox + logical_size.x - 3, oy + logical_size.y / 2)
	var bottom_blue := screen_img.get_pixel(ox + logical_size.x / 2, oy + logical_size.y - 3)
	var left_yellow := screen_img.get_pixel(ox + 2, oy + logical_size.y / 2)
	ok = _color_matches(top_red, 255, 0, 0, 0) and ok
	ok = _color_matches(right_green, 0, 255, 0, 0) and ok
	ok = _color_matches(bottom_blue, 0, 0, 255, 0) and ok
	ok = _color_matches(left_yellow, 255, 255, 0, 0) and ok

	var checker := _checker_origin(logical_size)
	for y in range(8):
		for x in range(8):
			var px := screen_img.get_pixel(ox + checker.x + x, oy + checker.y + y)
			var want := 255 if ((x + y) % 2 == 0) else 0
			ok = _color_matches(px, want, want, want, 0) and ok

	print("ORIGINAL_FULLSCREEN_CHECK:%s:origin=%d,%d:logical=%s:screen=%s:ok=%s" % [
		state_tag, ox, oy, logical_size, screen_img.get_size(), ok
	])
	return ok

func _run_interactive(control_dir: String, initial_logical: Vector2i, legacy_red: bool) -> void:
	DirAccess.make_dir_recursive_absolute(control_dir)
	var logical := initial_logical
	var painted := _paint_pattern(logical)
	await _frames(6)
	if not painted:
		push_error("Failed to paint initial RGSS pattern")
		quit(1)
		return

	_write_status(control_dir.path_join("ready.txt"), "ready", logical)
	print("ORIGINAL_FULLSCREEN_INTERACTIVE_READY:legacy=%s:logical=%s" % [legacy_red, logical])

	var max_frames := 36000
	for frame in range(max_frames):
		driver.UpdateRenderManager()
		await process_frame
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw

		var cmd_path := control_dir.path_join("command.txt")
		if FileAccess.file_exists(cmd_path):
			var raw_cmd := FileAccess.get_file_as_string(cmd_path).strip_edges()
			DirAccess.remove_absolute(cmd_path)
			var tokens := raw_cmd.split(":")
			var action := tokens[0] if tokens.size() > 0 else ""
			var arg := tokens[1] if tokens.size() > 1 else ""
			var cmd_ok := true

			if action == "alt_enter":
				if legacy_red:
					var fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fs else DisplayServer.WINDOW_MODE_FULLSCREEN)
				else:
					_send_alt_enter()
				await _frames(8)
			elif action == "f1_fullscreen":
				var enable := arg == "1" or arg.to_lower() == "true"
				if legacy_red:
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enable else DisplayServer.WINDOW_MODE_WINDOWED)
					await _frames(8)
				else:
					cmd_ok = await _set_f1_fullscreen(enable)
					await _frames(6)
			elif action == "resize":
				logical = _parse_size(arg, logical)
				cmd_ok = _paint_pattern(logical)
				await _frames(8)
			elif action == "focus_out":
				if settings != null:
					await _frames(20)
					settings.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
				await _frames(6)
			elif action == "focus_in":
				if settings != null:
					settings.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_IN)
				await _frames(8)
			elif action == "snapshot":
				var tag := arg if arg != "" else "shot"
				var viewport_img := root.get_texture().get_image()
				viewport_img.save_png(control_dir.path_join("viewport-%s.png" % tag))
				var screen_img := DisplayServer.screen_get_image(root.current_screen)
				if screen_img != null and not screen_img.is_empty():
					screen_img.save_png(control_dir.path_join("screen-%s.png" % tag))
				cmd_ok = _verify_logical(logical)
			elif action == "quit":
				_write_status(control_dir.path_join("ack.txt"), "quit", logical)
				break

			cmd_ok = _verify_logical(logical) and cmd_ok
			_write_status(control_dir.path_join("ack.txt"), "%s:%s" % [action, "ok" if cmd_ok else "fail"], logical)

		if FileAccess.file_exists(control_dir.path_join("stop.signal")):
			break

	driver.RunRuby("$c12_viewport.dispose if $c12_viewport; $c12_sprite.dispose if $c12_sprite; $c12_bitmap.dispose if $c12_bitmap")
	if legacy_red and DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	if settings != null:
		root.remove_child(settings)
		settings.free()
	driver.Shutdown()
	print("ORIGINAL_FULLSCREEN_INTERACTIVE_DONE")
	quit(0)

func _run() -> void:
	Engine.max_fps = 60
	if OS.get_name() != "Windows":
		push_error("ORIGINAL_FULLSCREEN_FAIL:Windows host required")
		print("ORIGINAL_FULLSCREEN_FAIL")
		quit(1)
		return
	if DisplayServer.get_name() == "headless":
		push_error("ORIGINAL_FULLSCREEN_FAIL:Rendered Windows DisplayServer required (headless cannot switch physical display mode)")
		print("ORIGINAL_FULLSCREEN_FAIL")
		quit(1)
		return

	var args := OS.get_cmdline_user_args()
	var legacy_red := "--legacy-godot-fullscreen" in args
	var interactive := "--interactive" in args
	var control_arg := _arg_value("--control-dir", "")
	var control_dir := TestPaths.repo(".omo/compatibility-run-tmp/c12-host-run") if control_arg.is_empty() else ProjectSettings.globalize_path(control_arg)
	var output_arg := _arg_value("--output-dir", "")
	var output_dir := TestPaths.repo(".omo/evidence/c12-host-self") if output_arg.is_empty() else ProjectSettings.globalize_path(output_arg)
	DirAccess.make_dir_recursive_absolute(control_dir)
	DirAccess.make_dir_recursive_absolute(output_dir)
	var initial_logical := _parse_size(_arg_value("--logical-size", "640x480"), Vector2i(640, 480))

	# Isolate user://rgss_settings.cfg state before instantiating GameSettings.
	var prior_cfg := ConfigFile.new()
	var had_prior_cfg := prior_cfg.load("user://rgss_settings.cfg") == OK
	if had_prior_cfg:
		var clean_cfg := ConfigFile.new()
		clean_cfg.set_value("general", "fullscreen", false)
		clean_cfg.save("user://rgss_settings.cfg")

	driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	driver.Initialize(host)
	var boot_ok: bool = driver.RunRuby("require 'color'; require 'tone'; require 'rect'; require 'font'; require 'rgss_reset'")
	if not boot_ok:
		push_error("ORIGINAL_FULLSCREEN_FAIL:Ruby bootstrap failed")
		print("ORIGINAL_FULLSCREEN_FAIL")
		quit(1)
		return

	root.title = "RGSS Original Fullscreen QA"
	root.exclude_from_capture = false
	root.current_screen = DisplayServer.get_primary_screen()
	root.mode = Window.MODE_WINDOWED
	root.position = DisplayServer.screen_get_position(root.current_screen) + Vector2i(120, 120)
	root.show()
	root.grab_focus()

	if not legacy_red:
		settings = load("res://Scripts/GameSettings.cs").new()
		root.add_child(settings)
		await _frames(4)

	if interactive:
		await _run_interactive(control_dir, initial_logical, legacy_red)
		return

	DirAccess.make_dir_recursive_absolute(output_dir)
	var ok := true
	var initial_screen_size := DisplayServer.screen_get_size(root.current_screen)
	print("ORIGINAL_FULLSCREEN_DESKTOP_BEFORE:%s" % initial_screen_size)

	# 1. Verify Alt+Enter across logical sizes 640x480, 544x416, and 320x240.
	var logical_cases: Array[Vector2i] = [Vector2i(640, 480), Vector2i(544, 416), Vector2i(320, 240)]
	for logical_size: Vector2i in logical_cases:
		var tag := "%dx%d" % [logical_size.x, logical_size.y]
		ok = _paint_pattern(logical_size) and ok
		await _frames(6)
		root.grab_focus()
		_send_alt_enter()
		await _frames(12)
		ok = settings.IsFullscreenRequested and settings.IsNativeFullscreenActive and ok
		ok = _verify_logical(logical_size) and ok
		var screen_img := DisplayServer.screen_get_image(root.current_screen)
		if screen_img != null and not screen_img.is_empty():
			screen_img.save_png(output_dir.path_join("fullscreen-%s-screen.png" % tag))
		var vp_img := root.get_texture().get_image()
		vp_img.save_png(output_dir.path_join("fullscreen-%s-viewport.png" % tag))
		ok = vp_img.get_size() == logical_size and ok
		ok = _verify_physical_screen_640x480(screen_img, logical_size, "alt_enter_" + tag) and ok

		# Restore to windowed via Alt+Enter.
		_send_alt_enter()
		await _frames(12)
		var restored_screen := DisplayServer.screen_get_size(root.current_screen)
		print("ORIGINAL_FULLSCREEN_RESTORED:%s:screen=%s:window=%s:mode=%d" % [tag, restored_screen, root.size, DisplayServer.window_get_mode()])
		ok = (not settings.IsFullscreenRequested) and (not settings.IsNativeFullscreenActive) and ok
		ok = restored_screen == initial_screen_size and ok
		ok = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED and ok
		ok = _verify_logical(logical_size) and ok

	# 2. Verify F1 Game Properties dialog uses the exact same native fullscreen path.
	ok = _paint_pattern(Vector2i(544, 416)) and ok
	await _frames(6)
	ok = (await _set_f1_fullscreen(true)) and ok
	await _frames(10)
	ok = settings.IsFullscreenRequested and settings.IsNativeFullscreenActive and ok
	var f1_screen := DisplayServer.screen_get_image(root.current_screen)
	if f1_screen != null and not f1_screen.is_empty():
		f1_screen.save_png(output_dir.path_join("fullscreen-f1-544x416-screen.png"))
	ok = _verify_physical_screen_640x480(f1_screen, Vector2i(544, 416), "f1_544x416") and ok

	# Focus-out restores desktop mode; focus-in re-enters 640x480 fullscreen.
	await _frames(20)
	settings.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	await _frames(8)
	var focus_out_size := DisplayServer.screen_get_size(root.current_screen)
	print("ORIGINAL_FULLSCREEN_FOCUS_OUT:screen=%s:native_active=%s" % [focus_out_size, settings.IsNativeFullscreenActive])
	ok = focus_out_size == initial_screen_size and (not settings.IsNativeFullscreenActive) and ok

	settings.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_IN)
	await _frames(10)
	var focus_in_img := DisplayServer.screen_get_image(root.current_screen)
	ok = _verify_physical_screen_640x480(focus_in_img, Vector2i(544, 416), "focus_in_544x416") and ok

	# Restore via F1 dialog back to windowed.
	ok = (await _set_f1_fullscreen(false)) and ok
	await _frames(10)
	ok = DisplayServer.screen_get_size(root.current_screen) == initial_screen_size and ok
	ok = (not settings.IsFullscreenRequested) and (not settings.IsNativeFullscreenActive) and ok

	# Restore prior user settings file if one existed.
	if had_prior_cfg:
		prior_cfg.save("user://rgss_settings.cfg")
	else:
		var abs_cfg := ProjectSettings.globalize_path("user://rgss_settings.cfg")
		if FileAccess.file_exists(abs_cfg):
			DirAccess.remove_absolute(abs_cfg)

	driver.RunRuby("$c12_viewport.dispose if $c12_viewport; $c12_sprite.dispose if $c12_sprite; $c12_bitmap.dispose if $c12_bitmap; Graphics.resize_screen(544, 416)")
	root.remove_child(settings)
	settings.free()
	driver.Shutdown()

	var final_screen := DisplayServer.screen_get_size(root.current_screen)
	ok = final_screen == initial_screen_size and ok
	print("ORIGINAL_FULLSCREEN_DESKTOP_AFTER:%s" % final_screen)
	print("ORIGINAL_FULLSCREEN_PASS" if ok else "ORIGINAL_FULLSCREEN_FAIL")
	quit(0 if ok else 1)
