extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	driver.Initialize(host)
	var midi := ProjectSettings.globalize_path("res://tests/fixtures/midi-reference.mid")
	var ok: bool = driver.RunRuby("require 'audio'; Audio.setup_midi; Audio.bgm_play(" + JSON.stringify(midi) + ")")
	await create_timer(0.8).timeout
	ok = driver.HasMidiPlayback() and ok
	ok = driver.RunRuby("raise 'MIDI public position' unless Audio.bgm_pos == 0; Audio.bgm_stop; raise 'MIDI stop position' unless Audio.bgm_pos == 0") and ok
	ok = not driver.HasMidiPlayback() and ok
	ok = driver.RunRuby("Audio.bgm_play(" + JSON.stringify(midi) + ",50,120,0.5)") and ok
	await create_timer(0.2).timeout
	ok = driver.HasMidiPlayback() and ok
	ok = driver.RunRuby("raise 'MIDI ignores seek' unless Audio.bgm_pos == 0; Audio.bgm_fade(100)") and ok
	await create_timer(0.25).timeout
	ok = not driver.HasMidiPlayback() and ok
	ok = driver.RunRuby("raise 'MIDI fade did not stop' unless Audio.bgm_pos == 0; Audio.bgm_stop") and ok
	ok = not driver.HasMidiPlayback() and ok
	for filename in ["midi-reference-sysex.mid", "midi-reference-smpte.mid"]:
		var path := ProjectSettings.globalize_path("res://tests/fixtures/" + filename)
		ok = driver.RunRuby("Audio.bgm_play(" + JSON.stringify(path) + ")") and ok
		await create_timer(0.2).timeout
		ok = driver.HasMidiPlayback() and ok
		ok = driver.RunRuby("raise 'MIDI variant public position' unless Audio.bgm_pos == 0; Audio.bgm_stop") and ok
		ok = not driver.HasMidiPlayback() and ok
	driver.Shutdown()
	# AudioServer retires the stopped playback on its next mixer iterations.
	for frame in range(6):
		await process_frame
	print("MIDI_PLAYBACK_PASS" if ok else "MIDI_PLAYBACK_FAIL")
	quit(0 if ok else 1)
