extends RefCounted

const NEW_MOB_IDS := [
	"reminisc", "hushroom", "paneic", "squish", "sentimint",
	"repeato", "toadally", "punkin", "nullaby", "quibble",
	"margin", "lookey", "remembran",
]

func test_all_enemies_present() -> void:
	var ids := EnemyLibrary.enemy_ids()
	TestHelper.eq(ids.size(), 19, "nineteen enemies")
	for id in ["froggit", "whimsun", "moldsmal", "loox", "vegetoid", "migosp"]:
		TestHelper.is_true(ids.has(id), "has enemy: " + id)

func test_library_has_all_new_mobs() -> void:
	for mob_id in NEW_MOB_IDS:
		var e: Dictionary = EnemyLibrary.get_enemy(mob_id)
		TestHelper.is_true(not e.is_empty(), "%s must exist" % mob_id)

func test_froggit_profile() -> void:
	var e := EnemyLibrary.get_enemy("froggit")
	TestHelper.eq(e["name"], "FROGGIT", "name")
	TestHelper.eq(e["hp"], 20, "hp 20")
	TestHelper.eq(e["atk"], 4, "atk 4")
	TestHelper.is_true(e["patterns"].size() >= 2, "at least two patterns")
	TestHelper.is_true(e["attack_lines"].size() >= 1, "has attack lines")
	TestHelper.eq(e["sprite_id"], "froggit", "sprite id")

func test_vegetoid_uses_green_heal() -> void:
	var e := EnemyLibrary.get_enemy("vegetoid")
	var has_green := false
	for p in e["patterns"]:
		if int(p.get("rule", Bullet.Rule.NONE)) == Bullet.Rule.GREEN:
			has_green = true
	TestHelper.is_true(has_green, "vegetoid drops green heal bullets")

func test_unknown_enemy_falls_back() -> void:
	var e := EnemyLibrary.get_enemy("nonexistent")
	TestHelper.eq(e["id"], "froggit", "falls back to froggit")
