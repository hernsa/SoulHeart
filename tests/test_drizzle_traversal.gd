extends RefCounted

const SOLID := {"#": true, "t": true, "T": true, "b": true, "d": true}

func test_compose_clean() -> void:
	var composed: Dictionary = _compose()
	TestHelper.is_true(not composed.has("error"), "traversal compose clean")

func test_all_sections_reachable() -> void:
	var composed: Dictionary = _compose()
	var reach: Dictionary = _flood(composed["grid"], _save_cell(composed))
	for sec_id in composed["origins"].keys():
		var origin: Vector2i = composed["origins"][sec_id]
		var sz: Vector2i = composed["sizes"][sec_id]
		TestHelper.is_true(_section_reached(reach, origin, sz), "section %s reachable" % sec_id)

func test_exits_reachable() -> void:
	var composed: Dictionary = _compose()
	var reach: Dictionary = _flood(composed["grid"], _save_cell(composed))
	for obj in composed["objects"]:
		if obj["type"] == "exit":
			TestHelper.is_true(reach.has(obj["cell"]), "exit %s reachable" % obj["data"].get("target", "?"))

func _compose() -> Dictionary:
	return SectionMap.compose(DrizzleSections.SECTIONS, DrizzleSections.ADJACENCY)

func _save_cell(composed: Dictionary) -> Vector2i:
	for obj in composed["objects"]:
		if obj["type"] == "save":
			return obj["cell"]
	return Vector2i(-1, -1)

func _section_reached(reach: Dictionary, origin: Vector2i, sz: Vector2i) -> bool:
	for y in range(origin.y, origin.y + sz.y):
		for x in range(origin.x, origin.x + sz.x):
			if reach.has(Vector2i(x, y)):
				return true
	return false

func _flood(grid: Array, start: Vector2i) -> Dictionary:
	var w: int = (grid[0] as String).length()
	var h: int = grid.size()
	var seen: Dictionary = {}
	var queue: Array = [start]
	seen[start] = true
	var head := 0
	while head < queue.size():
		var cur: Vector2i = queue[head]
		head += 1
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nxt: Vector2i = cur + d
			if seen.has(nxt):
				continue
			if nxt.x < 0 or nxt.y < 0 or nxt.x >= w or nxt.y >= h:
				continue
			if SOLID.has((grid[nxt.y] as String)[nxt.x]):
				continue
			seen[nxt] = true
			queue.append(nxt)
	return seen