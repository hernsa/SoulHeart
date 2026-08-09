extends RefCounted

func test_simulated_spare_fight() -> void:
	var enemy := EnemyLibrary.get_enemy("willowisp")
	var state := BattleState.new()
	state.transition(BattleState.Phase.PLAYER_TURN)
	var mood := 0
	TestHelper.is_true(enemy["hp"] > 0, "enemy alive at start")
	mood += EnemyLibrary.act_by_label(enemy["acts"], "Ribbit")["mood"]
	mood += EnemyLibrary.act_by_label(enemy["acts"], "Ribbit")["mood"]
	var spareable: bool = mood >= enemy["spare_after"]
	TestHelper.is_true(spareable, "spareable after two acts")
	TestHelper.is_true(state.transition(BattleState.Phase.SPARED), "spared")

func test_simulated_kill_fight() -> void:
	var enemy := EnemyLibrary.get_enemy("willowisp")
	while int(enemy["hp"]) > 0:
		enemy["hp"] = int(enemy["hp"]) - CombatMath.calculate_damage(1, enemy["def"], 1.0)
	TestHelper.is_true(int(enemy["hp"]) <= 0, "enemy dies")
