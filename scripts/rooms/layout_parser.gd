class_name LayoutParser

static func parse(ascii: String) -> Dictionary:
	var rows: Array = []
	var encounters: Array[Vector2] = []
	var save_points: Array[Vector2] = []
	var doors: Array = []
	var player_start := Vector2.ZERO
	var max_w := 0
	var y := 0
	for raw in ascii.split("\n"):
		var row := raw.strip_edges()
		if row.is_empty():
			continue
		max_w = maxi(max_w, row.length())
		var cells: Array = []
		for x in row.length():
			var ch := row[x]
			var tile := int(GameTiles.Tile.GRASS)
			match ch:
				"#":
					tile = int(GameTiles.Tile.WALL)
				"T":
					tile = int(GameTiles.Tile.TREE)
				".":
					tile = int(GameTiles.Tile.PATH)
			cells.append(tile)
			var pos := Vector2(x * 16, y * 16)
			match ch:
				"P":
					player_start = pos
				"E":
					encounters.append(pos)
				"S":
					save_points.append(pos)
				"D":
					doors.append({"pos": pos})
		rows.append(cells)
		y += 1
	for row in rows:
		while row.size() < max_w:
			row.append(int(GameTiles.Tile.GRASS))
	while rows.size() < 30:
		var filler: Array = []
		filler.resize(max_w)
		filler.fill(int(GameTiles.Tile.GRASS))
		rows.append(filler)
	return {
		"grid": rows,
		"player_start": player_start,
		"encounters": encounters,
		"save_points": save_points,
		"doors": doors,
	}
