extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	Engine.max_fps = 60
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	driver.Initialize(host)
	var movie := ProjectSettings.globalize_path("res://tests/fixtures/movie-reference.ogv")
	if "--wide" in OS.get_cmdline_user_args():
		movie = ProjectSettings.globalize_path("res://tests/fixtures/movie-reference-wide.ogv")
	var ok: bool = driver.RunRuby("require 'graphics'; $movie_returned=false; $movie_fiber=Fiber.new { Graphics.play_movie(" + JSON.stringify(movie) + "); $movie_returned=true }")
	ok = driver.RunRuby("$movie_fiber.resume") and ok
	ok = driver.RunRuby("raise 'movie must wait' if $movie_returned") and ok
	for i in range(15):
		driver.UpdateRenderManager()
		driver.RunRuby("$movie_fiber.resume if $movie_fiber.alive?")
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://movie-playing-wide.png" if "--wide" in OS.get_cmdline_user_args() else "user://movie-playing.png")
	for i in range(120):
		driver.UpdateRenderManager()
		driver.RunRuby("$movie_fiber.resume if $movie_fiber.alive?")
		await process_frame
	ok = driver.RunRuby("raise 'movie never returned' unless $movie_returned; raise 'movie layer retained' if Unity::Graphics.movie_playing?") and ok
	ok = driver.RunRuby("$movie_returned=false; $movie_fiber=Fiber.new { Graphics.play_movie(" + JSON.stringify(movie) + "); $movie_returned=true }; $movie_fiber.resume") and ok
	await process_frame
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	driver.RunRuby("$movie_fiber.resume if $movie_fiber.alive?")
	ok = driver.RunRuby("raise 'movie skip did not return' unless $movie_returned") and ok
	ok = not driver.RunRuby("Unity::Graphics.play_movie('CompatibilityMissingMovie.ogv')") and ok
	ok = driver.RunRuby("raise 'failed movie left active state' if Unity::Graphics.movie_playing?") and ok
	driver.Shutdown()
	print("MOVIE_PLAYBACK_PASS" if ok else "MOVIE_PLAYBACK_FAIL")
	quit(0 if ok else 1)
