extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	driver.Initialize(host)
	var ok: bool = driver.RunRuby("require 'color'; require 'tone'; require 'rect'; require 'font'; require 'graphics'; require 'bitmap'; require 'viewport'; require 'sprite'; require 'plane'; require 'window'; require 'table'; require 'tilemap'")
	if ok:
		ok = driver.RunRuby("""
v=Viewport.new(0,0,32,32)
b=Bitmap.new(32,32)
s=Sprite.new(v); s.bitmap=b
raise 'assigned bitmap identity' unless s.bitmap.equal?(b)
raise 'sprite viewport identity' unless s.viewport.equal?(v)
[:src_rect,:color,:tone].each { |prop| raise "sprite #{prop} identity" unless s.send(prop).equal?(s.send(prop)) }
p=Plane.new(v); p.bitmap=b
raise 'plane bitmap identity' unless p.bitmap.equal?(b)
w=Window.new(0,0,32,32); w.viewport=v
raise 'unset windowskin must be nil' unless w.windowskin.nil?
[:contents,:cursor_rect,:tone].each { |prop| raise "window #{prop} identity" unless w.send(prop).equal?(w.send(prop)) }
[:rect,:color,:tone].each { |prop| raise "viewport #{prop} identity" unless v.send(prop).equal?(v.send(prop)) }
t=Tilemap.new(v)
raise 'tilemap viewport identity' unless t.viewport.equal?(v)
[s,p,w,v,t,b].each do |resource|
  resource.dispose; resource.dispose
  raise 'dispose query' unless resource.disposed?
  begin
    resource.is_a?(Bitmap) ? resource.get_pixel(0,0) : resource.visible
    raise 'disposed access must fail'
  rescue RGSSError
  end
end
""")
	driver.Shutdown()
	print("RESOURCE_LIFECYCLE_PASS" if ok else "RESOURCE_LIFECYCLE_FAIL")
	quit(0 if ok else 1)
