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
	var output := TestPaths.output("battle-damage")
	DirAccess.make_dir_recursive_absolute(output)
	var path := output.path_join("battle_damage_reference.tsv")
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var code := "$battle_damage_host=true; $rgss_compat_output=" + JSON.stringify(output) + "; DataManager.setup_new_game\n" + TestPaths.ruby_setup() + FileAccess.get_file_as_string(TestPaths.fixture("battle_damage_reference.rb"))
	var ok: bool = driver.RunRuby(code)
	var actual := FileAccess.get_file_as_string(path).replace("\r\n","\n").strip_edges()
	ok = actual.sha256_text()=="2a4ca1c7c70eef25b7c76a501e41d865b1db7518e52e71b08006134fbfa8eebf" and ok
	var hit_actual := FileAccess.get_file_as_string(output.path_join("battle_hit_reference.tsv")).replace("\r\n","\n").strip_edges()
	var hit_original := FileAccess.get_file_as_string(TestPaths.fixture("battle_hit_original.tsv")).replace("\r\n","\n").strip_edges()
	ok = not hit_original.is_empty() and hit_actual==hit_original and ok
	var state_actual := FileAccess.get_file_as_string(output.path_join("battle_state_reference.tsv")).replace("\r\n","\n").strip_edges()
	var state_original := FileAccess.get_file_as_string(TestPaths.fixture("battle_state_original.tsv")).replace("\r\n","\n").strip_edges()
	ok = not state_original.is_empty() and state_actual==state_original and ok
	var edges_actual := FileAccess.get_file_as_string(output.path_join("battle_damage_edges_reference.tsv")).replace("\r\n","\n").strip_edges()
	var edges_original := FileAccess.get_file_as_string(TestPaths.fixture("battle_damage_edges_original.tsv")).strip_edges()
	ok = not edges_original.is_empty() and edges_actual==edges_original and ok
	print("BATTLE_DAMAGE_PASS" if ok else "BATTLE_DAMAGE_FAIL")
	quit(0 if ok else 1)
