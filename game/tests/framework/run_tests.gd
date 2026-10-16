extends SceneTree
## Kør: godot --headless --path game -s res://tests/framework/run_tests.gd

const TEST_DIR := "res://tests"


func _init() -> void:
	var failed: int = 0
	var passed: int = 0
	var logger := TestErrorCounter.new()
	OS.add_logger(logger)
	var test_dir: String = TEST_DIR
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--test-dir="):
			test_dir = a.trim_prefix("--test-dir=")
	for path in _find_tests(test_dir):
		logger.take()
		var script: GDScript = load(path) as GDScript
		var load_errors: PackedStringArray = logger.take()
		# T-096: en testfil, der ikke kan indlæses/parses, er en fejl (ikke et stille skip).
		if script == null or not script.can_instantiate() or not load_errors.is_empty():
			failed += 1
			printerr("FAIL %s – kunne ikke indlæses: %s" % [path, "; ".join(load_errors)])
			continue
		for m in script.get_script_method_list():
			var name: String = m["name"]
			if not name.begins_with("test_"):
				continue
			var tc: TestCase = script.new()
			logger.take()
			tc.call(name)
			for e in logger.take():
				tc.failures.append("script error: " + e)
			if tc.failures.is_empty():
				passed += 1
			else:
				failed += 1
				printerr("FAIL %s::%s – %s" % [path, name, "; ".join(tc.failures)])
	OS.remove_logger(logger)
	print("Tests: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _find_tests(dir_path: String) -> PackedStringArray:
	var out: PackedStringArray = []
	var dir := DirAccess.open(dir_path)
	for f in dir.get_files():
		if f.begins_with("test_") and f.ends_with(".gd"):
			out.append(dir_path.path_join(f))
	for d in dir.get_directories():
		if d != "framework":
			out.append_array(_find_tests(dir_path.path_join(d)))
	return out
