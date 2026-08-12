# tests/test_plan_a_integration.gd
extends RefCounted

func test_enemy_library_total() -> void:
	TestHelper.eq(EnemyLibrary.ids().size(), 24, "21 mobs plus 3 bosses")

func test_wisp_scene_spawns_in_both_rooms() -> void:
	var DrizzleScene := preload("res://scenes/rooms/DrizzleFields.tscn")
	var d: Node = DrizzleScene.instantiate()
	var d_stub := Node2D.new()
	d_stub.name = "Player"
	d.add_child(d_stub)
	d._spawn_wisp(d_stub)
	TestHelper.is_true(_has_wisp(d), "DrizzleFields spawns Wisp")
	d.free()

	var GrumbleScene := preload("res://scenes/rooms/GrumbleWoods.tscn")
	var g: Node = GrumbleScene.instantiate()
	var g_stub := Node2D.new()
	g_stub.name = "Player"
	g.add_child(g_stub)
	g._spawn_wisp(g_stub)
	TestHelper.is_true(_has_wisp(g), "GrumbleWoods spawns Wisp")
	g.free()

func test_hum_action_registered() -> void:
	GameState._ensure_input_actions()
	TestHelper.is_true(InputMap.has_action("hum"), "hum action exists")

func test_wisp_dialogue_covers_all_contexts() -> void:
	var contexts := ["intro", "drizzle", "grumble", "hum_low", "hum_high", "hum_ready"]
	for ctx in contexts:
		TestHelper.is_true(WispDialogue.get_line(ctx).length() > 0,
			"dialogue for '%s' non-empty" % ctx)

func test_wisp_state_resets_to_zero() -> void:
	WispState.set_mood(80)
	WispState.reset()
	TestHelper.eq(WispState.mood(), 0, "WispState.reset zeroes mood")

func _has_wisp(node: Node) -> bool:
	if node.get_script() != null and node.get_script().resource_path == "res://scripts/wisp/wisp.gd":
		return true
	for c in node.get_children():
		if _has_wisp(c):
			return true
	return false