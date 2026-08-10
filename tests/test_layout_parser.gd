extends RefCounted

const SAMPLE := """
############
#P..T....E.#
#....T...S.#
#........D.#
############
"""

func test_parse_grid() -> void:
	var parsed := MapBuilder.parse_layout(SAMPLE)
	var grid: Array = parsed["grid"]
	TestHelper.is_true(grid.size() >= 30, "grid padded to 30 rows")
	TestHelper.eq((grid[0] as Array).size(), 12, "twelve columns")
	TestHelper.eq((grid[0] as Array)[0], int(GameTiles.Tile.WALL), "corner is wall")
	TestHelper.eq((grid[1] as Array)[4], int(GameTiles.Tile.TREE), "tree parsed")
	TestHelper.eq((grid[1] as Array)[2], int(GameTiles.Tile.FLOOR), "floor parsed")
	TestHelper.eq((grid[1] as Array)[0], int(GameTiles.Tile.WALL), "left wall")

func test_parse_points() -> void:
	var parsed := MapBuilder.parse_layout(SAMPLE)
	TestHelper.eq(parsed["player_start"], Vector2(16, 16), "player start")
	var encounters: Array = parsed["encounters"]
	TestHelper.eq(encounters.size(), 1, "one encounter")
	TestHelper.eq(encounters[0], Vector2(9 * 16, 16), "encounter position")
	var saves: Array = parsed["save_points"]
	TestHelper.eq(saves.size(), 1, "one save point")
	TestHelper.eq(saves[0], Vector2(9 * 16, 32), "save position")
	var doors: Array = parsed["doors"]
	TestHelper.eq(doors.size(), 1, "one door")
	TestHelper.eq(doors[0]["pos"], Vector2(9 * 16, 48), "door position")

func test_padding_to_uniform_width() -> void:
	var parsed := MapBuilder.parse_layout("#\n#P.")
	var grid: Array = parsed["grid"]
	TestHelper.eq((grid[0] as Array).size(), 3, "row padded to max width")
	TestHelper.eq((grid[0] as Array)[1], int(GameTiles.Tile.FLOOR), "padding is floor")
	TestHelper.eq((grid[1] as Array)[2], int(GameTiles.Tile.FLOOR), "floor survives padding")
	TestHelper.is_true(grid.size() >= 30, "grid padded to 30 rows")
