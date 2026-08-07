class_name GameTiles

enum Tile { GRASS = 0, PATH = 1, TREE = 2, WALL = 3 }

static func build_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(16, 16)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	var src := TileSetAtlasSource.new()
	src.texture = _atlas_texture()
	src.texture_region_size = Vector2i(16, 16)
	for x in 4:
		src.create_tile(Vector2i(x, 0))
	ts.add_source(src, 0)
	var solid := PackedVector2Array([
		Vector2(0, 0), Vector2(16, 0), Vector2(16, 16), Vector2(0, 16)
	])
	for coords in [Vector2i(2, 0), Vector2i(3, 0)]:
		var td := src.get_tile_data(coords, 0)
		td.set_collision_polygons_count(0, 1)
		td.set_collision_polygon_points(0, 0, solid)
	return ts

static func _atlas_texture() -> Texture2D:
	var img := Image.create(64, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.1, 0.1, 0.1, 1))
	_fill_tile(img, 0, Color(0.3, 0.5, 0.28))
	_fill_tile(img, 1, Color(0.72, 0.62, 0.4))
	_fill_tile(img, 2, Color(0.18, 0.38, 0.2))
	_fill_tile(img, 3, Color(0.42, 0.42, 0.5))
	return ImageTexture.create_from_image(img)

static func _fill_tile(img: Image, col: int, c: Color) -> void:
	for y in 16:
		for x in 16:
			img.set_pixel(col * 16 + x, y, c)
