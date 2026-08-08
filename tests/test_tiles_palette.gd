extends RefCounted

func _tileset_image(palette: Dictionary) -> Image:
	var ts: TileSet = GameTiles.build_tileset(palette)
	var src: TileSetAtlasSource = ts.get_source(0) as TileSetAtlasSource
	return src.texture.get_image()

func test_default_palette_matches_legacy() -> void:
	var a: Image = _tileset_image({})
	var b: Image = _tileset_image(GameTiles.DEFAULT_PALETTE)
	TestHelper.is_true(a.get_data() == b.get_data(), "default palette should equal explicit default")

func test_snow_palette_differs() -> void:
	var a: Image = _tileset_image(GameTiles.DEFAULT_PALETTE)
	var b: Image = _tileset_image(GameTiles.SNOW_PALETTE)
	TestHelper.is_true(a.get_data() != b.get_data(), "snow palette should differ from default")

func test_build_tileset_still_four_tiles() -> void:
	var ts: TileSet = GameTiles.build_tileset(GameTiles.SNOW_PALETTE)
	var src: TileSetAtlasSource = ts.get_source(0) as TileSetAtlasSource
	TestHelper.eq(src.get_tiles_count(), 4, "snow tileset keeps 4 tiles")
