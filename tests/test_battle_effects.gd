extends SceneTree

const TestPaths = preload("res://tools/test_paths.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	TestPaths.required("game_project")
	root.add_child(load("res://Scenes/Boot.tscn").instantiate())
	for frame in range(180):
		await process_frame
		await RenderingServer.frame_post_draw
	var output := TestPaths.output("battle-effects")
	DirAccess.make_dir_recursive_absolute(output)
	var path := output.path_join("battle_effect_reference.tsv")
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var code := "$battle_effect_host=true; $rgss_compat_output=" + JSON.stringify(output) + "; DataManager.setup_new_game\n" + TestPaths.ruby_setup() + FileAccess.get_file_as_string(TestPaths.fixture("battle_effect_reference.rb"))
	var ok: bool = driver.RunRuby(code)
	var actual := FileAccess.get_file_as_string(path).replace("\r\n","\n").strip_edges()
	ok = actual.sha256_text()=="27a46fc4d4816bab56e09483f05fdfcced74eed53eb89662cefab9c5d9fe9f43" and ok
	var limits_actual := FileAccess.get_file_as_string(output.path_join("battle_effect_limits.tsv")).replace("\r\n","\n").strip_edges()
	var limits_original := FileAccess.get_file_as_string(TestPaths.fixture("battle_effect_limits_original.tsv")).replace("\r\n","\n").strip_edges()
	ok = not limits_original.is_empty() and limits_actual==limits_original and ok
	var scope_actual := FileAccess.get_file_as_string(output.path_join("battle_scope_reference.tsv")).replace("\r\n","\n").strip_edges()
	var scope_original := FileAccess.get_file_as_string(TestPaths.fixture("battle_scope_original.tsv")).replace("\r\n","\n").strip_edges()
	ok = not scope_original.is_empty() and scope_actual==scope_original and ok
	print("BATTLE_EFFECTS_PASS" if ok else "BATTLE_EFFECTS_FAIL")
	quit(0 if ok else 1)
