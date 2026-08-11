extends RefCounted

func test_boss_ids_registered() -> void:
	var ids: Array = EnemyLibrary.ids()
	TestHelper.is_true(ids.has("mourning_knight"), "mourning_knight must be registered")
	TestHelper.is_true(ids.has("index"), "index must be registered")
	TestHelper.is_true(ids.has("canon_true"), "canon_true must be registered")

func test_mourning_knight_shape() -> void:
	var enemy: Dictionary = EnemyLibrary.get_enemy("mourning_knight")
	TestHelper.is_true(enemy["boss"], "mourning_knight must be a boss")
	TestHelper.is_true(enemy["no_flee"], "mourning_knight must set no_flee")
	TestHelper.eq(int(enemy["spare_after"]), 6, "mourning_knight spare_after must be 6")
	var mono: Array = enemy["monologue"]
	TestHelper.eq(mono.size(), 3, "mourning_knight must have 3 monologue lines")
	for line in mono:
		TestHelper.is_true(line.has("at"), "monologue line must have at")
		TestHelper.is_true(line.has("speaker"), "monologue line must have speaker")
		TestHelper.is_true(line.has("text"), "monologue line must have text")
	TestHelper.is_true(EnemyLibrary.act_labels(enemy["acts"]).has("* Mourn"), "acts must include * Mourn")

func test_mourning_knight_patterns_resolve() -> void:
	var enemy: Dictionary = EnemyLibrary.get_enemy("mourning_knight")
	for pattern in enemy["patterns"]:
		var out: Array = BulletPatterns.make(pattern, Vector2(320, 300))
		TestHelper.is_true(out.size() > 0, "mourning_knight pattern must resolve non-empty")

func test_index_has_three_forms() -> void:
	var enemy: Dictionary = EnemyLibrary.get_enemy("index")
	var forms: Array = enemy["forms"]
	TestHelper.eq(forms.size(), 3, "index must have exactly 3 forms")
	var keys: Array = ["name", "hp", "def", "spare_after", "acts", "attack_lines",
			"patterns", "intro_line", "sprite_id"]
	for i in forms.size():
		var form: Dictionary = forms[i]
		for key in keys:
			TestHelper.is_true(form.has(key), "form %d must have key %s" % [i, key])
	TestHelper.eq(str(forms[0]["sprite_id"]), "index_f1", "form 1 sprite must be index_f1")
	TestHelper.eq(str(forms[1]["sprite_id"]), "index_f2", "form 2 sprite must be index_f2")
	TestHelper.eq(str(forms[2]["sprite_id"]), "index_f3", "form 3 sprite must be index_f3")
	TestHelper.eq(int(enemy["hp"]), int(forms[0]["hp"]), "top-level hp must mirror form 1")

func test_index_patterns_resolve() -> void:
	var enemy: Dictionary = EnemyLibrary.get_enemy("index")
	for form in enemy["forms"]:
		for pattern in form["patterns"]:
			if str(pattern["type"]) == "edit":
				continue
			var out: Array = BulletPatterns.make(pattern, Vector2(320, 300))
			TestHelper.is_true(out.size() > 0, "index pattern must resolve non-empty")

func test_canon_true_shape() -> void:
	var enemy: Dictionary = EnemyLibrary.get_enemy("canon_true")
	TestHelper.is_true(enemy["boss"], "canon_true must be a boss")
	TestHelper.is_true(enemy["no_flee"], "canon_true must set no_flee")
	TestHelper.eq(int(enemy["hp"]), 120, "canon_true hp must be 120")
	var labels: Array = EnemyLibrary.act_labels(enemy["acts"])
	TestHelper.is_true(labels.has("* Accept"), "acts must include * Accept")
	TestHelper.is_true(labels.has("* Refuse"), "acts must include * Refuse")

func test_canon_true_patterns_resolve() -> void:
	var enemy: Dictionary = EnemyLibrary.get_enemy("canon_true")
	for pattern in enemy["patterns"]:
		var out: Array = BulletPatterns.make(pattern, Vector2(320, 300))
		TestHelper.is_true(out.size() > 0, "canon_true pattern must resolve non-empty")

func test_boss_dlg_files() -> void:
	for path in ["res://dialogue/mourning_knight.dlg", "res://dialogue/index.dlg"]:
		TestHelper.is_true(FileAccess.file_exists(path), "%s must exist" % path)
		var f: FileAccess = FileAccess.open(path, FileAccess.READ)
		TestHelper.is_true(f != null, "%s must open" % path)
		if f == null:
			continue
		var text: String = f.get_as_text()
		f.close()
		var count := 0
		for line in text.split("\n"):
			if line.strip_edges().begins_with("*"):
				count += 1
		TestHelper.is_true(count >= 4, "%s must have at least 4 asterisk lines" % path)