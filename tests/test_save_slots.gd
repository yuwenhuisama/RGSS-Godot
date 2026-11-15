extends SceneTree

func frames(count: int) -> void:
	for frame in range(count):
		await process_frame
		await RenderingServer.frame_post_draw

func tap(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await frames(2)
	await frames(12)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	root.add_child(load("res://Scenes/Boot.tscn").instantiate())
	for frame in range(180):
		await process_frame
		await RenderingServer.frame_post_draw
	var from_title := "--from-title" in OS.get_cmdline_user_args()
	if from_title and not "--ui" in OS.get_cmdline_user_args():
		push_error("Title project flow requires --ui for save/load acceptance")
		quit(1)
		return
	var ok := true
	if from_title:
		ok = driver.RunRuby("raise 'title not ready' unless SceneManager.scene.is_a?(Scene_Title); command=SceneManager.scene.instance_variable_get(:@command_window); raise 'title commands inactive' unless command.active; command.select_symbol(:new_game)") and ok
		await tap(KEY_ENTER)
		await frames(180)
		ok = driver.RunRuby("raise 'title New Game did not enter map' unless SceneManager.scene.is_a?(Scene_Map)") and ok
		await tap(KEY_ESCAPE)
		await frames(90)
		ok = driver.RunRuby("raise 'map menu input failed' unless SceneManager.scene.is_a?(Scene_Menu)") and ok
		await tap(KEY_ESCAPE)
		await frames(90)
		ok = driver.RunRuby("raise 'menu cancel did not resume map' unless SceneManager.scene.is_a?(Scene_Map)") and ok
		var flow_output := ProjectSettings.globalize_path("res://.omo/evidence/rmva-compatibility/godot/project-flow")
		DirAccess.make_dir_recursive_absolute(flow_output)
		# The event list enters the stock battle scene and resumes after victory.
		ok = driver.RunRuby("""
$flow_saved_events=$game_map.events.dup
$flow_saved_position=[$game_player.x,$game_player.y,$game_player.direction]
$flow_saved_attack=[$data_skills[1].hit_type,$data_skills[1].success_rate,$data_skills[1].damage.formula,$data_skills[1].damage.variance,$data_skills[1].damage.critical]
$data_skills[1].hit_type=0; $data_skills[1].success_rate=100; $data_skills[1].damage.formula='99999'; $data_skills[1].damage.variance=0; $data_skills[1].damage.critical=false
troop=RPG::Troop.new; troop.id=$data_troops.size
member=RPG::Troop::Member.new; member.enemy_id=1; member.x=272; member.y=240
troop.members=[member]; $data_troops << troop
$flow_variable=$data_system.variables.size; $data_system.variables << 'Project flow completion'
data=RPG::Event.new(6,5); data.id=9001
page=data.pages[0]; page.priority_type=1; page.trigger=0
page.list=[RPG::EventCommand.new(101,0,['',0,0,2]),RPG::EventCommand.new(401,0,['\\>Compatibility battle']),RPG::EventCommand.new(301,0,[0,troop.id,false,false]),RPG::EventCommand.new(122,0,[$flow_variable,$flow_variable,0,0,77]),RPG::EventCommand.new]
$game_map.events.clear; $game_map.events[data.id]=Game_Event.new($game_map.map_id,data)
$game_player.moveto(5,5); $game_player.set_direction(6)
"""
		) and ok
		await frames(15)
		await tap(KEY_ENTER)
		await frames(60)
		ok = driver.RunRuby("raise 'project event did not block at message' unless $game_message.busy? && $game_map.interpreter.running? && $game_variables[$flow_variable]==0") and ok
		root.get_texture().get_image().save_png(flow_output.path_join("map-message.png"))
		await tap(KEY_ENTER)
		await frames(90)
		ok = driver.RunRuby("raise 'project event did not enter battle' unless SceneManager.scene.is_a?(Scene_Battle); $game_map.events[9001].erase; $flow_battle_gold=$game_party.gold") and ok
		for acknowledgment in range(6):
			var busy_path := flow_output.path_join("battle-message.txt")
			ok = driver.RunRuby("File.open(%s,'w') { |file| file.write($game_message.busy? ? 'busy' : 'idle') }" % JSON.stringify(busy_path)) and ok
			if FileAccess.get_file_as_string(busy_path) != "busy":
				break
			await tap(KEY_ENTER)
			await frames(20)
		ok = driver.RunRuby("raise 'project party commands inactive' unless SceneManager.scene.instance_variable_get(:@party_command_window).active") and ok
		await tap(KEY_ENTER)
		ok = driver.RunRuby("raise 'project actor commands inactive' unless BattleManager.actor && SceneManager.scene.instance_variable_get(:@actor_command_window).active") and ok
		await tap(KEY_ENTER)
		ok = driver.RunRuby("raise 'project battle target inactive' unless SceneManager.scene.instance_variable_get(:@enemy_window).active; $flow_battle_reward=$game_troop.members.inject(0) { |sum,enemy| sum+enemy.gold }") and ok
		root.get_texture().get_image().save_png(flow_output.path_join("battle-target.png"))
		await tap(KEY_ENTER)
		await frames(180)
		for acknowledgment in range(12):
			await tap(KEY_ENTER)
		await frames(120)
		ok = driver.RunRuby("raise 'project battle did not resume event on map' unless SceneManager.scene.is_a?(Scene_Map) && !$game_party.in_battle && !$game_map.interpreter.running? && $game_variables[$flow_variable]==77; raise 'project victory reward lost' unless $game_party.gold==$flow_battle_gold+$flow_battle_reward; $game_map.events.clear; $flow_saved_events.each { |id,event| $game_map.events[id]=event }; $game_player.moveto($flow_saved_position[0],$flow_saved_position[1]); $game_player.set_direction($flow_saved_position[2]); $data_skills[1].hit_type,$data_skills[1].success_rate,$data_skills[1].damage.formula,$data_skills[1].damage.variance,$data_skills[1].damage.critical=*$flow_saved_attack; $data_troops.pop; $data_system.variables.pop; $game_variables[$flow_variable]=0") and ok
		await frames(90)
		root.get_texture().get_image().save_png(flow_output.path_join("returned-map.png"))
		if not ok:
			print("TITLE_SAVE_FLOW_FAIL")
			quit(1)
			return
	var output := ProjectSettings.globalize_path("res://.omo/evidence/rmva-compatibility/godot/save-slots")
	if from_title:
		output = ProjectSettings.globalize_path("res://.omo/evidence/rmva-compatibility/godot/project-flow/save-slots")
	DirAccess.make_dir_recursive_absolute(output)
	var code := ("" if from_title else "DataManager.setup_new_game; ") + "$save_slots_host=true; $rgss_compat_output=" + JSON.stringify(output) + "\n" + FileAccess.get_file_as_string("res://tests/fixtures/save_slots_reference.rb")
	if from_title:
		ok = driver.RunRuby("File.open(%s,'w') { |file| ([$game_player]+$game_map.events.values.to_a).each { |character| file.puts([character.class,character.pattern,character.pattern.class,character.blend_type,character.blend_type.class].join('\t')) } }" % JSON.stringify(output.path_join("character-types-before.txt"))) and ok
	ok = driver.RunRuby(code) and ok
	if from_title:
		ok = driver.RunRuby("File.open(%s,'w') { |file| ([$game_player]+$game_map.events.values.to_a).each { |character| file.puts([character.class,character.pattern,character.pattern.class,character.blend_type,character.blend_type.class].join('\t')) } }" % JSON.stringify(output.path_join("character-types-after.txt"))) and ok
	var text := FileAccess.get_file_as_string(output.path_join("save_slots_reference.tsv")).replace("\r\n", "\n").strip_edges()
	print(text)
	ok = text.sha256_text() == "623738bdb543603ba172b1d9e0f0bf8fcbc2edefe9eb7cc395bf7f4ecf9483a2" and ok
	if "--ui" in OS.get_cmdline_user_args():
		ok = driver.RunRuby("SceneManager.goto(Scene_Map)") and ok
		await frames(120)
		var baseline := Vector3i(driver.GetViewportCount(), driver.GetSpriteCount(), driver.GetWindowCount())
		ok = driver.RunRuby("$game_variables[1]=444; SceneManager.call(Scene_Save)") and ok
		await frames(90)
		ok = driver.RunRuby("raise 'save list not16' unless SceneManager.scene.is_a?(Scene_Save) && SceneManager.scene.instance_variable_get(:@savefile_windows).size==16; raise 'save slot selection' unless SceneManager.scene.index==0") and ok
		root.get_texture().get_image().save_png(output.path_join("save-list.png"))
		await tap(KEY_ENTER)
		await frames(90)
		ok = driver.RunRuby("raise 'save UI did not return map' unless SceneManager.scene.is_a?(Scene_Map); $game_variables[1]=555; File.open(DataManager.make_filename(1),'wb') { |file| file.write('broken') }; SceneManager.call(Scene_Load)") and ok
		await frames(90)
		var index_path := output.path_join("load-index.txt")
		ok = driver.RunRuby("File.open(%s,'w') { |file| file.write(SceneManager.scene.index.to_s) }" % JSON.stringify(index_path)) and ok
		var start_index := int(FileAccess.get_file_as_string(index_path))
		for step in range(absi(1 - start_index)):
			await tap(KEY_DOWN if start_index < 1 else KEY_UP)
		ok = driver.RunRuby("raise 'bad slot not selected' unless SceneManager.scene.index==1") and ok
		await tap(KEY_ENTER)
		ok = driver.RunRuby("raise 'bad slot left load UI' unless SceneManager.scene.is_a?(Scene_Load) && $game_variables[1]==555") and ok
		root.get_texture().get_image().save_png(output.path_join("load-corrupt.png"))
		await tap(KEY_UP)
		await tap(KEY_ENTER)
		await frames(180)
		ok = driver.RunRuby("raise 'valid slot not loaded' unless SceneManager.scene.is_a?(Scene_Map) && $game_variables[1]==444; DataManager.delete_save_file(1)") and ok
		var returned := Vector3i(driver.GetViewportCount(), driver.GetSpriteCount(), driver.GetWindowCount())
		print("SAVE_UI_RESOURCES:baseline=%s:returned=%s" % [baseline, returned])
		if returned != baseline:
			push_error("Save/load UI did not restore map resources")
			ok = false
		# Repeat real cancel/return paths in the same VM to expose retained scenes.
		for cycle in range(3):
			for scene in ["Scene_Save", "Scene_Load"]:
				ok = driver.RunRuby("SceneManager.call(%s)" % scene) and ok
				await frames(90)
				ok = driver.RunRuby("raise 'cancel target scene' unless SceneManager.scene.is_a?(%s)" % scene) and ok
				await tap(KEY_ESCAPE)
				await frames(90)
				ok = driver.RunRuby("raise 'cancel did not return map' unless SceneManager.scene.is_a?(Scene_Map); raise 'cancel changed loaded variable' unless $game_variables[1]==444") and ok
				var cancelled := Vector3i(driver.GetViewportCount(), driver.GetSpriteCount(), driver.GetWindowCount())
				print("SAVE_CANCEL_RESOURCES:cycle=%d:scene=%s:baseline=%s:returned=%s" % [cycle, scene, baseline, cancelled])
				if cancelled != baseline:
					push_error("Repeated save/load cancel retained map resources")
					ok = false
	if from_title:
		ok = driver.RunRuby("raise 'project victory gold not retained through save/load' unless $game_party.gold==$flow_battle_gold+$flow_battle_reward") and ok
		print("TITLE_SAVE_FLOW_PASS" if ok else "TITLE_SAVE_FLOW_FAIL")
	print("SAVE_SLOTS_PASS" if ok else "SAVE_SLOTS_FAIL")
	quit(0 if ok else 1)
