class_name GameTiles

enum Tile { GRASS = 0, PATH = 1, TREE = 2, WALL = 3 }

const DEFAULT_PALETTE := {
	Tile.GRASS: Color(0.3, 0.5, 0.28),
	Tile.PATH: Color(0.72, 0.62, 0.4),
	Tile.TREE: Color(0.18, 0.38, 0.2),
	Tile.WALL: Color(0.42, 0.42, 0.5),
}

const SNOW_PALETTE := {
	Tile.GRASS: Color(0.92, 0.92, 0.95),
	Tile.PATH: Color(0.6, 0.62, 0.7),
	Tile.TREE: Color(0.35, 0.4, 0.5),
	Tile.WALL: Color(0.3, 0.35, 0.45),
}

static func build_tileset(palette: Dictionary = {}) -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(16, 16)
	var src := TileSetAtlasSource.new()
	src.texture = _atlas_texture(palette)
	src.texture_region_size = Vector2i(16, 16)
	for x in [0, 1, 2, 3, 6, 7]:
		src.create_tile(Vector2i(x, 0))
		src.create_tile(Vector2i(x, 1))
	ts.add_source(src, 0)
	return ts

static func _atlas_texture(palette: Dictionary) -> Texture2D:
	var img := Image.create(128, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.1, 0.1, 0.1, 1))
	for tile in 4:
		_fill_tile_detailed(img, tile, palette.get(tile, DEFAULT_PALETTE[tile]))
	return ImageTexture.create_from_image(img)

static func _fill_tile_detailed(img: Image, col: int, c: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 100 + col
	if col == Tile.TREE:
		_draw_tree(img, c)
		return
	for y in 32:
		for x in 16:
			var color := c
			if y % 16 < 2:
				color = c.darkened(0.2)
			elif y % 16 >= 14:
				color = c.darkened(0.1)
			elif rng.randf() < 0.08:
				color = c.darkened(0.08)
			img.set_pixel(col * 16 + x, y, color)

const TREE_BLOCK_X := 96

static func _draw_tree(img: Image, c: Color) -> void:
	var trunk := Color(0.42, 0.26, 0.12)
	for y in 32:
		for x in 32:
			img.set_pixel(TREE_BLOCK_X + x, y, Color(0, 0, 0, 0))
	for y in 32:
		for x in 32:
			var px := Vector2(x - 16.0, y - 20.0)
			var d := px.length()
			if y >= 20 and y <= 31 and x >= 13 and x <= 18:
				img.set_pixel(TREE_BLOCK_X + x, y, trunk)
			elif d <= 9.0 and y >= 4:
				var canopy := c.lightened(0.15) if (d < 6.0) else c
				img.set_pixel(TREE_BLOCK_X + x, y, canopy)
