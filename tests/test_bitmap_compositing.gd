extends SceneTree

const TestPaths = preload("res://tools/test_paths.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	driver.Initialize(host)
	var ok: bool = driver.RunRuby("require 'color'; require 'tone'; require 'rect'; require 'font'; require 'bitmap'")
	if ok:
		var image_path := TestPaths.fixture("bitmap-file-reference.png")
		ok = driver.RunRuby("loaded=Bitmap.new(" + JSON.stringify(image_path) + "); raise 'file bitmap dimensions' unless [loaded.width,loaded.height,loaded.rect.width,loaded.rect.height] == [16,12,16,12]; loaded.dispose")
	if ok:
		var mixed_case_path := TestPaths.fixture("bitmap-file-reference.png").to_upper()
		ok = driver.RunRuby("path=" + JSON.stringify(mixed_case_path) + "; raise 'case-insensitive bitmap probe' unless Unity::Bitmap.file_exists?(path); loaded=Bitmap.new(path); raise 'case-insensitive bitmap load' unless [loaded.width,loaded.height] == [16,12]; loaded.dispose")
	if ok:
		ok = driver.RunRuby("""
[[0,8],[-1,8],[8,0]].each do |size|
  begin
    invalid=Bitmap.new(*size)
  rescue RGSSError
    next
  end
  invalid.dispose
  raise 'invalid bitmap dimensions must raise RGSSError'
end
b=Bitmap.new(8,8)
c=b.get_pixel(0,0)
raise 'new bitmap must zero RGBA' unless [c.red,c.green,c.blue,c.alpha] == [0,0,0,0]
s=Bitmap.new(4,4)
s.fill_rect(0,0,4,4,Color.new(20,150,200,128))
b.clear
b.stretch_blt(Rect.new(0,0,8,8),s,Rect.new(0,0,4,4))
c=b.get_pixel(2,2)
raise 'straight alpha RGB corrupted' unless [c.red,c.green,c.blue,c.alpha] == [20,150,200,128]
grid=Bitmap.new(4,4)
4.times {|y|4.times {|x|grid.set_pixel(x,y,Color.new(x*60,y*60,0,255))}}
scaled=Bitmap.new(6,6)
scaled.stretch_blt(scaled.rect,grid,grid.rect)
raise 'stretch original nearest sampling' unless (0...6).map {|x|scaled.get_pixel(x,0).red} == [0,0,60,60,120,180]
small=Bitmap.new(3,3)
small.stretch_blt(small.rect,grid,grid.rect)
raise 'stretch original shrinking sampling' unless (0...3).map {|x|small.get_pixel(x,0).red} == [0,60,120]
small.dispose
scaled.dispose;grid.dispose
b.clear_rect(0,0,2,2)
c=b.get_pixel(0,0)
raise 'clear must zero RGBA' unless [c.red,c.green,c.blue,c.alpha] == [0,0,0,0]
b.clear
b.gradient_fill_rect(-2,0,8,8,Color.new(0,0,0,255),Color.new(255,255,255,255))
raise 'clipping must retain requested gradient length' unless b.get_pixel(1,0).red == 36
[false,true,nil].each do |flag|
  b.gradient_fill_rect(0,0,8,8,Color.new(0,0,0,255),Color.new(255,255,255,255),flag)
  raise 'numeric gradient explicit argument must select vertical' unless b.get_pixel(1,0).red == 0 && b.get_pixel(0,1).red == 36
end
b.gradient_fill_rect(0,0,8,8,Color.new(0,20,100,64),Color.new(255,220,0,192),true)
raise 'gradient descending channel rounding' unless b.get_pixel(1,1).blue == 86
b.clear
b.set_pixel(6,3,Color.new(255,100,0,255))
b.radial_blur(30,5)
[[2,51],[3,204],[4,51]].each do |row|
  c=b.get_pixel(6,row[0])
  raise 'radial blur must sample both angle endpoints' unless c.red == row[1] && c.alpha == row[1]
end
b.fill_rect(0,0,8,8,Color.new(100,50,20,128))
b.radial_blur(30,5)
c=b.get_pixel(3,3)
raise 'radial blur must preserve uniform brightness' unless [c.red,c.green,c.blue,c.alpha] == [100,50,20,128]
edge=Bitmap.new(16,16)
16.times {|y|16.times {|x|edge.set_pixel(x,y,Color.new(x*15,y*15,(x+y)*7,128+(x+y)*3))}}
edge.radial_blur(90,9)
c=edge.get_pixel(0,0)
raise 'radial border must reflect source pixels' unless [c.red,c.green,c.blue,c.alpha] == [41,41,38,144]
edge.dispose
b.fill_rect(0,0,8,8,Color.new(200,80,10,128))
b.hue_change(90)
c=b.get_pixel(0,0)
raise 'hue must use original integer HSL' unless [c.red,c.green,c.blue,c.alpha] == [36,199,11,128]
b.dispose;s.dispose
""")
	driver.Shutdown()
	print("BITMAP_COMPOSITING_PASS" if ok else "BITMAP_COMPOSITING_FAIL")
	quit(0 if ok else 1)
