extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	Engine.max_fps=60
	var host:=Node.new()
	root.add_child(host)
	var driver=load("res://Scripts/StressDisposeTestDriver.cs").new()
	driver.Initialize(host)
	var audio=load("res://Scripts/AudioFormatTestDriver.cs").new()
	audio.Initialize(host)
	var output:=ProjectSettings.globalize_path("res://.omo/evidence/rmva-compatibility/godot/audio-loop-tags")
	DirAccess.make_dir_recursive_absolute(output)
	var code:="$audio_loop_tags_host=true; $rgss_compat_output="+JSON.stringify(output)+"; require 'audio'; require 'graphics'; $loop_tags=Fiber.new do\n"+FileAccess.get_file_as_string("res://tests/fixtures/audio_loop_tags_reference.rb")+"\nend"
	var ok: bool=driver.RunRuby(code)
	for frame in range(302):
		ok=driver.RunRuby("$loop_tags.resume if $loop_tags.alive?") and ok
		await process_frame
	ok=driver.RunRuby("raise 'loop tags unfinished' if $loop_tags.alive?") and ok
	var text:=FileAccess.get_file_as_string(output.path_join("audio_loop_tags_reference.tsv")).strip_edges()
	print(text)
	for row in text.split("\n"):
		var fields:=row.split("\t")
		if fields.size()!=2 or float(fields[1]) < 15000 or float(fields[1]) >= 30000:
			push_error("Tagged OGG position differs from original full-source loop at150 frames")
			ok=false
	if text.split("\n").size()!=2:
		ok=false
	audio.Shutdown()
	driver.Shutdown()
	print("AUDIO_LOOP_TAGS_PASS" if ok else "AUDIO_LOOP_TAGS_FAIL")
	quit(0 if ok else 1)
