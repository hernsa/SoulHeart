extends RefCounted

func test_door_spawn_walkable() -> void:
	var parsed := MapBuilder.parse_layout(DrizzleFields.LAYOUT)
	var spawn: Vector2 = DrizzleFields.GRUMBLE_SPAWN
	var cell_x := int(spawn.x / 16)
	var cell_y := int(spawn.y / 16)
	var cell: int = parsed["grid"][cell_y][cell_x]
	TestHelper.is_true(cell == int(GameTiles.Tile.FLOOR), "Door spawn cell (%d,%d) should be walkable, got %s" % [cell_x, cell_y, cell])

func test_door_spawn_on_camera() -> void:
	var spawn: Vector2 = DrizzleFields.GRUMBLE_SPAWN
	TestHelper.is_true(spawn.x >= 0 and spawn.x <= 640, "Spawn x in viewport")
	TestHelper.is_true(spawn.y >= 0 and spawn.y <= 480, "Spawn y in viewport")

func test_grumble_door_spawn_walkable() -> void:
	var parsed := MapBuilder.parse_layout(GrumbleWoods.LAYOUT)
	var spawn: Vector2 = GrumbleWoods.DRIZZLE_SPAWN
	var cell_x := int(spawn.x / 16)
	var cell_y := int(spawn.y / 16)
	var cell: int = parsed["grid"][cell_y][cell_x]
	TestHelper.is_true(cell == int(GameTiles.Tile.FLOOR), "Grumble door spawn cell (%d,%d) should be walkable, got %s" % [cell_x, cell_y, cell])

func test_room_layouts_are_40x30() -> void:
	for layout in [DrizzleFields.LAYOUT, GrumbleWoods.LAYOUT]:
		var rows: Array = []
		for raw in layout.split("\n"):
			var row: String = raw.strip_edges()
			if not row.is_empty():
				rows.append(row)
		TestHelper.is_true(rows.size() == 30, "layout has 30 rows, got %d" % rows.size())
		for r in rows:
			TestHelper.is_true(r.length() == 40, "row width 40, got %d" % r.length())

func test_door_fail_loud_on_invalid_spawn() -> void:
	var door := Door.new()
	door.target_spawn = Vector2(-1, -1)
	door._ready()
	TestHelper.is_true(door.target_spawn.x >= 0, "Door should fallback to valid spawn")
