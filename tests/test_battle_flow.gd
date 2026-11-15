extends SceneTree

var driver
var ok := true

func _initialize() -> void:
	call_deferred("_run")

func frames(count: int) -> void:
	for frame in range(count):
		await process_frame
		await RenderingServer.frame_post_draw

func check(code: String) -> void:
	ok = driver.RunRuby(code) and ok

func tap(code: Key) -> void:
	for pressed in [true,false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await frames(2)
	await frames(12)

func _run() -> void:
	driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	root.add_child(load("res://Scenes/Boot.tscn").instantiate())
	await frames(180)
	if "--manager" in OS.get_cmdline_user_args():
		var manager_output := ProjectSettings.globalize_path("res://.omo/evidence/rmva-compatibility/godot/battle-flow")
		DirAccess.make_dir_recursive_absolute(manager_output)
		var manager_path := manager_output.path_join("battle_end_reference.tsv")
		if FileAccess.file_exists(manager_path):
			DirAccess.remove_absolute(manager_path)
		check("$battle_end_host=true; $rgss_compat_output=" + JSON.stringify(manager_output) + "\n" + FileAccess.get_file_as_string("res://tests/fixtures/battle_end_reference.rb"))
		var actual := FileAccess.get_file_as_string(manager_path).replace("\r\n","\n").strip_edges()
		var original := FileAccess.get_file_as_string("res://tests/fixtures/battle_end_original.tsv").replace("\r\n","\n").strip_edges()
		ok = not original.is_empty() and actual==original and ok
		var initiative_actual := FileAccess.get_file_as_string(manager_output.path_join("battle_initiative_reference.tsv")).replace("\r\n","\n").strip_edges()
		var initiative_original := FileAccess.get_file_as_string("res://tests/fixtures/battle_initiative_original.tsv").replace("\r\n","\n").strip_edges()
		ok = not initiative_original.is_empty() and initiative_actual==initiative_original and ok
		check("SceneManager.goto(Scene_Base)")
		print("BATTLE_END_REFERENCE_PASS" if ok else "BATTLE_END_REFERENCE_FAIL")
		quit(0 if ok else 1)
		return
	check("DataManager.setup_new_game; SceneManager.goto(Scene_Map)")
	await frames(180)
	var baseline := Vector3i(driver.GetViewportCount(),driver.GetSpriteCount(),driver.GetWindowCount())
	var output := ProjectSettings.globalize_path("res://.omo/evidence/rmva-compatibility/godot/battle-flow")
	DirAccess.make_dir_recursive_absolute(output)
	check("$battle_flow_saved_count=$game_system.battle_count; $battle_flow_troop=RPG::Troop.new; $battle_flow_troop.id=$data_troops.size; member=RPG::Troop::Member.new; member.enemy_id=1; member.x=272; member.y=240; $battle_flow_troop.members=[member]; $data_troops << $battle_flow_troop; $battle_flow_results=[]")
	for ending in ["escape", "abort", "allowed-defeat", "victory", "failed-escape", "disabled-escape", "gameover"]:
		var can_escape := "false" if ending == "disabled-escape" else "true"
		var can_lose := "false" if ending == "gameover" else "true"
		check("$game_party.battle_members.each { |actor| actor.recover_all }; BattleManager.setup($battle_flow_troop.id,%s,%s); BattleManager.instance_variable_set(:@preemptive,true); BattleManager.save_bgm_and_bgs; BattleManager.event_proc=proc { |result| $battle_flow_results << result }; SceneManager.call(Scene_Battle)" % [can_escape,can_lose])
		await frames(90)
		for acknowledgment in range(6):
			var message_path := output.path_join("message-busy.txt")
			check("File.open(%s,'w') { |file| file.write($game_message.busy? ? 'busy' : 'idle') }" % JSON.stringify(message_path))
			var waiting := FileAccess.get_file_as_string(message_path) == "busy"
			if not waiting:
				break
			await tap(KEY_ENTER)
			await frames(20)
		check("raise 'battle did not start' unless SceneManager.scene.is_a?(Scene_Battle) && $game_party.in_battle; raise 'party commands not ready' unless SceneManager.scene.instance_variable_get(:@party_command_window).active")
		root.get_texture().get_image().save_png(output.path_join(ending + "-battle.png"))
		if ending in ["escape", "failed-escape", "disabled-escape"]:
			if ending == "failed-escape":
				check("BattleManager.instance_variable_set(:@preemptive,false); BattleManager.instance_variable_set(:@escape_ratio,-1.0)")
			check("$battle_flow_before_results=$battle_flow_results.size")
			await tap(KEY_DOWN)
			await tap(KEY_ENTER)
			if ending != "escape":
				await frames(10)
				check("raise 'refused escape left battle' unless SceneManager.scene.is_a?(Scene_Battle) && $game_party.in_battle && $battle_flow_results.size==$battle_flow_before_results")
				if ending == "disabled-escape":
					check("raise 'disabled escape accepted input' unless SceneManager.scene.instance_variable_get(:@party_command_window).active; raise 'escape command enabled' if BattleManager.can_escape?")
				else:
					check("raise 'failed escape ratio did not increase' unless BattleManager.instance_variable_get(:@escape_ratio)==-0.9")
					for acknowledgment in range(6):
						var failure_path := output.path_join("message-busy.txt")
						check("File.open(%s,'w') { |file| file.write($game_message.busy? ? 'busy' : 'idle') }" % JSON.stringify(failure_path))
						if FileAccess.get_file_as_string(failure_path) != "busy":
							break
						await tap(KEY_ENTER)
						await frames(20)
					await frames(30)
				check("BattleManager.abort")
		elif ending == "abort":
			check("BattleManager.abort")
		elif ending == "victory":
			check("$battle_flow_before_gold=$game_party.gold; $battle_flow_before_exp=$game_party.members.map { |actor| actor.exp }; $battle_flow_exp_rates=$game_party.members.map { |actor| actor.final_exp_rate }; $game_troop.members.each { |enemy| enemy.hp=0 }; $battle_flow_reward_gold=$game_troop.gold_total; $battle_flow_reward_exp=$game_troop.exp_total")
		else:
			check("$game_party.battle_members.each { |actor| actor.hp=0 }")
		for acknowledgment in range(12):
			await tap(KEY_ENTER)
		await frames(120)
		var expected := 2 if ending in ["allowed-defeat", "gameover"] else 0 if ending == "victory" else 1
		check("puts ['BATTLE_FLOW_RESULT',%s,SceneManager.scene.class,$battle_flow_results.last,$game_party.battle_members.map { |actor| actor.hp }.join(',')].join(':')" % JSON.stringify(ending))
		if ending == "gameover":
			check("raise 'non-allowed defeat not gameover' unless SceneManager.scene.is_a?(Scene_Gameover) && !$game_party.in_battle && $battle_flow_results.last==2; raise 'gameover revived party' unless $game_party.all_dead?")
			root.get_texture().get_image().save_png(output.path_join("gameover.png"))
			check("$game_party.battle_members.each { |actor| actor.recover_all }; SceneManager.goto(Scene_Map)")
			await frames(180)
		check("raise 'battle callback result' unless $battle_flow_results.last==%d; raise 'battle did not return map' unless SceneManager.scene.is_a?(Scene_Map) && !$game_party.in_battle; raise 'allowed defeat did not revive' unless $game_party.battle_members.all? { |actor| actor.hp>0 }" % expected)
		if ending == "victory":
			check("raise 'victory gold reward' unless $game_party.gold==$battle_flow_before_gold+$battle_flow_reward_gold; raise 'victory experience reward' unless $game_party.members.each_with_index.all? { |actor,index| actor.exp==$battle_flow_before_exp[index]+($battle_flow_reward_exp*$battle_flow_exp_rates[index]).to_i }")
		var returned := Vector3i(driver.GetViewportCount(),driver.GetSpriteCount(),driver.GetWindowCount())
		if returned != baseline:
			push_error("Battle return changed resources: %s -> %s" % [baseline,returned])
			ok = false
		print("BATTLE_FLOW_CASE:%s:%s" % [ending,ok])
		if not ok:
			print("BATTLE_FLOW_FAIL")
			quit(1)
			return
	check("raise 'battle starts were not counted' unless $game_system.battle_count==$battle_flow_saved_count+7; $game_system.battle_count=$battle_flow_saved_count; $data_troops.pop; $game_party.battle_members.each { |actor| actor.recover_all }")
	print("BATTLE_FLOW_PASS" if ok else "BATTLE_FLOW_FAIL")
	quit(0 if ok else 1)
