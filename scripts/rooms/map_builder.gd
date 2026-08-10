class_name MapBuilder

static func parse_layout(ascii: String) -> Dictionary:
	return LayoutParser.parse(ascii)

static func build_room(grid: Array, style: String) -> Dictionary:
	var tml := TileMapLayer.new()
	tml.name = "TileMapLayer"
	tml.tile_set = GameTiles.build_tileset(style)
	tml.z_index = -1
	var trees: Array[Node2D] = []
	for y in grid.size():
		var row: Array = grid[y]
		for x in row.size():
			var tile: int = row[x]
			match tile:
				GameTiles.Tile.FLOOR:
					tml.set_cell(Vector2i(x, y), 0, FLOOR_VARIANT(x, y))
				GameTiles.Tile.WALL:
					tml.set_cell(Vector2i(x, y), 0, GameTiles.WALL_TILE)
				GameTiles.Tile.TREE:
					trees.append(_make_tree(x, y))
	var size := room_pixel_size(grid)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 1)
	bg.size = size
	bg.position = Vector2.ZERO
	bg.z_index = -10
	return {
		"tilemap": tml,
		"trees": trees,
		"background": bg,
		"pixel_size": size,
	}

static func FLOOR_VARIANT(x: int, y: int) -> Vector2i:
	return GameTiles.FLOOR_A if (x + y) % 2 == 0 else GameTiles.FLOOR_B

static func _make_tree(x: int, y: int) -> Node2D:
	var tree: Node2D = Node2D.new()
	tree.name = "Tree"
	tree.position = Vector2(x * 16 + 8, y * 16 + 8)
	var spr := Sprite2D.new()
	spr.texture = load("res://assets/sprites/overworld/tree_pine.png")
	spr.position = Vector2(0, 8)
	tree.add_child(spr)
	return tree

static func room_pixel_size(grid: Array) -> Vector2:
	var h: int = grid.size()
	var w: int = 0
	for row in grid:
		w = maxi(w, row.size())
	return Vector2(w * 16, h * 16)
