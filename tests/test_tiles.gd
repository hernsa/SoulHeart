extends RefCounted

func test_tileset_properties() -> void:
	var ts := GameTiles.build_tileset()
	TestHelper.eq(ts.tile_size, Vector2i(16, 16), "tile size")
	var src := ts.get_source(0) as TileSetAtlasSource
	TestHelper.is_true(src != null, "atlas source exists")
	TestHelper.eq(src.get_tiles_count(), 12, "twelve tiles (rows 0-1, tree cols 6-7)")
	TestHelper.is_true(src.has_tile(Vector2i(2, 0)), "TREE tile present")
	TestHelper.is_true(src.has_tile(Vector2i(3, 0)), "WALL tile present")
	TestHelper.is_true(src.has_tile(Vector2i(6, 0)), "TREE top tile present")
	TestHelper.is_true(src.has_tile(Vector2i(6, 1)), "TREE base tile present")
	TestHelper.is_true(src.has_tile(Vector2i(7, 0)), "TREE top-right tile present")
	TestHelper.is_true(src.has_tile(Vector2i(7, 1)), "TREE base-right tile present")

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

func test_tree_has_canopy_and_trunk() -> void:
	var img := GameTiles._atlas_texture({}).get_image()
	var brown := Color(0.42, 0.26, 0.12)
	var has_brown := false
	var has_green := false
	for y in 32:
		for x in 32:
			var c := img.get_pixel(6 * 16 + x, y)
			if absf(c.r - brown.r) < 0.01 and absf(c.g - brown.g) < 0.01 and absf(c.b - brown.b) < 0.01:
				has_brown = true
			if c.g > c.r and c.g > 0.2:
				has_green = true
	TestHelper.is_true(has_brown, "tree has trunk pixels")
	TestHelper.is_true(has_green, "tree has canopy pixels")
