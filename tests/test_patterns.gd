extends RefCounted

func test_burst() -> void:
	var shots := BulletPatterns.burst(5, 100.0, Vector2.DOWN, Vector2(317, 317))
	TestHelper.eq(shots.size(), 5, "five bullets")
	for shot in shots:
		TestHelper.eq(shot["vel"], Vector2.DOWN * 100.0, "velocity straight down")
		TestHelper.eq(shot["pos"], Vector2(317, 317), "same origin")
		TestHelper.eq(shot["life"], 4.0, "lifetime")

func test_fan_symmetric_around_direction() -> void:
	var shots := BulletPatterns.fan(7, 60.0, 100.0, Vector2.DOWN, Vector2(317, 317))
	TestHelper.eq(shots.size(), 7, "seven bullets")
	var base := Vector2.DOWN.angle()
	var first: float = shots[0]["vel"].angle()
	var last: float = shots[6]["vel"].angle()
	TestHelper.is_true(is_equal_approx(first, base - deg_to_rad(30.0)), "first at -30 deg")
	TestHelper.is_true(is_equal_approx(last, base + deg_to_rad(30.0)), "last at +30 deg")
	TestHelper.is_true(is_equal_approx((first + last) / 2.0, base), "symmetric around base")

func test_fan_single_shot() -> void:
	var shots := BulletPatterns.fan(1, 60.0, 100.0, Vector2.RIGHT, Vector2(317, 317))
	TestHelper.eq(shots.size(), 1, "single shot")
	TestHelper.eq(shots[0]["vel"], Vector2.RIGHT * 100.0, "straight along direction")

func test_make_parses_pattern_dict() -> void:
	var shots := BulletPatterns.make({"type": "fan", "count": 3, "spread": 40.0, "speed": 80.0, "dir": [0.0, 1.0]}, Vector2(317, 300))
	TestHelper.eq(shots.size(), 3, "parsed count")
	TestHelper.is_true(shots[1]["vel"].is_equal_approx(Vector2.DOWN * 80.0), "center bullet straight down")

func test_aimed_bullets_track_heart() -> void:
	var out := BulletPatterns.make({"type": "aimed", "count": 3, "speed": 100.0,
			"origin": Vector2(317, 100)}, Vector2(317, 300))
	TestHelper.eq(out.size(), 3, "three aimed bullets")
	for d in out:
		var vel: Vector2 = d["vel"]
		TestHelper.is_true(vel.y > 0.0, "aimed bullet moves toward heart (down)")

func test_sine_row_has_behavior() -> void:
	var out := BulletPatterns.make({"type": "sine", "count": 5, "speed": 60.0,
			"origin": Vector2(317, 100)}, Vector2(317, 300))
	TestHelper.eq(out.size(), 5, "five sine bullets")
	TestHelper.eq(str(out[0]["behavior"]), "sine", "sine behavior set")

func test_ring_is_radial() -> void:
	var out := BulletPatterns.make({"type": "ring", "count": 12, "speed": 90.0,
			"origin": Vector2(317, 300)}, Vector2(317, 300))
	TestHelper.eq(out.size(), 12, "twelve ring bullets")
	var dirs := {}
	for d in out:
		var v: Vector2 = d["vel"]
		dirs[Vector2(roundi(v.x / 10.0), roundi(v.y / 10.0))] = true
	TestHelper.is_true(dirs.size() >= 8, "radial spread: " + str(dirs.size()))

func test_bone_wall_uses_bone_type() -> void:
	var out := BulletPatterns.make({"type": "bone_wall", "count": 5, "speed": 140.0,
			"origin": Vector2(317, 100)}, Vector2(317, 300))
	for d in out:
		TestHelper.eq(int(d["type"]), Bullet.Type.BONE, "bone wall uses BONE")

func test_spear_volley_uses_gravity() -> void:
	var out := BulletPatterns.make({"type": "spear_volley", "count": 3, "speed": 200.0,
			"origin": Vector2(317, 100)}, Vector2(317, 300))
	for d in out:
		TestHelper.eq(str(d["behavior"]), "gravity", "spears fall")
		TestHelper.eq(int(d["type"]), Bullet.Type.SPEAR, "spears typed")
