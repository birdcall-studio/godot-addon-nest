extends RefCounted
## Base class for test files. tests/run_tests.gd runs each test_* method in
## any tests/**/test_*.gd file. Call check() to test a condition.

var failures: Array[String] = []


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
