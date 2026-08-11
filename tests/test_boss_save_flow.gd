extends RefCounted

const SAVE_PATH := "user://save.json"

func _fresh() -> void:
	GameState.reset()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

func test_boss_trigger_autosaves() -> void:
	_fresh()
	var enc = load("res://scripts/rooms/encounter.gd").new()
	enc.enemy_id = "index"
	enc.boss = true
	var stub := Node.new()
	stub.add_to_group("player")
	enc._on_body_entered(stub)
	TestHelper.eq(str(GameState.flags.get("pending_enemy", "")), "index", "pending enemy set")
	TestHelper.eq(str(GameState.flags.get("last_boss_save", "")), "index", "boss save flag set")
	TestHelper.is_true(str(GameState.flags.get("from_room", "")) != "", "from_room set")
	TestHelper.is_true(FileAccess.file_exists(SAVE_PATH), "autosave file written")
	enc.free()
	stub.free()

func test_normal_trigger_skips_autosave() -> void:
	_fresh()
	var enc = load("res://scripts/rooms/encounter.gd").new()
	enc.enemy_id = "froggit"
	var stub := Node.new()
	stub.add_to_group("player")
	enc._on_body_entered(stub)
	TestHelper.eq(str(GameState.flags.get("pending_enemy", "")), "froggit", "pending enemy set")
	TestHelper.is_true(not GameState.flags.has("last_boss_save"), "no boss save flag")
	TestHelper.is_true(not FileAccess.file_exists(SAVE_PATH), "no autosave for normal")
	enc.free()
	stub.free()

func test_room_boss_consts() -> void:
	var rooms: Array[Dictionary] = [
		{"script": "res://scripts/rooms/canon.gd", "want": ["mourning_knight"]},
		{"script": "res://scripts/rooms/cracks.gd", "want": ["index", "canon_true"]},
	]
	for r in rooms:
		var script := load(r["script"])
		var consts: Dictionary = script.get_script_constant_map()
		var bosses: Array = consts["BOSSES"]
		TestHelper.eq(bosses.size(), r["want"].size(), "%s boss count" % r["script"])
		var parsed := MapBuilder.parse_layout(consts["LAYOUT"])
		var grid: Array = parsed["grid"]
		for b in bosses:
			var id: String = str(b["id"])
			var pos: Vector2 = b["pos"]
			var tile := Vector2i(int(pos.x / 16.0), int(pos.y / 16.0))
			var kind: int = int(grid[tile.y][tile.x])
			TestHelper.is_true(kind == GameTiles.Tile.FLOOR,
				"%s %s on floor tile (got %s)" % [r["script"], id, str(kind)])
			TestHelper.is_true(id in r["want"], "%s unexpected boss %s" % [r["script"], id])
			TestHelper.is_true(not EnemyLibrary.get_enemy(id).is_empty(),
				"%s references unknown enemy %s" % [r["script"], id])

func test_boss_spawn_marks_boss_flag() -> void:
	for room in ["res://scripts/rooms/canon.gd", "res://scripts/rooms/cracks.gd"]:
		var src := FileAccess.get_file_as_string(room)
		TestHelper.is_true(src.contains("enc.boss = true"), "%s sets boss flag on spawn" % room)