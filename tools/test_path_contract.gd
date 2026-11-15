extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var paths = load("res://tools/test_paths.gd")
	if "--missing" in OS.get_cmdline_user_args():
		paths.required("game_project")
		return
	var expected := ProjectSettings.globalize_path("res://tests/fixtures/audio/tone.ogg")
	if paths.fixture("audio/tone.ogg") != expected:
		push_error("Fixture path must derive from the active checkout")
		quit(1)
		return
	var configured: String = paths.required("game_project")
	if not FileAccess.file_exists(configured.path_join("Data/Map001.rvdata2")):
		push_error("Configured game_project does not contain the required map input")
		quit(1)
		return
	var directory: String = paths.output("path-contract")
	if not DirAccess.dir_exists_absolute(directory):
		quit(1)
		return
	print("TEST_PATH_CONFIG_PASS")
	quit(0)
