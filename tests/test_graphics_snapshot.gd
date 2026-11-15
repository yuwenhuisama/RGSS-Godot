extends SceneTree

# Requires a real renderer (do not pass --headless).
# godot --path . -s tests/test_graphics_snapshot.gd
var _driver


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	_driver.Initialize(host)
	var ok := _check("""
require 'color'
require 'tone'
require 'rect'
require 'font'
require 'bitmap'
require 'graphics'
require 'viewport'
require 'sprite'
$snapshot_source = Bitmap.new(Graphics.width, Graphics.height)
$snapshot_source.fill_rect(0, 0, Graphics.width / 2, Graphics.height, Color.new(255, 0, 0))
$snapshot_source.fill_rect(Graphics.width / 2, 0, Graphics.width / 2, Graphics.height, Color.new(0, 255, 0))
$snapshot_sprite = Sprite.new
$snapshot_sprite.bitmap = $snapshot_source
true
""")
	for i in range(4):
		_driver.UpdateRenderManager()
		await process_frame
		await RenderingServer.frame_post_draw
	if ok:
		ok = _check("""
$snapshot = Graphics.snap_to_bitmap
raise 'snapshot dimensions' unless $snapshot.width == Graphics.width && $snapshot.height == Graphics.height
[[32, 255, 0], [Graphics.width - 32, 0, 255]].each do |x, red, green|
  pixel = $snapshot.get_pixel(x, 32)
  raise "snapshot missing rendered pixels: #{pixel.red},#{pixel.green},#{pixel.alpha}" unless (pixel.red - red).abs <= 1 && (pixel.green - green).abs <= 1 && pixel.alpha >= 254
end
$snapshot_source.clear
$snapshot_sprite.dispose
$snapshot_source.dispose
true
""")
	for i in range(2):
		_driver.UpdateRenderManager()
		await process_frame
		await RenderingServer.frame_post_draw
	if ok:
		ok = _check("""
pixel = $snapshot.get_pixel(32, 32)
raise 'snapshot must survive source disposal and later frames' unless pixel.red >= 254 && pixel.alpha >= 254
$snapshot.dispose
true
""")
	_driver.Shutdown()
	print("GRAPHICS_SNAPSHOT_PASS" if ok else "GRAPHICS_SNAPSHOT_FAIL")
	quit(0 if ok else 1)


func _check(code: String) -> bool:
	# RunRuby's native protect does not report compiler exceptions reliably.
	# Record the Ruby assertion outcome explicitly across the VM boundary.
	var path := OS.get_user_data_dir().path_join("graphics_snapshot_result.txt")
	var script := "result = 'PASS'\nbegin\n" + code + "\nrescue Exception => e\nresult = e.message\nend\nFile.open(" + JSON.stringify(path) + ", 'w') { |f| f.write(result) }\n"
	_driver.RunRuby(script)
	var result := FileAccess.get_file_as_string(path)
	DirAccess.remove_absolute(path)
	if result != "PASS":
		push_error(result)
	return result == "PASS"


func _finalize() -> void:
	if _driver != null:
		_driver.Shutdown()
