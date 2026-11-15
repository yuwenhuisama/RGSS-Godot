extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	driver.Initialize(host)
	var ok: bool = driver.RunRuby("require 'color'; require 'tone'; require 'rect'; require 'font'; require 'bitmap'")
	if ok:
		ok = driver.RunRuby("""
b = Bitmap.new(200, 40)
raise 'Chinese original default font mismatch' unless Font.default_name == 'nsimsun'
old_default = Font.default_name
Font.default_name = ['CompatibilityMissingFont', 'Arial']
default_font = Font.new
raise 'default name array contract' unless default_font.name == Font.default_name
Font.default_name = old_default
b.font.name = 'Arial'
b.font.size = 24
[['Hello',46],['iiii',20],['WWWW',84],['12345',60],['AV',27],['',0]].each do |text,width|
  rect = b.text_size(text)
  height = text.empty? ? 0 : 24
  raise "original metric mismatch for #{text}: #{rect.width},#{rect.height}" unless rect.width == width && rect.height == height
end
b.font.name = ['CompatibilityMissingFont', 'Arial']
raise 'array font name must retain requested order' unless b.font.name == ['CompatibilityMissingFont', 'Arial']
raise 'ordered fallback mismatch' unless b.text_size('Hello').width == 46
b.font.name = 'Arial'
raise 'string font name must stay a string' unless b.font.name == 'Arial'
b.font.bold = true
b.font.italic = true
b.font.shadow = true
raise 'font getter resets styles' unless b.font.bold && b.font.italic && b.font.shadow
raise 'font getter must retain identity' unless b.font.equal?(b.font)
b.font.bold = false
b.font.italic = false
b.font.shadow = false
b.font.outline = false
b.clear
b.draw_text(0, 0, 200, 40, 'Hello')
raise 'actual text raster is empty' unless (0...200).any? { |x| (0...40).any? { |y| b.get_pixel(x,y).alpha > 0 } }
b.font.bold = true
raise 'bold font measurement must change' unless b.text_size('Hello').width > 46
b.font.bold = false
b.dispose
b = Bitmap.new(544, 60)
b.font.name = 'Arial'
b.font.size = 24
b.font.outline = false
b.font.shadow = false
[[500,278],[260,278],[259,237],[250,237],[230,206],[220,206],[200,181],[180,181],[160,179],[100,119]].each do |width,right|
  b.clear
  b.draw_text(20,20,width,40,'Hello AV iiii WWWW 12345')
  xs=[]
  (0...60).each { |y| (0...544).each { |x| xs << x if b.get_pixel(x,y).alpha > 180 } }
  raise "original compression mismatch at #{width}: #{xs.max} vs #{right}" unless xs.max == right
end
raise 'installed Arial missing' unless Font.exist?('Arial')
raise 'missing font reported available' if Font.exist?('CompatibilityMissingFont')
b.dispose
""")
	driver.Shutdown()
	print("FONT_METRICS_PASS" if ok else "FONT_METRICS_FAIL")
	quit(0 if ok else 1)
