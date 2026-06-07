extends SceneTree

# RGSS API unit-test runner.
#
# Drives the embedded mruby VM via StressDisposeTestDriver.RunRuby(code)->bool
# (returns false if the Ruby raised). Each test is a self-asserting Ruby block that
# does `raise "msg" unless <condition>`; a raise -> RunRuby false -> test FAIL.
#
# Run headless:
#   godot --headless --path . -s tests/test_rgss_api.gd
# Exit code 0 = all passed, 1 = one or more failed. CI markers:
# "RGSS_API_TESTS_PASS" / "RGSS_API_TESTS_FAIL".
#
# Per Oracle guidance: one RunRuby block per class/cluster (localizes failures and
# limits shared-VM state leakage); each block disposes its own objects.

var _driver
var _root: Node
var _passed := 0
var _failed := 0
var _failures: Array = []


func _initialize() -> void:
	var driver_script := load("res://Scripts/StressDisposeTestDriver.cs")
	_driver = driver_script.new()
	_root = Node.new()
	_root.name = "RgssApiTestRoot"
	root.add_child(_root)
	_driver.Initialize(_root)
	for i in range(3):
		_driver.UpdateRenderManager()
		await process_frame

	for t in _all_tests():
		_run_one(t[0], t[1])

	print("\n==== RGSS API TEST SUMMARY ====")
	print("PASSED: %d   FAILED: %d" % [_passed, _failed])
	for f in _failures:
		print("  FAIL: %s" % f)
	var exit_code := 0 if _failed == 0 else 1
	print("RGSS_API_TESTS_PASS" if _failed == 0 else "RGSS_API_TESTS_FAIL")
	_driver.Shutdown()
	quit(exit_code)


func _finalize() -> void:
	if _driver != null:
		_driver.Shutdown()


func _run_one(test_name: String, ruby_code: String) -> void:
	var ok: bool = _driver.RunRuby(ruby_code)
	if ok:
		_passed += 1
		print("  ok   - %s" % test_name)
	else:
		_failed += 1
		_failures.append(test_name)
		print("  FAIL - %s" % test_name)


# Returns Array of [name, ruby_code]. Each ruby_code MUST end with a truthy value and
# raise on any assertion failure. Tests use the high-level Ruby wrappers (Color, Sprite,
# ...) — exactly the API real RMVA scripts call — exercising wrapper + C# binding.
func _all_tests() -> Array:
	var t: Array = []
	t.append_array(_color_tests())
	t.append_array(_tone_tests())
	t.append_array(_rect_tests())
	t.append_array(_table_tests())
	t.append_array(_font_tests())
	t.append_array(_bitmap_tests())
	t.append_array(_sprite_tests())
	t.append_array(_plane_tests())
	t.append_array(_viewport_tests())
	t.append_array(_window_tests())
	t.append_array(_tilemap_tests())
	t.append_array(_graphics_tests())
	return t


# Shared Ruby assertion helpers. RGSS exposes Color/Tone as 0..255 (stored 0..1), so
# color/tone comparisons use a small tolerance.
const _ASSERT := """
def _aeq(actual, expected, tol, msg)
  raise "#{msg}: expected #{expected} got #{actual}" unless (actual - expected).abs <= tol
end
def _eq(actual, expected, msg)
  raise "#{msg}: expected #{expected.inspect} got #{actual.inspect}" unless actual == expected
end
"""


# ============================ COLOR ============================
func _color_tests() -> Array:
	return [
		["Color.new(r,g,b,a) round-trips 0..255", _ASSERT + """
c = Color.new(255, 128, 0, 200)
_aeq(c.red, 255, 0.6, 'red'); _aeq(c.green, 128, 0.6, 'green')
_aeq(c.blue, 0, 0.6, 'blue'); _aeq(c.alpha, 200, 0.6, 'alpha')
true
"""],
		["Color.new(r,g,b) defaults alpha 255", _ASSERT + """
c = Color.new(10, 20, 30)
_aeq(c.alpha, 255, 0.6, 'alpha default')
true
"""],
		["Color.new (no args) is 0,0,0,0", _ASSERT + """
c = Color.new
_aeq(c.red, 0, 0.6, 'r'); _aeq(c.alpha, 0, 0.6, 'a')
true
"""],
		["Color#set(r,g,b,a) normalizes (N1 regression)", _ASSERT + """
c = Color.new(0,0,0,0)
c.set(255, 64, 32, 128)
_aeq(c.red, 255, 0.6, 'set red'); _aeq(c.green, 64, 0.6, 'set green')
_aeq(c.blue, 32, 0.6, 'set blue'); _aeq(c.alpha, 128, 0.6, 'set alpha')
true
"""],
		["Color#set(color) copies", _ASSERT + """
src = Color.new(11, 22, 33, 44)
c = Color.new(0,0,0,0); c.set(src)
_aeq(c.red, 11, 0.6, 'r'); _aeq(c.green, 22, 0.6, 'g')
_aeq(c.blue, 33, 0.6, 'b'); _aeq(c.alpha, 44, 0.6, 'a')
true
"""],
		["Color setters clamp to 0..255", _ASSERT + """
c = Color.new(0,0,0,0)
c.red = 999; c.green = -50
_aeq(c.red, 255, 0.6, 'clamp hi'); _aeq(c.green, 0, 0.6, 'clamp lo')
true
"""],
		["Color::BLACK is black not white (B3 regression)", _ASSERT + """
_aeq(Color::BLACK.red, 0, 0.6, 'black r'); _aeq(Color::BLACK.green, 0, 0.6, 'black g')
_aeq(Color::BLACK.blue, 0, 0.6, 'black b'); _aeq(Color::BLACK.alpha, 255, 0.6, 'black a')
true
"""],
		["Color _dump/_load round-trips", _ASSERT + """
c = Color.new(200, 150, 100, 50)
c2 = Color._load(c._dump)
_aeq(c2.red, 200, 0.6, 'r'); _aeq(c2.alpha, 50, 0.6, 'a')
true
"""],
	]


# ============================ TONE ============================
func _tone_tests() -> Array:
	return [
		["Tone.new(r,g,b,gray) round-trips", _ASSERT + """
t = Tone.new(100, -100, 50, 80)
_aeq(t.red, 100, 0.6, 'r'); _aeq(t.green, -100, 0.6, 'g')
_aeq(t.blue, 50, 0.6, 'b'); _aeq(t.gray, 80, 0.6, 'gray')
true
"""],
		["Tone.new(r,g,b) defaults gray 0", _ASSERT + """
t = Tone.new(10, 20, 30)
_aeq(t.gray, 0, 0.6, 'gray default')
true
"""],
		["Tone#set(r,g,b,gray) sets values", _ASSERT + """
t = Tone.new(0,0,0,0); t.set(60, 70, 80, 90)
_aeq(t.red, 60, 0.6, 'r'); _aeq(t.gray, 90, 0.6, 'gray')
true
"""],
		["Tone clamps r/g/b -255..255, gray 0..255 (B10)", _ASSERT + """
t = Tone.new(0,0,0,0)
t.red = 999; t.green = -999; t.gray = -10
_aeq(t.red, 255, 0.6, 'r hi'); _aeq(t.green, -255, 0.6, 'g lo'); _aeq(t.gray, 0, 0.6, 'gray lo')
true
"""],
		["Tone _dump/_load round-trips", _ASSERT + """
t = Tone.new(120, -120, 60, 30)
t2 = Tone._load(t._dump)
_aeq(t2.red, 120, 0.6, 'r'); _aeq(t2.green, -120, 0.6, 'g')
true
"""],
	]


# ============================ RECT ============================
func _rect_tests() -> Array:
	return [
		["Rect.new(x,y,w,h) round-trips", _ASSERT + """
r = Rect.new(1, 2, 3, 4)
_eq(r.x, 1, 'x'); _eq(r.y, 2, 'y'); _eq(r.width, 3, 'w'); _eq(r.height, 4, 'h')
true
"""],
		["Rect.new (no args) is 0,0,0,0", _ASSERT + """
r = Rect.new
_eq(r.x, 0, 'x'); _eq(r.width, 0, 'w')
true
"""],
		["Rect#set(x,y,w,h)", _ASSERT + """
r = Rect.new; r.set(5,6,7,8)
_eq(r.x, 5, 'x'); _eq(r.height, 8, 'h')
true
"""],
		["Rect#set(rect) copies", _ASSERT + """
src = Rect.new(9,10,11,12); r = Rect.new; r.set(src)
_eq(r.x, 9, 'x'); _eq(r.width, 11, 'w')
true
"""],
		["Rect#empty zeroes", _ASSERT + """
r = Rect.new(1,2,3,4); r.empty
_eq(r.x, 0, 'x'); _eq(r.width, 0, 'w')
true
"""],
		["Rect w/h aliases", _ASSERT + """
r = Rect.new(0,0,3,4)
_eq(r.w, 3, 'w alias'); _eq(r.h, 4, 'h alias')
r.w = 9; _eq(r.width, 9, 'w= alias')
true
"""],
		["Rect _dump/_load round-trips", _ASSERT + """
r = Rect.new(13,14,15,16); r2 = Rect._load(r._dump)
_eq(r2.x, 13, 'x'); _eq(r2.height, 16, 'h')
true
"""],
	]


# ============================ TABLE ============================
func _table_tests() -> Array:
	return [
		["Table 1D get/set + xsize", _ASSERT + """
t = Table.new(4)
_eq(t.xsize, 4, 'xsize'); _eq(t.ysize, 0, 'ysize'); _eq(t[0], 0, 'init 0')
t[2] = 7; _eq(t[2], 7, 'set/get')
true
"""],
		["Table 2D get/set indexing", _ASSERT + """
t = Table.new(3, 2)
t[2, 1] = 42; _eq(t[2, 1], 42, '2d set/get')
t[0, 0] = 5; _eq(t[0, 0], 5, '2d origin')
true
"""],
		["Table 3D get/set indexing (B1/N2)", _ASSERT + """
t = Table.new(2, 2, 2)
t[1, 1, 1] = 99; _eq(t[1, 1, 1], 99, '3d corner')
t[0, 1, 0] = 13; _eq(t[0, 1, 0], 13, '3d mid')
_eq(t[1, 1, 1], 99, '3d corner stable')
true
"""],
		["Table out-of-range read returns nil (N2)", _ASSERT + """
t = Table.new(3)
_eq(t[3], nil, 'oob hi nil'); _eq(t[99], nil, 'oob far nil'); _eq(t[-1], nil, 'oob neg nil')
true
"""],
		["Table out-of-range write is ignored (N2)", _ASSERT + """
t = Table.new(3)
t[3] = 5; t[-1] = 9
_eq(t[0], 0, 'unchanged')
true
"""],
		["Table#resize preserves overlap", _ASSERT + """
t = Table.new(3); t[1] = 8
t.resize(5)
_eq(t.xsize, 5, 'new xsize'); _eq(t[1], 8, 'preserved')
true
"""],
		["Table _dump/_load 3D round-trips (B1)", _ASSERT + """
t = Table.new(2, 2, 2)
n = 0
(0...2).each { |z| (0...2).each { |y| (0...2).each { |x| t[x,y,z] = (n += 1) } } }
t2 = Table._load(t._dump)
_eq(t2.xsize, 2, 'xsize'); _eq(t2.zsize, 2, 'zsize')
_eq(t2[1,1,1], 8, 'last'); _eq(t2[0,0,0], 1, 'first'); _eq(t2[1,0,1], t[1,0,1], 'mid match')
true
"""],
	]


# ============================ FONT ============================
func _font_tests() -> Array:
	return [
		["Font.new(name,size) round-trips", _ASSERT + """
f = Font.new('Arial', 30)
_eq(f.size, 30, 'size')
true
"""],
		["Font.new (no args) applies defaults (N3)", _ASSERT + """
f = Font.new
_eq(f.size, Font.default_size, 'default size')
_eq(f.bold, Font.default_bold, 'default bold')
_eq(f.outline, Font.default_outline, 'default outline')
true
"""],
		["Font#size=/bold=/italic= round-trip", _ASSERT + """
f = Font.new('Arial', 24)
f.size = 18; f.bold = true; f.italic = true
_eq(f.size, 18, 'size'); _eq(f.bold, true, 'bold'); _eq(f.italic, true, 'italic')
true
"""],
		["Font#name= reflected by getter (B11)", _ASSERT + """
f = Font.new('Arial', 24)
f.name = 'Times'
_eq(f.name, ['Times'], 'name array')
true
"""],
		["Font.exist? returns boolean (G1)", _ASSERT + """
v = Font.exist?('Arial')
raise 'exist? not boolean' unless v == true || v == false
true
"""],
		["Font class defaults present", _ASSERT + """
_eq(Font.default_size.is_a?(Integer), true, 'default_size int')
raise 'default_out_color' unless Font.default_out_color.is_a?(Color)
true
"""],
	]


# ============================ BITMAP ============================
func _bitmap_tests() -> Array:
	return [
		["Bitmap.new(w,h) dims + dispose lifecycle", _ASSERT + """
b = Bitmap.new(32, 48)
_eq(b.width, 32, 'w'); _eq(b.height, 48, 'h'); _eq(b.disposed?, false, 'not disposed')
b.dispose; _eq(b.disposed?, true, 'disposed')
b.dispose
true
"""],
		["Bitmap#rect matches dims", _ASSERT + """
b = Bitmap.new(16, 20)
r = b.rect
_eq(r.width, 16, 'rect w'); _eq(r.height, 20, 'rect h')
b.dispose
true
"""],
		["Bitmap get/set_pixel round-trips a Color", _ASSERT + """
b = Bitmap.new(4, 4)
b.set_pixel(1, 1, Color.new(255, 0, 0, 255))
c = b.get_pixel(1, 1)
raise "red px got #{c.red},#{c.green},#{c.blue}" unless c.red > 250 && c.green < 5 && c.blue < 5
b.dispose
true
"""],
		["Bitmap#font is a Font", _ASSERT + """
b = Bitmap.new(8, 8)
raise 'font' unless b.font.is_a?(Font)
b.dispose
true
"""],
		["Bitmap#fill_rect fills pixels with color", _ASSERT + """
b = Bitmap.new(8, 8)
b.fill_rect(0, 0, 8, 8, Color.new(0, 255, 0, 255))
c = b.get_pixel(4, 4)
raise "fill got #{c.red},#{c.green},#{c.blue}" unless c.green > 250 && c.red < 5 && c.blue < 5
b.dispose
true
"""],
		["Bitmap#fill_rect(rect, color) overload", _ASSERT + """
b = Bitmap.new(8, 8)
b.fill_rect(Rect.new(0, 0, 8, 8), Color.new(0, 0, 255, 255))
c = b.get_pixel(2, 2)
raise 'fill rect overload' unless c.blue > 250 && c.red < 5
b.dispose
true
"""],
		["Bitmap#clear wipes to transparent", _ASSERT + """
b = Bitmap.new(8, 8)
b.fill_rect(0, 0, 8, 8, Color.new(255, 255, 255, 255))
b.clear
c = b.get_pixel(4, 4)
raise "clear alpha #{c.alpha}" unless c.alpha < 5
b.dispose
true
"""],
		["Bitmap#clear_rect clears a region", _ASSERT + """
b = Bitmap.new(8, 8)
b.fill_rect(0, 0, 8, 8, Color.new(255, 0, 0, 255))
b.clear_rect(0, 0, 4, 4)
c0 = b.get_pixel(1, 1); c1 = b.get_pixel(6, 6)
raise 'cleared region' unless c0.alpha < 5
raise 'kept region' unless c1.red > 250
b.dispose
true
"""],
		["Bitmap#blt copies from source", _ASSERT + """
src = Bitmap.new(8, 8); src.fill_rect(0, 0, 8, 8, Color.new(255, 0, 0, 255))
dst = Bitmap.new(16, 16)
dst.blt(4, 4, src, Rect.new(0, 0, 8, 8))
c = dst.get_pixel(6, 6); edge = dst.get_pixel(0, 0)
raise 'blt copied' unless c.red > 250
raise 'blt bounded' unless edge.alpha < 5
src.dispose; dst.dispose
true
"""],
		["Bitmap#stretch_blt scales source", _ASSERT + """
src = Bitmap.new(4, 4); src.fill_rect(0, 0, 4, 4, Color.new(0, 255, 0, 255))
dst = Bitmap.new(16, 16)
dst.stretch_blt(Rect.new(0, 0, 16, 16), src, Rect.new(0, 0, 4, 4))
c = dst.get_pixel(8, 8)
raise 'stretch_blt' unless c.green > 250
src.dispose; dst.dispose
true
"""],
		["Bitmap#gradient_fill_rect endpoints differ", _ASSERT + """
b = Bitmap.new(16, 4)
b.gradient_fill_rect(0, 0, 16, 4, Color.new(255,0,0,255), Color.new(0,0,255,255))
left = b.get_pixel(0, 2); right = b.get_pixel(15, 2)
raise 'grad left red' unless left.red > 200
raise 'grad right blue' unless right.blue > 200
b.dispose
true
"""],
		["Bitmap#text_size returns a Rect with positive size", _ASSERT + """
b = Bitmap.new(64, 32)
r = b.text_size('Hi')
raise 'text_size type' unless r.is_a?(Rect)
raise "text_size w #{r.width}" unless r.width > 0 && r.height > 0
b.dispose
true
"""],
		["Bitmap#draw_text does not raise", _ASSERT + """
b = Bitmap.new(64, 32)
b.draw_text(0, 0, 64, 32, 'Hello', 1)
b.draw_text(Rect.new(0, 0, 64, 32), 'X')
b.draw_text(0, 0, 64, 32, 123)   # non-String coerced via to_s
b.dispose
true
"""],
		["Bitmap#hue_change does not raise", _ASSERT + """
b = Bitmap.new(8, 8); b.fill_rect(0, 0, 8, 8, Color.new(255, 0, 0, 255))
b.hue_change(120)
b.dispose
true
"""],
		["Bitmap#blur / radial_blur do not raise", _ASSERT + """
b = Bitmap.new(8, 8); b.fill_rect(0, 0, 8, 8, Color.new(255, 255, 255, 255))
b.blur
b.radial_blur(180, 4)
b.dispose
true
"""],
		["Bitmap#font= and rect= round-trip", _ASSERT + """
b = Bitmap.new(8, 8)
f = Font.new('Arial', 18); b.font = f
raise 'font=' unless b.font.size == 18
b.rect = Rect.new(0, 0, 8, 8)   # setter must not raise
b.dispose
true
"""],
	]


# ============================ SPRITE ============================
func _sprite_tests() -> Array:
	return [
		["Sprite position/z round-trip + dispose", _ASSERT + """
s = Sprite.new
s.x = 10; s.y = 20; s.z = 5
_eq(s.x, 10, 'x'); _eq(s.y, 20, 'y'); _eq(s.z, 5, 'z')
_eq(s.disposed?, false, 'alive'); s.dispose; _eq(s.disposed?, true, 'disposed')
true
"""],
		["Sprite#opacity clamps 0..255", _ASSERT + """
s = Sprite.new
s.opacity = 999; _eq(s.opacity, 255, 'clamp hi')
s.opacity = -10; _eq(s.opacity, 0, 'clamp lo')
s.dispose
true
"""],
		["Sprite#bitmap= accepts nil (B9)", _ASSERT + """
s = Sprite.new
s.bitmap = Bitmap.new(8,8)
s.bitmap = nil
_eq(s.bitmap, nil, 'nil bitmap')
s.dispose
true
"""],
		["Sprite#visible + zoom round-trip", _ASSERT + """
s = Sprite.new
s.visible = false; _eq(s.visible, false, 'visible')
s.zoom_x = 2.0; _aeq(s.zoom_x, 2.0, 0.001, 'zoom_x')
s.dispose
true
"""],
		["Sprite#blend_type validates range", _ASSERT + """
s = Sprite.new
s.blend_type = 1; _eq(s.blend_type, 1, 'bt')
ok = false
begin; s.blend_type = 9; rescue; ok = true; end
raise 'blend_type range not validated' unless ok
s.dispose
true
"""],
		["Sprite ox/oy/zoom_y/angle/mirror round-trip", _ASSERT + """
s = Sprite.new
s.ox = 4; s.oy = 6; s.zoom_y = 1.5; s.angle = 90; s.mirror = true
_eq(s.ox, 4, 'ox'); _eq(s.oy, 6, 'oy')
_aeq(s.zoom_y, 1.5, 0.001, 'zoom_y'); _aeq(s.angle, 90, 0.5, 'angle'); _eq(s.mirror, true, 'mirror')
s.dispose
true
"""],
		["Sprite bush + wave properties round-trip", _ASSERT + """
s = Sprite.new
s.bush_depth = 8; s.bush_opacity = 100
s.wave_amp = 5; s.wave_length = 90; s.wave_speed = 200; s.wave_phase = 45
_eq(s.bush_depth, 8, 'bush_depth'); _eq(s.bush_opacity, 100, 'bush_opacity')
_eq(s.wave_amp, 5, 'wave_amp'); _eq(s.wave_length, 90, 'wave_length')
_eq(s.wave_speed, 200, 'wave_speed'); _aeq(s.wave_phase, 45, 0.5, 'wave_phase')
s.dispose
true
"""],
		["Sprite#color and #tone round-trip", _ASSERT + """
s = Sprite.new
s.color = Color.new(255, 0, 0, 128)
_aeq(s.color.red, 255, 0.6, 'color r'); _aeq(s.color.alpha, 128, 0.6, 'color a')
s.tone = Tone.new(50, -50, 25, 80)
_aeq(s.tone.red, 50, 0.6, 'tone r'); _aeq(s.tone.gray, 80, 0.6, 'tone gray')
s.dispose
true
"""],
		["Sprite#src_rect + width/height track bitmap", _ASSERT + """
s = Sprite.new
b = Bitmap.new(40, 30); s.bitmap = b
_eq(s.width, 40, 'width'); _eq(s.height, 30, 'height')
s.src_rect = Rect.new(0, 0, 10, 12)
_eq(s.src_rect.width, 10, 'src w')
s.dispose; b.dispose
true
"""],
		["Sprite#flash(color/nil) and #update do not raise", _ASSERT + """
s = Sprite.new
s.flash(Color.new(255,255,255,255), 8)
s.update
s.flash(nil, 8)   # hide-flash
s.update
s.dispose
true
"""],
		["Sprite#viewport= nil resets to default", _ASSERT + """
vp = Viewport.new(0, 0, 32, 32)
s = Sprite.new(vp)
raise 'has viewport' if s.viewport.nil?
s.viewport = nil
_eq(s.viewport, nil, 'nil viewport')
s.dispose; vp.dispose
true
"""],
	]


# ============================ PLANE ============================
func _plane_tests() -> Array:
	return [
		["Plane#visible exists and round-trips (B6)", _ASSERT + """
p = Plane.new
p.visible = false; _eq(p.visible, false, 'visible')
p.visible = true;  _eq(p.visible, true, 'visible2')
p.dispose
true
"""],
		["Plane ox/oy/z round-trip", _ASSERT + """
p = Plane.new
p.ox = 7; p.oy = 9; p.z = 3
_eq(p.ox, 7, 'ox'); _eq(p.oy, 9, 'oy'); _eq(p.z, 3, 'z')
p.dispose
true
"""],
		["Plane#bitmap= accepts nil (B9)", _ASSERT + """
p = Plane.new
p.bitmap = Bitmap.new(8,8)
p.bitmap = nil
_eq(p.bitmap, nil, 'nil bitmap')
p.dispose
true
"""],
		["Plane color/tone/opacity/blend_type/zoom round-trip", _ASSERT + """
p = Plane.new
p.color = Color.new(10, 20, 30, 40)
_aeq(p.color.red, 10, 0.6, 'color r')
p.tone = Tone.new(5, 5, 5, 10); _aeq(p.tone.gray, 10, 0.6, 'tone gray')
p.opacity = 200; _eq(p.opacity, 200, 'opacity')
p.blend_type = 1; _eq(p.blend_type, 1, 'blend')
p.zoom_x = 2.0; p.zoom_y = 3.0
_aeq(p.zoom_x, 2.0, 0.001, 'zx'); _aeq(p.zoom_y, 3.0, 0.001, 'zy')
p.dispose
true
"""],
	]


# ============================ VIEWPORT ============================
func _viewport_tests() -> Array:
	return [
		["Viewport#visible exists and round-trips (B7)", _ASSERT + """
v = Viewport.new(0, 0, 100, 80)
v.visible = false; _eq(v.visible, false, 'visible')
v.visible = true;  _eq(v.visible, true, 'visible2')
v.dispose
true
"""],
		["Viewport rect + z + ox/oy", _ASSERT + """
v = Viewport.new(0, 0, 64, 48)
_eq(v.rect.width, 64, 'rect w')
v.z = 50; v.ox = 4; v.oy = 6
_eq(v.z, 50, 'z'); _eq(v.ox, 4, 'ox')
v.dispose
true
"""],
		["Viewport#flash(nil, dur) does not raise (B8)", _ASSERT + """
v = Viewport.new(0, 0, 32, 32)
v.flash(Color.new(255,255,255,255), 10)
v.flash(nil, 10)
v.dispose
true
"""],
		["Viewport color/tone/rect= round-trip", _ASSERT + """
v = Viewport.new(0, 0, 32, 32)
v.color = Color.new(60, 70, 80, 90); _aeq(v.color.blue, 80, 0.6, 'color b')
v.tone = Tone.new(-30, 0, 30, 50); _aeq(v.tone.red, -30, 0.6, 'tone r')
v.rect = Rect.new(5, 6, 40, 50)
_eq(v.rect.x, 5, 'rect x'); _eq(v.rect.height, 50, 'rect h')
v.dispose
true
"""],
	]


# ============================ WINDOW ============================
func _window_tests() -> Array:
	return [
		["Window default padding is 12 (G3)", _ASSERT + """
w = Window.new(0, 0, 100, 80)
_eq(w.padding, 12, 'padding')
w.dispose
true
"""],
		["Window opacity fields clamp 0..255", _ASSERT + """
w = Window.new(0, 0, 100, 80)
w.opacity = 999; _eq(w.opacity, 255, 'op clamp')
w.back_opacity = -5; _eq(w.back_opacity, 0, 'back clamp')
w.openness = 999; _eq(w.openness, 255, 'openness clamp')
w.dispose
true
"""],
		["Window open?/close? track openness", _ASSERT + """
w = Window.new(0, 0, 100, 80)
w.openness = 255; _eq(w.open?, true, 'open'); _eq(w.close?, false, 'not closed')
w.openness = 0;   _eq(w.close?, true, 'closed')
w.dispose
true
"""],
		["Window#move sets geometry", _ASSERT + """
w = Window.new(0, 0, 10, 10)
w.move(5, 6, 40, 30)
_eq(w.x, 5, 'x'); _eq(w.width, 40, 'w')
w.dispose
true
"""],
		["Window active/visible/pause/arrows_visible booleans", _ASSERT + """
w = Window.new(0, 0, 100, 80)
w.active = false; _eq(w.active, false, 'active')
w.visible = false; _eq(w.visible, false, 'visible')
w.pause = true; _eq(w.pause, true, 'pause')
w.arrows_visible = false; _eq(w.arrows_visible, false, 'arrows')
w.dispose
true
"""],
		["Window contents/windowskin are Bitmaps", _ASSERT + """
w = Window.new(0, 0, 100, 80)
w.contents = Bitmap.new(80, 60)
raise 'contents' unless w.contents.is_a?(Bitmap)
_eq(w.contents.width, 80, 'contents w')
w.dispose
true
"""],
		["Window cursor_rect + tone + ox/oy + z round-trip", _ASSERT + """
w = Window.new(0, 0, 100, 80)
w.cursor_rect = Rect.new(2, 4, 20, 16)
_eq(w.cursor_rect.width, 20, 'cursor w')
w.tone = Tone.new(10, 20, 30, 0); _aeq(w.tone.green, 20, 0.6, 'tone g')
w.ox = 3; w.oy = 5; w.z = 200
_eq(w.ox, 3, 'ox'); _eq(w.z, 200, 'z')
w.dispose
true
"""],
		["Window contents_opacity clamps", _ASSERT + """
w = Window.new(0, 0, 100, 80)
w.contents_opacity = 999; _eq(w.contents_opacity, 255, 'co clamp')
w.dispose
true
"""],
	]


# ============================ TILEMAP ============================
func _tilemap_tests() -> Array:
	return [
		["Tilemap ox/oy/visible + dispose", _ASSERT + """
tm = Tilemap.new
tm.ox = 16; tm.oy = 32; tm.visible = false
_eq(tm.ox, 16, 'ox'); _eq(tm.oy, 32, 'oy'); _eq(tm.visible, false, 'visible')
_eq(tm.disposed?, false, 'alive'); tm.dispose; _eq(tm.disposed?, true, 'disposed')
true
"""],
		["Tilemap map_data/flags accept Table", _ASSERT + """
tm = Tilemap.new
md = Table.new(4, 4, 3); tm.map_data = md
raise 'map_data' unless tm.map_data.equal?(md)
fl = Table.new(8); tm.flags = fl
raise 'flags' unless tm.flags.equal?(fl)
tm.dispose
true
"""],
		["Tilemap#bitmaps proxy indexed assign", _ASSERT + """
tm = Tilemap.new
b = Bitmap.new(32, 32)
tm.bitmaps[0] = b
raise 'bitmaps[0]' unless tm.bitmaps[0].equal?(b)
tm.dispose
true
"""],
	]


# ============================ GRAPHICS (value methods only) ============================
# update/wait/fadeout/fadein/transition need the Fiber-pump context and are exercised by
# the boot/scene integration tests, not here (a bare Fiber.yield would mis-yield).
func _graphics_tests() -> Array:
	return [
		["Graphics.width/height are positive", _ASSERT + """
raise "w #{Graphics.width}" unless Graphics.width > 0
raise "h #{Graphics.height}" unless Graphics.height > 0
true
"""],
		["Graphics.frame_rate= round-trips", _ASSERT + """
old = Graphics.frame_rate
Graphics.frame_rate = 30; _eq(Graphics.frame_rate, 30, 'fr 30')
Graphics.frame_rate = 60; _eq(Graphics.frame_rate, 60, 'fr 60')
Graphics.frame_rate = old
true
"""],
		["Graphics.frame_count= and frame_reset", _ASSERT + """
Graphics.frame_count = 123; _eq(Graphics.frame_count, 123, 'fc set')
Graphics.frame_reset; _eq(Graphics.frame_count, 0, 'fc reset')
true
"""],
		["Graphics.brightness= round-trips 0..255", _ASSERT + """
Graphics.brightness = 128; _aeq(Graphics.brightness, 128, 1.0, 'b 128')
Graphics.brightness = 255; _aeq(Graphics.brightness, 255, 1.0, 'b 255')
true
"""],
	]
