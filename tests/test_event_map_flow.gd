extends SceneTree

const TestPaths = preload("res://tools/test_paths.gd")

func _initialize() -> void:
	call_deferred("_run")

func frames(count: int) -> void:
	for frame in range(count):
		await process_frame
		await RenderingServer.frame_post_draw

func _run() -> void:
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	TestPaths.required("game_project")
	root.add_child(load("res://Scenes/Boot.tscn").instantiate())
	await frames(180)
	var ok: bool = driver.RunRuby("raise 'title not ready' unless SceneManager.scene.is_a?(Scene_Title); DataManager.setup_new_game; SceneManager.goto(Scene_Map)")
	await frames(180)
	ok = driver.RunRuby("raise 'map not ready' unless SceneManager.scene.is_a?(Scene_Map); $event_flow_saved_events=$game_map.events.dup; $event_flow_saved_xy=[$game_player.x,$game_player.y,$game_player.direction]; $event_flow_counter_id=$data_system.variables.size; $data_system.variables << 'Compatibility Event Flow'; $game_player.moveto(5,5); $game_player.set_direction(6); $event_flow_id=($game_map.events.keys.max || 0)+1; data=RPG::Event.new(6,5); data.id=$event_flow_id; page=data.pages[0]; page.priority_type=1; page.trigger=0; page.list=[RPG::EventCommand.new(122,0,[$event_flow_counter_id,$event_flow_counter_id,1,0,1]),RPG::EventCommand.new(230,0,[12]),RPG::EventCommand.new]; $game_map.events.clear; $game_map.events[$event_flow_id]=Game_Event.new($game_map.map_id,data)") and ok
	await frames(15)
	for cycle in range(3):
		var key := InputEventKey.new()
		key.keycode = KEY_ENTER
		key.pressed = true
		Input.parse_input_event(key)
		await frames(3)
		ok = driver.RunRuby("raise 'confirmation did not dispatch map event' unless $game_variables[$event_flow_counter_id] == %d; raise 'event wait not active' unless $game_map.interpreter.running?" % (cycle + 1)) and ok
		key = InputEventKey.new()
		key.keycode = KEY_ENTER
		key.pressed = false
		Input.parse_input_event(key)
		await frames(30)
		ok = driver.RunRuby("raise 'map event did not finish/unlock' if $game_map.interpreter.running?; raise 'map event still starting' if $game_map.events[$event_flow_id].starting; raise 'event repeated without confirmation' unless $game_variables[$event_flow_counter_id] == %d" % (cycle + 1)) and ok
	ok = driver.RunRuby("$game_map.events[$event_flow_id].erase; data=RPG::Event.new(6,5); data.id=$event_flow_id; page=data.pages[0]; page.priority_type=1; page.trigger=1; page.list=[RPG::EventCommand.new(122,0,[$event_flow_counter_id,$event_flow_counter_id,1,0,1]),RPG::EventCommand.new(230,0,[12]),RPG::EventCommand.new]; $game_map.events[$event_flow_id]=Game_Event.new($game_map.map_id,data); $game_player.moveto(5,5); $game_player.set_direction(6)") and ok
	await frames(5)
	var touch_key := InputEventKey.new()
	touch_key.keycode = KEY_RIGHT
	touch_key.pressed = true
	Input.parse_input_event(touch_key)
	await frames(3)
	ok = driver.RunRuby("raise 'direction key did not trigger player touch event' unless $game_variables[$event_flow_counter_id] == 4; raise 'touch wait not active' unless $game_map.interpreter.running?") and ok
	touch_key = InputEventKey.new()
	touch_key.keycode = KEY_RIGHT
	touch_key.pressed = false
	Input.parse_input_event(touch_key)
	await frames(30)
	ok = driver.RunRuby("raise 'touch event did not finish' if $game_map.interpreter.running?; raise 'touch event repeated after release' unless $game_variables[$event_flow_counter_id] == 4") and ok
	ok = driver.RunRuby("$game_map.events[$event_flow_id].erase; data=RPG::Event.new(6,5); data.id=$event_flow_id; page=data.pages[0]; page.priority_type=1; page.trigger=2; page.list=[RPG::EventCommand.new(122,0,[$event_flow_counter_id,$event_flow_counter_id,1,0,1]),RPG::EventCommand.new(230,0,[12]),RPG::EventCommand.new]; event=Game_Event.new($game_map.map_id,data); $game_map.events[$event_flow_id]=event; $game_player.moveto(5,5); route=RPG::MoveRoute.new; route.repeat=false; route.wait=false; route.list=[RPG::MoveCommand.new(2),RPG::MoveCommand.new]; event.force_move_route(route)") and ok
	await frames(5)
	ok = driver.RunRuby("raise 'event movement did not trigger event touch' unless $game_variables[$event_flow_counter_id] == 5; raise 'event-touch wait not active' unless $game_map.interpreter.running?") and ok
	await frames(30)
	ok = driver.RunRuby("event=$game_map.events[$event_flow_id]; raise 'non-skippable collision route should still be forcing' unless event.move_route_forcing; event.instance_variable_get(:@move_route).skippable=true") and ok
	await frames(30)
	ok = driver.RunRuby("raise 'event-touch interpreter did not finish' if $game_map.interpreter.running?; $event_flow_touch_total=$game_variables[$event_flow_counter_id]") and ok
	await frames(30)
	ok = driver.RunRuby("raise 'completed event-touch route repeated' unless $game_variables[$event_flow_counter_id] == $event_flow_touch_total") and ok
	ok = driver.RunRuby("$game_map.events[$event_flow_id].erase; data=RPG::Event.new(6,5); data.id=$event_flow_id; page=data.pages[0]; page.priority_type=1; page.trigger=0; page.list=[RPG::EventCommand.new(101,0,['',0,0,2]),RPG::EventCommand.new(401,0,['\\\\>Map event acknowledgment']),RPG::EventCommand.new(122,0,[$event_flow_counter_id,$event_flow_counter_id,1,0,1]),RPG::EventCommand.new]; $game_map.events[$event_flow_id]=Game_Event.new($game_map.map_id,data); $game_player.set_direction(6); $event_flow_before_message=$game_variables[$event_flow_counter_id]") and ok
	var message_key := InputEventKey.new()
	message_key.keycode = KEY_ENTER
	message_key.pressed = true
	Input.parse_input_event(message_key)
	await frames(3)
	message_key = InputEventKey.new()
	message_key.keycode = KEY_ENTER
	message_key.pressed = false
	Input.parse_input_event(message_key)
	await frames(90)
	ok = driver.RunRuby("raise 'real map message not blocking event' unless $game_message.busy? && $game_map.interpreter.running?; raise 'event continued before acknowledgment' unless $game_variables[$event_flow_counter_id] == $event_flow_before_message") and ok
	message_key = InputEventKey.new()
	message_key.keycode = KEY_ENTER
	message_key.pressed = true
	Input.parse_input_event(message_key)
	await frames(3)
	message_key = InputEventKey.new()
	message_key.keycode = KEY_ENTER
	message_key.pressed = false
	Input.parse_input_event(message_key)
	await frames(45)
	ok = driver.RunRuby("raise 'map message did not resume event' unless $game_variables[$event_flow_counter_id] == $event_flow_before_message+1; raise 'map message remained busy' if $game_message.busy? || $game_map.interpreter.running?") and ok
	var baseline := Vector3i(driver.GetViewportCount(), driver.GetSpriteCount(), driver.GetWindowCount())
	ok = driver.RunRuby("$game_map.events[$event_flow_id].erase; $event_flow_animation_id=$data_animations.size; animation=RPG::Animation.new; animation.frame_max=12; animation.frames=Array.new(12) { RPG::Animation::Frame.new }; $data_animations << animation; data=RPG::Event.new(6,5); data.id=$event_flow_id; page=data.pages[0]; page.priority_type=1; page.trigger=0; page.list=[RPG::EventCommand.new(212,0,[-1,$event_flow_animation_id,true]),RPG::EventCommand.new(201,0,[0,$game_map.map_id,8,5,4,0]),RPG::EventCommand.new(122,0,[$event_flow_counter_id,$event_flow_counter_id,1,0,1]),RPG::EventCommand.new]; $game_map.events[$event_flow_id]=Game_Event.new($game_map.map_id,data); $game_player.moveto(5,5); $game_player.set_direction(6); $event_flow_before_transfer=$game_variables[$event_flow_counter_id]") and ok
	var transfer_key := InputEventKey.new()
	transfer_key.keycode = KEY_ENTER
	transfer_key.pressed = true
	Input.parse_input_event(transfer_key)
	await frames(3)
	transfer_key = InputEventKey.new()
	transfer_key.keycode = KEY_ENTER
	transfer_key.pressed = false
	Input.parse_input_event(transfer_key)
	await frames(6)
	ok = driver.RunRuby("raise 'map animation did not block transfer' unless $game_map.interpreter.running? && $game_player.x==5 && $game_variables[$event_flow_counter_id]==$event_flow_before_transfer") and ok
	await frames(210)
	ok = driver.RunRuby("raise 'actual Scene_Map transfer did not complete' unless $game_player.x==8 && $game_player.y==5 && $game_player.direction==4 && !$game_player.transfer?; raise 'transfer event did not resume' unless $game_variables[$event_flow_counter_id]==$event_flow_before_transfer+1; raise 'transfer event remained running' if $game_map.interpreter.running?; raise 'transfer fade did not restore brightness' unless Graphics.brightness==255; $data_animations.pop") and ok
	var returned := Vector3i(driver.GetViewportCount(), driver.GetSpriteCount(), driver.GetWindowCount())
	if returned != baseline:
		push_error("Map animation/transfer changed live resource counts: %s -> %s" % [baseline, returned])
		ok = false
	var transfer_base := TestPaths.repo(".omo/compatibility-run-tmp/event-map-flow")
	DirAccess.make_dir_recursive_absolute(transfer_base.path_join("RMProject/Data"))
	for map_name in ["Map001.rvdata2", "Map002.rvdata2"]:
		ok = DirAccess.copy_absolute(TestPaths.required("game_project").path_join("Data/Map001.rvdata2"), transfer_base.path_join("RMProject/Data/" + map_name)) == OK and ok
	ok = driver.RunRuby("$event_flow_saved_base=$rmva_project_base_path; $rmva_project_base_path=" + JSON.stringify(transfer_base) + "; $game_map.events[$event_flow_id].erase; data=RPG::Event.new(9,5); data.id=$event_flow_id; page=data.pages[0]; page.priority_type=1; page.trigger=0; page.list=[RPG::EventCommand.new(201,0,[0,2,8,5,4,0]),RPG::EventCommand.new(122,0,[$event_flow_counter_id,$event_flow_counter_id,1,0,1]),RPG::EventCommand.new]; $game_map.events[$event_flow_id]=Game_Event.new($game_map.map_id,data); $game_player.set_direction(6); $event_flow_before_cross=$game_variables[$event_flow_counter_id]") and ok
	var cross_key := InputEventKey.new()
	cross_key.keycode = KEY_ENTER
	cross_key.pressed = true
	Input.parse_input_event(cross_key)
	await frames(3)
	cross_key = InputEventKey.new()
	cross_key.keycode = KEY_ENTER
	cross_key.pressed = false
	Input.parse_input_event(cross_key)
	await frames(180)
	ok = driver.RunRuby("raise 'cross-map event did not reach map2' unless $game_map.map_id==2 && $game_player.x==8 && $game_player.y==5 && !$game_player.transfer?; raise 'cross-map event did not resume' unless $game_variables[$event_flow_counter_id]==$event_flow_before_cross+1; raise 'cross-map interpreter remained busy' if $game_map.interpreter.running?; $game_player.reserve_transfer(1,8,5,4)") and ok
	await frames(180)
	ok = driver.RunRuby("raise 'cross-map return failed' unless SceneManager.scene.is_a?(Scene_Map) && $game_map.map_id==1 && !$game_player.transfer? && Graphics.brightness==255; $rmva_project_base_path=$event_flow_saved_base") and ok
	var output := TestPaths.output("event-flow")
	DirAccess.make_dir_recursive_absolute(output)
	root.get_texture().get_image().save_png(output.path_join("map-after-events.png"))
	ok = driver.RunRuby("$game_map.events.clear; $event_flow_saved_events.each { |id,event| $game_map.events[id]=event }; $game_player.moveto(*$event_flow_saved_xy[0,2]); $game_player.set_direction($event_flow_saved_xy[2]); $data_system.variables.pop") and ok
	await frames(30)
	var cross_returned := Vector3i(driver.GetViewportCount(), driver.GetSpriteCount(), driver.GetWindowCount())
	if cross_returned != baseline:
		push_error("Cross-map return changed live resource counts: %s -> %s" % [baseline,cross_returned])
		ok = false
	print("EVENT_MAP_FLOW_PASS" if ok else "EVENT_MAP_FLOW_FAIL")
	quit(0 if ok else 1)
