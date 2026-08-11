extends RefCounted

const BOSS_IDS: Array[String] = ["mourning_knight", "index", "canon_true"]

func test_all_boss_patterns_resolve() -> void:
	for id in BOSS_IDS:
		var e := EnemyLibrary.get_enemy(id)
		for pat in e["patterns"]:
			var items := BulletPatterns.make(pat, Vector2(317, 317))
			TestHelper.is_true(items.size() > 0,
				"%s pattern %s resolves" % [id, str(pat.get("type"))])

func test_boss_edit_patterns_spawn_edit_bullets() -> void:
	var e := EnemyLibrary.get_enemy("index")
	var checked := false
	for pat in e["patterns"]:
		if str(pat.get("type")) == "edit":
			checked = true
			for d in BulletPatterns.make(pat, Vector2(317, 317)):
				TestHelper.eq(str(d.get("behavior", "")), "edit", "edit behavior stamped")
				TestHelper.is_true(float(d.get("edit_at", -1.0)) > 0.0, "edit_at set")
				TestHelper.is_true(int(d.get("edit_rule", -1)) != int(d.get("rule", -1)),
					"edit_rule toggled against rule")
	TestHelper.is_true(checked, "index has at least one edit pattern")

func test_index_form_chain_applies() -> void:
	var e := EnemyLibrary.get_enemy("index")
	var forms: Array = e.get("forms", [])
	TestHelper.eq(forms.size(), 3, "index has 3 forms")
	var cur := e.duplicate(true)
	for i in forms.size():
		EnemyLibrary.apply_form(cur, forms[i])
		TestHelper.is_true(int(cur["hp"]) > 0, "form %d hp positive" % i)
		TestHelper.is_true(int(cur["def"]) > 0, "form %d def positive" % i)
		TestHelper.is_true(cur["patterns"].size() > 0, "form %d has patterns" % i)
		TestHelper.is_true(str(cur["sprite_id"]) != "", "form %d sprite set" % i)
		TestHelper.is_true(cur["acts"].size() > 0, "form %d has acts" % i)

func test_monologue_triggers_by_hp() -> void:
	var e := EnemyLibrary.get_enemy("mourning_knight")
	var monologue: Array = e.get("monologue", [])
	TestHelper.is_true(monologue.size() >= 3, "knight has 3 monologue lines")
	var shown: Array = []
	TestHelper.eq(EnemyLibrary.monologue_lines(monologue, 1.0, shown).size(), 0,
		"no lines above full hp")
	TestHelper.eq(EnemyLibrary.monologue_lines(monologue, 0.5, shown).size(), 2,
		"two lines at 50% hp")
	TestHelper.eq(EnemyLibrary.monologue_lines(monologue, 0.1, shown).size(), 3,
		"all three lines at 10% hp")

func test_boss_flags() -> void:
	for id in BOSS_IDS:
		var e := EnemyLibrary.get_enemy(id)
		TestHelper.is_true(bool(e.get("boss", false)), "%s is boss" % id)
		TestHelper.is_true(bool(e.get("no_flee", false)), "%s no flee" % id)