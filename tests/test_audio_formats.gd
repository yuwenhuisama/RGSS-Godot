extends SceneTree

const TestPaths = preload("res://tools/test_paths.gd")

# Real audio loader contract for B09 (WMA) and E08 (RTP path fallback).
# Run: godot --headless --path . -s tests/test_audio_formats.gd
#
# Fixtures in tests/fixtures/audio are real encoded files generated once with the
# local ffmpeg (no library install):
#   ffmpeg -f lavfi -i sine=frequency=440:duration=0.5 -c:a pcm_s16le tone.wav
#   ffmpeg -f lavfi -i sine=frequency=440:duration=0.5 -c:a libvorbis  tone.ogg
#   ffmpeg -f lavfi -i sine=frequency=440:duration=0.5 -c:a wmav2      tone.wma
# WMA uses the bundled platform decoder or an explicit RGSS_TEST_FFMPEG override.

var _driver
var _root: Node
var _failures: Array[String] = []
var _skips: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_driver = load("res://Scripts/AudioFormatTestDriver.cs").new()
	_root = Node.new()
	_root.name = "AudioFormatRoot"
	root.add_child(_root)
	_driver.Initialize(_root)

	_check_native_formats()
	_check_extension_resolution()
	_check_rtp_fallback()
	_check_wma_explicit_decoder()
	_check_playback_path()

	_driver.Shutdown()
	# Let the audio server drop the stopped playback before the stream refs go away.
	for _i in range(6):
		await process_frame
	_root.queue_free()
	for _i in range(6):
		await process_frame
	for skip in _skips:
		print("AUDIO_FORMATS_SKIP:%s" % skip)
	for failure in _failures:
		push_error(failure)
	print("AUDIO_FORMATS_PASS" if _failures.is_empty() else "AUDIO_FORMATS_FAIL:%d" % _failures.size())
	# Quit from a separate call so the local stream references above are released
	# before engine shutdown (otherwise Godot reports them as leaked ObjectDB instances).
	call_deferred("_finish")


func _finish() -> void:
	quit(0 if _failures.is_empty() else 1)


func _fixture(file_name: String) -> String:
	return TestPaths.fixture("audio/" + file_name)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _check_native_formats() -> void:
	var wav = _driver.LoadStream(_fixture("tone.wav"))
	_expect(wav != null, "WAV fixture did not load")
	_expect(wav is AudioStreamWAV, "WAV fixture loaded as %s" % _type_name(wav))
	if wav != null:
		_expect(wav.get_length() > 0.4 and wav.get_length() < 0.6, "WAV length unexpected: %s" % wav.get_length())

	var ogg = _driver.LoadStream(_fixture("tone.ogg"))
	_expect(ogg != null, "Ogg fixture did not load")
	_expect(ogg is AudioStreamOggVorbis, "Ogg fixture loaded as %s" % _type_name(ogg))
	if ogg != null:
		_expect(ogg.get_length() > 0.4 and ogg.get_length() < 0.6, "Ogg length unexpected: %s" % ogg.get_length())
	var mp3 = _driver.LoadStream(_fixture("tone.mp3"))
	_expect(mp3 is AudioStreamMP3, "MP3 fixture did not load as AudioStreamMP3")
	if mp3 != null:
		_expect(mp3.get_length() > 0.4 and mp3.get_length() < 0.7, "MP3 length unexpected: %s" % mp3.get_length())


func _check_extension_resolution() -> void:
	# patch_rmva.rb appends ".ogg" before the native call, so a project asset that is
	# really .wav/.wma/.mp3 is only reachable if the loader probes sibling extensions.
	var probe_dir: String = ProjectSettings.globalize_path("user://audio_format_probe")
	DirAccess.make_dir_recursive_absolute(probe_dir)
	var source := FileAccess.open(_fixture("tone.wav"), FileAccess.READ)
	var bytes := source.get_buffer(source.get_length())
	source.close()
	var target: String = probe_dir.path_join("probe_stem.wav")
	var out := FileAccess.open(target, FileAccess.WRITE)
	out.store_buffer(bytes)
	out.close()

	var requested: String = probe_dir.path_join("probe_stem.ogg")
	var resolved: String = _driver.ResolveAudioPath(requested)
	_expect(resolved.replace("\\", "/") == target.replace("\\", "/"), "extension probe resolved '%s' instead of '%s'" % [resolved, target])
	var probed = _driver.LoadStream(requested)
	_expect(probed is AudioStreamWAV, "extension probe loaded %s instead of AudioStreamWAV" % _type_name(probed))
	_expect(_driver.LoadStream(probe_dir.path_join("probe_absent.ogg")) == null, "missing stem unexpectedly loaded")

	# An exact extension match must win over sibling probing (project-first contract).
	var exact_ogg: String = probe_dir.path_join("probe_exact.ogg")
	var ogg_source := FileAccess.open(_fixture("tone.ogg"), FileAccess.READ)
	var ogg_bytes := ogg_source.get_buffer(ogg_source.get_length())
	ogg_source.close()
	var ogg_out := FileAccess.open(exact_ogg, FileAccess.WRITE)
	ogg_out.store_buffer(ogg_bytes)
	ogg_out.close()
	var wav_out := FileAccess.open(probe_dir.path_join("probe_exact.wav"), FileAccess.WRITE)
	wav_out.store_buffer(bytes)
	wav_out.close()
	var exact_resolved: String = _driver.ResolveAudioPath(exact_ogg)
	_expect(exact_resolved.replace("\\", "/") == exact_ogg.replace("\\", "/"), "exact extension did not win: '%s'" % exact_resolved)
	_expect(_driver.LoadStream(exact_ogg) is AudioStreamOggVorbis, "exact .ogg loaded as %s" % _type_name(_driver.LoadStream(exact_ogg)))


func _check_rtp_fallback() -> void:
	# E08: patch_rmva.rb passes an ABSOLUTE project path. The old fallback did
	# Path.Combine(rtp, absolute), which returns the absolute path unchanged, so RTP
	# was never consulted. Theme1.ogg exists only in the RTP here.
	var rtp: String = _driver.GetRtpPath()
	if rtp.is_empty():
		_skips.append("RTP path not configured")
		return
	var expected: String = rtp.path_join("Audio/BGM/Theme1.ogg")
	if not FileAccess.file_exists(expected):
		_skips.append("RTP reference audio missing: " + expected)
		return
	var project_path: String = _driver.GetProjectAudioDir().path_join("BGM").path_join("Theme1.ogg")
	_expect(not FileAccess.file_exists(project_path), "test precondition broken: project Theme1.ogg exists")
	var resolved: String = _driver.ResolveAudioPath(project_path)
	_expect(resolved.replace("\\", "/") == expected.replace("\\", "/"), "RTP fallback resolved '%s' instead of '%s'" % [resolved, expected])
	var stream = _driver.LoadStream(project_path)
	_expect(stream is AudioStreamOggVorbis, "RTP fallback loaded %s instead of AudioStreamOggVorbis" % _type_name(stream))


func _check_wma_explicit_decoder() -> void:
	var wma: String = _fixture("tone.wma")
	var probe_dir: String = ProjectSettings.globalize_path("user://audio_format_probe")
	DirAccess.make_dir_recursive_absolute(probe_dir)

	var ffmpeg := OS.get_environment("RGSS_TEST_FFMPEG")
	if ffmpeg.is_empty():
		var configured = TestPaths.values().get("ffmpeg", "")
		if configured is String and not configured.strip_edges().is_empty():
			ffmpeg = TestPaths.required("ffmpeg")
	if ffmpeg.is_empty():
		var platform := "windows" if OS.get_name() == "Windows" else "macos" if OS.get_name() == "macOS" else "linux"
		var executable := "ffmpeg.exe" if platform == "windows" else "ffmpeg"
		var bundled := ProjectSettings.globalize_path("res://Plugins/" + platform + "/audio/" + executable)
		if FileAccess.file_exists(bundled):
			ffmpeg = bundled
	if ffmpeg.is_empty() or not FileAccess.file_exists(ffmpeg):
		_skips.append("no ffmpeg available for WMA decode")
	else:
		_driver.SetFfmpegPath(ffmpeg)
		var stream = _driver.LoadStream(wma)
		_expect(stream != null, "WMA did not load with ffmpeg '%s': %s" % [ffmpeg, _driver.GetLastLoadDiagnostic()])
		_expect(stream is AudioStreamWAV, "WMA decoded to %s instead of AudioStreamWAV" % _type_name(stream))
		if stream != null:
			_expect(stream.get_length() > 0.4 and stream.get_length() < 0.6, "WMA length unexpected: %s" % stream.get_length())
		var cache: String = _driver.GetWmaCachePath(wma)
		_expect(not cache.is_empty(), "WMA cache path helper missing")
		_expect(FileAccess.file_exists(cache), "WMA cache file missing: " + cache)
		if FileAccess.file_exists(cache):
			var cached := FileAccess.open(cache, FileAccess.READ)
			_expect(cached.get_buffer(4).get_string_from_ascii() == "RIFF", "WMA cache is not a RIFF WAV")
			cached.close()

	# Bundled decoder must work without an environment override.
	_driver.SetFfmpegPath("")
	if not ffmpeg.is_empty():
		var bundled_probe := ProjectSettings.globalize_path("user://audio_format_probe/bundled-fresh.wma")
		DirAccess.make_dir_recursive_absolute(bundled_probe.get_base_dir())
		_expect(DirAccess.copy_absolute(wma, bundled_probe) == OK, "fresh bundled WMA probe copy failed")
		var bundled_cache: String = _driver.GetWmaCachePath(bundled_probe)
		if FileAccess.file_exists(bundled_cache):
			_expect(DirAccess.remove_absolute(bundled_cache) == OK, "owned bundled WMA cache removal failed")
		_expect(_driver.LoadStream(bundled_probe) is AudioStreamWAV, "bundled WMA decoder did not load fresh source")
	# A explicitly configured unavailable decoder is a real boundary failure.
	_driver.SetFfmpegPath(probe_dir.path_join("missing-decoder/ffmpeg.exe"))
	_expect(_driver.LoadStream(wma) == null, "missing explicit decoder must fail")
	_expect("AUDIO_WMA_NO_DECODER" in _driver.GetLastLoadDiagnostic(), "missing explicit no-decoder diagnostic")


func _check_playback_path() -> void:
	_driver.SetFfmpegPath("")
	for extension in ["wav", "ogg", "mp3", "wma"]:
		_expect(_driver.PlayBgm(_fixture("tone." + extension)), "PlayBgm rejected " + extension)
		_expect(_driver.GetBgmStream() != null, "BGM player did not receive decoded " + extension)
		_expect(_driver.GetBgmPlaying(), "BGM player did not start " + extension)
		_driver.StopBgm()
		_expect(not _driver.GetBgmPlaying(), "BGM player did not stop " + extension)


func _type_name(value) -> String:
	return "null" if value == null else value.get_class()
