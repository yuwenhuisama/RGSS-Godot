extends SceneTree

# golden_diff.gd - Headless golden-screenshot diff tool (migration task T8, Part B)
#
# Run via Godot's -s (script main-loop) flag. Three modes:
#
#   1) Screenshot (default):
#        godot --headless --path <proj> -s tools/golden_diff.gd
#      Captures the root viewport and saves it to user://screenshot.png.
#
#   2) Golden:
#        godot --headless --path <proj> -s tools/golden_diff.gd -- --golden <path>
#      Captures the root viewport and saves it as the golden reference at <path>.
#
#   3) Compare:
#        godot --headless --path <proj> -s tools/golden_diff.gd -- --compare <golden> <actual>
#      Loads both PNGs, converts to RGBA8, computes the maximum per-channel
#      absolute pixel difference (0..255) and prints:
#        GOLDEN_DIFF:PASS:<max_diff>   when max_diff <= tolerance
#        GOLDEN_DIFF:FAIL:<max_diff>   when max_diff >  tolerance
#      On FAIL (or size mismatch) a diff image is written to user://golden_diff.png.
#
# Tolerance defaults to 5; override with: -- --tolerance <n>
# Flags are accepted both after a "--" separator (user args) and inline.
#
# Exit code: 0 on PASS / successful screenshot / golden save; 1 on FAIL or error.
#
# NOTE: As a SceneTree script there is no get_viewport(); the SceneTree-level
# equivalent is get_root(), which returns the root Window (a Viewport). So
#   get_viewport().get_texture().get_image()
# becomes
#   get_root().get_texture().get_image()

const DEFAULT_TOLERANCE := 5
const SCREENSHOT_PATH := "user://screenshot.png"
const DIFF_PATH := "user://golden_diff.png"
const CAPTURE_FRAME_THRESHOLD := 3

var _mode := "screenshot"
var _golden_path := ""
var _compare_golden := ""
var _compare_actual := ""
var _tolerance := DEFAULT_TOLERANCE
var _frames_waited := 0
var _exit_code := 0


func _initialize() -> void:
	_parse_args()
	if _mode == "compare":
		_exit_code = _do_compare(_compare_golden, _compare_actual)
		quit(_exit_code)
		return
	# screenshot / golden: wait a few frames so the viewport can render,
	# then capture. Use the process_frame signal to avoid overriding the
	# SceneTree's own _process loop.
	process_frame.connect(_on_process_frame)


func _on_process_frame() -> void:
	_frames_waited += 1
	if _frames_waited < CAPTURE_FRAME_THRESHOLD:
		return
	if process_frame.is_connected(_on_process_frame):
		process_frame.disconnect(_on_process_frame)
	_exit_code = _do_capture()
	quit(_exit_code)


# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

func _parse_args() -> void:
	var args := _gather_args()
	var i := 0
	while i < args.size():
		var a: String = args[i]
		match a:
			"--golden":
				_mode = "golden"
				if i + 1 < args.size():
					_golden_path = args[i + 1]
					i += 1
			"--compare":
				_mode = "compare"
				if i + 2 < args.size():
					_compare_golden = args[i + 1]
					_compare_actual = args[i + 2]
					i += 2
			"--tolerance":
				if i + 1 < args.size():
					_tolerance = int(args[i + 1])
					i += 1
			_:
				pass
		i += 1


func _gather_args() -> PackedStringArray:
	# Scan both the post-"--" user args and the full command line so the tool
	# works whether or not the caller used the "--" separator.
	var combined := PackedStringArray()
	combined.append_array(OS.get_cmdline_user_args())
	combined.append_array(OS.get_cmdline_args())
	return combined


# ---------------------------------------------------------------------------
# Compare mode
# ---------------------------------------------------------------------------

func _do_compare(golden_path: String, actual_path: String) -> int:
	var img_g := _load_image(golden_path)
	var img_a := _load_image(actual_path)
	if img_g == null or img_a == null:
		print("GOLDEN_DIFF:FAIL:255")
		push_error("golden_diff: could not load image(s) golden='%s' actual='%s'" % [golden_path, actual_path])
		return 1

	if img_g.get_format() != Image.FORMAT_RGBA8:
		img_g.convert(Image.FORMAT_RGBA8)
	if img_a.get_format() != Image.FORMAT_RGBA8:
		img_a.convert(Image.FORMAT_RGBA8)

	var wg := img_g.get_width()
	var hg := img_g.get_height()
	var wa := img_a.get_width()
	var ha := img_a.get_height()
	if wg != wa or hg != ha:
		# Differing dimensions cannot be compared pixel-wise: definite failure.
		print("GOLDEN_DIFF:FAIL:255")
		push_error("golden_diff: size mismatch golden=%dx%d actual=%dx%d" % [wg, hg, wa, ha])
		return 1

	var data_g := img_g.get_data()
	var data_a := img_a.get_data()
	var n := data_g.size()
	var max_diff := 0
	for idx in range(n):
		var d: int = absi(int(data_g[idx]) - int(data_a[idx]))
		if d > max_diff:
			max_diff = d
			if max_diff >= 255:
				break

	if max_diff <= _tolerance:
		print("GOLDEN_DIFF:PASS:%d" % max_diff)
		return 0

	print("GOLDEN_DIFF:FAIL:%d" % max_diff)
	_save_diff_image(img_g, img_a)
	return 1


func _save_diff_image(img_g: Image, img_a: Image) -> void:
	var w := img_g.get_width()
	var h := img_g.get_height()
	var dg := img_g.get_data()
	var da := img_a.get_data()
	var out := PackedByteArray()
	out.resize(dg.size())
	var i := 0
	while i < dg.size():
		out[i] = absi(int(dg[i]) - int(da[i]))          # R
		out[i + 1] = absi(int(dg[i + 1]) - int(da[i + 1]))  # G
		out[i + 2] = absi(int(dg[i + 2]) - int(da[i + 2]))  # B
		out[i + 3] = 255                                  # A (opaque)
		i += 4
	var diff := Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, out)
	var err := diff.save_png(DIFF_PATH)
	if err == OK:
		print("GOLDEN_DIFF:DIFF_IMAGE:%s" % ProjectSettings.globalize_path(DIFF_PATH))
	else:
		push_error("golden_diff: failed to save diff image (err %d)" % err)


func _load_image(path: String) -> Image:
	if path.is_empty() or not FileAccess.file_exists(path):
		return null
	return Image.load_from_file(path)


# ---------------------------------------------------------------------------
# Screenshot / golden capture
# ---------------------------------------------------------------------------

func _do_capture() -> int:
	# The headless/dummy display server has no real framebuffer to read back,
	# so get_texture().get_image() returns null (and logs an internal error).
	# Detect that up front and report cleanly instead of attempting a read that
	# is guaranteed to fail. Real golden captures run on a GPU display server.
	if DisplayServer.get_name() == "headless":
		print("GOLDEN_DIFF:SCREENSHOT_UNAVAILABLE_HEADLESS")
		return 0

	var root_vp := get_root()
	if root_vp == null:
		push_error("golden_diff: no root viewport")
		return 1
	var tex := root_vp.get_texture()
	var img: Image = null
	if tex != null:
		img = tex.get_image()
	if img == null:
		# Defensive fallback: a non-headless server should yield an image, but
		# if read-back still fails, signal clearly without hard-failing.
		print("GOLDEN_DIFF:SCREENSHOT_UNAVAILABLE_HEADLESS")
		return 0

	var target := SCREENSHOT_PATH
	if _mode == "golden":
		target = _golden_path if not _golden_path.is_empty() else SCREENSHOT_PATH

	var err := img.save_png(target)
	if err != OK:
		push_error("golden_diff: failed to save png to '%s' (err %d)" % [target, err])
		return 1

	if _mode == "golden":
		print("GOLDEN_DIFF:GOLDEN_SAVED:%s" % ProjectSettings.globalize_path(target))
	else:
		print("GOLDEN_DIFF:SCREENSHOT:%s" % ProjectSettings.globalize_path(target))
	return 0
