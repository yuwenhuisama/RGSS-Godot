extends SceneTree

const TestPaths = preload("res://tools/test_paths.gd")

# D07 menu operations: drives the stock Scene_Menu / Scene_Item / Scene_Skill /
# Scene_Equip / Scene_Status handlers with real Godot InputEventKey events.
# The shared fixture is also executed by the isolated original RGSS300 runtime;
# its no-input data and scene-state rows are pinned below. Original input parity
# is not claimed: the original branch has no synthetic key injection.
const DATA_ROWS := [
	"data.item_use\t100,562,3,2,1",
	"data.skill_use\t98,94,100,367,2,26",
	"data.equip_change\t2,46,0,1,0,1,0,0,1,0",
	"data.equip_optimize\t2,46,0,2,0,1,0,1,0,0",
	"data.equip_clear\t0,0,0,0,0,1,1,1,1,1",
	"data.formation_swap\t1,2,3,4,1,3,2,4",
	"data.actor_nav\t1,2,3,2",
]
const SCENE_ROWS := [
	"scene.menu\t0,1,1,7,item,-1,0,1,4",
	"scene.item\t0,1,item,-1,0,1,0",
	"scene.skill\t0,1,2,skill,-1,0,0",
	"scene.equip\t0,1,3,equip,-1,0,5,-1,0,1",
	"scene.status\t1,1,-1",
]

var driver
var output := ""
var error_path := ""
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func frames(count: int) -> void:
	for frame in range(count):
		await process_frame
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw

func ruby(code: String, label: String) -> bool:
	var guarded := "begin\n" + code + "\nrescue Exception => e\nFile.open(" + JSON.stringify(error_path) + ", 'a') { |f| f.puts(" + JSON.stringify(label) + ", e.class.to_s, e.message, e.backtrace) }; raise\nend"
	if not driver.RunRuby(guarded):
		failed = true
		push_error("D07_MENU_RUBY_FAIL:" + label)
		return false
	return true

func check(label: String, code: String) -> bool:
	if not ruby(code, label):
		push_error("D07_MENU_CHECK_FAIL:" + label)
		return false
	print("D07_MENU_CHECK_PASS:" + label)
	return true

func tap(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await frames(1)
	await frames(4)

func taps(code: Key, count: int) -> void:
	for i in range(count):
		await tap(code)

func screenshot(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		print("D07_MENU_CAPTURE_SKIP:" + name)
		return
	var path := output.path_join("d07-menu-" + name + ".png")
	if root.get_texture().get_image().save_png(path) != OK:
		failed = true
		push_error("D07_MENU_CAPTURE_FAIL:" + path)
	else:
		print("D07_MENU_CAPTURE:" + path)

func compare_rows(file: String, expected: Array, label: String) -> void:
	var path := output.path_join(file)
	if not FileAccess.file_exists(path):
		failed = true
		push_error("D07_MENU_ROWS_MISSING:" + label)
		return
	var actual := FileAccess.get_file_as_string(path).replace("\r\n", "\n").strip_edges()
	var wanted := "\n".join(PackedStringArray(expected))
	print("D07_MENU_ROWS_HASH:%s:%s" % [label, actual.sha256_text()])
	if actual != wanted:
		failed = true
		push_error("D07_MENU_ROWS_FAIL:" + label + "\n" + actual)
	else:
		print("D07_MENU_ROWS_PASS:" + label)

func open_menu(label: String) -> void:
	await tap(KEY_X)
	await frames(30)
	check(label + "-scene", "raise 'menu scene' unless SceneManager.scene.is_a?(Scene_Menu); c=SceneManager.scene.instance_variable_get(:@command_window); raise 'menu command' unless c.index == 0 && c.active")

func return_to_map(label: String) -> void:
	await tap(KEY_ESCAPE)
	await frames(30)
	check(label + "-map", "raise 'map scene' unless SceneManager.scene.is_a?(Scene_Map)")

func equip_state(actor: int) -> String:
	return "$game_actors[%d].equips.map {|e| e ? e.id : 0 } + [$game_party.item_number($data_weapons[1]),$game_party.item_number($data_weapons[2]),$game_party.item_number($data_armors[1]),$game_party.item_number($data_armors[2]),$game_party.item_number($data_armors[46])]" % actor

func _run() -> void:
	output = TestPaths.output("menu-operations")
	DirAccess.make_dir_recursive_absolute(output)
	error_path = output.path_join("d07-menu-error.txt")
	for name in ["menu_operations_reference.tsv", "menu_operations_scenes.tsv", "d07-menu-error.txt"]:
		if FileAccess.file_exists(output.path_join(name)):
			DirAccess.remove_absolute(output.path_join(name))
	driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	TestPaths.required("game_project")
	root.add_child(load("res://Scenes/Boot.tscn").instantiate())
	await frames(180)

	var fixture := TestPaths.ruby_setup() + FileAccess.get_file_as_string(TestPaths.fixture("menu_operations_reference.rb"))
	var setup := "$d07_host = true\n" + fixture + "\nD07Menu.prepare(" + JSON.stringify(output) + ")\nD07Menu.data_ops"
	if ruby(setup, "fixture-data-ops"):
		compare_rows("menu_operations_reference.tsv", DATA_ROWS, "data")

	# No-input scene states, driven by the real main fiber on Godot.
	var scene_cases := [
		["scene.menu", "Scene_Menu", 1],
		["scene.item", "Scene_Item", 1],
		["scene.skill", "Scene_Skill", 4],
		["scene.equip", "Scene_Equip", 1],
		["scene.status", "Scene_Status", 1],
	]
	ruby("SceneManager.instance_variable_set(:@background_bitmap, Bitmap.new(Graphics.width, Graphics.height)); Window_MenuCommand.init_command_position", "scene-background")
	for scene_case in scene_cases:
		ruby("D07Menu.reset_party; $game_party.menu_actor = $game_actors[%d]; SceneManager.goto(%s)" % [scene_case[2], scene_case[1]], scene_case[0] + "-goto")
		await frames(40)
		check(scene_case[0] + "-state", "raise 'scene' unless SceneManager.scene.is_a?(%s); D07Menu.read_scene('%s')" % [scene_case[1], scene_case[0]])
	ruby("SceneManager.goto(Scene_Map)", "scene-map-goto")
	await frames(60)
	check("scene-map-ready", "raise 'map scene' unless SceneManager.scene.is_a?(Scene_Map)")
	compare_rows("menu_operations_scenes.tsv", SCENE_ROWS, "scenes")

	ruby("D07Menu.reset_party; $game_actors[1].hp = 100; $game_actors[2].hp = 100; $game_actors[4].mp = $game_actors[4].mmp; $game_player.refresh", "operation-setup")
	await frames(5)
	var baseline := Vector3i(driver.GetViewportCount(), driver.GetSpriteCount(), driver.GetWindowCount())
	print("D07_MENU_COUNTS_BASELINE:%s" % baseline)

	# Item use: HP recovers and the consumable count drops.
	await open_menu("item-open")
	check("item-control", "raise 'control hp' unless $game_actors[1].hp == 100; raise 'control count' unless $game_party.item_number($data_items[1]) == 3")
	await screenshot("menu")
	await tap(KEY_Z)
	await frames(30)
	check("item-scene", "raise 'item scene' unless SceneManager.scene.is_a?(Scene_Item); iw=SceneManager.scene.instance_variable_get(:@item_window); raise 'item window' unless !iw.active && iw.index == -1")
	await tap(KEY_Z)
	check("item-list", "iw=SceneManager.scene.instance_variable_get(:@item_window); raise 'item list' unless iw.active && iw.index == 0 && iw.item && iw.item.id == 1")
	await tap(KEY_Z)
	check("item-target", "aw=SceneManager.scene.instance_variable_get(:@actor_window); raise 'item target' unless aw.active && aw.index == 0")
	await screenshot("item-target")
	await tap(KEY_Z)
	check("item-used", "$a=$game_actors[1]; raise 'item hp' unless $a.hp == $a.mhp; raise 'item count' unless $game_party.item_number($data_items[1]) == 2; raise 'item memory' unless $game_party.last_item.object.id == 1")
	await tap(KEY_ESCAPE)
	check("item-subwindow-hidden", "iw=SceneManager.scene.instance_variable_get(:@item_window); aw=SceneManager.scene.instance_variable_get(:@actor_window); raise 'subwindow' unless iw.active && !aw.visible")
	await tap(KEY_ESCAPE)
	check("item-category", "cw=SceneManager.scene.instance_variable_get(:@category_window); raise 'category not active' unless cw.active")
	await tap(KEY_ESCAPE)
	await frames(30)
	check("item-return", "raise 'item return' unless SceneManager.scene.is_a?(Scene_Menu); c=SceneManager.scene.instance_variable_get(:@command_window); raise 'item command' unless c.index == 0 && c.active")
	await return_to_map("item")

	# Skill use: MP is paid and the selected target receives the heal.
	await open_menu("skill-open")
	await tap(KEY_DOWN)
	check("skill-command", "c=SceneManager.scene.instance_variable_get(:@command_window); raise 'skill command' unless c.index == 1")
	await tap(KEY_Z)
	check("skill-personal", "st=SceneManager.scene.instance_variable_get(:@status_window); raise 'personal status' unless st.active && st.index == 0")
	await taps(KEY_DOWN, 3)
	check("skill-actor4", "st=SceneManager.scene.instance_variable_get(:@status_window); raise 'actor 4' unless st.index == 3")
	await tap(KEY_Z)
	await frames(40)
	check("skill-scene", "raise 'skill scene' unless SceneManager.scene.is_a?(Scene_Skill); c=SceneManager.scene.instance_variable_get(:@command_window); raise 'skill types' unless c.index == 0 && c.item_max == 2")
	await tap(KEY_DOWN)
	check("skill-magic", "c=SceneManager.scene.instance_variable_get(:@command_window); raise 'magic type' unless c.index == 1")
	await tap(KEY_Z)
	check("skill-list", "iw=SceneManager.scene.instance_variable_get(:@item_window); raise 'skill list' unless iw.active && iw.item_max == 1 && iw.item && iw.item.id == 26")
	await tap(KEY_Z)
	check("skill-target", "aw=SceneManager.scene.instance_variable_get(:@actor_window); raise 'skill target' unless aw.active && aw.index == 0")
	await tap(KEY_DOWN)
	check("skill-target2", "aw=SceneManager.scene.instance_variable_get(:@actor_window); raise 'skill target 2' unless aw.index == 1")
	await screenshot("skill-target")
	await tap(KEY_Z)
	check("skill-used", "raise 'skill mp' unless $game_actors[4].mp == 94; raise 'skill hp' unless $game_actors[2].hp == 367; raise 'skill memory' unless $game_actors[4].last_skill.object.id == 26; raise 'skill target memory' unless $game_party.target_actor.id == 2")
	await tap(KEY_ESCAPE)
	check("skill-subwindow-hidden", "iw=SceneManager.scene.instance_variable_get(:@item_window); raise 'skill window not active' unless iw.active")
	await tap(KEY_ESCAPE)
	check("skill-command-back", "c=SceneManager.scene.instance_variable_get(:@command_window); raise 'skill command not active' unless c.active")
	await tap(KEY_ESCAPE)
	await frames(30)
	check("skill-return", "raise 'skill return' unless SceneManager.scene.is_a?(Scene_Menu); c=SceneManager.scene.instance_variable_get(:@command_window); raise 'skill return command' unless c.index == 1 && c.active")
	await return_to_map("skill")

	# Equip: item selection, optimize, clear.
	await open_menu("equip-open")
	await taps(KEY_DOWN, 2)
	check("equip-command", "c=SceneManager.scene.instance_variable_get(:@command_window); raise 'equip command' unless c.index == 2")
	await tap(KEY_Z)
	check("equip-personal", "st=SceneManager.scene.instance_variable_get(:@status_window); raise 'equip personal' unless st.active && st.index == 3")
	await taps(KEY_UP, 3)
	check("equip-actor1", "st=SceneManager.scene.instance_variable_get(:@status_window); raise 'equip actor 1' unless st.index == 0")
	await tap(KEY_Z)
	await frames(40)
	check("equip-scene", "raise 'equip scene' unless SceneManager.scene.is_a?(Scene_Equip); c=SceneManager.scene.instance_variable_get(:@command_window); raise 'equip commands' unless c.index == 0 && c.item_max == 3")
	await tap(KEY_Z)
	check("equip-slot", "sw=SceneManager.scene.instance_variable_get(:@slot_window); raise 'equip slot' unless sw.active && sw.index == 0 && sw.item_max == 5")
	await tap(KEY_Z)
	check("equip-item", "iw=SceneManager.scene.instance_variable_get(:@item_window); raise 'equip item' unless iw.active && iw.index == 0 && iw.item_max == 2 && iw.item && iw.item.id == 2")
	await screenshot("equip-item")
	await tap(KEY_Z)
	check("equip-changed", "raise 'equip state' unless " + equip_state(1) + " == [2,46,0,1,0,1,0,0,1,0]")
	await tap(KEY_ESCAPE)
	check("equip-command-back", "c=SceneManager.scene.instance_variable_get(:@command_window); raise 'command back' unless c.active && c.index == 0")
	await tap(KEY_RIGHT)
	check("equip-optimize-index", "c=SceneManager.scene.instance_variable_get(:@command_window); raise 'optimize index' unless c.index == 1")
	await tap(KEY_Z)
	check("equip-optimized", "raise 'optimize state' unless " + equip_state(1) + " == [2,46,0,2,0,1,0,1,0,0]")
	await tap(KEY_RIGHT)
	check("equip-clear-index", "c=SceneManager.scene.instance_variable_get(:@command_window); raise 'clear index' unless c.index == 2")
	await tap(KEY_Z)
	check("equip-cleared", "raise 'clear state' unless " + equip_state(1) + " == [0,0,0,0,0,1,1,1,1,1]")
	await tap(KEY_ESCAPE)
	await frames(30)
	check("equip-return", "raise 'equip return' unless SceneManager.scene.is_a?(Scene_Menu); c=SceneManager.scene.instance_variable_get(:@command_window); raise 'equip return command' unless c.index == 2 && c.active")
	await return_to_map("equip")

	# Formation: pending selection then swap.
	await open_menu("formation-open")
	await taps(KEY_DOWN, 4)
	check("formation-command", "c=SceneManager.scene.instance_variable_get(:@command_window); raise 'formation command' unless c.index == 4")
	await tap(KEY_Z)
	check("formation-personal", "st=SceneManager.scene.instance_variable_get(:@status_window); raise 'formation personal' unless st.active && st.index == 0")
	await tap(KEY_Z)
	check("formation-pending", "st=SceneManager.scene.instance_variable_get(:@status_window); raise 'formation pending' unless st.pending_index == 0")
	await tap(KEY_DOWN)
	check("formation-selected", "st=SceneManager.scene.instance_variable_get(:@status_window); raise 'formation selected' unless st.index == 1")
	await screenshot("formation-pending")
	await tap(KEY_Z)
	check("formation-swapped", "raise 'formation order' unless $game_party.members.map {|a| a.id } == [2,1,3,4]; st=SceneManager.scene.instance_variable_get(:@status_window); raise 'formation pending reset' unless st.pending_index == -1")
	await tap(KEY_ESCAPE)
	check("formation-cancel-command", "st=SceneManager.scene.instance_variable_get(:@status_window); c=SceneManager.scene.instance_variable_get(:@command_window); raise 'formation cancel' unless st.pending_index == -1 && st.index == -1 && !st.active && c.active")
	await tap(KEY_ESCAPE)
	await frames(30)
	check("formation-map", "raise 'formation map' unless SceneManager.scene.is_a?(Scene_Map)")

	# Status: actor switching and return.
	await open_menu("status-open")
	await taps(KEY_DOWN, 3)
	check("status-command", "c=SceneManager.scene.instance_variable_get(:@command_window); raise 'status command' unless c.index == 3")
	await tap(KEY_Z)
	check("status-personal", "st=SceneManager.scene.instance_variable_get(:@status_window); raise 'status personal' unless st.active && st.index == 1")
	await tap(KEY_Z)
	await frames(40)
	check("status-scene", "raise 'status scene' unless SceneManager.scene.is_a?(Scene_Status); sw=SceneManager.scene.instance_variable_get(:@status_window); raise 'status actor 1' unless sw.instance_variable_get(:@actor).id == 1")
	await screenshot("status-actor1")
	await tap(KEY_PAGEDOWN)
	check("status-next", "sw=SceneManager.scene.instance_variable_get(:@status_window); raise 'status next' unless sw.instance_variable_get(:@actor).id == 3")
	await screenshot("status-actor3")
	await tap(KEY_PAGEUP)
	check("status-prev", "sw=SceneManager.scene.instance_variable_get(:@status_window); raise 'status prev' unless sw.instance_variable_get(:@actor).id == 1")
	await tap(KEY_ESCAPE)
	await frames(30)
	check("status-return", "raise 'status return' unless SceneManager.scene.is_a?(Scene_Menu); c=SceneManager.scene.instance_variable_get(:@command_window); raise 'status return command' unless c.index == 3 && c.active")
	await return_to_map("status")

	# Restore the controlled fixture state and confirm live resources return.
	ruby("D07Menu.restore", "restore")
	check("restore-party", "raise 'restore party' unless $game_party.members.map {|a| a.id } == [1]; raise 'restore equips' unless " + equip_state(1) + " == [1,46,0,1,0,0,1,0,1,0]; raise 'restore variance' unless $data_skills[26].damage.variance == 20")
	check("restore-vitals", "raise 'restore hp' unless $game_actors[1].hp == $game_actors[1].mhp; raise 'restore mp' unless $game_actors[4].mp == $game_actors[4].mmp; raise 'restore menu actor' unless $game_party.menu_actor.id == 1; raise 'restore target actor' unless $game_party.target_actor.id == 1")
	ruby("SceneManager.background_bitmap.dispose if SceneManager.background_bitmap; SceneManager.instance_variable_set(:@background_bitmap, nil)", "dispose-background")
	await frames(30)
	var final_counts := Vector3i(driver.GetViewportCount(), driver.GetSpriteCount(), driver.GetWindowCount())
	print("D07_MENU_COUNTS_FINAL:%s" % final_counts)
	if final_counts != baseline:
		failed = true
		push_error("D07_MENU_COUNTS_CHANGED:%s:%s" % [baseline, final_counts])
	driver.Shutdown()
	print("D07_MENU_PASS" if not failed else "D07_MENU_FAIL")
	quit(0 if not failed else 1)
