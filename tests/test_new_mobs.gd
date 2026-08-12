# tests/test_new_mobs.gd
extends RefCounted

const NEW_IDS := [
    "reminisc", "hushroom", "paneic", "squish", "sentimint",
    "repeato", "toadally", "punkin", "nullaby", "quibble",
    "margin", "lookey", "remembran",
]

func test_new_mob_count() -> void:
    var ids := EnemyLibrary.ids()
    TestHelper.eq(ids.size(), 24, "EnemyLibrary must have 24 entries (21 mobs + 3 bosses)")

func test_each_new_mob_has_required_keys() -> void:
    var required := ["id", "name", "hp", "atk", "def", "acts",
                     "spare_after", "intro_line", "attack_lines",
                     "sprite_id", "patterns"]
    for mob_id in NEW_IDS:
        var e: Dictionary = EnemyLibrary.get_enemy(mob_id)
        TestHelper.is_true(not e.is_empty(), "%s must be defined" % mob_id)
        for k in required:
            TestHelper.is_true(e.has(k), "%s missing key '%s'" % [mob_id, k])
        TestHelper.is_true(e.acts.size() >= 1, "%s must have >=1 ACT" % mob_id)
        TestHelper.is_true(e.attack_lines.size() >= 1, "%s must have >=1 attack line" % mob_id)
        TestHelper.is_true(e.patterns.size() >= 1, "%s must have >=1 pattern" % mob_id)

func test_patterns_resolve_to_bullets() -> void:
    var heart := Vector2(160, 120)
    for mob_id in NEW_IDS:
        var e: Dictionary = EnemyLibrary.get_enemy(mob_id)
        for p in e.patterns:
            var bullets := BulletPatterns.make(p, heart)
            TestHelper.is_true(bullets.size() > 0,
                "%s pattern '%s' must produce bullets" % [mob_id, p])