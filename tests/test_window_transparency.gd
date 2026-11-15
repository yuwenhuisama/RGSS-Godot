extends SceneTree

# Requires a real renderer. Tests one opacity application to the combined skin.
var _driver

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	_driver.Initialize(host)
	_driver.RunRuby("""
require 'color'; require 'tone'; require 'rect'; require 'font'
require 'bitmap'; require 'graphics'; require 'viewport'; require 'sprite'; require 'window'
$source = Bitmap.new(Graphics.width, Graphics.height)
$source.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(0, 255, 0))
$sprite = Sprite.new; $sprite.bitmap = $source
$skin = Bitmap.new(128, 128)
$skin.fill_rect(0, 0, 64, 128, Color.new(0, 0, 255))
$window = Window.new(0, 0, Graphics.width, Graphics.height)
$window.windowskin = $skin
$window.back_opacity = 0
""")
	var ok := true
	for opacity in [0, 128, 255]:
		_driver.RunRuby("$window.back_opacity = %d" % opacity)
		for i in range(4):
			_driver.UpdateRenderManager()
			await process_frame
			await RenderingServer.frame_post_draw
		var pixel := root.get_texture().get_image().get_pixel(100, 100)
		# Original RGSS300 blends the composed skin once, with integer alpha.
		var expected_green: float = 1.0 - (opacity + 1.0) / 256.0 if opacity > 0 else 1.0
		if abs(pixel.g - expected_green) > 0.02 or abs(pixel.b - (1.0 - expected_green)) > 0.02:
			push_error("back_opacity=%d: expected green %.3f, got %s" % [opacity, expected_green, pixel])
			ok = false
	# Hidden scroll-arrow texels inside the frame atlas must not enter the border.
	ok = _driver.RunRuby("$skin.clear; $skin.fill_rect(88,16,16,8,Color.new(255,0,0)); $window.move(20,20,120,72); $window.back_opacity=0; $window.arrows_visible=false") and ok
	for i in range(4):
		_driver.UpdateRenderManager()
		await process_frame
		await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var leaking := 0
	for y in range(36,76):
		for x in range(36,124):
			if image.get_pixel(x,y).r > 0.1:
				leaking += 1
	if leaking != 0:
		push_error("Hidden windowskin arrow leaked into %d interior pixels" % leaking)
		ok = false
	_driver.RunRuby("$window.dispose; $skin.dispose; $sprite.dispose; $source.dispose")
	_driver.Shutdown()
	print("WINDOW_TRANSPARENCY_PASS" if ok else "WINDOW_TRANSPARENCY_FAIL")
	quit(0 if ok else 1)

func _finalize() -> void:
	if _driver != null:
		_driver.Shutdown()
