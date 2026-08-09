extends RefCounted

func test_encounter_shows_enemy_sprite() -> void:
	var enc = load("res://scripts/rooms/encounter.gd").new()
	enc.enemy_id = "froggit"
	enc._ready()
	var spr: Node = enc.get_node_or_null("EnemySprite")
	TestHelper.is_true(spr != null, "enemy sprite node exists")
	if spr != null:
		TestHelper.is_true(spr.texture != null, "sprite has texture")
		TestHelper.eq(spr.scale, Vector2(0.5, 0.5), "sprite scaled 0.5")
		TestHelper.eq(spr.position, Vector2(0, -26), "sprite floats above trigger")
	enc.free()
