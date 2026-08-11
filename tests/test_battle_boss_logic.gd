extends RefCounted

const BATTLE_PATH := "res://scripts/battle/battle.gd"

func test_battle_script_parses() -> void:
	var script: GDScript = load(BATTLE_PATH)
	TestHelper.is_true(script != null, "battle.gd loads as GDScript resource")

func test_battle_has_no_flee_guard() -> void:
	var src := FileAccess.get_file_as_string(BATTLE_PATH)
	TestHelper.is_true(src.contains("no_flee"), "battle.gd checks no_flee flag")
	TestHelper.is_true(src.contains("There is nowhere to flee"), "battle.gd blocks fleeing for bosses")

func test_battle_has_form_advance() -> void:
	var src := FileAccess.get_file_as_string(BATTLE_PATH)
	TestHelper.is_true(src.contains("_forms"), "battle.gd tracks forms array")
	TestHelper.is_true(src.contains("_form_index"), "battle.gd tracks form index")
	TestHelper.is_true(src.contains("apply_form"), "battle.gd calls EnemyLibrary.apply_form")
	TestHelper.is_true(src.contains("FORM "), "battle.gd shows form label")

func test_battle_has_monologue() -> void:
	var src := FileAccess.get_file_as_string(BATTLE_PATH)
	TestHelper.is_true(src.contains("monologue_lines"), "battle.gd uses EnemyLibrary.monologue_lines")
	TestHelper.is_true(src.contains("_monologue_shown"), "battle.gd tracks shown monologue lines")

func test_battle_mercy_skips_flee_for_bosses() -> void:
	var src := FileAccess.get_file_as_string(BATTLE_PATH)
	TestHelper.is_true(src.contains("\"Spare\""), "battle.gd keeps Spare option")
	var spare_only := src.find("no_flee") < src.find("_open_submenu(mercy")
	TestHelper.is_true(spare_only, "MERCY submenu built from conditional list")
