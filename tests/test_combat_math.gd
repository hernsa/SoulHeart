extends RefCounted

func test_damage_formula() -> void:
	TestHelper.eq(CombatMath.calculate_damage(3, 0, 1.0), 3, "atk minus def at full intent")
	TestHelper.eq(CombatMath.calculate_damage(3, 1, 1.0), 2, "defense reduces")
	TestHelper.eq(CombatMath.calculate_damage(1, 5, 1.0), 1, "never below 1")
	TestHelper.eq(CombatMath.calculate_damage(4, 0, 0.5), 2, "half intent")
	TestHelper.eq(CombatMath.calculate_damage(4, 0, 0.0), 1, "zero intent floors at 1")

func test_clamp_to_box() -> void:
	var box := Rect2(200, 60, 240, 220)
	TestHelper.eq(CombatMath.clamp_to_box(Vector2(320, 170), box), Vector2(320, 170), "inside unchanged")
	TestHelper.eq(CombatMath.clamp_to_box(Vector2(100, 170), box), Vector2(200, 170), "clamp left")
	TestHelper.eq(CombatMath.clamp_to_box(Vector2(320, 10), box), Vector2(320, 60), "clamp top")
	TestHelper.eq(CombatMath.clamp_to_box(Vector2(900, 900), box), Vector2(439, 279), "clamp right-bottom")

func test_circle_hit() -> void:
	TestHelper.is_true(CombatMath.circle_hit(Vector2(0, 0), 4.0, Vector2(3, 0), 3.0), "overlapping")
	TestHelper.is_true(CombatMath.circle_hit(Vector2(0, 0), 4.0, Vector2(7, 0), 3.0), "touching edges")
	TestHelper.is_true(not CombatMath.circle_hit(Vector2(0, 0), 4.0, Vector2(8, 0), 3.0), "apart")

func test_clamp_to_box_inset_basic() -> void:
	var box: Rect2 = Rect2(32, 250, 570, 135)
	var p: Vector2 = CombatMath.clamp_to_box_inset(Vector2(0, 0), box, 4.0, 4.0, -16.0, -16.0)
	TestHelper.eq(p, Vector2(36, 254), "inset clamps left/top")
	var q: Vector2 = CombatMath.clamp_to_box_inset(Vector2(1000, 1000), box, 4.0, 4.0, -16.0, -16.0)
	TestHelper.eq(q, Vector2(585, 368), "inset clamps right/bottom")

func test_clamp_to_box_inset_inside_unchanged() -> void:
	var box: Rect2 = Rect2(32, 250, 570, 135)
	var p: Vector2 = CombatMath.clamp_to_box_inset(Vector2(300, 300), box, 4.0, 4.0, -16.0, -16.0)
	TestHelper.eq(p, Vector2(300, 300), "inside stays put")
