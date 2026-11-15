extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	Engine.max_fps = 60
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	driver.Initialize(host)
	var audio = load("res://Scripts/AudioFormatTestDriver.cs").new()
	audio.Initialize(host)
	var stream = audio.LoadStream(ProjectSettings.globalize_path("res://tests/fixtures/audio/tone.ogg"))
	var packet = stream.packet_sequence.packet_data[0][0]
	print("AUDIO_SEEK_METADATA:rate=%s:channels=%s" % [stream.packet_sequence.sampling_rate, packet[11]])
	var output := ProjectSettings.globalize_path("res://.omo/evidence/rmva-compatibility/godot/audio-seek-units")
	DirAccess.make_dir_recursive_absolute(output)
	var code := "require 'graphics'; require 'audio'; $audio_seek_units_host=true; $rgss_compat_output=" + JSON.stringify(output) + "; $audio_seek_probe=Fiber.new do\n" + FileAccess.get_file_as_string("res://tests/fixtures/audio_seek_units_reference.rb") + "\nend"
	var ok: bool = driver.RunRuby(code)
	for frame in range(50):
		ok = driver.RunRuby("$audio_seek_probe.resume if $audio_seek_probe.alive?") and ok
		await process_frame
		await RenderingServer.frame_post_draw
	ok = driver.RunRuby("raise 'seek fixture unfinished' if $audio_seek_probe.alive?") and ok
	var text := FileAccess.get_file_as_string(output.path_join("audio_seek_units_reference.tsv")).replace("\r\n", "\n").strip_edges()
	print(text)
	var rows := text.split("\n")
	ok = rows.size() == 8 and ok
	for row in rows:
		var fields := row.split("\t")
		if fields.size() != 7:
			ok = false
			continue
		var ogg := fields[0] == "ogg"
		ok = float(fields[2]) == (float(fields[1]) if ogg else 0.0) and fields[3] == ("true" if ogg else "false") and fields[4] == "true" and ok
	audio.Shutdown()
	driver.Shutdown()
	print("AUDIO_SEEK_UNITS_PASS" if ok else "AUDIO_SEEK_UNITS_FAIL")
	quit(0 if ok else 1)
