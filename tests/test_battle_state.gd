extends RefCounted

func test_legal_transitions() -> void:
	var s := BattleState.new()
	TestHelper.is_true(s.transition(BattleState.Phase.PLAYER_TURN), "intro to player")
	TestHelper.is_true(s.transition(BattleState.Phase.FIGHT), "player to fight")
	TestHelper.is_true(s.transition(BattleState.Phase.ENEMY_TURN), "fight to enemy")
	TestHelper.is_true(s.transition(BattleState.Phase.PLAYER_TURN), "enemy to player")
	TestHelper.is_true(s.transition(BattleState.Phase.MERCY), "player to mercy")
	TestHelper.is_true(s.transition(BattleState.Phase.SPARED), "mercy to spared")

func test_illegal_transition_rejected() -> void:
	var s := BattleState.new()
	TestHelper.is_true(not s.transition(BattleState.Phase.WIN), "cannot win from intro")
	TestHelper.eq(s.phase, BattleState.Phase.INTRO, "phase unchanged")
	s.transition(BattleState.Phase.PLAYER_TURN)
	TestHelper.is_true(not s.transition(BattleState.Phase.INTRO), "cannot go back")
	TestHelper.is_true(not s.transition(BattleState.Phase.WIN), "cannot win directly")
	TestHelper.eq(s.phase, BattleState.Phase.PLAYER_TURN, "still player turn")
	s.transition(BattleState.Phase.SPARED)
	TestHelper.is_true(not s.transition(BattleState.Phase.PLAYER_TURN), "spared is terminal")

func test_win_path_from_fight() -> void:
	var s := BattleState.new()
	s.transition(BattleState.Phase.PLAYER_TURN)
	s.transition(BattleState.Phase.FIGHT)
	TestHelper.is_true(s.transition(BattleState.Phase.WIN), "win from fight")
