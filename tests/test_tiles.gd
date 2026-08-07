extends RefCounted

func test_tileset_properties() -> void:
	var ts := GameTiles.build_tileset()
	TestHelper.eq(ts.tile_size, Vector2i(16, 16), "tile size")
	var src := ts.get_source(0) as TileSetAtlasSource
	TestHelper.is_true(src != null, "atlas source exists")
	TestHelper.eq(src.get_tiles_count(), 4, "four tiles")
	TestHelper.is_true(src.has_tile(Vector2i(2, 0)), "TREE tile present")
	TestHelper.is_true(src.has_tile(Vector2i(3, 0)), "WALL tile present")

func test_tileset_visual_only() -> void:
	var ts := GameTiles.build_tileset()
	TestHelper.eq(ts.get_physics_layers_count(), 0, "tileset carries no physics")

func test_map_builder_solid_bodies() -> void:
	var grid := [
		[GameTiles.Tile.WALL, GameTiles.Tile.WALL, GameTiles.Tile.GRASS],
		[GameTiles.Tile.GRASS, GameTiles.Tile.PATH, GameTiles.Tile.TREE],
	]
	var tml := MapBuilder.build_tilemap(grid)
	var bodies := tml.get_children()
	var walls := 0
	var trees := 0
	for c in bodies:
		if c is StaticBody2D:
			var cell: Vector2 = c.position / 16.0
			if grid[int(cell.y)][int(cell.x)] == GameTiles.Tile.WALL:
				walls += 1
			if grid[int(cell.y)][int(cell.x)] == GameTiles.Tile.TREE:
				trees += 1
			TestHelper.eq(c.get_node("CollisionShape2D").shape.get_class(), "RectangleShape2D", "solid body has rect shape")
	TestHelper.eq(walls, 2, "two wall bodies")
	TestHelper.eq(trees, 1, "one tree body")
	var totals := 0
	for c in bodies:
		if c is StaticBody2D:
			totals += 1
	TestHelper.eq(totals, 3, "exactly three solid bodies")
	tml.free()
