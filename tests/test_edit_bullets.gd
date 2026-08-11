extends RefCounted

func _ensure_actions() -> void:
	for a in ["move_left", "move_right", "move_up", "move_down"]:
		if not InputMap.has_action(a):
			InputMap.add_action(a)

func test_edit_pattern_spawns_edit_bullets() -> void:
	var items := BulletPatterns.make(
			{"type": "edit", "count": 4, "speed": 90.0, "rule": Bullet.Rule.BLUE, "edit_at": 0.5},
			Vector2(319, 305))
	TestHelper.eq(items.size(), 4, "edit pattern makes 4 bullets")
	for d in items:
		TestHelper.eq(d.get("behavior"), "edit", "bullet uses edit behavior")
		var ed: float = d.get("edit_at", -1.0)
		TestHelper.is_true(ed > 0.0, "edit_at set positive")
		var er: int = d.get("edit_rule", -1)
		TestHelper.eq(er, Bullet.Rule.ORANGE, "BLUE toggles to ORANGE")
		var bt: int = d.get("type", -1)
		TestHelper.eq(bt, Bullet.Type.PELLET, "base type preserved")
		var ev: Vector2 = d.get("edit_vel", Vector2.ZERO)
		TestHelper.is_true(ev.length() > 0.0, "edit velocity non-zero")
		var br: int = d.get("rule", -1)
		TestHelper.eq(br, Bullet.Rule.BLUE, "base rule stays BLUE")

func test_edit_toggle_reverses_orange_to_blue() -> void:
	var items := BulletPatterns.make(
			{"type": "edit", "count": 2, "speed": 60.0, "rule": Bullet.Rule.ORANGE},
			Vector2(319, 305))
	for d in items:
		var er: int = d.get("edit_rule", -1)
		TestHelper.eq(er, Bullet.Rule.BLUE, "ORANGE toggles to BLUE")

func test_edit_at_staggered_per_index() -> void:
	var items := BulletPatterns.make(
			{"type": "edit", "count": 4, "speed": 90.0, "rule": Bullet.Rule.ORANGE, "edit_at": 0.5},
			Vector2(319, 305))
	var first: float = items[0].get("edit_at", -1.0)
	var last: float = items[3].get("edit_at", -1.0)
	TestHelper.is_true(last > first, "later bullets edit later")

func test_setup_reads_edit_fields_only_for_edit_behavior() -> void:
	var b := Bullet.new()
	b.setup({"pos": Vector2(300, 300), "vel": Vector2(0, 80), "life": 4.0, "size": 3.0})
	TestHelper.eq(b.edit_at, -1.0, "non-edit bullet keeps edit_at default")
	TestHelper.eq(b.edited, false, "non-edit bullet not flagged edited")
	b.free()
	b = Bullet.new()
	b.setup({"pos": Vector2(300, 300), "vel": Vector2(0, 80), "life": 4.0, "size": 3.0,
			"behavior": "edit", "edit_at": 0.7, "edit_btype": Bullet.Type.ARROW,
			"edit_rule": Bullet.Rule.ORANGE, "edit_vel": Vector2(40, 0)})
	TestHelper.eq(b.edit_at, 0.7, "edit_at read from dict")
	TestHelper.eq(b.edit_btype, Bullet.Type.ARROW, "edit_btype read from dict")
	TestHelper.eq(b.edit_rule, Bullet.Rule.ORANGE, "edit_rule read from dict")
	TestHelper.eq(b.edit_vel, Vector2(40, 0), "edit_vel read from dict")
	TestHelper.eq(b.edited, false, "starts unedited")
	TestHelper.is_true(b._sprite != null, "sprite reference stored")
	b.free()

func test_apply_edit_swaps_and_retextures() -> void:
	var b := Bullet.new()
	b.setup({"pos": Vector2(300, 300), "vel": Vector2(0, 80), "life": 4.0, "size": 3.0,
			"behavior": "edit", "edit_at": 0.5, "edit_btype": Bullet.Type.ARROW,
			"edit_rule": Bullet.Rule.BLUE, "edit_vel": Vector2(-80, 0)})
	var t_before: Texture2D = b._sprite.texture
	b._apply_edit()
	TestHelper.eq(b.edited, true, "flagged edited after apply")
	TestHelper.eq(b.btype, Bullet.Type.ARROW, "type swapped to edit_btype")
	TestHelper.eq(b.rule, Bullet.Rule.BLUE, "rule swapped to edit_rule")
	TestHelper.eq(b.vel, Vector2(-80, 0), "velocity swapped to edit_vel")
	TestHelper.is_true(b._sprite.texture != t_before and b._sprite.texture != null,
			"sprite re-textured to new type")
	b._apply_edit()
	TestHelper.eq(b.vel, Vector2(-80, 0), "second apply is a no-op")
	b.free()

func test_dodge_box_edit_arm_flips_midflight() -> void:
	_ensure_actions()
	var box: DodgeBox = preload("res://scripts/battle/dodge_box.gd").new()
	box._ready()
	box.set_active(true)
	var edit_vel := Vector2(0, 50).rotated(PI * 0.5)
	box.spawn_patterns([{"pos": Vector2(319, 317), "vel": Vector2(0, 50), "life": 8.0, "size": 3.0,
			"behavior": "edit", "edit_at": 0.5, "edit_rule": Bullet.Rule.ORANGE,
			"edit_vel": edit_vel}])
	var b: Bullet = box.bullets[0]
	for i in 4:
		box._process(0.1)
	TestHelper.is_true(not b.edited, "still unedited before threshold")
	TestHelper.eq(int(b.rule), Bullet.Rule.NONE, "rule unchanged before edit")
	TestHelper.is_true(absf(b.position.y - 337.0) < 0.01, "flew straight before edit")
	box._process(0.1)
	TestHelper.is_true(b.edited, "edits at threshold")
	TestHelper.eq(int(b.rule), Bullet.Rule.ORANGE, "rule toggled after edit")
	TestHelper.is_true(b.position.x < 319.0, "now moving along edited velocity")
	box._process(0.1)
	TestHelper.is_true(b.position.x < 314.0, "continues on edited velocity")
	box.free()