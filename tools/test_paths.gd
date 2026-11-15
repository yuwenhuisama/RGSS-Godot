extends RefCounted

static func repo(relative: String = "") -> String:
	return ProjectSettings.globalize_path("res://".path_join(relative))
static func fixture(relative: String) -> String:
	return repo("tests/fixtures".path_join(relative))
static func config_file() -> String:
	var override := OS.get_environment("RGSS_TEST_PATHS_FILE")
	return override if not override.is_empty() else repo(".test-paths.local.json")
static func values() -> Dictionary:
	if not FileAccess.file_exists(config_file()): return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(config_file()).trim_prefix("\ufeff"))
	if not parsed is Dictionary:
		_fail("Invalid test path config: " + config_file())
		return {}
	return parsed
static func required(key: String) -> String:
	var value = values().get(key, "")
	if not value is String or value.strip_edges().is_empty():
		_fail("Missing test setting '%s' in %s. Copy .test-paths.example.json and configure this input." % [key, config_file()])
		return ""
	return value if value.is_absolute_path() else config_file().get_base_dir().path_join(value)
static func output(relative: String = "") -> String:
	var result := repo(".omo/evidence/rmva-compatibility/godot".path_join(relative))
	if DirAccess.make_dir_recursive_absolute(result) != OK:
		_fail("Cannot create test output: " + result)
	return result
static func _fail(message: String) -> void:
	push_error(message)
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null: tree.quit(1)
static func ruby_setup() -> String:
	var settings := values()
	var code := "$test_repo_root=" + JSON.stringify(repo()) + ";"
	for entry in [["game_project", "$test_game_project"], ["rtp", "$test_rtp_path"]]:
		if settings.has(entry[0]) and not str(settings[entry[0]]).is_empty():
			code += entry[1] + "=" + JSON.stringify(required(entry[0])) + ";"
	return code + FileAccess.get_file_as_string(fixture("test_paths.rb")) + "\n"
