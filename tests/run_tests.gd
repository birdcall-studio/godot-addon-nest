extends SceneTree
## Headless checks that need no outside tools:
##   1. Check that project.godot turns on Godot's warnings for add-on code.
##   2. Compile every script under res://addons. The project sets its GDScript
##      warnings to Error, so this is also the lint step.
##   3. Run every test_* method in res://tests/**/test_*.gd. A test fails if a
##      check() fails or if it raises any engine or script error.
## Run: godot --headless --path . -s res://tests/run_tests.gd

const ADDONS_DIR := "res://addons"
const TESTS_DIR := "res://tests"
const TEST_CASE_PATH := "res://tests/support/test_case.gd"
const WARNINGS := "debug/gdscript/warnings/"
## Warnings project.godot must set to 2 (Error).
const REQUIRED_WARNINGS: PackedStringArray = [
	"unused_variable",
	"unused_local_constant",
	"unused_parameter",
	"shadowed_variable",
	"unreachable_code",
	"standalone_expression",
]
const RULE_INCLUDE := 1

var _total := 0
var _failed := 0
var _tests := 0
var _errors := ErrorCounter.new()


## Counts engine and script errors. GDScript can't catch them, so this is how
## a test that raises one still fails.
class ErrorCounter extends Logger:
	var count := 0
	var _mutex := Mutex.new()

	func _log_error(
		_function: String,
		_file: String,
		_line: int,
		_code: String,
		_rationale: String,
		_editor_notify: bool,
		error_type: int,
		_script_backtraces: Array[ScriptBacktrace],
	) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		_mutex.lock()
		count += 1
		_mutex.unlock()


func _initialize() -> void:
	OS.add_logger(_errors)
	_check_settings()
	for path: String in _find_scripts(ADDONS_DIR):
		_compile_check(path)
	for path: String in _find_scripts(TESTS_DIR):
		if path.get_file().begins_with("test_") and path != TEST_CASE_PATH:
			await _run_suite(path)
	if _tests == 0:
		_fail(TESTS_DIR, "no test_* methods found in tests/**/test_*.gd")
	var version: String = Engine.get_version_info().string
	print("\n%d checks, %d failed (Godot %s)" % [_total, _failed, version])
	quit(1 if _failed > 0 else 0)


func _check_settings() -> void:
	_total += 1
	var problems := PackedStringArray()
	if not ProjectSettings.get_setting(WARNINGS + "enable", true):
		problems.append("Debug > GDScript > Enable is off")
	for addon: String in DirAccess.get_directories_at(ADDONS_DIR):
		if not _warnings_apply_to(ADDONS_DIR.path_join(addon) + "/"):
			problems.append("Debug > GDScript > Directory Rules excludes res://addons/%s" % addon)
	for warning: String in REQUIRED_WARNINGS:
		if ProjectSettings.get_setting(WARNINGS + warning, 0) != 2:
			problems.append("Debug > GDScript > %s is not Error" % warning.capitalize())
	if problems.is_empty():
		print("ok   project settings")
		return
	_failed += 1
	for problem: String in problems:
		printerr("FAIL project.godot: %s" % problem)


## The most specific directory rule that covers dir_path wins. If no rule
## covers it, warnings apply.
func _warnings_apply_to(dir_path: String) -> bool:
	var rules: Dictionary = ProjectSettings.get_setting(WARNINGS + "directory_rules", {})
	var best := ""
	var include := true
	for rule_path: String in rules:
		var prefix := rule_path if rule_path.ends_with("/") else rule_path + "/"
		if dir_path.begins_with(prefix) and prefix.length() > best.length():
			best = prefix
			include = rules[rule_path] == RULE_INCLUDE
	return include


func _find_scripts(dir_path: String) -> PackedStringArray:
	var found := PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return found
	for file: String in dir.get_files():
		if file.get_extension() == "gd":
			found.append(dir_path.path_join(file))
	for sub: String in dir.get_directories():
		found.append_array(_find_scripts(dir_path.path_join(sub)))
	found.sort()
	return found


func _compile_check(path: String) -> void:
	_total += 1
	var cache_mode := ResourceLoader.CACHE_MODE_IGNORE
	var gd_script := ResourceLoader.load(path, "", cache_mode) as GDScript
	if gd_script == null or gd_script.reload() != OK:
		_fail("compile %s" % path, "script has errors, see output above")
	else:
		print("ok   compile %s" % path)


func _run_suite(path: String) -> void:
	var suite_script := load(path) as GDScript
	if suite_script == null or not suite_script.can_instantiate():
		_total += 1
		_fail(path, "test file has errors, see output above")
		return
	if not _extends_test_case(suite_script):
		_total += 1
		_fail(path, "test file must extend \"%s\"" % TEST_CASE_PATH)
		return
	for method: Dictionary in suite_script.get_script_method_list():
		var method_name: String = method.name
		if not method_name.begins_with("test_"):
			continue
		_total += 1
		_tests += 1
		var suite: RefCounted = suite_script.new()
		var errors_before := _errors.count
		await suite.call(method_name)
		var errors := _errors.count - errors_before
		var failures: Array[String] = suite.get("failures")
		if failures.is_empty() and errors == 0:
			print("ok   %s" % method_name)
			continue
		_failed += 1
		for message: String in failures:
			printerr("FAIL %s: %s" % [method_name, message])
		if errors > 0:
			printerr("FAIL %s: raised %d error(s), see output above" % [method_name, errors])


func _extends_test_case(gd_script: Script) -> bool:
	var base := gd_script.get_base_script()
	while base != null:
		if base.resource_path == TEST_CASE_PATH:
			return true
		base = base.get_base_script()
	return false


func _fail(label: String, message: String) -> void:
	_failed += 1
	printerr("FAIL %s: %s" % [label, message])
