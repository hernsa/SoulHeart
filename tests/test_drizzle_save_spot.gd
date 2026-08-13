extends RefCounted

func test_exactly_one_save() -> void:
	var composed: Dictionary = SectionMap.compose(DrizzleSections.SECTIONS, DrizzleSections.ADJACENCY)
	var saves: Array = []
	for obj in composed["objects"]:
		if obj["type"] == "save":
			saves.append(obj)
	TestHelper.eq(saves.size(), 1, "exactly one save point in DrizzleFields")

func test_save_in_wisp_grove() -> void:
	var composed: Dictionary = SectionMap.compose(DrizzleSections.SECTIONS, DrizzleSections.ADJACENCY)
	var save_cell := Vector2i(-1, -1)
	for obj in composed["objects"]:
		if obj["type"] == "save":
			save_cell = obj["cell"]
	TestHelper.eq(save_cell, Vector2i(18, 23), "save sits at wisp_grove master cell (18,23)")

func test_save_cell_walkable() -> void:
	var composed: Dictionary = SectionMap.compose(DrizzleSections.SECTIONS, DrizzleSections.ADJACENCY)
	var save_cell := Vector2i(-1, -1)
	for obj in composed["objects"]:
		if obj["type"] == "save":
			save_cell = obj["cell"]
	var grid: Array = composed["grid"]
	var ch: String = (grid[save_cell.y] as String)[save_cell.x]
	TestHelper.is_true(ch != "#" and ch != "t" and ch != "T" and ch != "b" and ch != "d", "save cell not solid, got '%s'" % ch)