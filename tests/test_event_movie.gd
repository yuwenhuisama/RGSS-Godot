extends SceneTree

const TestPaths = preload("res://tools/test_paths.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	Engine.max_fps = 60
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	TestPaths.required("game_project")
	root.add_child(load("res://Scenes/Boot.tscn").instantiate())
	for frame in range(180):
		await process_frame
		await RenderingServer.frame_post_draw
	var output := TestPaths.output()
	var code := "$rgss_compat_output=" + JSON.stringify(output) + "\n$event_movie_name=" + JSON.stringify(TestPaths.fixture("movie-reference.ogv")) + "\n$event_movie_fiber=Fiber.new do\n" + TestPaths.ruby_setup() + FileAccess.get_file_as_string(TestPaths.fixture("event_movie_reference.rb")) + "\nend"
	var ok: bool = driver.RunRuby(code)
	for frame in range(180):
		driver.UpdateRenderManager()
		ok = driver.RunRuby("$event_movie_fiber.resume if $event_movie_fiber.alive?") and ok
		await process_frame
	ok = driver.RunRuby("raise 'event movie unfinished' if $event_movie_fiber.alive?; raise 'event movie player retained' if Unity::Graphics.movie_playing?") and ok
	if ok:
		var actual := FileAccess.get_file_as_string(output.path_join("event_movie_reference.tsv")).replace("\r\n", "\n")
		ok = actual == "empty\tbefore\ttrue\nempty\tafter\tfalse\nmovie\tbefore\ttrue\nmovie\tafter\tfalse\n"
	print("EVENT_MOVIE_PASS" if ok else "EVENT_MOVIE_FAIL")
	quit(0 if ok else 1)
