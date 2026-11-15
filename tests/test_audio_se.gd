extends SceneTree

# Public Ruby SE playback measured at the real mixer, rather than pool internals.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	Engine.max_fps = 60
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	driver.Initialize(host)
	var audio_driver = load("res://Scripts/AudioFormatTestDriver.cs").new()
	audio_driver.Initialize(host)
	var capture := AudioEffectCapture.new()
	capture.buffer_length = 1.0
	AudioServer.add_bus_effect(0, capture)
	var tone := ProjectSettings.globalize_path("res://tests/fixtures/audio/tone.wav")
	var ok: bool = driver.RunRuby("require 'audio'; Audio.se_play(" + JSON.stringify(tone) + ",20,100); Audio.se_play(" + JSON.stringify(tone) + ",20,150)")
	for frame in range(12):
		await process_frame
	var samples := capture.get_buffer(capture.get_frames_available())
	var low := _amplitude(samples, 440)
	var high := _amplitude(samples, 660)
	print("SE_MIX:%d:440=%f:660=%f" % [samples.size(),low,high])
	if low < 0.002 or high < 0.002:
		push_error("Two SE pitches did not coexist in the mixer")
		ok = false
	ok = driver.RunRuby("Audio.se_stop") and ok
	for frame in range(6):
		await process_frame
	capture.clear_buffer()
	for frame in range(6):
		await process_frame
	var stopped := capture.get_buffer(capture.get_frames_available())
	var peak := 0.0
	for sample in stopped:
		peak = maxf(peak, maxf(absf(sample.x),absf(sample.y)))
	if stopped.is_empty() or peak > 0.00001:
		push_error("SE stop did not silence all simultaneous voices: %f" % peak)
		ok = false
	var rtp_request: String = audio_driver.GetProjectAudioDir().path_join("SE/Absorb1.ogg")
	# RGSS300 retains all 17 distinct pitches; a busy eight-player pool must grow.
	capture.clear_buffer()
	ok = driver.RunRuby("17.times { |i| Audio.se_play(" + JSON.stringify(tone) + ",10,50+i*5) }") and ok
	for frame in range(12):
		await process_frame
	var voices := capture.get_buffer(capture.get_frames_available())
	for index in range(17):
		var frequency := 220 + 22 * index
		var amplitude := _amplitude(voices, frequency)
		print("SE_CAPACITY:%d:%f" % [frequency, amplitude])
		if amplitude < 0.001:
			push_error("SE voice was cut off at frequency %d" % frequency)
			ok = false
	ok = driver.RunRuby("Audio.se_stop") and ok
	for frame in range(6):
		await process_frame
	capture.clear_buffer()
	if FileAccess.file_exists(rtp_request):
		push_error("RTP-only SE precondition broken: project Absorb1 exists")
		ok = false
	ok = driver.RunRuby("Audio.se_play(" + JSON.stringify(rtp_request) + ",20,100)") and ok
	for frame in range(12):
		await process_frame
	var rtp_samples := capture.get_buffer(capture.get_frames_available())
	var rtp_peak := 0.0
	for sample in rtp_samples:
		rtp_peak = maxf(rtp_peak,absf(sample.x))
	if rtp_peak < 0.002:
		push_error("RTP-only SE did not produce mixer PCM")
		ok = false
	print("SE_RTP_PCM:%f" % rtp_peak)
	ok = driver.RunRuby("Audio.se_stop; Audio.se_play(" + JSON.stringify(tone) + ",20,100)") and ok
	for frame in range(48):
		await process_frame
	capture.clear_buffer()
	for frame in range(6):
		await process_frame
	var ended := capture.get_buffer(capture.get_frames_available())
	for sample in ended:
		if absf(sample.x) > 0.00001 or absf(sample.y) > 0.00001:
			push_error("SE continued after the finite WAV ended")
			ok = false
			break
	if ended.is_empty():
		ok = false
	audio_driver.Shutdown()
	for frame in range(6):
		await process_frame
	audio_driver.Initialize(host)
	capture.clear_buffer()
	ok = driver.RunRuby("Audio.se_play(" + JSON.stringify(tone) + ",20,100)") and ok
	for frame in range(12):
		await process_frame
	var restarted := capture.get_buffer(capture.get_frames_available())
	if _amplitude(restarted,440) < 0.002:
		push_error("SE mixer did not recover after audio manager disposal/reinitialization")
		ok = false
	ok = driver.RunRuby("Audio.se_stop") and ok
	AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
	audio_driver.Shutdown()
	driver.Shutdown()
	for frame in range(6):
		await process_frame
	print("AUDIO_SE_PASS" if ok else "AUDIO_SE_FAIL")
	quit(0 if ok else 1)

func _amplitude(samples: PackedVector2Array, frequency: float) -> float:
	if samples.is_empty():
		return 0.0
	var real := 0.0
	var imaginary := 0.0
	var rate := AudioServer.get_mix_rate()
	for index in range(samples.size()):
		var phase := TAU * frequency * index / rate
		real += samples[index].x * cos(phase)
		imaginary += samples[index].x * sin(phase)
	return 2.0 * sqrt(real*real + imaginary*imaginary) / samples.size()
