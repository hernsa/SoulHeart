# tests/test_grumble_doors.gd
extends RefCounted

func test_grumble_has_two_doors() -> void:
	var script := load("res://scripts/rooms/grumble_woods.gd")
	var consts: Dictionary = script.get_script_constant_map()
	var layout: String = consts["LAYOUT"]
	var parsed := MapBuilder.parse_layout(layout)
	var targets: Array = consts["DOOR_TARGETS"]
	TestHelper.eq(parsed["doors"].size(), 2, "grumble must have 2 doors (Echo + Drizzle)")
	TestHelper.eq(targets.size(), 2, "grumble DOOR_TARGETS has 2 entries")

func test_grumble_doors_lead_to_existing_scenes() -> void:
	var script := load("res://scripts/rooms/grumble_woods.gd")
	var consts: Dictionary = script.get_script_constant_map()
	var targets: Array = consts["DOOR_TARGETS"]
	for t in targets:
		TestHelper.is_true(ResourceLoader.exists(t["target_room"]),
			"grumble target missing: %s" % t["target_room"])

func test_grumble_door_to_echo() -> void:
	var script := load("res://scripts/rooms/grumble_woods.gd")
	var consts: Dictionary = script.get_script_constant_map()
	var targets: Array = consts["DOOR_TARGETS"]
	var found := false
	for t in targets:
		if str(t["target_room"]).ends_with("Echo.tscn"):
			found = true
			TestHelper.is_true(t["target_spawn"] == Vector2(40, 232),
				"echo spawn must be (40, 232), got %s" % [t["target_spawn"]])
	TestHelper.is_true(found, "grumble must have a door to Echo")