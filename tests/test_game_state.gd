extends RefCounted

const GAME_STATE := preload("res://scripts/autoload/game_state.gd")

func _new_gs() -> GAME_STATE:
	var gs: GAME_STATE = GAME_STATE.new()
	gs.reset()
	return gs

func test_reset_defaults() -> void:
	var gs := _new_gs()
	TestHelper.eq(gs.player_stats["hp"], 20, "default hp")
	TestHelper.eq(gs.player_stats["max_hp"], 20, "default max hp")
	TestHelper.eq(gs.player_stats["atk"], 1, "default atk")
	TestHelper.eq(gs.player_stats["gold"], 0, "default gold")
	TestHelper.eq(gs.inventory.size(), 1, "starter item")
	TestHelper.eq(gs.inventory[0]["id"], "dream_candy", "starter item id")
	TestHelper.eq(gs.kills, 0, "no kills")
	TestHelper.eq(gs.spares, 0, "no spares")
	gs.free()

func test_counters() -> void:
	var gs := _new_gs()
	gs.add_kill()
	gs.add_kill()
	gs.add_spare()
	TestHelper.eq(gs.kills, 2, "kill counter")
	TestHelper.eq(gs.spares, 1, "spare counter")
	gs.free()

func test_change_hp_clamps() -> void:
	var gs := _new_gs()
	gs.change_hp(-5)
	TestHelper.eq(gs.player_stats["hp"], 15, "damage")
	gs.change_hp(-100)
	TestHelper.eq(gs.player_stats["hp"], 0, "clamp low")
	gs.change_hp(100)
	TestHelper.eq(gs.player_stats["hp"], 20, "clamp high")
	gs.free()

func test_heal_full() -> void:
	var gs := _new_gs()
	gs.change_hp(-8)
	gs.heal_full()
	TestHelper.eq(gs.player_stats["hp"], 20, "healed to max")
	gs.free()

func test_use_item_heals_and_consumes() -> void:
	var gs := _new_gs()
	gs.change_hp(-10)
	var used: Dictionary = gs.use_item(0)
	TestHelper.eq(used["id"], "dream_candy", "used item returned")
	TestHelper.eq(gs.player_stats["hp"], 16, "heal applied")
	TestHelper.eq(gs.inventory.size(), 0, "item consumed")
	gs.free()

func test_use_item_out_of_range() -> void:
	var gs := _new_gs()
	var used: Dictionary = gs.use_item(5)
	TestHelper.eq(used.size(), 0, "empty dict on bad index")
	gs.free()

func test_save_load_roundtrip() -> void:
	var gs := _new_gs()
	gs.add_kill()
	gs.add_spare()
	gs.change_hp(-7)
	gs.set_flag("dreams_repaired", 3)
	gs.set_flag("save_point", [64, 96])
	gs.set_flag("current_room", "res://scenes/rooms/DrizzleFields.tscn")
	TestHelper.is_true(gs.save_game("user://test_save.json"), "save succeeds")
	var gs2 := _new_gs()
	TestHelper.is_true(gs2.load_game("user://test_save.json"), "load succeeds")
	TestHelper.eq(gs2.kills, 1, "kills restored")
	TestHelper.eq(gs2.spares, 1, "spares restored")
	TestHelper.eq(gs2.player_stats["hp"], 13, "hp restored")
	TestHelper.eq(gs2.flags["dreams_repaired"], 3, "flag restored")
	TestHelper.eq(gs2.flags["save_point"], [64, 96], "save_point restored")
	TestHelper.eq(gs2.flags["current_room"], "res://scenes/rooms/DrizzleFields.tscn", "room restored")
	DirAccess.remove_absolute("user://test_save.json")
	gs2.free()
	gs.free()

func test_load_missing_file() -> void:
	var gs := _new_gs()
	TestHelper.is_true(not gs.load_game("user://does_not_exist.json"), "load missing returns false")
	gs.free()

func test_input_actions_created() -> void:
	var gs := _new_gs()
	gs.call("_ensure_input_actions")
	TestHelper.is_true(InputMap.has_action("confirm"), "confirm action exists")
	TestHelper.is_true(InputMap.has_action("cancel"), "cancel action exists")
	TestHelper.is_true(InputMap.has_action("move_up"), "move_up exists")
	TestHelper.is_true(InputMap.has_action("move_down"), "move_down exists")
	TestHelper.is_true(InputMap.has_action("move_left"), "move_left exists")
	TestHelper.is_true(InputMap.has_action("move_right"), "move_right exists")
	gs.free()
