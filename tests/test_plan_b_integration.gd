# tests/test_plan_b_integration.gd
extends RefCounted

func test_six_areas_all_styles() -> void:
	TestHelper.eq(GameTiles.AREA_STYLES.size(), 6, "6 area styles")

func test_full_chain_all_targets_exist() -> void:
	var rooms := ["grumble_woods", "echo", "hometown", "canon", "cracks"]
	for id: String in rooms:
		var script: GDScript = load("res://scripts/rooms/%s.gd" % id)
		var consts: Dictionary = script.get_script_constant_map()
		var targets: Array = consts["DOOR_TARGETS"]
		for t in targets:
			TestHelper.is_true(ResourceLoader.exists(t["target_room"]),
				"%s target missing: %s" % [id, t["target_room"]])

func test_every_scene_instantiates() -> void:
	for path in [
			"res://scenes/rooms/DrizzleFields.tscn",
			"res://scenes/rooms/GrumbleWoods.tscn",
			"res://scenes/rooms/Echo.tscn",
			"res://scenes/rooms/Hometown.tscn",
			"res://scenes/rooms/Canon.tscn",
			"res://scenes/rooms/Cracks.tscn"]:
		var inst: Node = load(path).instantiate()
		TestHelper.is_true(inst != null, "%s instantiates" % path)
		inst.free()

func test_all_wisp_contexts_covered() -> void:
	var contexts := ["intro", "drizzle", "grumble", "echo", "hometown", "canon",
			"cracks", "hum_low", "hum_high", "hum_ready"]
	for ctx: String in contexts:
		TestHelper.is_true(WispDialogue.get_line(ctx).length() > 0,
			"wisp dialogue '%s' non-empty" % ctx)

func test_area_enemies_resolve() -> void:
	var script: GDScript = load("res://scripts/rooms/echo.gd")
	var consts: Dictionary = script.get_script_constant_map()
	for id: String in consts["ENCOUNTER_ENEMIES"]:
		TestHelper.is_true(Sprites.battle_enemy_texture(id, false) != null,
			"%s has battle texture" % id)