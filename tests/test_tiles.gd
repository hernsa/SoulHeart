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

func test_tree_prop_survives_neighbor_cells() -> void:
	var grid := [
		[GameTiles.Tile.GRASS, GameTiles.Tile.GRASS, GameTiles.Tile.GRASS, GameTiles.Tile.GRASS],
		[GameTiles.Tile.GRASS, GameTiles.Tile.GRASS, GameTiles.Tile.TREE, GameTiles.Tile.GRASS],
		[GameTiles.Tile.GRASS, GameTiles.Tile.GRASS, GameTiles.Tile.GRASS, GameTiles.Tile.GRASS],
	]
	var tml := MapBuilder.build_tilemap(grid)
	TestHelper.eq(tml.get_cell_atlas_coords(Vector2i(2, 1)), Vector2i(6, 1), "tree base keeps (6,1)")
	TestHelper.eq(tml.get_cell_atlas_coords(Vector2i(3, 1)), Vector2i(7, 1), "tree base-right keeps (7,1)")
	TestHelper.eq(tml.get_cell_atlas_coords(Vector2i(2, 0)), Vector2i(6, 0), "tree top keeps (6,0)")
	TestHelper.eq(tml.get_cell_atlas_coords(Vector2i(3, 0)), Vector2i(7, 0), "tree top-right keeps (7,0)")
	tml.free()

func test_tree_top_skipped_over_wall() -> void:
	var grid := [
		[GameTiles.Tile.WALL, GameTiles.Tile.WALL, GameTiles.Tile.WALL, GameTiles.Tile.WALL],
		[GameTiles.Tile.GRASS, GameTiles.Tile.GRASS, GameTiles.Tile.TREE, GameTiles.Tile.GRASS],
		[GameTiles.Tile.GRASS, GameTiles.Tile.GRASS, GameTiles.Tile.GRASS, GameTiles.Tile.GRASS],
	]
	var tml := MapBuilder.build_tilemap(grid)
	TestHelper.eq(tml.get_cell_atlas_coords(Vector2i(2, 0)), Vector2i(3, 0), "wall above tree base stays visible")
	TestHelper.eq(tml.get_cell_atlas_coords(Vector2i(3, 0)), Vector2i(3, 0), "wall above tree right stays visible")
	TestHelper.eq(tml.get_cell_atlas_coords(Vector2i(2, 1)), Vector2i(6, 1), "tree base still placed")
	TestHelper.eq(tml.get_cell_atlas_coords(Vector2i(3, 1)), Vector2i(7, 1), "tree base-right still placed")
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

func test_grass_has_light_speckles() -> void:
	var img := GameTiles._atlas_texture({}).get_image()
	var base := Color(0.3, 0.5, 0.28)
	var lighter := false
	for y in 16:
		for x in 16:
			var c := img.get_pixel(x, y)
			if c.r > base.r + 0.05 and c.g > base.g + 0.05:
				lighter = true
	TestHelper.is_true(lighter, "grass has lighter speckles")

func test_grumble_woods_grid_padded_to_viewport() -> void:
	var room: GDScript = load("res://scripts/rooms/grumble_woods.gd")
	TestHelper.is_true(room != null, "grumble woods script loads")
	var parsed: Dictionary = LayoutParser.parse(room.LAYOUT)
	var padded: Array = room.build_padded_grid(parsed["grid"])
	TestHelper.eq(padded.size(), 46, "padded grid rows (30 parsed + 16 pad)")
	TestHelper.eq(int(padded[0].size()), 40, "padded grid cols fill viewport width")
	TestHelper.eq(MapBuilder.room_pixel_size(padded), Vector2(640, 736), "room pixels cover 640x480 viewport")
	for d in parsed["doors"]:
		var pos: Vector2 = d["pos"]
		var runtime_pos: Vector2 = pos + room.PAD_PIXELS
		var tile: int = int(padded[int(runtime_pos.y) / 16][int(runtime_pos.x) / 16])
		TestHelper.is_true(tile != int(GameTiles.Tile.WALL) and tile != int(GameTiles.Tile.TREE), "door lands on walkable cell at padded runtime position")
	for e in parsed["encounters"]:
		var runtime_pos: Vector2 = e + room.PAD_PIXELS
		var tile: int = int(padded[int(runtime_pos.y) / 16][int(runtime_pos.x) / 16])
		TestHelper.is_true(tile != int(GameTiles.Tile.WALL) and tile != int(GameTiles.Tile.TREE), "encounter lands on walkable cell at padded runtime position")
