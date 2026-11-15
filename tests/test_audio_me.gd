extends SceneTree

const TestPaths = preload("res://tools/test_paths.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	Engine.max_fps = 60
	TestPaths.required("rtp")
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	driver.Initialize(host)
	var audio_driver = load("res://Scripts/AudioFormatTestDriver.cs").new()
	audio_driver.Initialize(host)
	var output := TestPaths.output("audio-me")
	DirAccess.make_dir_recursive_absolute(output)
	var path := output.path_join("audio_me_reference.tsv")
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var bgm: String = TestPaths.required("rtp").path_join("Audio/BGM/Theme1.ogg")
	var me := TestPaths.fixture("audio/tone.ogg")
	var code := "require 'graphics'; require 'audio'; $audio_me_host=true; $audio_me_bgm=" + JSON.stringify(bgm) + "; $audio_me_sound=" + JSON.stringify(me) + "; $rgss_compat_output=" + JSON.stringify(output) + "; $audio_me_probe=Fiber.new do\n" + TestPaths.ruby_setup() + FileAccess.get_file_as_string(TestPaths.fixture("audio_me_reference.rb")) + "\nend"
	var ok: bool = driver.RunRuby(code)
	for frame in range(890):
		ok = driver.RunRuby("$audio_me_probe.resume if $audio_me_probe.alive?") and ok
		await process_frame
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
	ok = driver.RunRuby("raise 'audio ME probe unfinished' if $audio_me_probe.alive?") and ok
	var text := FileAccess.get_file_as_string(path).replace("\r\n", "\n").strip_edges()
	print(text)
	var rows := text.split("\n")
	if rows.size() != 7:
		ok = false
	else:
		var before := float(rows[0].split("\t")[-1])
		var paused := float(rows[1].split("\t")[-1])
		for row in range(2, 4):
			if float(rows[row].split("\t")[-1]) != paused:
				push_error("BGM position advanced while ME played")
				ok = false
		var resumed := float(rows[4].split("\t")[-1])
		var continued := float(rows[5].split("\t")[-1])
		if resumed <= before or continued <= resumed:
			push_error("BGM did not resume from its preserved position after ME")
			ok = false
		if host.get_node("BGM").playing:
			push_error("ME restarted an explicitly stopped BGM")
			ok = false
		if before < 1000 and "--pause-only" not in OS.get_cmdline_user_args():
			push_error("BGM position units differ from original RGSS300")
			ok = false
	var endings := FileAccess.get_file_as_string(output.path_join("audio_me_end_reference.tsv")).strip_edges().split("\n")
	print("ME_ENDINGS:\n" + "\n".join(endings))
	if endings.size() != 4:
		ok = false
	else:
		for row in endings:
			var fields := row.split("\t")
			if fields.size() != 3 or ((fields[0].begins_with("stop") or fields[0] == "fade-late") and float(fields[2]) <= float(fields[1])):
				push_error("BGM did not resume after explicit ME " + fields[0])
				ok = false
	var capture := AudioEffectCapture.new()
	capture.buffer_length = 1.0
	AudioServer.add_bus_effect(0,capture)
	var tone := TestPaths.fixture("audio/tone.wav")
	ok = driver.RunRuby("Audio.bgm_play(" + JSON.stringify(tone) + ",20,100)") and ok
	for frame in range(12):
		await process_frame
	capture.clear_buffer()
	ok = driver.RunRuby("Audio.me_play(" + JSON.stringify(tone) + ",20,150)") and ok
	for frame in range(6):
		await process_frame
	capture.clear_buffer()
	for frame in range(9):
		await process_frame
	var during := capture.get_buffer(capture.get_frames_available())
	var paused_bgm := _amplitude(during,440)
	var active_me := _amplitude(during,660)
	print("ME_PCM_DURING:440=%f:660=%f" % [paused_bgm,active_me])
	if active_me < 0.002 or paused_bgm > active_me*0.1:
		push_error("ME did not replace the audible BGM while active")
		ok = false
	for frame in range(24):
		await process_frame
	capture.clear_buffer()
	for frame in range(12):
		await process_frame
	var after := capture.get_buffer(capture.get_frames_available())
	var resumed_bgm := _amplitude(after,440)
	var ended_me := _amplitude(after,660)
	print("ME_PCM_AFTER:440=%f:660=%f" % [resumed_bgm,ended_me])
	if resumed_bgm < 0.002 or ended_me > resumed_bgm*0.1:
		push_error("BGM audio did not resume after the finite ME ended")
		ok = false
	ok = driver.RunRuby("Audio.bgm_stop; Audio.me_stop") and ok
	AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
	print("AUDIO_ME_PASS" if ok else "AUDIO_ME_FAIL")
	audio_driver.Shutdown()
	driver.Shutdown()
	quit(0 if ok else 1)

func _amplitude(samples: PackedVector2Array, frequency: float) -> float:
	if samples.is_empty():
		return 0.0
	var real := 0.0
	var imaginary := 0.0
	for index in range(samples.size()):
		var phase := TAU * frequency * index / AudioServer.get_mix_rate()
		real += samples[index].x*cos(phase)
		imaginary += samples[index].x*sin(phase)
	return 2*sqrt(real*real+imaginary*imaginary)/samples.size()
