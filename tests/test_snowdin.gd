extends RefCounted

func test_snowdin_scene_exists() -> void:
	var ok := ResourceLoader.exists("res://scenes/rooms/Snowdin.tscn")
	TestHelper.is_true(ok, "snowdin scene must exist")

func test_snowdin_script_loads() -> void:
	var s := load("res://scripts/rooms/snowdin.gd")
	TestHelper.is_true(s != null, "snowdin script must load")

func test_snowdin_uses_existing_enemy_ids() -> void:
	var src := FileAccess.get_file_as_string("res://scripts/rooms/snowdin.gd")
	for id in ["froggit", "loox", "moldsmal", "whimsun"]:
		TestHelper.is_true(src.find(id) != -1, "snowdin references enemy id: " + id)

func test_drizzle_door_points_to_snowdin() -> void:
	var src := FileAccess.get_file_as_string("res://scripts/rooms/drizzle_fields.gd")
	TestHelper.is_true(src.find("Snowdin.tscn") != -1, "drizzle door targets Snowdin")