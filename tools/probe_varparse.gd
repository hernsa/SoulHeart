extends SceneTree

func _initialize() -> void:
	for f in ["res://tests/test_variety.gd", "res://tests/test_trees.gd", "res://tests/test_plan_d_integration.gd"]:
		var s := load(f)
		print("LOADED %s -> %s" % [f, s])
	quit(0)