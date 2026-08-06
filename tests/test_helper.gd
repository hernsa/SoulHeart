class_name TestHelper

static var failures: int = 0

static func eq(got: Variant, expected: Variant, msg: String) -> void:
	if got != expected:
		failures += 1
		push_error("ASSERT FAIL [%s]: got %s, expected %s" % [msg, str(got), str(expected)])

static func is_true(cond: bool, msg: String) -> void:
	if not cond:
		failures += 1
		push_error("ASSERT FAIL [%s]: expected true, got false" % msg)
