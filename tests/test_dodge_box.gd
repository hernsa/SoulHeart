extends RefCounted

func _ensure_actions() -> void:
	for a in ["move_left", "move_right", "move_up", "move_down"]:
		if not InputMap.has_action(a):
			InputMap.add_action(a)

func _make_box() -> DodgeBox:
	var box: DodgeBox = preload("res://scripts/battle/dodge_box.gd").new()
	box._ready()
	return box

func test_bullet_setup_rounds_position() -> void:
	var b := Bullet.new()
	b.setup({"pos": Vector2(10.6, 3.4), "vel": Vector2(1.5, 2.5), "life": 2.0, "size": 3.0})
	TestHelper.eq(b.position, Vector2(11, 3), "position rounded to ints")
	TestHelper.eq(b.vel, Vector2(1.5, 2.5), "velocity kept as-is")
	TestHelper.eq(b.life, 2.0, "life kept as-is")
	TestHelper.eq(b.size, 3.0, "size kept as-is")
	b.free()

func test_bullet_dead_lifecycle() -> void:
	var b := Bullet.new()
	b.setup({"pos": Vector2(0, 0), "vel": Vector2.ZERO, "life": 1.0})
	TestHelper.is_true(not b.dead(), "alive while life > 0")
	b.life = 0.0
	TestHelper.is_true(b.dead(), "dead at life 0")
	b.life = -0.5
	TestHelper.is_true(b.dead(), "dead below zero")
	b.free()

func test_heart_starts_at_center_and_visibility() -> void:
	var box := _make_box()
	TestHelper.eq(box.heart.position, Vector2(320, 170), "heart at box center")
	TestHelper.eq(box.visible, false, "hidden until active")
	TestHelper.eq(box.active, false, "inactive until set_active")
	box.set_active(true)
	TestHelper.eq(box.visible, true, "visible when active")
	TestHelper.eq(box.active, true, "active flag set")
	box.free()

func test_spawn_patterns_adds_bullets() -> void:
	var box := _make_box()
	box.set_active(true)
	box.spawn_patterns([{"pos": Vector2(240, 120), "vel": Vector2(0, 50), "life": 4.0}])
	TestHelper.is_true(box.has_bullets(), "has bullets after spawn")
	TestHelper.eq(box.bullets.size(), 1, "one bullet spawned")
	TestHelper.eq(box.bullets[0].position, Vector2(240, 120), "bullet placed at given pos")
	box.spawn_patterns(BulletPatterns.make({"type": "burst", "count": 3, "speed": 100.0}))
	TestHelper.eq(box.bullets.size(), 4, "pattern output spawns more bullets")
	box.free()

func test_set_active_false_clears_bullets() -> void:
	var box := _make_box()
	box.set_active(true)
	box.spawn_patterns([{"pos": Vector2(240, 120), "vel": Vector2.ZERO, "life": 4.0}])
	TestHelper.is_true(box.has_bullets(), "bullets present while active")
	box.set_active(false)
	TestHelper.is_true(not box.has_bullets(), "bullets cleared on deactivate")
	TestHelper.eq(box.visible, false, "hidden on deactivate")
	box.free()

func test_player_hit_emitted_once_per_invuln() -> void:
	_ensure_actions()
	var box := _make_box()
	box.set_active(true)
	box.spawn_patterns([{"pos": Vector2(320, 170), "vel": Vector2.ZERO, "life": 4.0}])
	var counter := {"hits": 0}
	box.player_hit.connect(func() -> void: counter["hits"] += 1)
	box._process(0.016)
	TestHelper.eq(counter["hits"], 1, "first contact emits player_hit")
	box._process(0.1)
	box._process(0.1)
	box._process(0.1)
	TestHelper.eq(counter["hits"], 1, "no emit while invuln active")
	box.invuln = 0.0
	box._process(0.016)
	TestHelper.eq(counter["hits"], 2, "emits again after invuln expires")
	box.free()

func test_bullet_outside_box_despawns() -> void:
	_ensure_actions()
	var box := _make_box()
	box.set_active(true)
	box.spawn_patterns([{"pos": Vector2(1000, 500), "vel": Vector2.ZERO, "life": 4.0}])
	TestHelper.is_true(box.has_bullets(), "bullet present before tick")
	box._process(0.016)
	TestHelper.is_true(not box.has_bullets(), "bullet outside box removed")
	TestHelper.eq(box.bullets.size(), 0, "bullets array emptied")
	box.free()

func test_dead_bullet_despawns() -> void:
	_ensure_actions()
	var box := _make_box()
	box.set_active(true)
	box.spawn_patterns([{"pos": Vector2(220, 80), "vel": Vector2.ZERO, "life": 0.01}])
	box._process(0.1)
	TestHelper.is_true(not box.has_bullets(), "expired bullet removed")
	box.free()

func test_heart_moves_and_clamps_to_box() -> void:
	_ensure_actions()
	var box := _make_box()
	box.set_active(true)
	Input.action_press("move_right")
	box._process(10.0)
	TestHelper.eq(box.heart.position.x, 439.0, "clamps at right edge")
	Input.action_release("move_right")
	Input.action_press("move_left")
	box._process(10.0)
	TestHelper.eq(box.heart.position.x, 200.0, "clamps at left edge")
	Input.action_release("move_left")
	Input.action_press("move_up")
	box._process(10.0)
	TestHelper.eq(box.heart.position.y, 60.0, "clamps at top edge")
	Input.action_release("move_up")
	Input.action_press("move_down")
	box._process(10.0)
	TestHelper.eq(box.heart.position.y, 279.0, "clamps at bottom edge")
	Input.action_release("move_down")
	box._process(1.0)
	TestHelper.eq(box.heart.position, Vector2(200, 279), "stays put with no input")
	box.free()

func test_inactive_box_ignores_process() -> void:
	_ensure_actions()
	var box := _make_box()
	box.spawn_patterns([{"pos": Vector2(220, 80), "vel": Vector2.ZERO, "life": 4.0}])
	Input.action_press("move_right")
	box._process(1.0)
	Input.action_release("move_right")
	TestHelper.eq(box.heart.position, Vector2(320, 170), "heart unmoved while inactive")
	TestHelper.is_true(box.has_bullets(), "bullets untouched while inactive")
	box.free()
