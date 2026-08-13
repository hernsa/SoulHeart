extends RefCounted

const ROOM_SCRIPTS := [
	"res://scripts/rooms/grumble_woods.gd",
	"res://scripts/rooms/echo.gd",
	"res://scripts/rooms/hometown.gd",
	"res://scripts/rooms/canon.gd",
	"res://scripts/rooms/cracks.gd",
]

func test_variety_markers_spawn_trees_and_props() -> void:
	var row: Array = [
		GameTiles.Tile.PINE2, GameTiles.Tile.BIRCH, GameTiles.Tile.DEAD,
		GameTiles.Tile.BUSH, GameTiles.Tile.MUSHROOM, GameTiles.Tile.GRASS,
		GameTiles.Tile.FLOOR,
	]
	var room := MapBuilder.build_room([row], GameTiles.SNOWDIN_STYLE)
	TestHelper.eq(room["trees"].size(), 3, "three tree variants spawned")
	TestHelper.eq(room["props"].size(), 3, "three small props spawned")
	for t in room["trees"]:
		TestHelper.is_true(t is RoomTree, "variant spawns are RoomTree")
		TestHelper.is_true(t.texture != null, "variant tree has texture")

func test_variant_trees_have_distinct_textures() -> void:
	var row: Array = [GameTiles.Tile.TREE, GameTiles.Tile.PINE2, GameTiles.Tile.BIRCH, GameTiles.Tile.DEAD]
	var room := MapBuilder.build_room([row], GameTiles.SNOWDIN_STYLE)
	var texes: Array = []
	for t in room["trees"]:
		texes.append(t.texture)
	TestHelper.eq(texes.size(), 4, "four trees spawned")
	var unique := texes.duplicate()
	unique.assign(texes.filter(func(x): return texes.count(x) == 1))
	TestHelper.is_true(unique.size() >= 2, "tree variants differ in texture")

func test_small_props_are_visual_only() -> void:
	var row: Array = [GameTiles.Tile.BUSH, GameTiles.Tile.MUSHROOM, GameTiles.Tile.GRASS]
	var room := MapBuilder.build_room([row], GameTiles.RUINS_STYLE)
	for p in room["props"]:
		TestHelper.is_true(p is Sprite2D, "prop is sprite")
		var has_body := false
		for child in p.get_children():
			if child is StaticBody2D:
				has_body = true
		TestHelper.is_true(not has_body, "small props have no collision")

func test_player_starts_off_wall_row_everywhere() -> void:
	for path in ROOM_SCRIPTS:
		var room_script := load(path)
		var consts: Dictionary = room_script.get_script_constant_map()
		var parsed := MapBuilder.parse_layout(consts["LAYOUT"])
		var start: Vector2 = parsed["player_start"]
		var name := String(path).get_file()
		TestHelper.is_true(start.y >= 32.0, "%s player y=%s too close to wall row" % [name, start.y])
		TestHelper.is_true(start.x >= 24.0, "%s player x=%s too close to wall col" % [name, start.x])

func test_handcrafted_layouts_use_variety_chars() -> void:
	var grumble: Dictionary = load("res://scripts/rooms/grumble_woods.gd").get_script_constant_map()
	var layout: String = grumble["LAYOUT"]
	for ch in ["t", "b", "B", "M", "g"]:
		TestHelper.is_true(layout.contains(ch), "grumble layout uses marker '%s'" % ch)

func test_variant_sprites_exist_on_disk() -> void:
	for f in ["tree_pine_b.png", "tree_birch.png", "tree_dead.png", "bush.png", "mushroom.png", "grass.png"]:
		TestHelper.is_true(FileAccess.file_exists("res://assets/sprites/overworld/" + f),
			"overworld sprite missing: %s" % f)
