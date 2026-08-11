extends RefCounted

const CANON_LAYOUT := """
########################################
#P...................................#
#......................................#
#......................................#
#.............E........................#
#......................................#
#......................................#
#........S.............................#
#......................................#
#.............E........................#
#......................................#
#......................................#
#......................................#
#......................................#
#D...................................D#
#......................................#
#......................................#
#.............E........................#
#......................................#
#......................................#
#......................................#
#......................................#
#......................................#
#......................................#
#...........E..........................#
#......................................#
#......................................#
#......................................#
#......................................#
########################################
"""

func test_event_ids_complete() -> void:
	TestHelper.eq(EditEvent.EVENT_IDS.size(), 6, "exactly 6 edit event ids")
	for id in EditEvent.EVENT_IDS:
		TestHelper.is_true(id.length() > 0, "event id non-empty: %s" % id)

func test_choose_accept() -> void:
	GameState.reset()
	var out := EditEvent.choose("shelf_book", "accept")
	TestHelper.eq(out, "accept", "choose returns accept")
	TestHelper.eq(str(GameState.flags["edit_event_shelf_book"]), "accept", "per-event flag set")
	TestHelper.eq(int(GameState.flags["edit_accepts"]), 1, "accepts counter incremented")
	TestHelper.eq(int(GameState.flags.get("edit_refuses", 0)), 0, "refuses untouched")

func test_choose_refuse() -> void:
	GameState.reset()
	EditEvent.choose("wall_window", "refuse")
	TestHelper.eq(str(GameState.flags["edit_event_wall_window"]), "refuse", "per-event flag refuse")
	TestHelper.eq(int(GameState.flags["edit_refuses"]), 1, "refuses counter incremented")
	TestHelper.eq(int(GameState.flags.get("edit_accepts", 0)), 0, "accepts untouched")

func test_choose_flee_defaults() -> void:
	GameState.reset()
	EditEvent.choose("door_moves", "anything_else")
	TestHelper.eq(str(GameState.flags["edit_event_door_moves"]), "flee", "unknown choice coerced to flee")
	TestHelper.eq(int(GameState.flags["edit_flees"]), 1, "flees counter incremented")

func test_counts_accumulate() -> void:
	GameState.reset()
	EditEvent.choose("portrait", "accept")
	EditEvent.choose("floor_crack", "accept")
	EditEvent.choose("name_changes", "refuse")
	TestHelper.eq(EditEvent.count("edit_accepts"), 2, "two accepts counted")
	TestHelper.eq(EditEvent.count("edit_refuses"), 1, "one refuse counted")

func test_events_floor_placed_in_canon() -> void:
	var parsed := MapBuilder.parse_layout(CANON_LAYOUT)
	var grid: Array = parsed["grid"]
	var canon := load("res://scripts/rooms/canon.gd")
	var events: Array = canon.EDIT_EVENTS
	TestHelper.eq(events.size(), 6, "canon defines 6 edit events")
	for e in events:
		var pos: Vector2 = e["pos"]
		var col := int(pos.x / 16.0)
		var row := int(pos.y / 16.0)
		var tile: int = int(grid[row][col])
		TestHelper.eq(tile, GameTiles.Tile.FLOOR, "event %s floor at (%d,%d)" % [e["id"], col, row])
		TestHelper.is_true(str(e["prompt"]).length() > 4, "event %s has prompt" % e["id"])

func test_edit_event_parses() -> void:
	var script: GDScript = load("res://scripts/world/edit_event.gd")
	TestHelper.is_true(script != null, "edit_event.gd loads")
	TestHelper.is_true(load("res://scripts/world/choice_menu.gd") != null, "choice_menu.gd loads")

func test_canon_source_has_events() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/rooms/canon.gd")
	TestHelper.is_true(source.contains("_spawn_edit_events()"), "canon calls _spawn_edit_events")
	TestHelper.is_true(source.contains("EDIT_EVENTS"), "canon defines EDIT_EVENTS")