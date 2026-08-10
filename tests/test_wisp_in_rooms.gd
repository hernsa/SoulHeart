# tests/test_wisp_in_rooms.gd
extends RefCounted

func test_drizzle_fields_spawns_wisp() -> void:
	var DrizzleScene := preload("res://scenes/rooms/DrizzleFields.tscn")
	var room: Node = DrizzleScene.instantiate()
	var stub := Node2D.new()
	stub.name = "Player"
	room.add_child(stub)
	room._spawn_wisp(stub)
	var found := _find_wisp(room)
	TestHelper.is_true(found != null, "DrizzleFields must contain a Wisp child")
	TestHelper.eq(WispState.last_area(), "drizzle_fields", "area set to drizzle_fields")
	room.free()

func test_grumble_woods_spawns_wisp() -> void:
	var GrumbleScene := preload("res://scenes/rooms/GrumbleWoods.tscn")
	var room: Node = GrumbleScene.instantiate()
	var stub := Node2D.new()
	stub.name = "Player"
	room.add_child(stub)
	room._spawn_wisp(stub)
	var found := _find_wisp(room)
	TestHelper.is_true(found != null, "GrumbleWoods must contain a Wisp child")
	TestHelper.eq(WispState.last_area(), "grumble_woods", "area set to grumble_woods")
	room.free()

func _find_wisp(node: Node) -> Node:
	if node.get_script() != null and node.get_script().resource_path == "res://scripts/wisp/wisp.gd":
		return node
	for child in node.get_children():
		var r := _find_wisp(child)
		if r != null:
			return r
	return null