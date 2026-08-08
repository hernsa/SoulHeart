class_name MapBuilder

static func parse_layout(ascii: String) -> Dictionary:
	return LayoutParser.parse(ascii)

static func build_tilemap(grid: Array, palette: Dictionary = {}) -> TileMapLayer:
	var tml := TileMapLayer.new()
	tml.name = "TileMapLayer"
	tml.tile_set = GameTiles.build_tileset(palette)
	for y in grid.size():
		var row: Array = grid[y]
		for x in row.size():
			var tile: int = row[x]
			tml.set_cell(Vector2i(x, y), 0, Vector2i(tile, 0))
			if tile == GameTiles.Tile.TREE or tile == GameTiles.Tile.WALL:
				_add_solid_body(tml, Vector2i(x, y))
	return tml

static func _add_solid_body(tml: TileMapLayer, cell: Vector2i) -> void:
	var body := StaticBody2D.new()
	body.name = "Solid"
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 16)
	shape.shape = rect
	body.add_child(shape)
	body.position = Vector2(cell.x * 16 + 8, cell.y * 16 + 8)
	tml.add_child(body)

static func room_pixel_size(grid: Array) -> Vector2:
	var h: int = grid.size()
	var w: int = 0
	for row in grid:
		w = maxi(w, row.size())
	return Vector2(w * 16, h * 16)
