extends SceneTree

const ITERATIONS := 6
const OBJECTS_PER_ITERATION := 60
const NODE_TOLERANCE := 8

var _driver
var _root: Node


func _initialize() -> void:
	var driver_script := load("res://Scripts/StressDisposeTestDriver.cs")
	_driver = driver_script.new()
	_root = Node.new()
	_root.name = "StressDisposeRoot"
	root.add_child(_root)

	var exit_code := 1
	var baseline_nodes := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)

	_driver.Initialize(_root)
	for i in range(3):
		_driver.UpdateRenderManager()
		await process_frame

	var baseline_viewports: int = _driver.GetViewportCount()
	var baseline_sprites: int = _driver.GetSpriteCount()
	var baseline_windows: int = _driver.GetWindowCount()
	var baseline_memory: int = _driver.GetManagedMemory()

	var ruby_code := _build_ruby_stress_script()
	if not _driver.RunRuby(ruby_code):
		push_error("Ruby stress script failed")
		_driver.Shutdown()
		quit(exit_code)
		return

	for i in range(8):
		_driver.UpdateRenderManager()
		_driver.CollectGarbage()
		await process_frame

	var after_nodes := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var after_viewports: int = _driver.GetViewportCount()
	var after_sprites: int = _driver.GetSpriteCount()
	var after_windows: int = _driver.GetWindowCount()
	var after_memory: int = _driver.GetManagedMemory()

	if after_viewports != baseline_viewports:
		push_error("Viewport count leaked: baseline=%d after=%d" % [baseline_viewports, after_viewports])
	elif after_sprites != baseline_sprites:
		push_error("Sprite count leaked: baseline=%d after=%d" % [baseline_sprites, after_sprites])
	elif after_windows != baseline_windows:
		push_error("Window count leaked: baseline=%d after=%d" % [baseline_windows, after_windows])
	elif after_nodes > baseline_nodes + NODE_TOLERANCE:
		push_error("Node count did not return near baseline: baseline=%d after=%d tolerance=%d" % [baseline_nodes, after_nodes, NODE_TOLERANCE])
	else:
		print("STRESS_COUNTS baseline_nodes=%d after_nodes=%d viewports=%d sprites=%d windows=%d managed_memory_before=%d managed_memory_after=%d" % [baseline_nodes, after_nodes, after_viewports, after_sprites, after_windows, baseline_memory, after_memory])
		print("STRESS_PASS")
		exit_code = 0

	_driver.Shutdown()
	quit(exit_code)


func _finalize() -> void:
	if _driver != null:
		_driver.Shutdown()


func _build_ruby_stress_script() -> String:
	return """
iterations = %d
objects_per_iteration = %d

iterations.times do |iteration|
  viewport = Unity::Viewport.new_without_rect
  sprites = []
  bitmaps = []
  windows = []

  objects_per_iteration.times do |index|
    bitmap = Unity::Bitmap.new_wh(32 + (index %% 4), 32 + (iteration %% 4))
    sprite = Unity::Sprite.new_with_viewport(viewport)
    sprite.bitmap = bitmap
    window = Unity::Window.new_with_viewport(viewport)
    window.contents = Unity::Bitmap.new_wh(24, 24)

    bitmaps << bitmap
    bitmaps << window.contents
    sprites << sprite
    windows << window
  end

  sprites.each { |sprite| sprite.dispose }
  windows.each { |window| window.dispose }
  bitmaps.each { |bitmap| bitmap.dispose }
  viewport.dispose

  sprites.clear
  windows.clear
  bitmaps.clear
  GC.start if defined?(GC) && GC.respond_to?(:start)
end

true
""" % [ITERATIONS, OBJECTS_PER_ITERATION]
