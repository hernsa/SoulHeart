extends SceneTree

func _initialize() -> void:
	var failures := 0
	for path in _find_tests():
		var script: GDScript = load(path)
		var inst: RefCounted = script.new()
		TestHelper.failures = 0
		for m in script.get_script_method_list():
			if str(m["name"]).begins_with("test_"):
				inst.call(m["name"])
		if TestHelper.failures == 0:
			print("PASS: %s" % path)
		else:
			failures += TestHelper.failures
			print("FAIL: %s (%d asserts)" % [path, TestHelper.failures])
	if failures == 0:
		print("ALL TESTS PASSED")
		quit(0)
	else:
		print("TOTAL FAILURES: %d" % failures)
		quit(1)

func _find_tests() -> Array:
	var out: Array = []
	for path in DirAccess.get_files_at("res://tests"):
		if path.ends_with(".gd") and path != "run_all.gd" and path != "test_helper.gd":
			out.append("res://tests/" + path)
	out.sort()
	return out
