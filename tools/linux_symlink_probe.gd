extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	driver.Initialize(host)
	var ok: bool = driver.RunRuby("require 'ext/dir'; {'target.txt'=>false, 'target-dir'=>false, 'file-link'=>true, 'dir-link'=>true, 'dangling-link'=>true, 'missing'=>false}.each { |name, expected| actual = File.symlink?('/tmp/rgss-symlink/' + name); raise name + ': ' + actual.inspect unless actual == expected; puts name + '\\t' + actual.to_s }")
	driver.Shutdown()
	print("LINUX_MANAGED_SYMLINK_PASS:6" if ok else "LINUX_MANAGED_SYMLINK_FAIL")
	quit(0 if ok else 1)
