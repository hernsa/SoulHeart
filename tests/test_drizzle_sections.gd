extends RefCounted

func test_ten_sections_in_roster() -> void:
	TestHelper.eq(DrizzleSections.SECTIONS.size(), 10, "exactly 10 sections")

func test_adjacency_ids_exist_in_sections() -> void:
	var ids: Dictionary = {}
	for s in DrizzleSections.SECTIONS:
		ids[s["id"]] = true
	for link in DrizzleSections.ADJACENCY:
		TestHelper.is_true(ids.has(link["a"]), "adjacency a id exists: %s" % link["a"])
		TestHelper.is_true(ids.has(link["b"]), "adjacency b id exists: %s" % link["b"])

func test_layout_rows_consistent_width() -> void:
	for s in DrizzleSections.SECTIONS:
		var layout: Array = s["layout"]
		var w: int = (layout[0] as String).length()
		for i in layout.size():
			TestHelper.eq((layout[i] as String).length(), w, "row %d of %s has first-row width" % [i, s["id"]])

func test_objects_and_flavor_cells_in_bounds() -> void:
	for s in DrizzleSections.SECTIONS:
		var layout: Array = s["layout"]
		var w: int = (layout[0] as String).length()
		var h: int = layout.size()
		for obj in s["objects"]:
			var c: Vector2i = obj["cell"]
			var msg: String = "object cell in bounds for %s" % s["id"]
			TestHelper.is_true(c.x >= 0 and c.x < w and c.y >= 0 and c.y < h, msg)
		for fl in s["flavor"]:
			var c: Vector2i = fl["cell"]
			var msg: String = "flavor cell in bounds for %s" % s["id"]
			TestHelper.is_true(c.x >= 0 and c.x < w and c.y >= 0 and c.y < h, msg)

func test_compose_produces_no_error() -> void:
	var out: Dictionary = SectionMap.compose(DrizzleSections.SECTIONS, DrizzleSections.ADJACENCY)
	TestHelper.is_true(not out.has("error"), "DrizzleSections compose clean")
	var grid: Array = out["grid"]
	TestHelper.is_true(grid.size() > 0, "composed grid non-empty")
	TestHelper.eq(out["origins"].size(), 10, "all 10 sections placed")