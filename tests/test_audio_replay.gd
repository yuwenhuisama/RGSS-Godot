extends SceneTree

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
	var output := ProjectSettings.globalize_path("res://.omo/evidence/rmva-compatibility/godot/audio-replay")
	DirAccess.make_dir_recursive_absolute(output)
	var path := output.path_join("audio_replay_reference.tsv")
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var tone := ProjectSettings.globalize_path("res://tests/fixtures/audio/tone.ogg")
	var code := "require 'graphics'; require 'audio'; $audio_replay_host=true; $audio_replay_tone=" + JSON.stringify(tone) + "; $rgss_compat_output=" + JSON.stringify(output) + "; $audio_replay_probe=Fiber.new do\n" + FileAccess.get_file_as_string("res://tests/fixtures/audio_replay_reference.rb") + "\nend"
	var ok: bool = driver.RunRuby(code)
	for frame in range(228):
		ok = driver.RunRuby("$audio_replay_probe.resume if $audio_replay_probe.alive?") and ok
		await process_frame
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
	ok = driver.RunRuby("raise 'audio replay probe unfinished' if $audio_replay_probe.alive?") and ok
	var text := FileAccess.get_file_as_string(path).replace("\r\n", "\n").strip_edges()
	print(text)
	var rows := text.split("\n")
	if rows.size() != 10:
		ok = false
	else:
		var initial := float(rows[0].split("\t")[1])
		var same_file := float(rows[1].split("\t")[1])
		if initial <= 0 or same_file < initial:
			push_error("Same-file volume change rewound BGM")
			ok = false
		if float(rows[2].split("\t")[1]) <= same_file:
			push_error("Same-file BGM did not continue")
			ok = false
		if float(rows[3].split("\t")[1]) < float(rows[2].split("\t")[1]):
			push_error("Active same-file BGM honored a seek that original ignores")
			ok = false
		if float(rows[4].split("\t")[1]) >= float(rows[3].split("\t")[1]):
			push_error("Same-file pitch change did not restart BGM as original does")
			ok = false
		if float(rows[6].split("\t")[2]) < float(rows[5].split("\t")[2]):
			push_error("Same-file volume change rewound BGS")
			ok = false
		if host.get_node("BGM").playing or host.get_node("BGS").playing:
			push_error("Audio stop/fade left a player active")
			ok = false
	var replacement := FileAccess.get_file_as_string(output.path_join("audio_fade_replace_reference.tsv")).strip_edges()
	print("FADE_REPLACEMENT_RESULT:" + replacement)
	if replacement != "replacement-advances\ttrue":
		push_error("Fade replacement differs from original advancing playback")
		ok = false
	var zero_fade := FileAccess.get_file_as_string(output.path_join("audio_zero_fade_reference.tsv")).replace("\r\n","\n").strip_edges()
	print("ZERO_FADE_RESULT:" + zero_fade)
	if zero_fade != "bgm\tzero-fade-advances\ttrue\nbgs\tzero-fade-advances\ttrue":
		push_error("Zero-length fade does not preserve original advancing playback")
		ok = false
	print("AUDIO_REPLAY_PASS" if ok else "AUDIO_REPLAY_FAIL")
	audio_driver.Shutdown()
	driver.Shutdown()
	quit(0 if ok else 1)
