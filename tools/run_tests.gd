extends SceneTree

# Headless contracts: godot --headless --path . -s tools/run_tests.gd
# All contracts including GPU rendering: godot --path . -s tools/run_tests.gd -- --rendered
const HEADLESS_TESTS := [
	["tests/test_shutdown_bitmaps.gd", "SHUTDOWN_BITMAPS_PASS"],
	["tests/test_native_extensions.gd", "NATIVE_EXTENSIONS_PASS"],
	["tests/test_zlib_stream.gd", "ZLIB_STREAM_PASS"],
	["tests/test_ruby_errors.gd", "RUBY_ERRORS_PASS"],
	["tests/test_defined_runtime.gd", "DEFINED_RUNTIME_PASS:77"],
	["tests/test_rgss_api.gd", "RGSS_API_TESTS_PASS"],
	["tests/test_eval_damage_fix.gd", "EVAL_DAMAGE_FIX_PASS"],
	["tests/test_stress_dispose.gd", "STRESS_PASS"],
	["tests/test_value_semantics.gd", "VALUE_SEMANTICS_PASS"],
	["tests/test_table_dimensions.gd", "TABLE_DIMENSIONS_PASS"],
	["tests/test_rpg_defaults.gd", "RPG_DEFAULTS_PASS"],
	["tests/test_rpg_database.gd", "RPG_DATABASE_PASS"],
	["tests/test_resource_lifecycle.gd", "RESOURCE_LIFECYCLE_PASS"],
	["tests/test_input_mapping.gd", "INPUT_MAPPING_PASS"],
	["tests/test_reset_callback.gd", "RESET_CALLBACK_PASS"],
	["tests/test_kernel_file_lifecycle.gd", "KERNEL_FILE_LIFECYCLE_PASS"],
	["tests/test_bitmap_compositing.gd", "BITMAP_COMPOSITING_PASS"],
	["tests/test_cursor_cache.gd", "CURSOR_CACHE_PASS"],
	["tests/test_marshal_io.gd", "MARSHAL_IO_PASS"],
	["tests/test_marshal_links.gd", "MARSHAL_LINKS_PASS"],
	["tests/test_marshal_metadata.gd", "MARSHAL_METADATA_PASS"],
	["tests/test_marshal_values.gd", "MARSHAL_VALUES_PASS"],
]
const WINDOWS_FONT_TESTS := [
	["tests/test_font_metrics.gd", "FONT_METRICS_PASS", "windows"],
	["tests/test_font_short_layout.gd", "FONT_SHORT_LAYOUT_PASS", "windows"],
	["tests/run_primitive_reference.gd", "GODOT_PRIMITIVE_REFERENCE_PASS", "variants"],
	["tests/run_primitive_reference.gd", "GODOT_PRIMITIVE_REFERENCE_PASS", "styles"],
	["tests/run_primitive_reference.gd", "GODOT_PRIMITIVE_REFERENCE_PASS", "layout"],
]
const RENDERED_TESTS := [
	["tests/test_game_reset.gd", "GAME_RESET_PASS"],
	["tests/test_default_draw_order.gd", "DEFAULT_DRAW_ORDER_PASS"],
	["tests/test_frame_loop.gd", "FRAME_LOOP_PASS"],
	["tests/test_graphics_snapshot.gd", "GRAPHICS_SNAPSHOT_PASS"],
	["tests/test_window_transparency.gd", "WINDOW_TRANSPARENCY_PASS"],
	["tests/test_window_activation.gd", "WINDOW_ACTIVATION_PASS"],
	["tests/test_window_cursor_shape.gd", "WINDOW_CURSOR_SHAPE_PASS"],
	["tests/test_cursor_tail.gd", "CURSOR_TAIL_PASS"],
	["tests/test_game_settings.gd", "GAME_SETTINGS_PASS"],
	["tests/test_movie_playback.gd", "MOVIE_PLAYBACK_PASS"],
]
const EVENT_TESTS := [
	["tests/test_event_control.gd", "EVENT_CONTROL_PASS"],
	["tests/test_event_inventory.gd", "EVENT_INVENTORY_PASS"],
	["tests/test_event_map.gd", "EVENT_MAP_PASS"],
	["tests/test_event_screen.gd", "EVENT_SCREEN_PASS"],
	["tests/test_event_character.gd", "EVENT_CHARACTER_PASS"],
	["tests/test_event_message.gd", "EVENT_MESSAGE_PASS"],
	["tests/test_event_actor.gd", "EVENT_ACTOR_PASS"],
	["tests/test_event_enemy.gd", "EVENT_ENEMY_PASS"],
	["tests/test_event_transfer.gd", "EVENT_TRANSFER_PASS"],
	["tests/test_event_scene.gd", "EVENT_SCENE_PASS"],
	["tests/test_event_battle.gd", "EVENT_BATTLE_PASS"],
	["tests/test_event_player.gd", "EVENT_PLAYER_PASS"],
	["tests/test_event_audio.gd", "EVENT_AUDIO_PASS"],
	["tests/test_event_movie.gd", "EVENT_MOVIE_PASS"],
	["tests/test_event_schedule.gd", "EVENT_SCHEDULE_PASS"],
	["tests/test_event_page.gd", "EVENT_PAGE_PASS"],
	["tests/test_event_effect_wait.gd", "EVENT_EFFECT_WAIT_PASS"],
	["tests/test_event_route.gd", "EVENT_ROUTE_PASS"],
	["tests/test_event_map_flow.gd", "EVENT_MAP_FLOW_PASS"],
	["tests/test_message_window.gd", "D05_MESSAGE_PASS"],
	["tests/test_map_screen_render.gd", "MAP_SCREEN_RENDER_PASS"],
	["tests/test_shop_name_operations.gd", "SHOP_NAME_OPERATIONS_PASS"],
	["tests/test_menu_operations.gd", "D07_MENU_PASS"],
	["tests/test_battle_flow.gd", "BATTLE_FLOW_PASS"],
	["tests/test_battle_flow.gd", "BATTLE_END_REFERENCE_PASS", "manager"],
	["tests/test_battle_turn.gd", "BATTLE_TURN_PASS"],
	["tests/test_battle_turn.gd", "BATTLE_TURN_PASS", "counter"],
	["tests/test_battle_turn.gd", "BATTLE_TURN_PASS", "reflection"],
	["tests/test_battle_turn.gd", "BATTLE_TURN_PASS", "item"],
	["tests/test_battle_turn.gd", "BATTLE_TURN_PASS", "skill"],
	["tests/test_battle_turn.gd", "BATTLE_FORCE_PASS", "force"],
	["tests/test_battle_turn.gd", "BATTLE_FORCE_PASS", "enemy-force"],
	["tests/test_battle_damage.gd", "BATTLE_DAMAGE_PASS"],
	["tests/test_battle_animation.gd", "BATTLE_ANIMATION_PASS"],
	["tests/test_battle_animation_pixels.gd", "BATTLE_ANIMATION_PIXELS_PASS"],
	["tests/test_battle_effects.gd", "BATTLE_EFFECTS_PASS"],
	["tests/test_battle_schedule.gd", "BATTLE_SCHEDULE_PASS"],
	["tests/test_save_interchange.gd", "SAVE_INTERCHANGE_PASS"],
	["tests/test_save_slots.gd", "TITLE_SAVE_FLOW_PASS", "ui", "from-title"],
	["tests/test_audio_replay.gd", "AUDIO_REPLAY_PASS"],
	["tests/test_audio_seek_units.gd", "AUDIO_SEEK_UNITS_PASS"],
	["tests/test_audio_me.gd", "AUDIO_ME_PASS"],
	["tests/test_audio_se.gd", "AUDIO_SE_PASS"],
	["tests/test_audio_loop.gd", "AUDIO_LOOP_PASS"],
	["tests/test_audio_loop_tags.gd", "AUDIO_LOOP_TAGS_PASS"],
	["tests/test_game_close.gd", "GAME_CLOSE_PASS"],
	["tests/test_midi_shutdown.gd", "MIDI_SHUTDOWN_PASS"],
	["tests/test_third_party_core.gd", "THIRD_PARTY_CORE_PASS", "ui"],
	["tests/test_third_party_core.gd", "THIRD_PARTY_CORE_PASS", "ruby-exit"],
	["tests/test_third_party_core.gd", "THIRD_PARTY_CORE_PASS", "immediate-free"],
	["tests/test_dense_map_runtime.gd", "DENSE_MAP_RUNTIME_PASS"],
	["tests/test_dense_map_runtime.gd", "DENSE_MAP_FIXTURE_PASS", "fixture"],
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var rendered := "--rendered" in OS.get_cmdline_user_args()
	var tests := HEADLESS_TESTS.duplicate()
	if "--events" in OS.get_cmdline_user_args():
		if DisplayServer.get_name() == "headless":
			push_error("Event contracts require the configured game's rendered Boot scene")
			quit(1)
			return
		tests.append_array(EVENT_TESTS)
	if rendered:
		tests.append_array(RENDERED_TESTS)
	if "--windows-fonts" in OS.get_cmdline_user_args():
		tests.append_array(WINDOWS_FONT_TESTS)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--start-at="):
			var start := int(argument.trim_prefix("--start-at="))
			if start < 0 or start >= tests.size():
				push_error("Suite start index outside selected test range")
				quit(1)
				return
			print("TEST_SUITE_RESUME:%d/%d" % [start,tests.size()])
			tests = tests.slice(start)
	var failed := 0
	for entry in tests:
		if entry in WINDOWS_FONT_TESTS and entry.size() > 2 and OS.get_name() != "Windows":
			push_error("Windows original font parity is not verified on this platform")
			failed += 1
			continue
		var args := PackedStringArray(["--windowed", "--path", ProjectSettings.globalize_path("res://"), "-s", entry[0]])
		if entry in HEADLESS_TESTS or entry in WINDOWS_FONT_TESTS:
			args.insert(0, "--headless")
		if entry.size() > 2 and entry[2] != "windows":
			args.append("--")
			for option in entry.slice(2):
				args.append("--" + option)
		var output: Array = []
		var code := OS.execute(OS.get_executable_path(), args, output, true)
		var text := "\n".join(output)
		print(text)
		var passed: bool = code == 0 and entry[1] in text and "ERROR: FATAL:" not in text and "ERROR: Leaked unsafe reference" not in text
		if not passed:
			failed += 1
		print("TEST_RESULT:%s:%s:exit=%d" % [entry[0], "PASS" if passed else "FAIL", code])
	print("TEST_SUITE_PASS:%d" % tests.size() if failed == 0 else "TEST_SUITE_FAIL:%d" % failed)
	quit(0 if failed == 0 else 1)
