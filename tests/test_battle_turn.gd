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
	check("DataManager.setup_new_game; SceneManager.goto(Scene_Map)")
	await frames(180)
	var baseline := Vector3i(driver.GetViewportCount(),driver.GetSpriteCount(),driver.GetWindowCount())
	var output := ProjectSettings.globalize_path("res://.omo/evidence/rmva-compatibility/godot/battle-turn")
	DirAccess.make_dir_recursive_absolute(output)
	var reaction := "counter" if "--counter" in OS.get_cmdline_user_args() else "reflection" if "--reflection" in OS.get_cmdline_user_args() else ""
	var item_probe := "--item" in OS.get_cmdline_user_args()
	var skill_probe := "--skill" in OS.get_cmdline_user_args()
	var force_probe := "--force" in OS.get_cmdline_user_args()
	var enemy_force_probe := "--enemy-force" in OS.get_cmdline_user_args()
	force_probe = force_probe or enemy_force_probe
	check("$turn_skill_saved=[$data_skills[1].hit_type,$data_skills[1].success_rate,$data_skills[1].damage.formula,$data_skills[1].damage.variance,$data_skills[1].damage.critical]; $data_skills[1].hit_type=0; $data_skills[1].success_rate=100; $data_skills[1].damage.formula='10'; $data_skills[1].damage.variance=0; $data_skills[1].damage.critical=false; troop=RPG::Troop.new; troop.id=$data_troops.size; member=RPG::Troop::Member.new; member.enemy_id=1; member.x=272; member.y=240; troop.members=[member]; $data_troops << troop; BattleManager.setup(troop.id,true,true); $turn_enemy=$game_troop.members[0]; $turn_enemy.hp=1; BattleManager.instance_variable_set(:@preemptive,true); BattleManager.save_bgm_and_bgs; $turn_results=[]; BattleManager.event_proc=proc { |result| $turn_results << result }; $turn_gold=$game_party.gold; $turn_reward=$turn_enemy.gold; SceneManager.call(Scene_Battle)")
	await frames(90)
	if force_probe:
		var subject_spec := "0,0" if enemy_force_probe else "1,$game_party.members[0].id"
		check("$turn_enemy.hp=$turn_enemy.mhp; $turn_enemy_hp=$turn_enemy.hp; $turn_force_variable=$data_system.variables.size; $data_system.variables << 'Forced action completion'; page=RPG::Troop::Page.new; page.condition.turn_valid=true; page.condition.turn_a=1; page.condition.turn_b=0; page.span=0; page.list=[RPG::EventCommand.new(339,0,[%s,1,0]),RPG::EventCommand.new(122,0,[$turn_force_variable,$turn_force_variable,0,0,23]),RPG::EventCommand.new]; $data_troops.last.pages=[page]" % subject_spec)
		if enemy_force_probe:
			check("$turn_actor=$game_party.members[0]; $turn_actor.recover_all; $turn_actor_hp=$turn_actor.hp; $turn_enemy_data=$data_enemies[1]; $turn_saved_features=$turn_enemy_data.features.dup; $turn_enemy_data.features=$turn_saved_features+[RPG::BaseItem::Feature.new(22,0,1-$turn_enemy.hit)]")
	if skill_probe:
		check("$turn_enemy.hp=$turn_enemy.mhp; $turn_enemy_hp=$turn_enemy.hp; $turn_skill=RPG::Skill.new; $turn_skill.id=$data_skills.size; $turn_skill.name='Compatibility Spell'; $turn_skill.stype_id=1; $turn_skill.scope=1; $turn_skill.hit_type=0; $turn_skill.damage.type=1; $turn_skill.damage.formula='10'; $turn_skill.damage.variance=0; $turn_skill.repeats=2; $turn_skill.mp_cost=3; $turn_skill.tp_cost=2; $data_skills << $turn_skill; $turn_actor=$game_party.members[0]; $turn_actor.learn_skill($turn_skill.id); $turn_actor.mp=10; $turn_actor.tp=10; $turn_mp_cost=$turn_actor.skill_mp_cost($turn_skill)")
	if item_probe:
		check("$turn_enemy.hp=$turn_enemy.mhp; $turn_enemy_hp=$turn_enemy.hp; $turn_item=RPG::Item.new; $turn_item.id=$data_items.size; $turn_item.name='Compatibility Bomb'; $turn_item.scope=1; $turn_item.hit_type=0; $turn_item.damage.type=1; $turn_item.damage.formula='10'; $turn_item.damage.variance=0; $turn_item.damage.critical=false; $turn_event=RPG::CommonEvent.new; $turn_event.id=$data_common_events.size; $turn_event_variable=$data_system.variables.size; $data_system.variables << 'Battle item event'; $turn_event.list=[RPG::EventCommand.new(122,0,[$turn_event_variable,$turn_event_variable,0,0,17]),RPG::EventCommand.new]; $data_common_events << $turn_event; $turn_item.effects=[RPG::UsableItem::Effect.new(44,$turn_event.id,0,0)]; $data_items << $turn_item; $game_party.gain_item($turn_item,2)")
	if not reaction.is_empty():
		var hit_type := 1 if reaction == "counter" else 2
		var trait_id := 6 if reaction == "counter" else 5
		check("$data_skills[1].hit_type=%d; $turn_enemy.hp=$turn_enemy.mhp; $turn_enemy_data=$data_enemies[1]; $turn_saved_features=$turn_enemy_data.features.dup; $turn_enemy_data.features=$turn_saved_features+[RPG::BaseItem::Feature.new(22,%d,1),RPG::BaseItem::Feature.new(22,0,1-$turn_enemy.hit)]; $turn_actor=$game_party.members[0]; $turn_actor.recover_all; $turn_actor_hp=$turn_actor.hp; $turn_reaction_state=RPG::State.new; $turn_reaction_state.id=$data_states.size; $turn_reaction_state.features=[RPG::BaseItem::Feature.new(22,1,-$turn_actor.eva),RPG::BaseItem::Feature.new(22,4,-$turn_actor.mev)]; $data_states << $turn_reaction_state; $turn_actor.add_state($turn_reaction_state.id); $turn_enemy_hp=$turn_enemy.hp; $turn_expected_damage=(10*$turn_actor.%s).to_i" % [hit_type,trait_id,"pdr" if reaction == "counter" else "mdr"])
	for acknowledgment in range(6):
		var message_path := output.path_join("message-busy.txt")
		check("File.open(%s,'w') { |file| file.write($game_message.busy? ? 'busy' : 'idle') }" % JSON.stringify(message_path))
		if FileAccess.get_file_as_string(message_path) != "busy":
			break
		await tap(KEY_ENTER)
		await frames(20)
	check("raise 'turn party command not ready' unless SceneManager.scene.instance_variable_get(:@party_command_window).active")
	await tap(KEY_ENTER)
	check("raise 'fight did not select actor' unless BattleManager.actor && SceneManager.scene.instance_variable_get(:@actor_command_window).active")
	if force_probe:
		# Choose guard; the event replaces that pending action with one forced attack.
		check("raise 'forced action completed before turn' unless $game_variables[$turn_force_variable]==0")
		var command_path := output.path_join("guard-command.txt")
		check("command=SceneManager.scene.instance_variable_get(:@actor_command_window).instance_variable_get(:@list).index { |entry| entry[:symbol]==:guard }; raise 'guard command absent' unless command; File.open(%s,'w') { |file| file.write(command.to_s) }" % JSON.stringify(command_path))
		for step in range(int(FileAccess.get_file_as_string(command_path))):
			await tap(KEY_DOWN)
		await tap(KEY_ENTER)
		await frames(180)
		if enemy_force_probe:
			check("puts ['ENEMY_FORCE_STATE',$turn_actor_hp,$turn_actor.hp,$turn_actor.guard?,$turn_enemy_hp,$turn_enemy.hp,$game_variables[$turn_force_variable],BattleManager.action_forced?,$game_troop.interpreter.running?].join(':')")
		var damage_assert := "$turn_actor.hp==$turn_actor_hp-(10*$turn_actor.pdr).to_i && $turn_enemy.hp==$turn_enemy_hp" if enemy_force_probe else "$turn_enemy.hp==$turn_enemy_hp-10"
		check("raise 'event forced attack not executed exactly once' unless %s; raise 'event resumed before/without forced completion' unless $game_variables[$turn_force_variable]==23 && !BattleManager.action_forced? && !$game_troop.interpreter.running?; $data_system.variables.pop; $game_variables[$turn_force_variable]=0; BattleManager.abort" % damage_assert)
		if enemy_force_probe:
			check("$data_enemies[1].features=$turn_saved_features")
		for acknowledgment in range(12):
			await tap(KEY_ENTER)
		await frames(120)
		check("raise 'forced turn cleanup not map' unless SceneManager.scene.is_a?(Scene_Map) && $turn_results==[1]; $data_skills[1].hit_type,$data_skills[1].success_rate,$data_skills[1].damage.formula,$data_skills[1].damage.variance,$data_skills[1].damage.critical=*$turn_skill_saved; $data_troops.pop")
		ok = Vector3i(driver.GetViewportCount(),driver.GetSpriteCount(),driver.GetWindowCount())==baseline and ok
		print("BATTLE_FORCE_PASS" if ok else "BATTLE_FORCE_FAIL")
		quit(0 if ok else 1)
		return
	if skill_probe:
		var command_path := output.path_join("skill-command.txt")
		check("command=SceneManager.scene.instance_variable_get(:@actor_command_window).instance_variable_get(:@list).index { |entry| entry[:symbol]==:skill && entry[:ext]==1 }; raise 'skill command absent' unless command; File.open(%s,'w') { |file| file.write(command.to_s) }" % JSON.stringify(command_path))
		for step in range(int(FileAccess.get_file_as_string(command_path))):
			await tap(KEY_DOWN)
		await tap(KEY_ENTER)
		check("raise 'battle skill window not active' unless SceneManager.scene.instance_variable_get(:@skill_window).active; window=SceneManager.scene.instance_variable_get(:@skill_window); index=window.instance_variable_get(:@data).index($turn_skill); raise 'skill list missing fixture skill' unless index; File.open(%s,'w') { |file| file.write((index-window.index).to_s) }" % JSON.stringify(command_path))
		for step in range(int(FileAccess.get_file_as_string(command_path))):
			await tap(KEY_DOWN)
		check("raise 'skill navigation did not select spell' unless SceneManager.scene.instance_variable_get(:@skill_window).item.equal?($turn_skill)")
		root.get_texture().get_image().save_png(output.path_join("skill-window.png"))
	if item_probe:
		check("$turn_item_command=SceneManager.scene.instance_variable_get(:@actor_command_window).instance_variable_get(:@list).index { |command| command[:symbol]==:item }; raise 'item command absent' unless $turn_item_command")
		var command_path := output.path_join("item-command.txt")
		check("File.open(%s,'w') { |file| file.write($turn_item_command.to_s) }" % JSON.stringify(command_path))
		for step in range(int(FileAccess.get_file_as_string(command_path))):
			await tap(KEY_DOWN)
		await tap(KEY_ENTER)
		check("raise 'battle item window not active' unless SceneManager.scene.instance_variable_get(:@item_window).active; raise 'selected item differs' unless SceneManager.scene.instance_variable_get(:@item_window).item.equal?($turn_item)")
		root.get_texture().get_image().save_png(output.path_join("item-window.png"))
	await tap(KEY_ENTER)
	check("raise 'attack did not request target' unless SceneManager.scene.instance_variable_get(:@enemy_window).active; raise 'attack ran before target confirm' unless $turn_enemy.hp==%s && $turn_results.empty?" % ("1" if reaction.is_empty() and not item_probe and not skill_probe else "$turn_enemy_hp"))
	root.get_texture().get_image().save_png(output.path_join("item-target.png" if item_probe else "skill-target.png" if skill_probe else "attack-target.png" if reaction.is_empty() else reaction + "-target.png"))
	await tap(KEY_ENTER)
	await frames(180)
	if skill_probe:
		check("raise 'battle skill repeats' unless $turn_enemy.hp==$turn_enemy_hp-20; raise 'battle skill cost' unless $turn_actor.mp==10-$turn_mp_cost && $turn_actor.tp==8; raise 'battle skill memory' unless $turn_actor.last_skill.object.equal?($turn_skill); $turn_actor.forget_skill($turn_skill.id); $data_skills.pop; BattleManager.abort")
	if item_probe:
		check("raise 'battle item damage' unless $turn_enemy.hp==$turn_enemy_hp-10; raise 'battle item consumption' unless $game_party.item_number($turn_item)==1; raise 'battle item memory' unless $game_party.last_item.object.equal?($turn_item); raise 'battle item common event not executed' unless $game_variables[$turn_event_variable]==17 && !$game_temp.common_event_reserved?; $game_party.lose_item($turn_item,99); $data_items.pop; $data_common_events.pop; $data_system.variables.pop; $game_variables[$turn_event_variable]=0; BattleManager.abort")
	if not reaction.is_empty():
		check("raise 'reaction did not hurt attacker' unless $turn_actor.hp==$turn_actor_hp-$turn_expected_damage; raise 'reaction damaged target' unless $turn_enemy.hp==$turn_enemy_hp; raise 'reaction ended battle' unless SceneManager.scene.is_a?(Scene_Battle) && $turn_results.empty?; $data_enemies[1].features=$turn_saved_features; $turn_actor.remove_state($turn_reaction_state.id); $data_states.pop; BattleManager.abort")
	for acknowledgment in range(12):
		await tap(KEY_ENTER)
	await frames(120)
	if reaction.is_empty() and not item_probe and not skill_probe:
		check("raise 'selected attack did not kill enemy' unless $turn_enemy.dead?; raise 'actual turn did not finish victory' unless $turn_results==[0] && SceneManager.scene.is_a?(Scene_Map) && !$game_party.in_battle; raise 'actual attack gold reward' unless $game_party.gold==$turn_gold+$turn_reward")
	else:
		check("raise 'reaction cleanup did not return map' unless $turn_results==[1] && SceneManager.scene.is_a?(Scene_Map) && !$game_party.in_battle")
	check("$data_skills[1].hit_type,$data_skills[1].success_rate,$data_skills[1].damage.formula,$data_skills[1].damage.variance,$data_skills[1].damage.critical=*$turn_skill_saved; $data_troops.pop")
	var returned := Vector3i(driver.GetViewportCount(),driver.GetSpriteCount(),driver.GetWindowCount())
	if returned != baseline:
		push_error("Battle action return changed resources: %s -> %s" % [baseline,returned])
		ok = false
	print("BATTLE_TURN_PASS" if ok else "BATTLE_TURN_FAIL")
	quit(0 if ok else 1)
