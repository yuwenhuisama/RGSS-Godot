extends SceneTree

# B04 value-semantics regression tests.
#
# Expected values come from the original RGSS300 run captured in
# .omo/compatibility-run-tmp/b04-values-original/value_semantics_reference.tsv.
# The pre-fix Godot counterpart is
# .omo/evidence/rmva-compatibility/godot/value_semantics_reference.tsv.
#
# Run headless:
#   godot --headless --path . -s tests/test_value_semantics.gd
# Exit code 0 = all passed, 1 = one or more failed.
# Marker: VALUE_SEMANTICS_PASS / VALUE_SEMANTICS_FAIL

var _driver
var _root: Node
var _passed := 0
var _failed := 0
var _failures: Array = []


func _initialize() -> void:
	var driver_script := load("res://Scripts/StressDisposeTestDriver.cs")
	_driver = driver_script.new()
	_root = Node.new()
	_root.name = "ValueSemanticsTestRoot"
	root.add_child(_root)
	_driver.Initialize(_root)
	if not _driver.RunRuby("""
require 'kernel'
require 'color'
require 'tone'
require 'rect'
require 'table'
"""):
		push_error("RGSS value-semantics wrappers failed to initialize")
		_driver.Shutdown()
		quit(1)
		return
	for i in range(3):
		_driver.UpdateRenderManager()
		await process_frame

	for t in _all_tests():
		_run_one(t[0], t[1])

	print("\n==== VALUE SEMANTICS TEST SUMMARY ====")
	print("PASSED: %d   FAILED: %d" % [_passed, _failed])
	for f in _failures:
		print("  FAIL: %s" % f)
	var exit_code := 0 if _failed == 0 else 1
	print("VALUE_SEMANTICS_PASS" if _failed == 0 else "VALUE_SEMANTICS_FAIL")
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


const _ASSERT := """
def _aeq(actual, expected, tol, msg)
  raise "#{msg}: expected #{expected} got #{actual}" unless (actual - expected).abs <= tol
end
def _eq(actual, expected, msg)
  raise "#{msg}: expected #{expected.inspect} got #{actual.inspect}" unless actual == expected
end
"""


func _all_tests() -> Array:
	return [
		# Reference row: table_resize 2,2,2 -> 1 2 11 12 0 112.
		# Pre-fix Godot produced 1 2 12 101 11 0 (flat-index copy).
		["Table 3D resize preserves (x,y,z) coordinates", _ASSERT + """
t = Table.new(2, 2, 2)
(0...2).each { |z| (0...2).each { |y| (0...2).each { |x| t[x, y, z] = x + y * 10 + z * 100 + 1 } } }
t.resize(3, 3, 2)
_eq(t.xsize, 3, 'xsize'); _eq(t.ysize, 3, 'ysize'); _eq(t.zsize, 2, 'zsize')
_eq(t[0, 0, 0], 1, '[0,0,0]')
_eq(t[1, 0, 0], 2, '[1,0,0]')
_eq(t[0, 1, 0], 11, '[0,1,0]')
_eq(t[1, 1, 0], 12, '[1,1,0]')
_eq(t[2, 0, 0], 0, '[2,0,0] new cell')
_eq(t[1, 1, 1], 112, '[1,1,1]')
true
"""],
		# Original table_dimensions_reference: omitted zsize=1, index arity=2.
		["Table 2D resize preserves rows and rejects 3D indexing", _ASSERT + """
t = Table.new(2, 2)
(0...2).each { |y| (0...2).each { |x| t[x, y] = x + y * 10 + 1 } }
t.resize(3, 3)
_eq(t.xsize, 3, 'xsize'); _eq(t.ysize, 3, 'ysize'); _eq(t.zsize, 1, 'zsize')
_eq(t[0, 0], 1, '[0,0]'); _eq(t[1, 0], 2, '[1,0]')
_eq(t[0, 1], 11, '[0,1]'); _eq(t[1, 1], 12, '[1,1]')
_eq(t[2, 0], 0, 'new cell')
begin
  t[0,0,0]
  raise '3D indexing accepted on 2D table'
rescue ArgumentError
end
true
"""],
		["Table 1D resize preserves overlap", _ASSERT + """
t = Table.new(3); t[1] = 8
t.resize(5)
_eq(t.xsize, 5, 'xsize'); _eq(t[1], 8, 'preserved'); _eq(t[4], 0, 'new cell')
true
"""],
		# Reference row: color_clamp -1.0 255.0 12.0 255.0.
		["Color constructor clamps upper bound only", _ASSERT + """
c = Color.new(-1, 300, 12, 400)
_aeq(c.red, -1, 0.01, 'red stays negative')
_aeq(c.green, 255, 0.01, 'green upper clamp')
_aeq(c.blue, 12, 0.01, 'blue')
_aeq(c.alpha, 255, 0.01, 'alpha upper clamp')
true
"""],
		# Reference row: tone_clamp -255.0 255.0 12.0 255.0.
		["Tone constructor clamps r/g/b -255..255 and gray 0..255", _ASSERT + """
t = Tone.new(-400, 400, 12, 400)
_aeq(t.red, -255, 0.01, 'red lower clamp')
_aeq(t.green, 255, 0.01, 'green upper clamp')
_aeq(t.blue, 12, 0.01, 'blue')
_aeq(t.gray, 255, 0.01, 'gray upper clamp')
true
"""],
		# Reference row: rect_negative 1 2 -3 -4 (control; unchanged by B04).
		["Color setter and set preserve original RGB negatives", _ASSERT + """
c = Color.new
c.red = -20; c.green = 300; c.alpha = -10
_aeq(c.red, -20, 0.01, 'negative red'); _aeq(c.green, 255, 0.01, 'upper green'); _aeq(c.alpha, 0, 0.01, 'lower alpha')
c.set(-30, 400, 12, -10)
_aeq(c.red, -30, 0.01, 'set red'); _aeq(c.green, 255, 0.01, 'set green'); _aeq(c.blue, 12, 0.01, 'set blue'); _aeq(c.alpha, 0, 0.01, 'set alpha')
true
"""],
		["Rect keeps negative width/height (control)", _ASSERT + """
r = Rect.new(1, 2, -3, -4)
_eq(r.x, 1, 'x'); _eq(r.y, 2, 'y'); _eq(r.width, -3, 'width'); _eq(r.height, -4, 'height')
true
"""],
		["Rect truncates positive and negative Float coordinates", _ASSERT + """
[1.9, -1.9].each do |value|
  expected = value.to_i
  r = Rect.new(value, value, value, value)
  _eq([r.x,r.y,r.width,r.height], [expected]*4, 'float constructor')
  r.set(-value,-value,-value,-value)
  _eq([r.x,r.y,r.width,r.height], [-expected]*4, 'float set')
  [:x,:y,:width,:height].each { |prop| r.send(prop.to_s+'=',value) }
  _eq([r.x,r.y,r.width,r.height], [expected]*4, 'float setters')
end
true
"""],
	]
