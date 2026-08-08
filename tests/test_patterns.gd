extends RefCounted

func test_burst() -> void:
	var shots := BulletPatterns.burst(5, 100.0, Vector2.DOWN)
	TestHelper.eq(shots.size(), 5, "five bullets")
	for shot in shots:
		TestHelper.eq(shot["vel"], Vector2.DOWN * 100.0, "velocity straight down")
		TestHelper.eq(shot["pos"], Vector2(317, 317), "same origin")
		TestHelper.eq(shot["life"], 4.0, "lifetime")

func test_fan_symmetric_around_direction() -> void:
	var shots := BulletPatterns.fan(7, 60.0, 100.0, Vector2.DOWN)
	TestHelper.eq(shots.size(), 7, "seven bullets")
	var base := Vector2.DOWN.angle()
	var first: float = shots[0]["vel"].angle()
	var last: float = shots[6]["vel"].angle()
	TestHelper.is_true(is_equal_approx(first, base - deg_to_rad(30.0)), "first at -30 deg")
	TestHelper.is_true(is_equal_approx(last, base + deg_to_rad(30.0)), "last at +30 deg")
	TestHelper.is_true(is_equal_approx((first + last) / 2.0, base), "symmetric around base")

func test_fan_single_shot() -> void:
	var shots := BulletPatterns.fan(1, 60.0, 100.0, Vector2.RIGHT)
	TestHelper.eq(shots.size(), 1, "single shot")
	TestHelper.eq(shots[0]["vel"], Vector2.RIGHT * 100.0, "straight along direction")

func test_make_parses_pattern_dict() -> void:
	var shots := BulletPatterns.make({"type": "fan", "count": 3, "spread": 40.0, "speed": 80.0, "dir": [0.0, 1.0]})
	TestHelper.eq(shots.size(), 3, "parsed count")
	TestHelper.is_true(shots[1]["vel"].is_equal_approx(Vector2.DOWN * 80.0), "center bullet straight down")
