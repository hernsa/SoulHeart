extends RefCounted

func test_tree_cells_spawn_roomtree() -> void:
	var grid := [[GameTiles.Tile.TREE]]
	var room := MapBuilder.build_room(grid, GameTiles.RUINS_STYLE)
	var trees: Array = room["trees"]
	TestHelper.eq(trees.size(), 1, "one tree spawned")
	TestHelper.is_true(trees[0] is RoomTree, "tree is RoomTree")

func test_tree_position_and_sprite() -> void:
	var grid := [[GameTiles.Tile.FLOOR], [GameTiles.Tile.TREE]]
	var room := MapBuilder.build_room(grid, GameTiles.RUINS_STYLE)
	var tree: RoomTree = room["trees"][0]
	TestHelper.eq(tree.position, Vector2(8, 24), "tree centered on cell (0,1)")
	TestHelper.is_true(tree.texture != null, "tree has pine texture")
	TestHelper.eq(tree.z_index, 1, "tree draws above floor")
	TestHelper.is_true(tree.y_sort_enabled, "tree y-sorts with player")

func test_tree_trunk_collision_narrow() -> void:
	var grid := [[GameTiles.Tile.TREE]]
	var room := MapBuilder.build_room(grid, GameTiles.RUINS_STYLE)
	var tree: RoomTree = room["trees"][0]
	var body: StaticBody2D = null
	for child in tree.get_children():
		if child is StaticBody2D:
			body = child
			break
	TestHelper.is_true(body != null, "tree has static body")
	var shape: CollisionShape2D = null
	for child in body.get_children():
		if child is CollisionShape2D:
			shape = child
			break
	TestHelper.is_true(shape != null, "body has collision shape")
	var rect := shape.shape as RectangleShape2D
	TestHelper.is_true(rect != null, "collision is rectangle")
	TestHelper.is_true(rect.size.x <= 10.0, "trunk collision narrow (<=10px wide)")

func test_tree_shadow_present() -> void:
	var grid := [[GameTiles.Tile.TREE]]
	var room := MapBuilder.build_room(grid, GameTiles.RUINS_STYLE)
	var tree: RoomTree = room["trees"][0]
	var shadow: Sprite2D = null
	for child in tree.get_children():
		if child is Sprite2D:
			shadow = child
			break
	TestHelper.is_true(shadow != null, "tree has shadow sprite")
	TestHelper.eq(shadow.position, Vector2(0, 24), "shadow under trunk")
	TestHelper.eq(shadow.z_index, -1, "shadow below tree sprite")
