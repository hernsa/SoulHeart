class_name MapBuilder

static func parse_layout(ascii: String) -> Dictionary:
	return LayoutParser.parse(ascii)

static func build_room(grid: Array, style: String) -> Dictionary:
	var tml := TileMapLayer.new()
	tml.name = "TileMapLayer"
	tml.tile_set = GameTiles.build_tileset(style)
	tml.z_index = -1
	var trees: Array[Node2D] = []
	var props: Array[Node2D] = []
	for y in grid.size():
		var row: Array = grid[y]
		for x in row.size():
			var tile: int = row[x]
			match tile:
				GameTiles.Tile.FLOOR:
					tml.set_cell(Vector2i(x, y), 0, FLOOR_VARIANT(x, y))
				GameTiles.Tile.WALL:
					tml.set_cell(Vector2i(x, y), 0, GameTiles.WALL_TILE)
				GameTiles.Tile.TREE, GameTiles.Tile.PINE2, GameTiles.Tile.BIRCH, GameTiles.Tile.DEAD:
					trees.append(_make_tree(tile, x, y))
				GameTiles.Tile.BUSH, GameTiles.Tile.MUSHROOM, GameTiles.Tile.GRASS:
					props.append(_make_prop(tile, x, y))
	var size := room_pixel_size(grid)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 1)
	bg.size = size
	bg.position = Vector2.ZERO
	bg.z_index = -10
	return {
		"tilemap": tml,
		"trees": trees,
		"props": props,
		"background": bg,
		"pixel_size": size,
	}

static func FLOOR_VARIANT(x: int, y: int) -> Vector2i:
	return GameTiles.FLOOR_A if (x + y) % 2 == 0 else GameTiles.FLOOR_B

static func _tree_texture(tile: int) -> String:
	match tile:
		GameTiles.Tile.PINE2:
			return "res://assets/sprites/overworld/tree_pine_b.png"
		GameTiles.Tile.BIRCH:
			return "res://assets/sprites/overworld/tree_birch.png"
		GameTiles.Tile.DEAD:
			return "res://assets/sprites/overworld/tree_dead.png"
	return "res://assets/sprites/overworld/tree_pine.png"

static func _tree_alpha(tile: int) -> float:
	return 1.0 if tile != GameTiles.Tile.DEAD else 0.9

static func _make_tree(tile: int, x: int, y: int) -> Node2D:
	var tree := RoomTree.new()
	tree.name = "Tree"
	tree.position = Vector2(x * 16 + 8, y * 16 + 8)
	var tex := load(_tree_texture(tile)) as Texture2D
	if tex != null:
		tree.texture = tex
	tree.modulate.a = _tree_alpha(tile)
	return tree

static func _make_prop(tile: int, x: int, y: int) -> Node2D:
	var prop := Sprite2D.new()
	var name: String
	match tile:
		GameTiles.Tile.BUSH:
			name = "Bush"
			prop.texture = load("res://assets/sprites/overworld/bush.png")
		GameTiles.Tile.MUSHROOM:
			name = "Mushroom"
			prop.texture = load("res://assets/sprites/overworld/mushroom.png")
		_:
			name = "Grass"
			prop.texture = load("res://assets/sprites/overworld/grass.png")
	prop.name = name
	prop.position = Vector2(x * 16 + 8, y * 16 + 8)
	return prop

static func room_pixel_size(grid: Array) -> Vector2:
	var h: int = grid.size()
	var w: int = 0
	for row in grid:
		w = maxi(w, row.size())
	return Vector2(w * 16, h * 16)
