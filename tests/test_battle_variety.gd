extends RefCounted

func _make_dbox() -> DodgeBox:
	var d := DodgeBox.new()
	d._ready()
	return d

func test_tint_per_rule() -> void:
	var b := Bullet.new()
	b.setup({"rule": Bullet.Rule.BLUE, "pos": Vector2.ZERO, "vel": Vector2.ZERO})
	TestHelper.eq(b._sprite.modulate, Color(0.35, 0.85, 1.0), "blue tint")
	b.free()
	b = Bullet.new()
	b.setup({"rule": Bullet.Rule.ORANGE, "pos": Vector2.ZERO, "vel": Vector2.ZERO})
	TestHelper.eq(b._sprite.modulate, Color(1.0, 0.6, 0.2), "orange tint")
	b.free()
	b = Bullet.new()
	b.setup({"rule": Bullet.Rule.GRAY, "pos": Vector2.ZERO, "vel": Vector2.ZERO})
	TestHelper.eq(b._sprite.modulate, Color(0.55, 0.55, 0.55), "gray tint")
	b.free()
	b = Bullet.new()
	b.setup({"rule": Bullet.Rule.GREEN, "pos": Vector2.ZERO, "vel": Vector2.ZERO})
	TestHelper.eq(b._sprite.modulate, Color(0.4, 1.0, 0.4), "green tint")
	b.free()
	b = Bullet.new()
	b.setup({"rule": Bullet.Rule.YELLOW, "pos": Vector2.ZERO, "vel": Vector2.ZERO})
	TestHelper.eq(b._sprite.modulate, Color(1.0, 1.0, 0.3), "yellow tint")
	b.free()

func test_delay_hides_sprite() -> void:
	var b := Bullet.new()
	b.setup({"delay": 1.0, "pos": Vector2.ZERO, "vel": Vector2.ZERO})
	TestHelper.is_true(not b._sprite.visible, "delayed bullet hidden")
	TestHelper.eq(b.delay, 1.0, "delay stored")
	b.free()
	b = Bullet.new()
	b.setup({"pos": Vector2.ZERO, "vel": Vector2.ZERO})
	TestHelper.is_true(b._sprite.visible, "undelayed bullet visible")
	b.free()

func test_new_pattern_types() -> void:
	var weave := BulletPatterns.make({"type": "weave", "count": 5, "speed": 80.0,
			"rule": Bullet.Rule.BLUE}, Vector2(320, 305))
	TestHelper.eq(weave.size(), 5, "weave count")
	TestHelper.is_true(weave[0]["rule"] == Bullet.Rule.BLUE, "weave rule stamp")
	TestHelper.eq(str(weave[0]["behavior"]), "sine", "weave behavior")
	var wall := BulletPatterns.make({"type": "wall", "count": 9, "speed": 80.0},
			Vector2(320, 305))
	TestHelper.is_true(wall.size() >= 5, "wall count with gap")
	for d in wall:
		TestHelper.eq(int(d["type"]), Bullet.Type.BONE, "wall bone type")
	TestHelper.eq((wall[0]["vel"] as Vector2).x, 80.0, "wall speed")
	var beams := BulletPatterns.make({"type": "beam_sweep", "count": 10}, Vector2(320, 305))
	TestHelper.eq(beams.size(), 10, "beam count")
	TestHelper.eq(int(beams[0]["type"]), Bullet.Type.LASER, "beam laser type")
	TestHelper.eq(str(beams[0]["behavior"]), "orbit", "beam orbit")
	TestHelper.eq(float(beams[0]["orbit_radius"]), 10.0, "beam radius starts small")
	TestHelper.eq(float(beams[0]["orbit_speed"]), 1.2, "beam orbit speed")
	var rain := BulletPatterns.make({"type": "rain", "count": 8, "speed": 70.0},
			Vector2(320, 305))
	TestHelper.eq(rain.size(), 8, "rain count")
	TestHelper.is_true(float(rain[0]["delay"]) == 0.0 and float(rain[1]["delay"]) > 0.0,
			"rain staggered delays")
	TestHelper.eq(str(rain[0]["behavior"]), "gravity", "rain gravity")
	var bait := BulletPatterns.make({"type": "bait", "count": 4, "speed": 90.0},
			Vector2(320, 305))
	TestHelper.eq(bait.size(), 4, "bait count")
	TestHelper.eq(float(bait[0]["delay"]), 0.7, "bait delay")
	var homing := BulletPatterns.make({"type": "homing", "count": 5, "speed": 50.0},
			Vector2(320, 305))
	TestHelper.eq(homing.size(), 5, "homing count")
	TestHelper.eq(str(homing[0]["behavior"]), "homing", "homing behavior")

func test_heal_and_pass_rules() -> void:
	var heal := BulletPatterns.make({"type": "green_heal", "count": 6, "speed": 60.0},
			Vector2(320, 305))
	TestHelper.eq(heal.size(), 6, "green_heal count")
	TestHelper.eq(int(heal[0]["type"]), Bullet.Type.RING, "green_heal ring")
	TestHelper.eq(int(heal[0]["rule"]), Bullet.Rule.GREEN, "green_heal rule")
	var passers := BulletPatterns.make({"type": "gray_pass", "count": 6, "speed": 50.0},
			Vector2(320, 305))
	TestHelper.eq(passers.size(), 6, "gray_pass count")
	TestHelper.eq(int(passers[0]["rule"]), Bullet.Rule.GRAY, "gray_pass rule")

func test_laser_sweep_centered_rows() -> void:
	var rows := BulletPatterns.make({"type": "laser_sweep"}, Vector2(317, 317))
	TestHelper.is_true(rows.size() >= 5, "laser rows")
	var ys: Array = []
	for r in rows:
		ys.append((r["pos"] as Vector2).y)
	var max_y: float = ys.max()
	var min_y: float = ys.min()
	TestHelper.is_true(max_y - min_y < 400.0, "rows centered near origin")

func test_enemy_signature_patterns() -> void:
	TestHelper.eq(EnemyLibrary.get_enemy("migosp")["patterns"].size(), 3, "migosp three patterns")
	TestHelper.eq(str(EnemyLibrary.get_enemy("froggit").get("soul_mode", "")), "", "froggit defaults red")
	TestHelper.eq(str(EnemyLibrary.get_enemy("nullaby")["soul_mode"]), "blue", "nullaby blue soul")
	TestHelper.eq(str(EnemyLibrary.get_enemy("margin")["soul_mode"]), "purple", "margin purple soul")
	TestHelper.eq(str(EnemyLibrary.get_enemy("lookey")["soul_mode"]), "green", "lookey green soul")
	var idx := EnemyLibrary.get_enemy("index")
	TestHelper.eq(str(idx["forms"][1]["soul_mode"]), "yellow", "index f2 yellow soul")
	TestHelper.eq(EnemyLibrary.get_enemy("mourning_knight")["patterns"].size(), 4,
			"mourning knight four patterns")
	TestHelper.eq(EnemyLibrary.get_enemy("canon_true")["patterns"].size(), 4,
			"canon four patterns")

func test_apply_form_copies_soul_mode() -> void:
	var target := EnemyLibrary.get_enemy("froggit").duplicate(true)
	EnemyLibrary.apply_form(target, {"soul_mode": "yellow"})
	TestHelper.eq(str(target["soul_mode"]), "yellow", "apply_form copies soul_mode")
	TestHelper.eq(str(EnemyLibrary.get_enemy("froggit").get("soul_mode", "")), "", "library unchanged")

func test_soul_sprites_generated() -> void:
	var red := Sprites.soul_texture("Red")
	TestHelper.is_true(Sprites.soul_texture("Purple") != red, "purple soul distinct")
	TestHelper.is_true(Sprites.soul_texture("Yellow") != red, "yellow soul distinct")

func test_dodgebox_soul_modes() -> void:
	var dbox := _make_dbox()
	dbox.set_mode("purple")
	TestHelper.eq(str(dbox.mode), "purple", "mode set purple")
	TestHelper.is_true(absf(dbox.heart.position.y - dbox._rail_y(2)) < 0.01,
			"purple snaps to rail 2")
	TestHelper.is_true(dbox._rail_y(0) < dbox._rail_y(1) and dbox._rail_y(2) < dbox._rail_y(3),
			"rails ordered")
	dbox.set_mode("green")
	TestHelper.eq(dbox.heart.position, dbox.HEART_START, "green resets heart")
	dbox.set_mode("blue")
	TestHelper.eq(dbox.heart.position.y, dbox.BOX_INNER.end.y - 4.0, "blue on floor")
	dbox.set_mode("yellow")
	TestHelper.is_true(absf(dbox.heart.rotation - PI) < 0.001, "yellow rotated")
	dbox.set_mode("red")
	TestHelper.eq(dbox.heart.rotation, 0.0, "red upright")
	dbox.free()

func test_green_shield_blocks() -> void:
	var dbox := _make_dbox()
	dbox.set_mode("green")
	dbox.set_active(true)
	var pel := Bullet.new()
	pel.setup({"pos": dbox.heart.position + dbox._shield_dir * 20.0,
			"vel": Vector2.ZERO, "life": 4.0})
	dbox.add_child(pel)
	dbox.bullets.append(pel)
	dbox._process(0.016)
	TestHelper.is_true(pel.dead(), "shield destroys bullet from shield dir")
	dbox.free()

func test_yellow_shot_destroys_bullet() -> void:
	var dbox := _make_dbox()
	dbox.set_mode("yellow")
	dbox.set_active(true)
	var pel := Bullet.new()
	var dir: Vector2 = (Vector2(216, 136) - dbox.heart.position).normalized()
	pel.setup({"pos": dbox.heart.position + dir * 30.0, "vel": Vector2.ZERO, "life": 4.0})
	dbox.add_child(pel)
	dbox.bullets.append(pel)
	dbox._fire_yellow()
	TestHelper.eq(dbox._shots.size(), 1, "shot fired")
	for i in 12:
		dbox._process(0.016)
	TestHelper.is_true(pel.dead(), "shot destroyed pellet")
	TestHelper.eq(dbox._shots.size(), 0, "shot consumed")
	dbox.free()

func test_fade_out_bullets_empties() -> void:
	var dbox := _make_dbox()
	dbox.spawn_patterns(BulletPatterns.make({"type": "ring", "count": 6, "speed": 60.0},
			Vector2(320, 305)))
	TestHelper.eq(dbox.bullets.size(), 6, "spawned ring")
	dbox.fade_out_bullets()
	TestHelper.eq(dbox.bullets.size(), 0, "bullets faded out")
	TestHelper.eq(dbox._shots.size(), 0, "shots faded out")
	dbox.free()
