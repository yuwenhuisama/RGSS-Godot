extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var settings = load("res://Scripts/GameSettings.cs").new()
	root.add_child(settings)
	await process_frame
	var event := InputEventKey.new()
	event.keycode = KEY_F1
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	await process_frame
	var layer: CanvasLayer = settings.get_child(0)
	var dialog: AcceptDialog = layer.get_child(0)
	var tabs: TabContainer = dialog.get_child(0)
	var ok := tabs.get_tab_count() == 3 and dialog.visible
	tabs.current_tab = 2
	await process_frame
	var keyboard_page: VBoxContainer = tabs.get_child(2)
	var scroll: ScrollContainer = keyboard_page.get_child(0)
	var grid: GridContainer = scroll.get_child(0)
	var enter_choice: OptionButton = grid.get_child(3)
	var original_enter := enter_choice.selected
	enter_choice.select(2)
	dialog.emit_signal("canceled")
	await process_frame
	ok = ok and InputMap.event_is_action(InputEventKey.new(), "rgss_c") == false
	event = InputEventKey.new()
	event.keycode = KEY_F1
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	await process_frame
	dialog = layer.get_child(0)
	tabs = dialog.get_child(0)
	tabs.current_tab = 2
	await process_frame
	await RenderingServer.frame_post_draw
	dialog.get_viewport().get_texture().get_image().save_png("user://rgss-settings-keyboard.png")
	tabs.current_tab = 1
	await process_frame
	await RenderingServer.frame_post_draw
	dialog.get_viewport().get_texture().get_image().save_png("user://rgss-settings-gamepad.png")
	tabs.current_tab = 0
	keyboard_page = tabs.get_child(2)
	scroll = keyboard_page.get_child(0)
	grid = scroll.get_child(0)
	enter_choice = grid.get_child(3)
	ok = ok and enter_choice.selected == original_enter
	var general: VBoxContainer = tabs.get_child(0)
	var music: CheckBox = general.get_child(2)
	var sound: CheckBox = general.get_child(3)
	var original_music := music.button_pressed
	var original_sound := sound.button_pressed
	music.button_pressed = false
	sound.button_pressed = false
	enter_choice.select(2)
	dialog.emit_signal("confirmed")
	await process_frame
	var reloaded := ConfigFile.new()
	ok = ok and reloaded.load("user://rgss_settings.cfg") == OK and reloaded.get_value("keyboard", "1") == 2
	var enter := InputEventKey.new()
	enter.keycode = KEY_ENTER
	ok = ok and InputMap.event_is_action(enter,"rgss_b") and not InputMap.event_is_action(enter,"rgss_c")
	ok = ok and AudioServer.is_bus_mute(AudioServer.get_bus_index("RGSSMusic")) and AudioServer.is_bus_mute(AudioServer.get_bus_index("RGSSSound"))
	# Restore the original mapping through the same public dialog path.
	event = InputEventKey.new()
	event.keycode = KEY_F1
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	await process_frame
	dialog = layer.get_child(0)
	tabs = dialog.get_child(0)
	keyboard_page = tabs.get_child(2)
	scroll = keyboard_page.get_child(0)
	grid = scroll.get_child(0)
	enter_choice = grid.get_child(3)
	enter_choice.select(original_enter)
	general = tabs.get_child(0)
	music = general.get_child(2)
	sound = general.get_child(3)
	music.button_pressed = original_music
	sound.button_pressed = original_sound
	dialog.emit_signal("confirmed")
	await process_frame
	event = InputEventKey.new()
	event.keycode = KEY_F1
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	await process_frame
	dialog = layer.get_child(0)
	tabs = dialog.get_child(0)
	await RenderingServer.frame_post_draw
	dialog.get_viewport().get_texture().get_image().save_png("user://rgss-settings.png")
	dialog.emit_signal("canceled")
	await process_frame
	event = InputEventKey.new()
	event.keycode = KEY_F2
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	ok = ok and " FPS" in root.title
	if "--fullscreen" in OS.get_cmdline_user_args():
		var previous_mode := DisplayServer.window_get_mode()
		event = InputEventKey.new()
		event.keycode = KEY_ENTER
		event.alt_pressed = true
		event.pressed = true
		Input.parse_input_event(event)
		await process_frame
		ok = ok and DisplayServer.window_get_mode() != previous_mode
		event = InputEventKey.new()
		event.keycode = KEY_ENTER
		event.alt_pressed = true
		event.pressed = true
		Input.parse_input_event(event)
		await process_frame
		ok = ok and DisplayServer.window_get_mode() == previous_mode
	print("GAME_SETTINGS_PASS" if ok else "GAME_SETTINGS_FAIL")
	quit(0 if ok else 1)
