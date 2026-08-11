extends RefCounted

func test_battle_sets_victory_flag() -> void:
	var src: String = FileAccess.get_file_as_string("res://scripts/battle/battle.gd")
	TestHelper.is_true(src.contains("end_for_victory"), "battle routes victory through ending")
	TestHelper.is_true(src.contains("keeper_victory"), "battle sets keeper_victory flag")
	TestHelper.is_true(src.contains('GameState.set_flag("keeper_victory", ending_id)'),
		"battle writes keeper_victory in win branch")

func test_cracks_returns_to_ending() -> void:
	var src: String = FileAccess.get_file_as_string("res://scripts/rooms/cracks.gd")
	TestHelper.is_true(src.contains("keeper_victory"), "cracks checks keeper_victory")
	TestHelper.is_true(src.contains("Ending.play_ending"), "cracks plays the keeper ending")
	TestHelper.is_true(src.contains('GameState.flags.erase("keeper_victory")'),
		"cracks clears keeper_victory")

func test_flag_clear_prevents_replay() -> void:
	GameState.reset()
	GameState.set_flag("keeper_victory", "keeper")
	cracks_logic_clear()
	TestHelper.is_true(not GameState.flags.has("keeper_victory"), "flag cleared after read")

func cracks_logic_clear() -> void:
	GameState.flags.erase("keeper_victory")