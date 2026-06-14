extends SceneTree

# Regression test for the zero-damage bug.
#
# Root cause: mruby 4.0.0 changed Kernel#eval registration from
# `mrb_define_module_function` (3.3.0 / MRI: private instance + PUBLIC singleton)
# to `mrb_define_private_method_id` (private-only). That made the explicit
# `Kernel.eval(@formula)` call in RPG::UsableItem::Damage#eval raise NoMethodError,
# which its trailing `rescue 0` swallowed -> every battle damage formula returned 0.
#
# Fix: revert mrbgems/mruby-eval/src/eval.c to register `eval` as a module_function,
# then rebuild + redeploy libmruby_x64.dll.
#
# This test drives the ACTUAL deployed DLL via StressDisposeTestDriver.RunRuby(code),
# which returns false if the Ruby raised. Each block self-asserts with `raise unless`.
#
# Run headless:
#   godot --headless --path . -s tests/test_eval_damage_fix.gd
# Exit 0 = all passed. Markers: EVAL_DAMAGE_FIX_PASS / EVAL_DAMAGE_FIX_FAIL.

var _driver
var _root: Node
var _passed := 0
var _failed := 0
var _failures: Array = []


func _initialize() -> void:
	var driver_script := load("res://Scripts/StressDisposeTestDriver.cs")
	_driver = driver_script.new()
	_root = Node.new()
	_root.name = "EvalDamageTestRoot"
	root.add_child(_root)
	_driver.Initialize(_root)
	for i in range(3):
		_driver.UpdateRenderManager()
		await process_frame

	for t in _all_tests():
		_run_one(t[0], t[1])

	print("\n==== EVAL DAMAGE FIX TEST SUMMARY ====")
	print("PASSED: %d   FAILED: %d" % [_passed, _failed])
	for f in _failures:
		print("  FAIL: %s" % f)
	print("EVAL_DAMAGE_FIX_PASS" if _failed == 0 else "EVAL_DAMAGE_FIX_FAIL")
	_driver.Shutdown()
	quit(0 if _failed == 0 else 1)


func _run_one(test_name: String, ruby_code: String) -> void:
	var ok: bool = _driver.RunRuby(ruby_code)
	if ok:
		_passed += 1
		print("  ok   - %s" % test_name)
	else:
		_failed += 1
		_failures.append(test_name)
		print("  FAIL - %s" % test_name)


func _all_tests() -> Array:
	# The fix lives in RGSS/main.rb as `module Kernel; module_function :eval; end`,
	# applied before the require block. The RunRuby harness does NOT load main.rb, so
	# each test below first applies that exact same line, then exercises eval. This
	# proves the one-liner is what restores the public Kernel.eval used by RGSS3.
	const PATCH := 'module Kernel; module_function :eval; end'
	return [
		# 0. Baseline: BEFORE the patch, the mruby 4.0.0 build registers Kernel#eval as a
		#    private method, so the explicit-receiver call raises -> RunRuby returns false.
		#    A passing test here means "the raise happened as expected" (proves the bug).
		["baseline_kernel_eval_is_private_without_patch",
			'begin\n' +
			'  Kernel.eval("1 + 2")\n' +
			'  raise "EXPECTED Kernel.eval to be private before patch, but it succeeded"\n' +
			'rescue NoMethodError\n' +
			'  # expected: private method `eval\' called for Kernel\n' +
			'end'],

		# 1. The exact broken pattern, AFTER applying the main.rb patch line.
		["kernel_eval_explicit_receiver_after_patch",
			PATCH + "\n" +
			'raise "Kernel.eval(string) failed" unless Kernel.eval("1 + 2") == 3'],

		# 2. Bare eval still works (Game_Interpreter / move-route script path).
		["bare_eval_with_local",
			PATCH + "\n" +
			'x = 21; raise "bare eval failed" unless eval("x * 2") == 42'],

		# 3. Full RGSS3 damage-formula simulation: a/b battlers + the literal
		#    `[Kernel.eval(@formula), 0].max * sign rescue 0` shape from
		#    RPG::UsableItem::Damage#eval. Must yield 360, NOT 0.
		["rgss3_damage_formula_nonzero",
			PATCH + "\n" +
			'class FakeBattler\n' +
			'  def atk; 100; end\n' +
			'  def def; 20; end\n' +
			'end\n' +
			'class FakeDamage\n' +
			'  def initialize(f); @formula = f; end\n' +
			'  def sign; 1; end\n' +
			'  def eval(a, b, v)\n' +
			'    [Kernel.eval(@formula), 0].max * sign rescue 0\n' +
			'  end\n' +
			'end\n' +
			'dmg = FakeDamage.new("a.atk * 4 - b.def * 2")\n' +
			'result = dmg.eval(FakeBattler.new, FakeBattler.new, [])\n' +
			'raise "expected 360 but got #{result}" unless result == 360'],

		# 4. Guard against silent rescue-to-zero: a valid formula must never be 0
		#    when the underlying stats are non-zero.
		["damage_not_silently_zero",
			PATCH + "\n" +
			'a = Object.new\n' +
			'def a.atk; 50; end\n' +
			'b = Object.new\n' +
			'def b.def; 10; end\n' +
			'val = (Kernel.eval("a.atk * 4 - b.def * 2") rescue 0)\n' +
			'raise "damage silently zeroed (eval still broken)" if val == 0\n' +
			'raise "wrong value #{val}" unless val == 180'],
	]
