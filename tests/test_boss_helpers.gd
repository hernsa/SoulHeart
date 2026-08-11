# tests/test_boss_helpers.gd
extends RefCounted

func test_apply_form_replaces_fight_fields() -> void:
	var target: Dictionary = {
		"id": "index", "name": "old", "hp": 10, "def": 1, "spare_after": 9,
		"acts": [], "attack_lines": [], "patterns": [], "intro_line": "x",
		"sprite_id": "a", "boss": true, "no_flee": true,
		"monologue": [{"at": 0.5, "text": "keep"}],
	}
	var form: Dictionary = {
		"name": "new", "hp": 50, "def": 4, "spare_after": 4,
		"acts": [{"id": "e"}], "attack_lines": ["l"], "patterns": [{"type": "ring"}],
		"intro_line": "y", "sprite_id": "b",
	}
	var out: Dictionary = EnemyLibrary.apply_form(target, form)
	TestHelper.eq(str(out["name"]), "new", "form must replace name")
	TestHelper.eq(int(out["hp"]), 50, "form must replace hp")
	TestHelper.eq(int(out["def"]), 4, "form must replace def")
	TestHelper.eq(int(out["spare_after"]), 4, "form must replace spare_after")
	TestHelper.eq(str(out["sprite_id"]), "b", "form must replace sprite_id")
	TestHelper.eq(str(out["intro_line"]), "y", "form must replace intro_line")
	TestHelper.eq(out["acts"].size(), 1, "form must replace acts")
	TestHelper.eq(out["patterns"].size(), 1, "form must replace patterns")
	TestHelper.eq(str(out["id"]), "index", "id must survive apply_form")
	TestHelper.is_true(out["boss"], "boss flag must survive apply_form")
	TestHelper.is_true(out["no_flee"], "no_flee flag must survive apply_form")
	TestHelper.eq(out["monologue"].size(), 1, "monologue list must survive apply_form")

func test_apply_form_missing_keys_keep_old() -> void:
	var target: Dictionary = {
		"name": "keep", "hp": 10, "def": 1, "spare_after": 9,
		"acts": [], "attack_lines": [], "patterns": [],
		"intro_line": "x", "sprite_id": "a",
	}
	var form: Dictionary = {"hp": 20}
	var out: Dictionary = EnemyLibrary.apply_form(target, form)
	TestHelper.eq(str(out["name"]), "keep", "missing name must keep old")
	TestHelper.eq(int(out["hp"]), 20, "present hp must replace")
	TestHelper.eq(str(out["sprite_id"]), "a", "missing sprite_id must keep old")

func test_monologue_lines_filters_by_threshold() -> void:
	var mono: Array = [
		{"at": 0.75, "text": "a"},
		{"at": 0.5, "text": "b"},
		{"at": 0.25, "text": "c"},
	]
	var lines: Array = EnemyLibrary.monologue_lines(mono, 0.6, [])
	TestHelper.eq(lines.size(), 1, "only lines crossed by hp_frac 0.6 fire")
	TestHelper.eq(str(lines[0]["text"]), "a", "0.75 line fires first")

func test_monologue_lines_full_hp_fires_none() -> void:
	var mono: Array = [{"at": 0.75, "text": "a"}, {"at": 0.5, "text": "b"}]
	var lines: Array = EnemyLibrary.monologue_lines(mono, 1.0, [])
	TestHelper.eq(lines.size(), 0, "no lines fire at full hp")

func test_monologue_lines_skips_already_shown() -> void:
	var mono: Array = [{"at": 0.75, "text": "a"}, {"at": 0.5, "text": "b"}]
	var lines: Array = EnemyLibrary.monologue_lines(mono, 0.4, [0.75])
	TestHelper.eq(lines.size(), 1, "shown line must be skipped")
	TestHelper.eq(str(lines[0]["text"]), "b", "0.5 line fires after 0.75 shown")

func test_monologue_lines_all_crossed() -> void:
	var mono: Array = [{"at": 0.75, "text": "a"}, {"at": 0.5, "text": "b"}, {"at": 0.25, "text": "c"}]
	var lines: Array = EnemyLibrary.monologue_lines(mono, 0.1, [])
	TestHelper.eq(lines.size(), 3, "all lines fire at 10% hp")