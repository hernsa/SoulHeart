class_name MapBuilder

static func parse_layout(ascii: String) -> Dictionary:
	return LayoutParser.parse(ascii)

static func build_tilemap(grid: Array) -> TileMapLayer:
	var tml := TileMapLayer.new()
	tml.name = "TileMapLayer"
	tml.tile_set = GameTiles.build_tileset()
	for y in grid.size():
		var row: Array = grid[y]
		for x in row.size():
			var tile: int = row[x]
			tml.set_cell(Vector2i(x, y), 0, Vector2i(tile, 0))
	return tml

static func room_pixel_size(grid: Array) -> Vector2:
	var h: int = grid.size()
	var w: int = 0
	for row in grid:
		w = maxi(w, row.size())
	return Vector2(w * 16, h * 16)
