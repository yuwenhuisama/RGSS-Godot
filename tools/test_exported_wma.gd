extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		push_error("Usage: exported executable -s test_exported_wma.gd -- ABSOLUTE_WMA")
		quit(1)
		return
	var driver = load("res://Scripts/AudioFormatTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	driver.Initialize(host)
	driver.SetFfmpegPath("")
	var cache: String = driver.GetWmaCachePath(args[0])
	if FileAccess.file_exists(cache) and DirAccess.remove_absolute(cache) != OK:
		push_error("Cannot clear owned exported-WMA cache")
		quit(1)
		return
	var stream = driver.LoadStream(args[0])
	var ok: bool = stream is AudioStreamWAV
	if ok:
		ok = stream.mix_rate == 22050 and stream.data.size() == 20480
	print("EXPORTED_WMA_DIAGNOSTIC:" + driver.GetLastLoadDiagnostic())
	driver.Shutdown()
	print("EXPORTED_WMA_PASS" if ok else "EXPORTED_WMA_FAIL")
	quit(0 if ok else 1)
