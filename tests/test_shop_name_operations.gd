extends SceneTree

const TestPaths = preload("res://tools/test_paths.gd")

var driver
var ok := true

func _initialize() -> void:
	call_deferred("_run")

func frames(count: int) -> void:
	for frame in range(count):
		await process_frame
		await RenderingServer.frame_post_draw

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await frames(2)
	event = InputEventKey.new()
	event.keycode = code
	event.pressed = false
	Input.parse_input_event(event)
	await frames(12)

func check(code: String) -> void:
	ok = driver.RunRuby(code) and ok

func _run() -> void:
	driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	TestPaths.required("game_project")
	root.add_child(load("res://Scenes/Boot.tscn").instantiate())
	await frames(180)
	check("DataManager.setup_new_game; SceneManager.goto(Scene_Map)")
	await frames(180)
	var baseline := Vector3i(driver.GetViewportCount(), driver.GetSpriteCount(), driver.GetWindowCount())
	var output := TestPaths.output("shop-name")
	DirAccess.make_dir_recursive_absolute(output)
	var reference_path := output.path_join("shop_name_reference.tsv")
	if FileAccess.file_exists(reference_path):
		DirAccess.remove_absolute(reference_path)
	check("$shop_name_host=true; $rgss_compat_output=" + JSON.stringify(output) + "\n" + TestPaths.ruby_setup() + FileAccess.get_file_as_string(TestPaths.fixture("shop_name_reference.rb")))
	var original := FileAccess.get_file_as_string(TestPaths.fixture("shop_name_original.tsv")).replace("\r\n", "\n").strip_edges()
	var actual := FileAccess.get_file_as_string(reference_path).replace("\r\n", "\n").strip_edges()
	if original.is_empty() or actual != original:
		push_error("Shop/name numeric reference differs from original RGSS300")
		ok = false
	check("bitmap=Bitmap.new(180,140); [[1.8,2.8,112,24],[0,57.6,112,24],[-1.8,2.8,112.8,24.8]].each { |rect| bitmap.draw_text(*rect,'Actor') }; [[1.8,2.8],[0,57.6],[-1.8,2.8]].each { |position| bitmap.blt(*position,bitmap,Rect.new(0,0,2,2)) }; bitmap.dispose")
	check("$shop_saved_gold=$game_party.gold; $shop_item=RPG::Item.new; $shop_item.id=$data_items.size; $shop_item.name='Compatibility Potion'; $shop_item.price=40; $data_items << $shop_item; $game_party.gain_gold(200-$game_party.gold); SceneManager.call(Scene_Shop); SceneManager.scene.prepare([[0,$shop_item.id,1,40]],false)")
	await frames(60)
	check("raise 'shop not ready' unless SceneManager.scene.is_a?(Scene_Shop)")
	await key(KEY_ENTER)
	await key(KEY_ENTER)
	await key(KEY_RIGHT)
	root.get_texture().get_image().save_png(output.path_join("buy-two.png"))
	await key(KEY_ENTER)
	check("raise 'purchase quantity/gold' unless $game_party.item_number($shop_item)==2 && $game_party.gold==120")
	await key(KEY_ENTER)
	await key(KEY_RIGHT)
	await key(KEY_ESCAPE)
	check("raise 'cancelled quantity changed inventory/gold' unless $game_party.item_number($shop_item)==2 && $game_party.gold==120")
	await key(KEY_ESCAPE)
	await key(KEY_RIGHT)
	await key(KEY_ENTER)
	await key(KEY_ENTER)
	await key(KEY_ENTER)
	root.get_texture().get_image().save_png(output.path_join("sell-one.png"))
	await key(KEY_ENTER)
	check("raise 'sale quantity/gold' unless $game_party.item_number($shop_item)==1 && $game_party.gold==140")
	await key(KEY_ESCAPE)
	await key(KEY_ESCAPE)
	await key(KEY_ESCAPE)
	await frames(60)
	check("raise 'shop return map' unless SceneManager.scene.is_a?(Scene_Map); $game_party.lose_gold($game_party.gold); SceneManager.call(Scene_Shop); SceneManager.scene.prepare([[0,$shop_item.id,1,40]],true)")
	await frames(60)
	await key(KEY_ENTER)
	await key(KEY_ENTER)
	check("raise 'unaffordable purchase changed inventory' unless $game_party.gold==0 && $game_party.item_number($shop_item)==1; raise 'unaffordable purchase opened number window' if SceneManager.scene.instance_variable_get(:@number_window).active; raise 'purchase-only sale enabled' if SceneManager.scene.instance_variable_get(:@command_window).command_enabled?(1)")
	await key(KEY_ESCAPE)
	await key(KEY_ESCAPE)
	await frames(60)
	for item_class in ["RPG::Weapon", "RPG::Armor"]:
		var collection: String = "$data_weapons" if item_class == "RPG::Weapon" else "$data_armors"
		var goods_type := 1 if item_class == "RPG::Weapon" else 2
		check("raise 'goods entry not map' unless SceneManager.scene.is_a?(Scene_Map); $shop_gear=%s.new; $shop_gear.id=%s.size; $shop_gear.name='Compatibility Gear'; %s << $shop_gear; SceneManager.call(Scene_Shop); SceneManager.scene.prepare([[%d,$shop_gear.id,1,0]],true)" % [item_class,collection,collection,goods_type])
		await frames(60)
		await key(KEY_ENTER)
		root.get_texture().get_image().save_png(output.path_join("gear-status-%d.png" % goods_type))
		await key(KEY_ENTER)
		await key(KEY_ENTER)
		check("raise 'free gear purchase' unless $game_party.item_number($shop_gear)==1 && $game_party.gold==0")
		if not ok:
			print("SHOP_NAME_OPERATIONS_FAIL")
			quit(1)
			return
		await key(KEY_ESCAPE)
		await key(KEY_ESCAPE)
		await frames(60)
		check("raise 'gear return map' unless SceneManager.scene.is_a?(Scene_Map); $game_party.lose_item($shop_gear,99); %s.pop" % collection)
	check("raise 'purchase-only return map' unless SceneManager.scene.is_a?(Scene_Map); $name_actor=$game_party.members[0]; $name_saved=$name_actor.name; $name_actor.name='AB'; SceneManager.call(Scene_Name); SceneManager.scene.prepare($name_actor.id,3)")
	await frames(60)
	await key(KEY_ESCAPE)
	check("raise 'name backspace' unless SceneManager.scene.instance_variable_get(:@edit_window).name=='A'")
	check("$name_character=SceneManager.scene.instance_variable_get(:@input_window).character; raise 'name first character absent' if $name_character.empty?")
	await key(KEY_ENTER)
	await key(KEY_ENTER)
	await key(KEY_ENTER)
	check("raise 'name maximum boundary' unless SceneManager.scene.instance_variable_get(:@edit_window).name=='A'+$name_character*2")
	root.get_texture().get_image().save_png(output.path_join("name-max.png"))
	await key(KEY_SHIFT)
	await key(KEY_ENTER)
	await frames(60)
	check("raise 'name confirm/return' unless SceneManager.scene.is_a?(Scene_Map) && $name_actor.name=='A'+$name_character*2; $name_actor.name='AB'; SceneManager.call(Scene_Name); SceneManager.scene.prepare($name_actor.id,3)")
	await frames(60)
	await key(KEY_ESCAPE)
	await key(KEY_ESCAPE)
	await key(KEY_SHIFT)
	await key(KEY_ENTER)
	check("raise 'empty name did not restore default' unless SceneManager.scene.is_a?(Scene_Name) && SceneManager.scene.instance_variable_get(:@edit_window).name=='AB'; raise 'empty confirmation committed too early' unless $name_actor.name=='AB'")
	await key(KEY_ENTER)
	await frames(60)
	check("raise 'restored name confirm/return' unless SceneManager.scene.is_a?(Scene_Map) && $name_actor.name=='AB'; $name_actor.name=$name_saved; $game_party.lose_item($shop_item,99); $data_items.pop; $game_party.gain_gold($shop_saved_gold-$game_party.gold)")
	await frames(30)
	var returned := Vector3i(driver.GetViewportCount(), driver.GetSpriteCount(), driver.GetWindowCount())
	if returned != baseline:
		push_error("Shop/name return changed live resources: %s -> %s" % [baseline,returned])
		ok = false
	print("SHOP_NAME_OPERATIONS_PASS" if ok else "SHOP_NAME_OPERATIONS_FAIL")
	quit(0 if ok else 1)
