# tests/test_plan_d_integration.gd
extends RefCounted

const EDIT_IDS: Array[String] = [
	"shelf_book", "wall_window", "door_moves", "name_changes", "portrait", "floor_crack",
]

func test_edit_events_full_chain() -> void:
	for id in EDIT_IDS:
		TestHelper.is_true(EditEvent.EVENT_IDS.has(id), "edit event registered: " + id)
		EditEvent.choose(id, "accept")
		TestHelper.eq(str(GameState.flags.get("edit_event_" + id, "")), "accept",
			"accept sets flag for " + id)
		TestHelper.is_true(EditEvent.count("edit_accepts") > 0, "accept counter moves")
	GameState.reset()
	TestHelper.eq(EditEvent.count("edit_accepts"), 0, "reset clears counters")

func test_flee_does_not_commit() -> void:
	GameState.reset()
	EditEvent.choose("portrait", "flee")
	TestHelper.eq(str(GameState.flags.get("edit_event_portrait", "")), "flee",
		"flee marks event as fled")
	TestHelper.eq(EditEvent.count("edit_accepts"), 0, "flee does not count as accept")
	TestHelper.eq(EditEvent.count("edit_refuses"), 0, "flee does not count as refuse")
	TestHelper.eq(EditEvent.count("edit_flees"), 1, "flee counter moves")

func test_ending_gates() -> void:
	GameState.reset()
	TestHelper.is_true(not Ending.door_unlocked("hollow"), "hollow sealed before 6 accepts")
	for i in 5:
		EditEvent.choose(EDIT_IDS[i], "accept")
	TestHelper.is_true(not Ending.door_unlocked("hollow"), "hollow still sealed at 5 accepts")
	EditEvent.choose("floor_crack", "accept")
	TestHelper.is_true(Ending.door_unlocked("hollow"), "hollow open at 6 accepts")
	GameState.reset()
	for i in 3:
		EditEvent.choose(EDIT_IDS[i], "refuse")
	TestHelper.is_true(not Ending.door_unlocked("keeper"), "keeper sealed at 3 refuses")
	EditEvent.choose("name_changes", "refuse")
	TestHelper.is_true(Ending.door_unlocked("keeper"), "keeper open at 4 refuses")
	GameState.reset()
	TestHelper.is_true(Ending.door_unlocked("wanderer"), "wanderer always open")

func test_keeper_battle_routing() -> void:
	GameState.reset()
	Ending.flag_keeper_battle("res://scenes/rooms/Cracks.tscn")
	TestHelper.eq(str(GameState.flags.get("pending_enemy", "")), "canon_true",
		"keeper sets pending_enemy canon_true")
	TestHelper.eq(str(GameState.flags.get("from_room", "")), "res://scenes/rooms/Cracks.tscn",
		"keeper sets from_room")
	TestHelper.eq(str(GameState.flags.get("last_boss_save", "")), "canon_true",
		"keeper sets last_boss_save")
	TestHelper.is_true(FileAccess.file_exists(GameState.SAVE_PATH), "keeper flow autosaves")

func test_victory_mapping() -> void:
	TestHelper.eq(Ending.end_for_victory("canon_true"), "keeper", "canon_true maps to keeper")
	TestHelper.eq(Ending.end_for_victory("froggit"), "", "normal enemies map to nothing")

func test_ending_lines_present() -> void:
	for id in ["keeper", "wanderer", "hollow"]:
		TestHelper.eq(Ending.ending_lines(id).size(), 4, id + " has 4 ending lines")
	TestHelper.eq(Ending.credits_lines().size(), 8, "credits has 8 lines")

func test_hollow_wipes_save() -> void:
	Ending.flag_keeper_battle("res://scenes/rooms/Cracks.tscn")
	TestHelper.is_true(FileAccess.file_exists(GameState.SAVE_PATH), "save exists before wipe")
	Ending.wipe_save()
	TestHelper.is_true(not FileAccess.file_exists(GameState.SAVE_PATH), "save gone after wipe")
	TestHelper.is_true(GameState.flags.is_empty(), "flags cleared after wipe")

func test_old_dreamer_dialogue_parses() -> void:
	var lines := DialogueParser.parse_file("res://dialogue/old_dreamer.dlg")
	TestHelper.is_true(lines.size() >= 6, "old dreamer has 6+ lines")
	for line in lines:
		TestHelper.is_true(str(line.get("text", "")) != "", "dialogue line has text")

func test_ending_scenes_exist() -> void:
	TestHelper.is_true(ResourceLoader.exists("res://scenes/Battle.tscn"), "battle scene exists")
	TestHelper.is_true(ResourceLoader.exists("res://scenes/Main.tscn"), "main scene exists")

func test_door_sprites_exist() -> void:
	for id in ["keeper", "wanderer", "hollow", "old_dreamer"]:
		var path := "res://assets/sprites/overworld/door_%s.png" % id if id != "old_dreamer" \
			else "res://assets/sprites/overworld/old_dreamer.png"
		TestHelper.is_true(FileAccess.file_exists(path), "missing sprite: " + id)

func test_music_chain() -> void:
	for id in ["canon", "cracks", "credits", "hollow", "wisp"]:
		TestHelper.is_true(Audio.MUSIC.has(id), "music key: " + id)
		TestHelper.is_true(
			FileAccess.file_exists("res://assets/audio/music/mus_%s.wav" % id),
			"music file: " + id)
	for id in ["edit_bell", "door_seal"]:
		TestHelper.is_true(Audio.SFX.has(id), "sfx key: " + id)
		TestHelper.is_true(FileAccess.file_exists("res://assets/audio/sfx/%s.wav" % id),
			"sfx file: " + id)
	var canon_src := FileAccess.get_file_as_string("res://scripts/rooms/canon.gd")
	TestHelper.is_true(canon_src.contains('play_music("canon")'),
		"canon room plays canon theme")
	var cracks_src := FileAccess.get_file_as_string("res://scripts/rooms/cracks.gd")
	TestHelper.is_true(cracks_src.contains('play_music("cracks")'),
		"cracks room plays cracks theme")