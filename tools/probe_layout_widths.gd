extends SceneTree
func _init() -> void:
	for pair in [["GrumbleWoods", "res://scripts/rooms/grumble_woods.gd"], ["DrizzleFields", "res://scripts/rooms/drizzle_fields.gd"]]:
		var s := load(pair[1])
		var layout: String = s.get_script_constant_map()["LAYOUT"]
		print(pair[0])
		var y := 0
		for raw in layout.split("\n"):
			var row: String = raw.strip_edges()
			if row.is_empty():
				continue
			if row.length() != 40:
				print("  row %d LEN %d -> %s" % [y, row.length(), row])
			y += 1
		print("  rows: %d" % y)
	quit()
