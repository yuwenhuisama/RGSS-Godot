extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	driver.Initialize(host)
	var ok: bool = driver.RunRuby("""
require 'kernel'; require 'resource_lifecycle'
$reset_attempts = 0
rgss_main do
  $reset_attempts += 1
  raise RGSSReset if $reset_attempts == 1
end
run_rgss_main_callback
raise 'reset callback retry' unless $reset_attempts == 2
""")
	driver.Shutdown()
	print("RESET_CALLBACK_PASS" if ok else "RESET_CALLBACK_FAIL")
	quit(0 if ok else 1)
