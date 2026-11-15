extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	driver.Initialize(host)
	var ok: bool = driver.RunRuby("require 'kernel'; require 'input'; raise 'Input constant' unless Input::DOWN == :DOWN")
	await process_frame
	ok = driver.RunRuby("[:UNSUPPORTED,1,nil].each { |key| raise 'invalid Input key must return false' unless Input.press?(key) == false && Input.trigger?(key) == false && Input.repeat?(key) == false }") and ok
	for entry in [[KEY_ESCAPE,"B"],[KEY_X,"B"],[KEY_ENTER,"C"],[KEY_SPACE,"C"],[KEY_Z,"C"],[KEY_SHIFT,"A"],[KEY_Q,"L"],[KEY_W,"R"],[KEY_D,"Z"],[KEY_A,"X"],[KEY_S,"Y"],[KEY_PAGEUP,"L"],[KEY_PAGEDOWN,"R"]]:
		var event := InputEventKey.new()
		event.keycode = entry[0]
		event.pressed = true
		Input.parse_input_event(event)
		await process_frame
		ok = driver.RunRuby("Input.update; raise 'key mapping %s/%s' unless Input.press?(Input::%s) && Input.trigger?(Input::%s) && Input.repeat?(Input::%s)" % [entry[0],entry[1],entry[1],entry[1],entry[1]]) and ok
		event = InputEventKey.new()
		event.keycode = entry[0]
		event.pressed = false
		Input.parse_input_event(event)
		await process_frame
		ok = driver.RunRuby("Input.update; raise 'released key %s' if Input.press?(Input::%s)" % [entry[1],entry[1]]) and ok
	var held := InputEventKey.new()
	held.keycode = KEY_RIGHT
	held.pressed = true
	Input.parse_input_event(held)
	await process_frame
	ok = driver.RunRuby("Input.update; raise 'first held frame' unless Input.repeat?(:RIGHT)") and ok
	ok = driver.RunRuby("22.times { Input.update; raise 'early repeated key' if Input.repeat?(:RIGHT) }; Input.update; raise 'repeat start frame' unless Input.repeat?(:RIGHT); 5.times { Input.update; raise 'repeat interval early' if Input.repeat?(:RIGHT) }; Input.update; raise 'repeat interval' unless Input.repeat?(:RIGHT)") and ok
	held = InputEventKey.new()
	held.keycode = KEY_RIGHT
	held.pressed = false
	Input.parse_input_event(held)
	await process_frame
	driver.RunRuby("Input.update")
	driver.Shutdown()
	print("INPUT_MAPPING_PASS" if ok else "INPUT_MAPPING_FAIL")
	quit(0 if ok else 1)
