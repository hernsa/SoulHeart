extends RefCounted

func test_npc_scripts_load() -> void:
	var npc = load("res://scripts/rooms/npc.gd")
	var door = load("res://scripts/rooms/door.gd")
	var save = load("res://scripts/rooms/save_point.gd")
	var enc = load("res://scripts/rooms/encounter.gd")
	TestHelper.is_true(npc != null, "npc script loads")
	TestHelper.is_true(door != null, "door script loads")
	TestHelper.is_true(save != null, "save point script loads")
	TestHelper.is_true(enc != null, "encounter script loads")

func test_room_scenes_load() -> void:
	var dz = load("res://scenes/rooms/DrizzleFields.tscn")
	var gw = load("res://scenes/rooms/GrumbleWoods.tscn")
	TestHelper.is_true(dz != null, "drizzle fields scene loads")
	TestHelper.is_true(gw != null, "grumble woods scene loads")

func test_dialogue_files_parse() -> void:
	var toad := DialogueParser.parse_file("res://dialogue/drizzle_toad.dlg")
	var sign := DialogueParser.parse_file("res://dialogue/grumble_sign.dlg")
	TestHelper.is_true(toad.size() >= 3, "toad has lines")
	TestHelper.is_true(sign.size() >= 2, "sign has lines")
	TestHelper.is_true(str(sign[0]["text"]).length() > 0, "sign text present")
