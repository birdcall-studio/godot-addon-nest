extends SceneTree
## nest-verify-package runs this in a clean project that holds only the
## unpacked release zip. That way it checks what games get, without this
## repo's tests or project settings:
##   1. plugin.cfg has every field the Godot editor shows or needs.
##   2. Its script loads and extends EditorPlugin.
##   3. Every script in the add-on compiles.
## Fails on any engine or script error as well.
## Run: godot --headless --path <project> -s res://verify_package.gd -- <name>

const PLUGIN_FIELDS: PackedStringArray = ["name", "description", "author", "version", "script"]

var _failed := 0
var _errors := ErrorCounter.new()


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
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		_fail("usage", "pass the add-on name after --")
		quit(1)
		return
	var addon_dir := "res://addons".path_join(args[0])
	_check_plugin(addon_dir)
	for path: String in _find_scripts(addon_dir):
		_compile(path)
	if _errors.count > 0:
		_fail("package", "raised %d error(s), see output above" % _errors.count)
	quit(1 if _failed > 0 else 0)


func _check_plugin(addon_dir: String) -> void:
	var cfg_path := addon_dir.path_join("plugin.cfg")
	var cfg := ConfigFile.new()
	if cfg.load(cfg_path) != OK:
		_fail(cfg_path, "missing or unreadable")
		return
	var failed_before := _failed
	for field: String in PLUGIN_FIELDS:
		if str(cfg.get_value("plugin", field, "")).strip_edges().is_empty():
			_fail(cfg_path, "[plugin] %s is missing or empty" % field)
	var script_path := addon_dir.path_join(str(cfg.get_value("plugin", "script", "")))
	var plugin_script := ResourceLoader.load(script_path) as GDScript
	if plugin_script == null:
		_fail(cfg_path, "script %s does not load" % script_path)
	elif not ClassDB.is_parent_class(plugin_script.get_instance_base_type(), "EditorPlugin"):
		_fail(script_path, "must extend EditorPlugin")
	elif _failed == failed_before:
		print("ok   %s" % cfg_path)


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


func _compile(path: String) -> void:
	var gd_script := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as GDScript
	if gd_script == null or gd_script.reload() != OK:
		_fail("compile %s" % path, "script has errors, see output above")
	else:
		print("ok   compile %s" % path)


func _fail(label: String, message: String) -> void:
	_failed += 1
	printerr("FAIL %s: %s" % [label, message])
