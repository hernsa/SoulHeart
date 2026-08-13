extends RefCounted

func test_compose_two_compatible_sections() -> void:
	var sections := [
		{"id": "A", "layout": ["..", ".."]},
		{"id": "B", "layout": ["..", ".."]},
	]
	var adjacency := [{"a": "A", "side": "e", "b": "B"}]
	var out: Dictionary = SectionMap.compose(sections, adjacency)
	var grid: Array = out["grid"]
	TestHelper.eq(grid.size(), 2, "two rows")
	TestHelper.eq((grid[0] as String).length(), 4, "merged width 2+2")

func test_compose_incompatible_edges_error() -> void:
	var sections := [
		{"id": "A", "layout": ["#.", ".."]},
		{"id": "B", "layout": ["##", ".."]},
	]
	var adjacency := [{"a": "A", "side": "e", "b": "B"}]
	var failed := false
	var result: Variant = null
	result = SectionMap.compose(sections, adjacency)
	if typeof(result) == TYPE_DICTIONARY and result.has("error"):
		failed = true
	TestHelper.is_true(failed, "incompatible edges must error")

func test_object_coord_remap() -> void:
	var sections := [
		{"id": "A", "layout": ["....", "...."], "objects": [{"type": "save", "cell": Vector2i(1, 1), "data": {}}]},
	]
	var adjacency: Array = []
	var out: Dictionary = SectionMap.compose(sections, adjacency)
	var objs: Array = out["objects"]
	TestHelper.eq(objs.size(), 1, "one composed object")
	TestHelper.eq(objs[0]["cell"], Vector2i(1, 1), "object cell carried through")

func test_flavor_coord_remap_with_offset() -> void:
	var sections := [
		{"id": "A", "layout": ["..", ".."]},
		{"id": "B", "layout": ["..", ".."], "flavor": [{"kind": "old_boot", "cell": Vector2i(0, 0)}]},
	]
	var adjacency := [{"a": "A", "side": "e", "b": "B"}]
	var out: Dictionary = SectionMap.compose(sections, adjacency)
	var flavor: Array = out["flavor"]
	TestHelper.eq(flavor.size(), 1, "one flavor")
	TestHelper.eq(flavor[0]["cell"], Vector2i(2, 0), "flavor remapped to master coords")

func test_irregular_chunk_supported() -> void:
	var sections := [
		{"id": "A", "layout": ["..", "..", ".."]},
		{"id": "B", "layout": ["..", ".."]},
	]
	var adjacency := [{"a": "A", "side": "s", "b": "B"}]
	var out: Dictionary = SectionMap.compose(sections, adjacency)
	var grid: Array = out["grid"]
	TestHelper.eq(grid.size(), 5, "irregular stack merges into 5 rows")
	TestHelper.eq((grid[0] as String).length(), 2, "irregular width kept")

func test_extras_passthrough_preserved() -> void:
	var sections := [
		{"id": "A", "layout": [".."], "extras": {"music": "calm", "weather": "misty"}},
	]
	var out: Dictionary = SectionMap.compose(sections, [])
	var meta: Dictionary = out["layout_meta"]
	TestHelper.is_true(meta.has("A"), "layout_meta keyed by section id")
	TestHelper.eq(meta["A"]["music"], "calm", "music extras preserved")
	TestHelper.eq(meta["A"]["weather"], "misty", "weather extras preserved")