extends RefCounted

func test_bullet_textures_are_distinct() -> void:
	var seen := {}
	for t in [0, 1, 2, 3, 4, 5]:
		var tex := Sprites.bullet_texture_for(t)
		TestHelper.is_true(tex != null, "bullet texture exists for type " + str(t))
		if tex == null:
			continue
		seen[hash(tex.get_image().get_data())] = true
	TestHelper.eq(seen.size(), 6, "six distinct bullet textures")

func test_setup_reads_type_and_rule() -> void:
	var b := Bullet.new()
	b.setup({"pos": Vector2(10, 10), "vel": Vector2(0, 100), "life": 3.0,
			"size": 4.0, "type": Bullet.Type.BONE, "rule": Bullet.Rule.BLUE,
			"behavior": "sine", "phase": 1.0, "orbit_center": Vector2(100, 100)})
	TestHelper.eq(b.btype, Bullet.Type.BONE, "type parsed")
	TestHelper.eq(b.rule, Bullet.Rule.BLUE, "rule parsed")
	TestHelper.eq(b.behavior, "sine", "behavior parsed")
	TestHelper.eq(b.position, Vector2(10, 10), "position set")
	b.free()
