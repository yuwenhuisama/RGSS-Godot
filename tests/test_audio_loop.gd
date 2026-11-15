extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	Engine.max_fps = 60
	var host := Node.new()
	root.add_child(host)
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	driver.Initialize(host)
	var audio_driver = load("res://Scripts/AudioFormatTestDriver.cs").new()
	audio_driver.Initialize(host)
	var ok: bool = driver.RunRuby("require 'audio'")
	var capture := AudioEffectCapture.new()
	capture.buffer_length = 1.0
	AudioServer.add_bus_effect(0,capture)
	for extension in ["wav","ogg","mp3","wma"]:
		var tone := ProjectSettings.globalize_path("res://tests/fixtures/audio/tone." + extension)
		ok = driver.RunRuby("Audio.bgm_play(" + JSON.stringify(tone) + ",20); Audio.bgs_play(" + JSON.stringify(tone) + ",20)") and ok
		for frame in range(54):
			await process_frame
		capture.clear_buffer()
		for frame in range(12):
			await process_frame
		var samples := capture.get_buffer(capture.get_frames_available())
		var energy := 0.0
		for sample in samples:
			energy += sample.length_squared()
		var rms := sqrt(energy / maxf(1,samples.size()*2))
		print("AUDIO_LOOP_PCM:%s:%f" % [extension,rms])
		if rms < 0.002:
			push_error("Looping %s did not produce PCM beyond source end" % extension)
			ok = false
		for channel in ["BGM","BGS"]:
			var player: AudioStreamPlayer = host.get_node(channel)
			print("AUDIO_LOOP:%s:%s:%s" % [extension,channel,player.playing])
			if not player.playing:
				push_error("%s %s ended instead of looping" % [extension,channel])
				ok = false
		ok = driver.RunRuby("Audio.bgm_stop; Audio.bgs_stop") and ok
	var replacement := ProjectSettings.globalize_path("res://tests/fixtures/audio/tone.ogg")
	ok = driver.RunRuby("Audio.bgm_play(" + JSON.stringify(replacement) + ",20); Audio.bgm_fade(500)") and ok
	for frame in range(6):
		await process_frame
	ok = driver.RunRuby("Audio.bgm_stop; Audio.bgm_play(" + JSON.stringify(replacement) + ",20)") and ok
	for frame in range(42):
		await process_frame
	if not host.get_node("BGM").playing:
		push_error("An obsolete fade stopped the replacement BGM")
		ok = false
	ok = driver.RunRuby("Audio.bgm_stop") and ok
	for channel in ["bgm","bgs"]:
		ok = driver.RunRuby("Audio."+channel+"_play("+JSON.stringify(replacement)+",20)") and ok
		for frame in range(6):
			await process_frame
		capture.clear_buffer()
		for frame in range(9):
			await process_frame
		var full := _rms(capture.get_buffer(capture.get_frames_available()))
		ok = driver.RunRuby("Audio."+channel+"_fade(2000)") and ok
		for frame in range(54):
			await process_frame
		capture.clear_buffer()
		for frame in range(9):
			await process_frame
		var fading := _rms(capture.get_buffer(capture.get_frames_available()))
		for frame in range(84):
			await process_frame
		capture.clear_buffer()
		for frame in range(9):
			await process_frame
		var silent := _rms(capture.get_buffer(capture.get_frames_available()))
		print("AUDIO_FADE_PCM:%s:%f:%f:%f" % [channel,full,fading,silent])
		if full < 0.002 or fading < full*0.6 or fading > full*0.8 or silent > 0.00001 or host.get_node(channel.to_upper()).playing:
			push_error("%s fade did not reduce actual PCM and finish silent" % channel)
			ok = false
	AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
	audio_driver.Shutdown()
	driver.Shutdown()
	for frame in range(6):
		await process_frame
	print("AUDIO_LOOP_PASS" if ok else "AUDIO_LOOP_FAIL")
	quit(0 if ok else 1)

func _rms(samples: PackedVector2Array) -> float:
	var energy := 0.0
	for sample in samples:
		energy += sample.length_squared()
	return sqrt(energy / maxf(1,samples.size()*2))
