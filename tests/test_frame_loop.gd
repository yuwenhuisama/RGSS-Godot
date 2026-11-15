extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	driver.Initialize(host)
	var ok: bool = driver.RunRuby("require 'graphics'; require 'rgss_reset'; Graphics.frame_count=0; $loop_steps=0; $loop_fiber=Fiber.new {30.times {$loop_steps+=1; Graphics.update}; Graphics.wait(4)}")
	for frame in range(34):
		driver.UpdateRenderManager()
		var resumed: bool = driver.RunRuby("$loop_fiber.resume")
		ok = resumed and ok
		await process_frame
		await RenderingServer.frame_post_draw
		var counted: bool = driver.RunRuby("raise 'frame counter cadence' unless Graphics.frame_count==%d; raise 'loop iteration cadence' unless $loop_steps==%d" % [frame+1, mini(frame+1,30)])
		ok = counted and ok
	ok = driver.RunRuby("$loop_fiber.resume; raise 'loop not finished' if $loop_fiber.alive?; raise 'frame_reset changed count' unless (Graphics.frame_reset; Graphics.frame_count)==34") and ok
	driver.Shutdown()
	print("FRAME_LOOP_PASS" if ok else "FRAME_LOOP_FAIL")
	quit(0 if ok else 1)
