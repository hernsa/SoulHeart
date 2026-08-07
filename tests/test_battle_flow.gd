extends RefCounted

func test_simulated_spare_fight() -> void:
	var enemy := EnemyLibrary.get_enemy("willowisp")
	var state := BattleState.new()
	state.transition(BattleState.Phase.PLAYER_TURN)
	var mood := 0
	TestHelper.is_true(enemy.hp > 0, "enemy alive at start")
	mood += enemy.act_by_label("Hum")["mood"]
	mood += enemy.act_by_label("Hum")["mood"]
	var spareable: bool = mood >= enemy.spare_after_acts
	TestHelper.is_true(spareable, "spareable after two hums")
	TestHelper.is_true(state.transition(BattleState.Phase.SPARED), "spared")

func test_simulated_kill_fight() -> void:
	var enemy := EnemyLibrary.get_enemy("willowisp")
	while not enemy.is_dead():
		enemy.hp -= CombatMath.calculate_damage(1, enemy.defense, 1.0)
	TestHelper.is_true(enemy.is_dead(), "enemy dies")
