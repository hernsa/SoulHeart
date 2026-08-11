extends RefCounted

const SAVE_PATH := "user://save.json"

func _fresh() -> void:
	GameState.reset()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

func test_wanderer_always_unlocked() -> void:
	GameState.reset()
	TestHelper.is_true(Ending.door_unlocked("wanderer"), "wanderer door always open")

func test_hollow_gate() -> void:
	GameState.reset()
	for i in 5:
		EditEvent.choose("ev%d" % i, "accept")
	TestHelper.is_true(not Ending.door_unlocked("hollow"), "hollow sealed at 5 accepts")
	EditEvent.choose("ev5", "accept")
	TestHelper.is_true(Ending.door_unlocked("hollow"), "hollow opens at 6 accepts")

func test_keeper_gate() -> void:
	GameState.reset()
	for i in 3:
		EditEvent.choose("ev%d" % i, "refuse")
	TestHelper.is_true(not Ending.door_unlocked("keeper"), "keeper sealed at 3 refuses")
	EditEvent.choose("ev3", "refuse")
	TestHelper.is_true(Ending.door_unlocked("keeper"), "keeper opens at 4 refuses")

func test_unknown_door_locked() -> void:
	GameState.reset()
	TestHelper.is_true(not Ending.door_unlocked("bogus"), "unknown door stays sealed")

func test_flag_keeper_battle() -> void:
	_fresh()
	Ending.flag_keeper_battle("res://scenes/rooms/Cracks.tscn")
	TestHelper.eq(str(GameState.flags.get("pending_enemy", "")), "canon_true", "pending enemy is canon_true")
	TestHelper.eq(str(GameState.flags.get("last_boss_save", "")), "canon_true", "boss save is canon_true")
	TestHelper.eq(str(GameState.flags.get("from_room", "")), "res://scenes/rooms/Cracks.tscn", "from_room set")
	TestHelper.is_true(FileAccess.file_exists(SAVE_PATH), "keeper gate autosaves")

func test_end_for_victory() -> void:
	TestHelper.eq(Ending.end_for_victory("canon_true"), "keeper", "canon_true routes to keeper ending")
	TestHelper.eq(Ending.end_for_victory("froggit"), "", "normal enemy routes nowhere")

func test_ending_lines() -> void:
	for id in ["keeper", "wanderer", "hollow"]:
		var lines: Array = Ending.ending_lines(id)
		TestHelper.eq(lines.size(), 4, "%s ending has 4 lines" % id)
		for line in lines:
			TestHelper.is_true(str(line["text"]).length() > 0, "%s line non-empty" % id)
	TestHelper.eq(Ending.ending_lines("bogus").size(), 0, "unknown ending has no lines")

func test_credits_lines() -> void:
	var lines: Array = Ending.credits_lines()
	TestHelper.eq(lines.size(), 8, "credits has 8 lines")
	for line in lines:
		TestHelper.is_true(str(line["text"]).length() > 0, "credit line non-empty")

func test_wipe_save() -> void:
	_fresh()
	Ending.flag_keeper_battle("res://scenes/rooms/Cracks.tscn")
	TestHelper.is_true(FileAccess.file_exists(SAVE_PATH), "save exists before wipe")
	Ending.wipe_save()
	TestHelper.is_true(not FileAccess.file_exists(SAVE_PATH), "save wiped")
	TestHelper.eq(GameState.flags.size(), 0, "flags reset after wipe")

func test_ending_scripts_load() -> void:
	TestHelper.is_true(load("res://scripts/world/ending.gd") != null, "ending.gd loads")
	TestHelper.is_true(load("res://scripts/world/ending_door.gd") != null, "ending_door.gd loads")

func test_old_dreamer_dialogue() -> void:
	var lines := DialogueParser.parse_file("res://dialogue/old_dreamer.dlg")
	TestHelper.eq(lines.size(), 6, "old dreamer has 6 lines")

func test_door_sprites_exist() -> void:
	for id in ["keeper", "wanderer", "hollow"]:
		TestHelper.is_true(FileAccess.file_exists("res://assets/sprites/overworld/door_%s.png" % id),
			"door_%s.png exists" % id)
	TestHelper.is_true(FileAccess.file_exists("res://assets/sprites/overworld/old_dreamer.png"), "old_dreamer.png exists")

func test_cracks_wiring() -> void:
	var src: String = FileAccess.get_file_as_string("res://scripts/rooms/cracks.gd")
	TestHelper.is_true(src.contains("old_dreamer.dlg"), "cracks spawns old dreamer")
	TestHelper.is_true(src.contains("ending_door.gd"), "cracks spawns ending doors")
	TestHelper.is_true(src.contains("_spawn_ending_doors()"), "cracks calls _spawn_ending_doors")
	var consts: Dictionary = load("res://scripts/rooms/cracks.gd").get_script_constant_map()
	var bosses: Array = consts["BOSSES"]
	for b in bosses:
		TestHelper.is_true(str(b["id"]) != "canon_true", "canon_true no longer in cracks BOSSES")

func test_ending_door_routes_to_gate() -> void:
	var src: String = FileAccess.get_file_as_string("res://scripts/world/ending_door.gd")
	TestHelper.is_true(src.contains("door_unlocked"), "ending door checks gate")
	TestHelper.is_true(src.contains("flag_keeper_battle"), "ending door routes keeper battle")
	TestHelper.is_true(src.contains("play_ending"), "ending door routes endings")
	TestHelper.is_true(src.contains("The way is sealed"), "ending door has sealed banner")
