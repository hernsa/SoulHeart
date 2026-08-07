extends RefCounted

func test_willowisp_stats() -> void:
	var e := EnemyLibrary.get_enemy("willowisp")
	TestHelper.eq(e.enemy_id, "willowisp", "id")
	TestHelper.eq(e.display_name, "Willowisp", "name")
	TestHelper.eq(e.max_hp, 8, "max hp")
	TestHelper.eq(e.hp, 8, "hp")
	TestHelper.eq(e.attack, 3, "attack")
	TestHelper.eq(e.defense, 0, "defense")
	TestHelper.eq(e.spare_after_acts, 2, "spare threshold")
	TestHelper.is_true(not e.is_dead(), "alive at full hp")

func test_willowisp_acts() -> void:
	var e := EnemyLibrary.get_enemy("willowisp")
	var labels := e.act_labels()
	TestHelper.eq(labels.size(), 2, "two acts")
	TestHelper.eq(labels[0], "Check", "first act")
	TestHelper.eq(labels[1], "Hum", "second act")
	var hum: Dictionary = e.act_by_label("Hum")
	TestHelper.eq(hum["mood"], 1, "hum raises mood")
	var check: Dictionary = e.act_by_label("Check")
	TestHelper.eq(check["mood"], 0, "check does not raise mood")
	TestHelper.is_true(str(check["text"]).length() > 10, "check has lore text")

func test_willowisp_patterns() -> void:
	var e := EnemyLibrary.get_enemy("willowisp")
	TestHelper.eq(e.patterns.size(), 2, "two attack patterns")
	TestHelper.eq(e.patterns[0]["type"], "burst", "first pattern burst")
	TestHelper.eq(e.patterns[1]["type"], "fan", "second pattern fan")

func test_unknown_id_falls_back() -> void:
	var e := EnemyLibrary.get_enemy("nobody")
	TestHelper.eq(e.enemy_id, "willowisp", "fallback to willowisp")
