extends RefCounted

func _ensure_actions() -> void:
	for a in ["move_left", "move_right", "move_up", "move_down"]:
		if not InputMap.has_action(a):
			InputMap.add_action(a)

func _make_box() -> DodgeBox:
	var box: DodgeBox = preload("res://scripts/battle/dodge_box.gd").new()
	box._ready()
	return box

func _hit_bullet(box: DodgeBox) -> Dictionary:
	return {"pos": box.heart_position() + Vector2(3, 0), "vel": Vector2.ZERO, "life": 4.0}

func test_invuln_time_is_one_second() -> void:
	var box := _make_box()
	box.set_active(true)
	box.spawn_patterns([_hit_bullet(box)])
	box._process(0.016)
	TestHelper.is_true(box.invuln > 0.9, "hit grants ~1s invuln")
	box.free()

func test_heart_flickers_during_invuln() -> void:
	_ensure_actions()
	var box := _make_box()
	box.set_active(true)
	box.spawn_patterns([_hit_bullet(box)])
	box.heart.visible = true
	box._process(0.016)
	TestHelper.is_true(box.invuln > 0.0, "hit happened")
	var saw_hidden := false
	for i in 20:
		box._process(0.05)
		if not box.heart.visible:
			saw_hidden = true
			break
	TestHelper.is_true(saw_hidden, "heart hides at least once during invuln")
	box.free()

func test_knockback_moves_heart_away_from_bullet() -> void:
	_ensure_actions()
	var box := _make_box()
	box.set_active(true)
	box.spawn_patterns([{"pos": box.heart_position() + Vector2(-4, 0), "vel": Vector2.ZERO, "life": 4.0}])
	box._process(0.016)
	TestHelper.is_true(box.heart.position.x > 319.0, "heart pushed away from bullet")
	box.free()

func test_stagger_freezes_heart_input() -> void:
	_ensure_actions()
	var box := _make_box()
	box.set_active(true)
	box.spawn_patterns([_hit_bullet(box)])
	box._process(0.016)
	var before_pos := box.heart.position
	Input.action_press("move_right")
	box._process(0.1)
	Input.action_release("move_right")
	TestHelper.eq(box.heart.position, before_pos, "heart frozen during stagger")
	box.free()

func test_no_double_hit_during_full_invuln() -> void:
	_ensure_actions()
	var box := _make_box()
	box.set_active(true)
	box.spawn_patterns([_hit_bullet(box)])
	var counter := {"hits": 0}
	box.player_hit.connect(func() -> void: counter["hits"] += 1)
	for i in 15:
		box._process(0.05)
	TestHelper.eq(counter["hits"], 1, "one hit total during full invuln window")
	box.free()
