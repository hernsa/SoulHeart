extends RefCounted

func test_tileset_properties() -> void:
	var ts := GameTiles.build_tileset()
	TestHelper.eq(ts.tile_size, Vector2i(16, 16), "tile size")
	TestHelper.eq(ts.get_physics_layers_count(), 1, "one physics layer")
	TestHelper.eq(ts.get_physics_layer_collision_layer(0), 1, "collision layer 1")
	var src := ts.get_source(0) as TileSetAtlasSource
	TestHelper.is_true(src != null, "atlas source exists")
	TestHelper.eq(src.get_tiles_count(), 4, "four tiles")
	TestHelper.is_true(src.has_tile(Vector2i(2, 0)), "TREE tile present")
	TestHelper.is_true(src.has_tile(Vector2i(3, 0)), "WALL tile present")
	TestHelper.eq(src.get_tile_data(Vector2i(2, 0), 0).get_collision_polygons_count(0), 1, "TREE is solid")
	TestHelper.eq(src.get_tile_data(Vector2i(3, 0), 0).get_collision_polygons_count(0), 1, "WALL is solid")
	TestHelper.eq(src.get_tile_data(Vector2i(0, 0), 0).get_collision_polygons_count(0), 0, "GRASS not solid")
