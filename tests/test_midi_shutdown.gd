extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game: Node=load("res://Scenes/Boot.tscn").instantiate()
	root.add_child(game)
	for frame in range(90):
		await process_frame
	var driver=load("res://Scripts/StressDisposeTestDriver.cs").new()
	var midi:=ProjectSettings.globalize_path("res://tests/fixtures/midi-reference.mid")
	var ok: bool=driver.RunRuby("Audio.bgm_play("+JSON.stringify(midi)+",20)")
	var before: bool=driver.HasMidiPlayback()
	game.queue_free()
	for frame in range(6):
		await process_frame
	var after: bool=driver.HasMidiPlayback()
	print("MIDI_SHUTDOWN:%s->%s" % [before,after])
	if not before or after:
		push_error("Runtime shutdown did not release active MIDI playback")
		ok=false
	print("MIDI_SHUTDOWN_PASS" if ok else "MIDI_SHUTDOWN_FAIL")
	quit(0 if ok else 1)
