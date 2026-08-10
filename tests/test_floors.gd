extends RefCounted

func test_floors_load() -> void:
	for f in ["ruins_floor.png", "ruins_floor_b.png", "snowdin_floor.png", "snowdin_floor_b.png"]:
		TestHelper.is_true(ResourceLoader.exists("res://assets/sprites/tiles/" + f),
				"floor asset missing: " + f)

func test_floor_tiles_seamless_horizontal() -> void:
	for style in [GameTiles.RUINS_STYLE, GameTiles.SNOWDIN_STYLE]:
		var img := Image.load_from_file("res://assets/sprites/tiles/%s_floor.png" % style)
		for y in 16:
			var left := img.get_pixel(0, y)
			var right := img.get_pixel(15, y)
			TestHelper.is_true(left == right,
					"%s row %d left != right (seamless fail)" % [style, y])

func test_floor_tiles_seamless_vertical() -> void:
	for style in [GameTiles.RUINS_STYLE, GameTiles.SNOWDIN_STYLE]:
		var img := Image.load_from_file("res://assets/sprites/tiles/%s_floor.png" % style)
		for x in 16:
			var top := img.get_pixel(x, 0)
			var bottom := img.get_pixel(x, 15)
			TestHelper.is_true(top == bottom,
					"%s col %d top != bottom (seamless fail)" % [style, x])

func test_floor_b_variants_seamless_and_distinct() -> void:
	for style in [GameTiles.RUINS_STYLE, GameTiles.SNOWDIN_STYLE]:
		var a := Image.load_from_file("res://assets/sprites/tiles/%s_floor.png" % style)
		var b := Image.load_from_file("res://assets/sprites/tiles/%s_floor_b.png" % style)
		TestHelper.is_true(a.get_data() != b.get_data(),
				"%s variant B should differ from A" % style)
		for y in 16:
			TestHelper.is_true(b.get_pixel(0, y) == b.get_pixel(15, y),
					"%s B row %d not seamless" % [style, y])
			TestHelper.is_true(b.get_pixel(y, 0) == b.get_pixel(y, 15),
					"%s B col %d not seamless" % [style, y])

func test_build_room_tiles_are_visible_floor() -> void:
	var grid := [[GameTiles.Tile.FLOOR]]
	var room := MapBuilder.build_room(grid, GameTiles.RUINS_STYLE)
	var src: TileSetAtlasSource = (room["tilemap"] as TileMapLayer).tile_set.get_source(0)
	var img: Image = src.texture.get_image()
	img.convert(Image.FORMAT_RGBA8)
	var has_floor_pixels := false
	for y in 16:
		for x in 16:
			if img.get_pixel(x, y).a > 0.5:
				has_floor_pixels = true
	TestHelper.is_true(has_floor_pixels, "floor atlas has visible pixels")
