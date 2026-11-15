extends SceneTree

const TestPaths = preload("res://tools/test_paths.gd")

var driver

func _initialize() -> void:
	call_deferred("_run")

func frames(count: int) -> void:
	for i in range(count):
		await process_frame
		await RenderingServer.frame_post_draw

func _run() -> void:
	driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	TestPaths.required("game_project")
	root.add_child(load("res://Scenes/Boot.tscn").instantiate())
	await frames(180)
	var ok: bool = driver.RunRuby("raise 'title not ready' unless SceneManager.scene.is_a?(Scene_Title); DataManager.setup_new_game; SceneManager.goto(Scene_Map)")
	await frames(180)
	ok = ok and driver.RunRuby("raise 'map not ready' unless SceneManager.scene.is_a?(Scene_Map)")
	var baseline := Vector3i(driver.GetViewportCount(), driver.GetSpriteCount(), driver.GetWindowCount())
	var output := TestPaths.output("menu")
	DirAccess.make_dir_recursive_absolute(output)
	root.get_texture().get_image().save_png(output.path_join("map_before.png"))
	for cycle in range(3):
		var entered: bool = driver.RunRuby("$menu_capture = Graphics.snap_to_bitmap; SceneManager.scene.call_menu")
		ok = entered and ok
		await frames(60)
		var menu_ready: bool = driver.RunRuby("raise 'menu not ready' unless SceneManager.scene.is_a?(Scene_Menu); $menu_background = SceneManager.background_bitmap; raise 'snapshot dimensions' unless $menu_background.width == Graphics.width; raise 'menu background disposed' if $menu_background.disposed?; raise 'background not wired' unless SceneManager.scene.instance_variable_get(:@background_sprite).bitmap.equal?($menu_background)")
		ok = menu_ready and ok
		if cycle == 0:
			root.get_texture().get_image().save_png(output.path_join("menu.png"))
			for submenu in ["Scene_Item", "Scene_Skill", "Scene_Equip", "Scene_Status", "Scene_Save", "Scene_End"]:
				var called: bool = driver.RunRuby("SceneManager.call(%s)" % submenu)
				ok = called and ok
				await frames(60)
				var child_ready: bool = driver.RunRuby("raise 'submenu not ready' unless SceneManager.scene.is_a?(%s); raise 'submenu snapshot changed' unless SceneManager.background_bitmap.equal?($menu_background); raise 'submenu background disposed' if $menu_background.disposed?; SceneManager.return" % submenu)
				ok = child_ready and ok
				await frames(60)
				var menu_returned: bool = driver.RunRuby("raise 'submenu return not menu' unless SceneManager.scene.is_a?(Scene_Menu)")
				ok = menu_returned and ok
				print("MENU_SUBSCENE_RESULT:%s:%s" % [submenu, called and child_ready and menu_returned])
		var left: bool = driver.RunRuby("SceneManager.return")
		ok = left and ok
		await frames(60)
		ok = ok and driver.RunRuby("raise 'return map not ready' unless SceneManager.scene.is_a?(Scene_Map); $menu_capture.dispose")
		var returned := Vector3i(driver.GetViewportCount(), driver.GetSpriteCount(), driver.GetWindowCount())
		print("MENU_ROUND_TRIP_COUNTS:%d:%s:%s" % [cycle, baseline, returned])
		if returned != baseline:
			push_error("Menu return changed live resource counts")
			ok = false
	root.get_texture().get_image().save_png(output.path_join("map_after.png"))
	print("MENU_ROUND_TRIP_PASS" if ok else "MENU_ROUND_TRIP_FAIL")
	quit(0 if ok else 1)
