# tests/test_area_rooms.gd
extends RefCounted

const ROOMS := {
	"echo": {"scene": "res://scenes/rooms/Echo.tscn", "script": "res://scripts/rooms/echo.gd", "class": "Echo"},
	"hometown": {"scene": "res://scenes/rooms/Hometown.tscn", "script": "res://scripts/rooms/hometown.gd", "class": "Hometown"},
	"canon": {"scene": "res://scenes/rooms/Canon.tscn", "script": "res://scripts/rooms/canon.gd", "class": "Canon"},
	"cracks": {"scene": "res://scenes/rooms/Cracks.tscn", "script": "res://scripts/rooms/cracks.gd", "class": "Cracks"},
}

func test_scenes_and_scripts_exist() -> void:
	for id in ROOMS:
		_scene_script_pair(id)

func _scene_script_pair(id: String) -> void:
	var r: Dictionary = ROOMS[id]
	TestHelper.is_true(ResourceLoader.exists(r["scene"]), "%s scene missing" % id)
	TestHelper.is_true(ResourceLoader.exists(r["script"]), "%s script missing" % id)

func test_each_room_layout_parses_to_40x30() -> void:
	for id in ROOMS:
		var script := load(ROOMS[id]["script"])
		var consts: Dictionary = script.get_script_constant_map()
		var layout: String = consts["LAYOUT"]
		var parsed := MapBuilder.parse_layout(layout)
		var grid: Array = parsed["grid"]
		TestHelper.eq(grid.size(), 30, "%s layout rows" % id)
		for row in grid:
			TestHelper.eq(row.size(), 40, "%s layout cols" % id)
		TestHelper.is_true(parsed["player_start"] != Vector2.ZERO, "%s player start set" % id)

func test_each_room_has_four_encounters() -> void:
	for id in ROOMS:
		var script := load(ROOMS[id]["script"])
		var consts: Dictionary = script.get_script_constant_map()
		var layout: String = consts["LAYOUT"]
		var parsed := MapBuilder.parse_layout(layout)
		TestHelper.eq(parsed["encounters"].size(), 4, "%s has 4 encounters" % id)

func test_each_room_enemies_exist_in_library() -> void:
	for id in ROOMS:
		var script := load(ROOMS[id]["script"])
		var consts: Dictionary = script.get_script_constant_map()
		var enemies: Array = consts["ENCOUNTER_ENEMIES"]
		TestHelper.is_true(enemies.size() >= 1, "%s has encounter enemies" % id)
		for e in enemies:
			TestHelper.is_true(not EnemyLibrary.get_enemy(e).is_empty(),
				"%s references unknown enemy '%s'" % [id, e])

func test_each_room_has_save_point() -> void:
	for id in ROOMS:
		var script := load(ROOMS[id]["script"])
		var consts: Dictionary = script.get_script_constant_map()
		var layout: String = consts["LAYOUT"]
		var parsed := MapBuilder.parse_layout(layout)
		TestHelper.eq(parsed["save_points"].size(), 1, "%s has 1 save point" % id)

func test_door_targets_match_door_count_and_exist() -> void:
	for id in ROOMS:
		var script := load(ROOMS[id]["script"])
		var consts: Dictionary = script.get_script_constant_map()
		var layout: String = consts["LAYOUT"]
		var parsed := MapBuilder.parse_layout(layout)
		var targets: Array = consts["DOOR_TARGETS"]
		TestHelper.eq(parsed["doors"].size(), targets.size(),
			"%s door count matches targets" % id)
		for t in targets:
			TestHelper.is_true(ResourceLoader.exists(t["target_room"]),
				"%s target scene missing: %s" % [id, t["target_room"]])

func test_walkable_chain_reachable() -> void:
	var chain := ["Echo", "Hometown", "Canon", "Cracks"]
	for i in chain.size() - 1:
		var from: String = chain[i]
		var to: String = chain[i + 1]
		var script := load(ROOMS[from.to_lower()]["script"])
		var consts: Dictionary = script.get_script_constant_map()
		var targets: Array = consts["DOOR_TARGETS"]
		var found := false
		for t in targets:
			if str(t["target_room"]).ends_with(to + ".tscn"):
				found = true
		TestHelper.is_true(found, "%s must lead to %s" % [from, to])

func test_scenes_instantiate() -> void:
	for id in ROOMS:
		var scene := load(ROOMS[id]["scene"])
		var inst: Node = scene.instantiate()
		TestHelper.is_true(inst != null, "%s instantiates" % id)
		TestHelper.is_true(inst is Node2D, "%s root is Node2D" % id)
		inst.free()
