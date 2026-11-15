extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	root.add_child(load("res://Scenes/Boot.tscn").instantiate())
	for frame in range(180):
		await process_frame
		await RenderingServer.frame_post_draw
	var output := ProjectSettings.globalize_path("res://.omo/evidence/rmva-compatibility/godot/battle-schedule")
	DirAccess.make_dir_recursive_absolute(output)
	var path := output.path_join("battle_schedule_reference.tsv")
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var code := "$battle_schedule_host=true; $rgss_compat_output=" + JSON.stringify(output) + "; DataManager.setup_new_game\n" + FileAccess.get_file_as_string("res://tests/fixtures/battle_schedule_reference.rb")
	var ok: bool = driver.RunRuby(code)
	var actual := FileAccess.get_file_as_string(path).replace("\r\n","\n").strip_edges()
	ok = actual.sha256_text()=="71fa45775eea9e0906662672c426dd268c812aea8671ba71e9fcf3bbac34f8a5" and ok
	var conditions_actual := FileAccess.get_file_as_string(output.path_join("battle_page_conditions.tsv")).replace("\r\n","\n").strip_edges()
	var conditions_original := FileAccess.get_file_as_string("res://tests/fixtures/battle_page_conditions_original.tsv").replace("\r\n","\n").strip_edges()
	ok = not conditions_original.is_empty() and conditions_actual==conditions_original and ok
	var order_actual := FileAccess.get_file_as_string(output.path_join("battle_order_reference.tsv")).replace("\r\n","\n").strip_edges()
	var order_original := FileAccess.get_file_as_string("res://tests/fixtures/battle_order_original.tsv").replace("\r\n","\n").strip_edges()
	ok = not order_original.is_empty() and order_actual==order_original and ok
	print("BATTLE_SCHEDULE_PASS" if ok else "BATTLE_SCHEDULE_FAIL")
	quit(0 if ok else 1)
