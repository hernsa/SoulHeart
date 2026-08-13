extends RefCounted

const NEW_STYLES := [
	GameTiles.ECHO_STYLE, GameTiles.HOMETOWN_STYLE,
	GameTiles.CANON_STYLE, GameTiles.CRACKS_STYLE,
]

func test_styles_consts_exist_and_unique() -> void:
	TestHelper.is_true(NEW_STYLES.size() == 4, "4 new styles defined")
	TestHelper.is_true(GameTiles.AREA_STYLES.size() == 7,
		"AREA_STYLES must contain all 7 styles")
	for s in NEW_STYLES:
		TestHelper.is_true(GameTiles.AREA_STYLES.has(s),
			"AREA_STYLES must include %s" % s)

func test_floor_pngs_exist() -> void:
	for style in NEW_STYLES:
		for variant in ["_floor.png", "_floor_b.png"]:
			var path := "res://assets/sprites/tiles/%s%s" % [style, variant]
			TestHelper.is_true(ResourceLoader.exists(path),
				"missing tile asset: %s" % path)

func test_new_floors_seamless_horizontal() -> void:
	for style in NEW_STYLES:
		var img := Image.load_from_file("res://assets/sprites/tiles/%s_floor.png" % style)
		for y in 16:
			TestHelper.is_true(img.get_pixel(0, y) == img.get_pixel(15, y),
				"%s row %d not seamless horizontally" % [style, y])

func test_new_floors_seamless_vertical() -> void:
	for style in NEW_STYLES:
		var img := Image.load_from_file("res://assets/sprites/tiles/%s_floor.png" % style)
		for x in 16:
			TestHelper.is_true(img.get_pixel(x, 0) == img.get_pixel(x, 15),
				"%s col %d not seamless vertically" % [style, x])

func test_new_b_variants_seamless_and_distinct() -> void:
	for style in NEW_STYLES:
		var a := Image.load_from_file("res://assets/sprites/tiles/%s_floor.png" % style)
		var b := Image.load_from_file("res://assets/sprites/tiles/%s_floor_b.png" % style)
		TestHelper.is_true(a.get_data() != b.get_data(),
			"%s B variant must differ from A" % style)
		for y in 16:
			TestHelper.is_true(b.get_pixel(0, y) == b.get_pixel(15, y),
				"%s B row %d not seamless" % [style, y])
			TestHelper.is_true(b.get_pixel(y, 0) == b.get_pixel(y, 15),
				"%s B col %d not seamless" % [style, y])

func test_tileset_builds_for_new_styles() -> void:
	for style in NEW_STYLES:
		var ts := GameTiles.build_tileset(style)
		TestHelper.eq(ts.tile_size, Vector2i(16, 16), "%s tile size" % style)
		var src := ts.get_source(0) as TileSetAtlasSource
		TestHelper.eq(src.get_tiles_count(), 3, "%s three tiles" % style)

func test_new_style_atlas_has_visible_pixels() -> void:
	for style in NEW_STYLES:
		var room := MapBuilder.build_room([[GameTiles.Tile.FLOOR]], style)
		var src: TileSetAtlasSource = (room["tilemap"] as TileMapLayer).tile_set.get_source(0)
		var img: Image = src.texture.get_image()
		img.convert(Image.FORMAT_RGBA8)
		var visible := false
		for y in 16:
			for x in 16:
				if img.get_pixel(x, y).a > 0.5:
					visible = true
		TestHelper.is_true(visible, "%s atlas has visible floor pixels" % style)
