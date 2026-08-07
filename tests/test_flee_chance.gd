extends RefCounted

func test_flee_roll_threshold() -> void:
	var S := load("res://scripts/battle/battle.gd")
	TestHelper.is_true(S.flee_roll(0.2), "roll below chance succeeds")
	TestHelper.is_true(not S.flee_roll(0.5), "roll at threshold fails")
	TestHelper.is_true(not S.flee_roll(0.99), "roll above chance fails")
	TestHelper.is_true(S.flee_roll(0.0), "roll 0 succeeds")
