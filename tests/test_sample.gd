extends GutTest

# Sample GUT test to validate the headless test harness (T8).
# Asserts a trivial truth so a green run proves the GUT pipeline works.


func test_one_plus_one_equals_two() -> void:
	assert_eq(1 + 1, 2, "1 + 1 should equal 2")
