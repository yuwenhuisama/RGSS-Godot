extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	driver.Initialize(host)
	var cases := [
		["valid Ruby", "1 + 2", true],
		["raised Ruby exception", "raise 'intentional regression failure'", false],
		["valid Ruby after exception", "2 + 3", true],
		["syntax error", "def incomplete(", false],
		["missing method", "Object.new.missing_compatibility_method", false],
		["valid Ruby after syntax error", "3 + 4", true],
		["managed binding exception", "b = Unity::Bitmap.new_wh(1, 1); b.dispose; b.get_pixel(0, 0)", false],
		["valid Ruby after managed exception", "4 + 5", true],
	]
	var failed := 0
	for entry in cases:
		var actual: bool = driver.RunRuby(entry[1])
		if actual != entry[2]:
			failed += 1
			push_error("%s: expected %s got %s" % [entry[0], entry[2], actual])
	driver.Shutdown()
	print("RUBY_ERRORS_PASS" if failed == 0 else "RUBY_ERRORS_FAIL:%d" % failed)
	quit(0 if failed == 0 else 1)
