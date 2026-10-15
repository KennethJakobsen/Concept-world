class_name TestCase
extends RefCounted
## Minimal testbase. Metoder der starter med "test_" køres af run_tests.gd.

var failures: PackedStringArray = []


func assert_true(cond: bool, msg: String = "") -> void:
	if not cond:
		failures.append("expected true. " + msg)


func assert_eq(actual: Variant, expected: Variant, msg: String = "") -> void:
	if actual != expected:
		failures.append("expected %s, got %s. %s" % [expected, actual, msg])
