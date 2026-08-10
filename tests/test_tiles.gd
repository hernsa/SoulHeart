extends RefCounted

func test_tileset_properties() -> void:
	var ts := GameTiles.build_tileset(GameTiles.RUINS_STYLE)
	TestHelper.eq(ts.tile_size, Vector2i(16, 16), "tile size")
	var src := ts.get_source(0) as TileSetAtlasSource
	TestHelper.is_true(src != null, "atlas source exists")
	TestHelper.eq(src.get_tiles_count(), 3, "three tiles (floor A, floor B, wall)")
	TestHelper.is_true(src.has_tile(GameTiles.FLOOR_A), "floor A tile present")
	TestHelper.is_true(src.has_tile(GameTiles.FLOOR_B), "floor B tile present")
	TestHelper.is_true(src.has_tile(GameTiles.WALL_TILE), "wall tile present")

func test_wall_tile_has_collision() -> void:
	var ts := GameTiles.build_tileset(GameTiles.RUINS_STYLE)
	TestHelper.eq(ts.get_physics_layers_count(), 1, "tileset has one physics layer")
	var src := ts.get_source(0) as TileSetAtlasSource
	var wall_data := src.get_tile_data(GameTiles.WALL_TILE, 0)
	TestHelper.eq(wall_data.get_collision_polygons_count(0), 1, "wall tile has collision polygon")
	var floor_data := src.get_tile_data(GameTiles.FLOOR_A, 0)
	TestHelper.eq(floor_data.get_collision_polygons_count(0), 0, "floor tile has no collision")

func test_build_room_floor_variants() -> void:
	var grid := [
		[GameTiles.Tile.FLOOR, GameTiles.Tile.FLOOR],
		[GameTiles.Tile.FLOOR, GameTiles.Tile.WALL],
	]
	var room := MapBuilder.build_room(grid, GameTiles.RUINS_STYLE)
	var tml: TileMapLayer = room["tilemap"]
	TestHelper.eq(tml.get_cell_atlas_coords(Vector2i(0, 0)), GameTiles.FLOOR_A, "(0,0) is floor A")
	TestHelper.eq(tml.get_cell_atlas_coords(Vector2i(1, 0)), GameTiles.FLOOR_B, "(1,0) is floor B")
	TestHelper.eq(tml.get_cell_atlas_coords(Vector2i(1, 1)), GameTiles.WALL_TILE, "wall gets invisible wall tile")

func test_void_background() -> void:
	var grid := [[GameTiles.Tile.FLOOR]]
	var room := MapBuilder.build_room(grid, GameTiles.RUINS_STYLE)
	var bg: ColorRect = room["background"]
	TestHelper.is_true(bg != null, "background exists")
	TestHelper.eq(bg.size, Vector2(16, 16), "background covers room")
	TestHelper.eq(bg.color, Color(0, 0, 0, 1), "background is black void")
	TestHelper.eq(bg.z_index, -10, "background behind tiles")

func test_tree_cells_spawn_nodes() -> void:
	var grid := [[GameTiles.Tile.TREE]]
	var room := MapBuilder.build_room(grid, GameTiles.RUINS_STYLE)
	TestHelper.eq((room["trees"] as Array).size(), 1, "one tree node spawned")
