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
	var output := TestPaths.output("save-interchange")
	DirAccess.make_dir_recursive_absolute(output)
	var peer := TestPaths.fixture("save_interchange_original.rvdata2")
	var code := "DataManager.setup_new_game; $save_interchange_host=true; $save_interchange_peer=" + JSON.stringify(peer) + "; $rgss_compat_output=" + JSON.stringify(output) + "\n" + TestPaths.ruby_setup() + FileAccess.get_file_as_string(TestPaths.fixture("save_interchange_reference.rb"))
	var ok: bool = driver.RunRuby(code)
	var text := FileAccess.get_file_as_string(output.path_join("save_interchange_reference.tsv")).strip_edges()
	print(text)
	var expected := FileAccess.get_file_as_string(TestPaths.fixture("save_interchange_original.tsv")).replace("\r\n", "\n").strip_edges()
	ok = text.replace("\r\n", "\n") == expected and not expected.is_empty() and ok
	ok = driver.RunRuby("raise 'save variable' unless $game_variables[1]==31415; raise 'save switches' unless $game_switches[1] && $game_self_switches[[1,1,'A']]; raise 'save actor identity' unless $game_party.members[0].equal?($game_actors[1]) && $game_actors[1].name=='Save actor'; raise 'save player' unless $game_player.x==3 && $game_player.y==4; raise 'save inventory' unless $game_party.gold==123 && $game_party.item_number($data_items[1])==3") and ok
	ok = driver.RunRuby("SceneManager.goto(Scene_Map)") and ok
	for frame in range(180):
		await process_frame
		await RenderingServer.frame_post_draw
	ok = driver.RunRuby("raise 'loaded save scene not running' unless SceneManager.scene.is_a?(Scene_Map); raise 'loaded save state changed' unless $game_variables[1]==31415 && $game_party.gold==123 && $game_party.item_number($data_items[1])==3; raise 'loaded save actor link changed' unless $game_party.members[0].equal?($game_actors[1])") and ok
	root.get_texture().get_image().save_png(output.path_join("resumed-map.png"))
	print("SAVE_INTERCHANGE_PASS" if ok else "SAVE_INTERCHANGE_FAIL")
	quit(0 if ok else 1)
