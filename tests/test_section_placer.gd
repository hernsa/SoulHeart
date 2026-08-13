extends RefCounted

func test_spawn_landmark_adds_child() -> void:
	var parent := Node2D.new()
	var objects := [{"section_id": "meadow", "type": "landmark", "cell": Vector2i(2, 2), "data": {"label": "X"}}]
	SectionPlacer.spawn_all(parent, objects, [], {})
	TestHelper.is_true(parent.get_child_count() >= 1, "landmark child added")

func test_spawn_save_returns_save_point() -> void:
	var parent := Node2D.new()
	var objects := [{"section_id": "grove", "type": "save", "cell": Vector2i(1, 1), "data": {}}]
	SectionPlacer.spawn_all(parent, objects, [], {})
	var found := false
	for c in parent.get_children():
		if c is SavePoint:
			found = true
	TestHelper.is_true(found, "save point spawned")

func test_spawn_door_sets_target() -> void:
	var parent := Node2D.new()
	var objects := [{"section_id": "ridge", "type": "exit", "cell": Vector2i(3, 3), "data": {"target": "res://scenes/rooms/GrumbleWoods.tscn", "target_spawn": Vector2(520, 392)}}]
	SectionPlacer.spawn_all(parent, objects, [], {})
	var found: Variant = null
	for c in parent.get_children():
		if c is Door:
			found = c
	TestHelper.is_true(found != null, "door spawned")
	TestHelper.eq(found.target_room, "res://scenes/rooms/GrumbleWoods.tscn", "door target set")

func test_spawn_flavor_adds_sprite() -> void:
	var parent := Node2D.new()
	var flavor := [{"section_id": "meadow", "kind": "old_boot", "cell": Vector2i(0, 0)}]
	SectionPlacer.spawn_all(parent, [], flavor, {})
	TestHelper.is_true(parent.get_child_count() >= 1, "flavor sprite added")