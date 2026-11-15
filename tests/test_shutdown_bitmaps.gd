extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var host := Node.new()
	root.add_child(host)
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	driver.Initialize(host)
	var ok: bool = driver.RunRuby("require 'color'; require 'tone'; require 'rect'; require 'font'; require 'bitmap'; $shutdown_bitmap=Bitmap.new(16,16); $shutdown_bitmap.fill_rect(0,0,16,16,Color.new(255,0,0))")
	var before: int = driver.GetPendingBitmapCount()
	ok = driver.RunRuby("Unity.register_update_fiber(Fiber.new { loop { Fiber.yield } })") and ok
	ok = driver.RunRuby("Unity.register_rmva_script(999,'old-vm','')") and ok
	driver.Shutdown()
	var after: int = driver.GetPendingBitmapCount()
	print("SHUTDOWN_BITMAPS:%d->%d" % [before,after])
	if before != 1 or after != 0:
		push_error("VM shutdown retains pending bitmap ownership")
		ok = false
	if driver.HasUpdateFiber():
		push_error("VM shutdown retains its registered update fiber")
		ok = false
	for frame in range(6):
		await process_frame
	driver.Initialize(host)
	ok = driver.RunRuby("raise 'old VM scripts retained' unless Unity.run_rmva_scripts.empty?") and ok
	driver.Shutdown()
	print("SHUTDOWN_BITMAPS_PASS" if ok else "SHUTDOWN_BITMAPS_FAIL")
	quit(0 if ok else 1)
