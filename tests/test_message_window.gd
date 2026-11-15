extends SceneTree

# Standalone rendered D05 runner; suite registration belongs to the lead.
var driver
var output := ""
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func ruby(code: String, label: String) -> bool:
	var guarded := "begin\n" + code + "\nrescue Exception => e\nFile.open(" + JSON.stringify(output.path_join("d05-message-error.txt")) + ", 'w') { |f| f.puts(e.class.to_s, e.message, e.backtrace) }; raise\nend"
	if not driver.RunRuby(guarded):
		failed = true
		push_error("D05_MESSAGE_CHECK_FAIL:" + label)
		return false
	print("D05_MESSAGE_CHECK_PASS:" + label)
	return true

func frames(count: int) -> void:
	for frame in range(count):
		if failed:
			return
		if not ruby_step():
			return
		driver.UpdateRenderManager()
		await process_frame
		await RenderingServer.frame_post_draw

func ruby_step() -> bool:
	if not driver.RunRuby("begin; D05Message.step; rescue Exception => e; File.open(" + JSON.stringify(output.path_join("d05-message-error.txt")) + ", 'w') { |f| f.puts(e.class.to_s, e.message, e.backtrace) }; raise; end"):
		failed = true
		push_error("D05_MESSAGE_CHECK_FAIL:window-update")
		return false
	return true

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame
	await frames(1)

func tap(code: Key) -> void:
	await key(code, true)
	await key(code, false)

func screenshot(name: String) -> void:
	driver.UpdateRenderManager()
	await process_frame
	await RenderingServer.frame_post_draw
	var path := output.path_join("d05-message-" + name + ".png")
	if root.get_texture().get_image().save_png(path) != OK:
		failed = true
		push_error("D05_MESSAGE_CAPTURE_FAIL:" + path)
	else:
		print("D05_MESSAGE_CAPTURE:" + path)
	# These original full-frame goldens include the Windows GDI Arial raster.
	if name.begins_with("baseline-") and OS.get_name() == "Windows":
		var expected := {
			"baseline-text": "ab810625251aa09b21dbec02c4f233ead5955828e21f8d6992adda8520e7b58a",
			"baseline-choice": "88fd2b518f404f6c40063cff96387a1378f9a516b91a89e096bd5cfee6f37f9b",
			"baseline-number": "58c92e870dea9269b79b59cd1ce083ca739cac33273a263ae13e9b9b2ba50de0",
			"baseline-item": "8d56aed44b1e4743d811c19283fc11a8d913aad0938e6336d060ae0f5cec8ff3",
		}
		var image := root.get_texture().get_image()
		image.convert(Image.FORMAT_RGBA8)
		var hash := HashingContext.new()
		hash.start(HashingContext.HASH_SHA256)
		hash.update(image.get_data())
		if hash.finish().hex_encode() != expected[name]:
			failed = true
			push_error("D05_MESSAGE_PIXEL_FAIL:" + name)
		else:
			print("D05_MESSAGE_PIXEL_PASS:" + name)

func finish_case() -> void:
	await frames(16)
	if not failed:
		ruby("D05Message.completed", "completed-fibers-and-interpreter")
	ruby("D05Message.stop", "dispose-case")

func _run() -> void:
	Engine.max_fps = 60
	output = ProjectSettings.globalize_path("res://.omo/evidence/d05-message/godot")
	DirAccess.make_dir_recursive_absolute(output)
	for name in ["message_window_reference.tsv", "d05-message-error.txt"]:
		if FileAccess.file_exists(output.path_join(name)):
			DirAccess.remove_absolute(output.path_join(name))
	driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	driver.Initialize(host)
	await process_frame
	var bootstrap := "module Kernel; module_function :eval; end\n"
	for name in ["kernel", "tone", "rect", "color", "font", "graphics", "input", "audio", "sprite", "bitmap", "viewport", "plane", "window", "table", "tilemap", "rgss_error", "rgss_reset"]:
		bootstrap += "require '" + name + "'\n"
	bootstrap += "Unity.run_rmva_scripts\n"
	bootstrap += "File.open(File.join(Unity.rmva_project_path, 'RMProject/Data/Scripts.rvdata2'),'rb') { |f| Marshal.load(f).each { |s| Unity.register_rmva_script(s[0],s[1],s[2]) unless s[1] == 'Main' } }\nUnity.run_rmva_scripts.each { |s| s.call }\n$rmva_project_base_path = Unity.rmva_project_path; $rtp_path = Unity.rtp_path; require 'patch_rmva'\n$d05_host = true\n"
	bootstrap += FileAccess.get_file_as_string("res://tests/fixtures/message_window_reference.rb")
	if not ruby(bootstrap, "load-stock-classes"):
		driver.Shutdown()
		quit(1)
		return
	ruby("D05Message.prepare(" + JSON.stringify(output) + ")", "prepare-real-resources")
	for name in ["text", "choice", "choice-cancel", "number", "item", "item-cancel", "fast", "scroll", "scroll-no-fast"]:
		if failed:
			break
		ruby("D05Message.start(" + JSON.stringify(name) + ")", "baseline-start-" + name)
		await frames(40)
		if name == "choice":
			ruby("D05Message.capture_choice_contents", "choice-contents-capture")
		if name in ["text", "choice", "number", "item"]:
			await screenshot("baseline-" + name)
		ruby("D05Message.stop", "baseline-dispose-" + name)
	if not failed:
		var actual := FileAccess.get_file_as_string(output.path_join("message_window_reference.tsv")).replace("\r\n", "\n").strip_edges()
		print("D05_MESSAGE_BASELINE_ROWS:%d" % actual.split("\n").size())
		print("D05_MESSAGE_BASELINE_HASH:" + actual.sha256_text())
		if actual.split("\n").size() != 360 or actual.sha256_text() != "c5980e4baf11cc53966db0b1fd686e12cad02f89e2d6c26ec18af1f65a5a10bb":
			failed = true
			push_error("D05_MESSAGE_BASELINE_FAIL:360 original no-input rows differ")
		else:
			print("D05_MESSAGE_BASELINE_PASS:360")
	# Interactions use real Godot key events, then the stock Input.update chain.
	if not failed:
		ruby("D05Message.start('text')", "text-start")
		await frames(20)
		ruby("D05Message.blocked; D05Message.check(D05Message.instance_variable_get(:@message).pause, 'page pause')", "text-page-blocked")
		await tap(KEY_ENTER)
		await frames(12)
		ruby("D05Message.blocked; D05Message.check(D05Message.instance_variable_get(:@message).pause, 'escape pause')", "text-escape-pause")
		await screenshot("text-second-page")
		await tap(KEY_ESCAPE)
		await frames(20)
		await finish_case()
	if not failed:
		ruby("D05Message.start('fast')", "fast-start")
		await frames(8)
		ruby("D05Message.blocked", "fast-before-trigger")
		await key(KEY_ENTER, true)
		ruby("D05Message.check(D05Message.instance_variable_get(:@message).instance_variable_get(:@show_fast), 'confirm fast flag'); D05Message.check(D05Message.instance_variable_get(:@message).instance_variable_get(:@pause_skip), 'pause skip flag')", "fast-trigger-and-skip")
		await key(KEY_ENTER, false)
		await finish_case()
	for name in ["choice", "choice-cancel"]:
		if failed:
			break
		ruby("D05Message.start(" + JSON.stringify(name) + ")", name + "-start")
		await frames(10)
		ruby("D05Message.blocked; D05Message.check(D05Message.instance_variable_get(:@choice).active, 'choice active')", name + "-blocked")
		if name == "choice":
			await tap(KEY_DOWN)
			ruby("D05Message.check(D05Message.instance_variable_get(:@choice).index == 1, 'choice cursor')", "choice-navigation")
			await screenshot("choice-blue")
		await tap(KEY_ENTER if name == "choice" else KEY_ESCAPE)
		await finish_case()
		ruby("D05Message.check($game_variables[1] == %d, 'choice branch')" % (22 if name == "choice" else 33), name + "-branch")
	if not failed:
		ruby("D05Message.start('number')", "number-start")
		await frames(10)
		ruby("D05Message.blocked; D05Message.check(D05Message.instance_variable_get(:@number).instance_variable_get(:@number) == 999, 'digits clamp')", "number-clamp")
		await tap(KEY_UP)
		await tap(KEY_RIGHT)
		await tap(KEY_DOWN)
		await tap(KEY_LEFT)
		await tap(KEY_LEFT)
		ruby("n = D05Message.instance_variable_get(:@number); D05Message.check(n.instance_variable_get(:@number) == 89 && n.instance_variable_get(:@index) == 2, 'digit arithmetic and cursor wrap')", "number-digits-and-wrap")
		await screenshot("number-089")
		await tap(KEY_ESCAPE)
		ruby("D05Message.blocked; D05Message.check(D05Message.instance_variable_get(:@number).active && $game_variables[2] == 9876, 'number cancel ignored')", "number-cancel-ignored")
		await tap(KEY_ENTER)
		await finish_case()
		ruby("D05Message.check($game_variables[2] == 89, 'number accepted')", "number-result")
	for name in ["item", "item-cancel"]:
		if failed:
			break
		ruby("D05Message.start(" + JSON.stringify(name) + ")", name + "-start")
		await frames(10)
		ruby("D05Message.blocked; D05Message.check(D05Message.instance_variable_get(:@item).item_max == 2, 'two real key items')", name + "-blocked")
		if name == "item":
			await tap(KEY_RIGHT)
			ruby("D05Message.check(D05Message.instance_variable_get(:@item).item.id == 2, 'item navigation')", "item-navigation")
			await screenshot("item-silver")
		await tap(KEY_ENTER if name == "item" else KEY_ESCAPE)
		await finish_case()
		if not failed:
			ruby("D05Message.check($game_variables[3] == %d, 'item result')" % (2 if name == "item" else 0), name + "-result")
	for name in ["scroll", "scroll-no-fast"]:
		if failed:
			break
		ruby("D05Message.start(" + JSON.stringify(name) + ")", name + "-start")
		await frames(2)
		if failed:
			break
		ruby("D05Message.blocked; $d05_scroll_before = D05Message.instance_variable_get(:@scroll).instance_variable_get(:@scroll_pos)", name + "-blocked")
		await key(KEY_SHIFT, true)
		if failed:
			break
		ruby("D05Message.check(D05Message.instance_variable_get(:@scroll).instance_variable_get(:@scroll_pos) - $d05_scroll_before == %d, 'scroll fast policy')" % (8 if name == "scroll" else 4), name + "-fast-policy")
		await frames(55 if name == "scroll" else 115)
		await key(KEY_SHIFT, false)
		await finish_case()
	if failed:
		await screenshot("failure")
	ruby("D05Message.close", "restore-fixture-globals")
	driver.Shutdown()
	print("D05_MESSAGE_PASS" if not failed else "D05_MESSAGE_FAIL")
	quit(0 if not failed else 1)
