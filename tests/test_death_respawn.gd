extends RefCounted

func test_respawn_state_after_death() -> void:
	var gs = load("res://scripts/autoload/game_state.gd").new()
	gs._ready()
	gs.reset()
	gs.set_flag("save_point", [128, 224])
	gs.change_hp(-20)
	TestHelper.eq(int(gs.player_stats["hp"]), 0, "hp zeroed by damage")
	var items_before: int = gs.inventory.size()
	gs.heal_full()
	TestHelper.eq(int(gs.player_stats["hp"]), int(gs.player_stats["max_hp"]), "hp restored to max")
	TestHelper.eq(gs.inventory.size(), items_before, "inventory kept on death")
	TestHelper.eq(gs.flags.get("save_point"), [128, 224], "save point preserved")
