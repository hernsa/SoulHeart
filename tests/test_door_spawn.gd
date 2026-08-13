extends RefCounted

func test_door_spawn_walkable() -> void:
	var composed: Dictionary = SectionMap.compose(DrizzleSections.SECTIONS, DrizzleSections.ADJACENCY)
	var grid: Array = composed["grid"]
	var spawn: Vector2 = DrizzleFields.GRUMBLE_SPAWN
	var cell_x := int(spawn.x / 16)
	var cell_y := int(spawn.y / 16)
	TestHelper.is_true(cell_x >= 0 and cell_x < (grid[0] as String).length(), "spawn x in bounds")
	TestHelper.is_true(cell_y >= 0 and cell_y < grid.size(), "spawn y in bounds")
	var row: String = grid[cell_y]
	TestHelper.is_true(row[cell_x] != "#", "Door spawn cell (%d,%d) is walkable, got '%s'" % [cell_x, cell_y, row[cell_x]])

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

func test_drizzle_master_grid_is_continuous() -> void:
	var composed: Dictionary = SectionMap.compose(DrizzleSections.SECTIONS, DrizzleSections.ADJACENCY)
	TestHelper.is_true(not composed.has("error"), "drizzle composes: " + str(composed.get("error", "")))
	var grid: Array = composed["grid"]
	TestHelper.is_true(grid.size() > 0, "grid has rows")
	for row in grid:
		TestHelper.is_true((row as String).length() > 0, "row non-empty")

func test_door_fail_loud_on_invalid_spawn() -> void:
	var door := Door.new()
	door.target_spawn = Vector2(-1, -1)
	door._ready()
	TestHelper.is_true(door.target_spawn.x >= 0, "Door should fallback to valid spawn")
