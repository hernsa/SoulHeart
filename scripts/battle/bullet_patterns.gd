class_name BulletPatterns

static func make(pattern: Dictionary, heart_pos: Vector2) -> Array[Dictionary]:
	var origin: Vector2 = pattern.get("origin", Vector2(317, 317))
	var rule := int(pattern.get("rule", Bullet.Rule.NONE))
	var base_type := int(pattern.get("type_override", Bullet.Type.PELLET))
	var dir_arr: Array = pattern.get("dir", [0.0, 1.0])
	var dir := Vector2(float(dir_arr[0]), float(dir_arr[1])).normalized()
	var count := int(pattern.get("count", 5))
	var speed := float(pattern.get("speed", 100.0))
	match str(pattern.get("type", "burst")):
		"fan":
			return _with_rule(fan(count, float(pattern.get("spread", 60.0)), speed, dir, origin), rule, base_type)
		"aimed":
			return _with_rule(_aimed(count, speed, origin, heart_pos), rule, base_type)
		"sine":
			return _with_rule(_sine_row(count, speed, dir, origin), rule, base_type)
		"ring":
			return _with_rule(_ring(count, speed, origin), rule, base_type)
		"spiral":
			return _with_rule(_spiral(count, speed, origin), rule, base_type)
		"bone_wall":
			return _with_rule(_bone_wall(count, speed, origin), rule, Bullet.Type.BONE)
		"spear_volley":
			return _with_rule(_spear_volley(count, speed, origin), rule, Bullet.Type.SPEAR)
		"laser_sweep":
			return _with_rule(_laser_sweep(count, origin), rule, Bullet.Type.LASER)
		"weave":
			return _with_rule(_weave(count, speed, dir, origin), rule, base_type)
		"wall":
			return _with_rule(_wall(count, speed, origin, heart_pos), rule, Bullet.Type.BONE)
		"beam_sweep":
			return _with_rule(_beam_sweep(count, origin), rule, Bullet.Type.LASER)
		"rain":
			return _with_rule(_rain(count, speed, origin), rule, base_type)
		"bait":
			return _with_rule(_bait(count, speed, origin, heart_pos), rule, base_type)
		"homing":
			return _with_rule(_homing(count, speed, origin), rule, base_type)
		"green_heal":
			return _green_heal(count, speed, origin)
		"gray_pass":
			return _gray_pass(count, speed, origin, heart_pos)
		"edit":
			return _edit(count, float(pattern.get("speed", 90.0)), rule, base_type,
					float(pattern.get("edit_at", 0.5)), origin, heart_pos)
		_:
			return _with_rule(burst(count, speed, dir, origin), rule, base_type)

static func _with_rule(items: Array[Dictionary], rule: int, btype: int) -> Array[Dictionary]:
	for d in items:
		d["rule"] = rule
		d["type"] = btype
	return items

static func burst(count: int, speed: float, direction: Vector2, origin: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in count:
		out.append({"pos": origin, "vel": direction * speed, "life": 4.0, "size": 3.0})
	return out

static func fan(count: int, spread_deg: float, speed: float, direction: Vector2, origin: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if count <= 1:
		return burst(1, speed, direction, origin)
	var base := direction.angle()
	for i in count:
		var t := -0.5 + float(i) / float(count - 1)
		var vel := Vector2.from_angle(base + deg_to_rad(spread_deg) * t) * speed
		out.append({"pos": origin, "vel": vel, "life": 4.0, "size": 3.0})
	return out

static func _aimed(count: int, speed: float, origin: Vector2, heart_pos: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var dir := (heart_pos - origin).normalized()
	var spread := 10.0
	for i in count:
		var t := -0.5 + float(i) / float(maxi(count - 1, 1))
		var vel := dir.rotated(deg_to_rad(spread) * t) * speed
		out.append({"pos": origin, "vel": vel, "life": 4.0, "size": 3.0})
	return out

static func _sine_row(count: int, speed: float, direction: Vector2, origin: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var side := Vector2(-direction.y, direction.x)
	for i in count:
		var pos := origin + side * (i - count / 2.0) * 26.0
		out.append({"pos": pos, "vel": direction * speed, "life": 6.0, "size": 3.0,
				"behavior": "sine", "phase": float(i)})
	return out

static func _ring(count: int, speed: float, origin: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in count:
		var vel := Vector2.from_angle(TAU * float(i) / float(count)) * speed
		out.append({"pos": origin, "vel": vel, "life": 3.0, "size": 3.0})
	return out

static func _spiral(count: int, speed: float, origin: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in count:
		out.append({"pos": origin, "vel": Vector2.ZERO, "life": 4.0, "size": 3.0,
				"behavior": "orbit", "phase": TAU * float(i) / float(count),
				"orbit_center": origin})
	return out

static func _bone_wall(count: int, speed: float, origin: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in count:
		var y := origin.y + (i - count / 2.0) * 30.0
		out.append({"pos": Vector2(origin.x, y), "vel": Vector2(0, speed), "life": 3.0,
				"size": 6.0})
	return out

static func _spear_volley(count: int, speed: float, origin: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in count:
		var x := origin.x + (i - count / 2.0) * 60.0
		out.append({"pos": Vector2(x, origin.y), "vel": Vector2(0, speed), "life": 2.0,
				"size": 4.0, "behavior": "gravity"})
	return out

static func _laser_sweep(count: int, origin: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var start_y := origin.y - float(count - 1) * 45.0
	for i in count:
		out.append({"pos": Vector2(-40.0, start_y + i * 90.0), "vel": Vector2(180.0, 0.0),
				"life": 5.0, "size": 8.0})
	return out

static func _weave(count: int, speed: float, direction: Vector2, origin: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var side := Vector2(-direction.y, direction.x)
	for i in count:
		var pos := origin + side * (i - count / 2.0) * 22.0
		out.append({"pos": pos, "vel": direction * speed, "life": 6.0, "size": 3.0,
				"behavior": "sine", "phase": float(i) * PI})
	return out

static func _wall(count: int, speed: float, origin: Vector2, heart_pos: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var gap_y := heart_pos.y
	var start := origin.y - float(count) * 14.0
	for i in count:
		var y := start + i * 28.0
		if absf(y - gap_y) < 30.0:
			continue
		out.append({"pos": Vector2(origin.x - 340.0, y), "vel": Vector2(speed, 0.0),
				"life": 5.0, "size": 6.0, "type": Bullet.Type.BONE})
	return out

static func _beam_sweep(count: int, origin: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in count:
		var radius := 10.0 + float(i) * 14.0
		out.append({"pos": origin, "vel": Vector2.ZERO, "life": 3.5, "size": 8.0,
				"type": Bullet.Type.LASER, "behavior": "orbit",
				"phase": 0.0, "orbit_center": origin,
				"orbit_radius": radius, "orbit_speed": 1.2})
	return out

static func _rain(count: int, speed: float, origin: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in count:
		var x := randf_range(origin.x - 140.0, origin.x + 140.0)
		out.append({"pos": Vector2(x, origin.y - 170.0), "vel": Vector2(0.0, speed * 0.6),
				"life": 3.0, "size": 3.0, "behavior": "gravity",
				"delay": float(i) * 0.15})
	return out

static func _bait(count: int, speed: float, origin: Vector2, heart_pos: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var dir := (heart_pos - origin).normalized()
	for i in count:
		var t := -0.5 + float(i) / float(maxi(count - 1, 1))
		var vel := dir.rotated(deg_to_rad(14.0) * t) * speed
		out.append({"pos": origin, "vel": vel, "life": 4.0, "size": 3.0, "delay": 0.7})
	return out

static func _homing(count: int, speed: float, origin: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in count:
		out.append({"pos": origin + Vector2((i - count / 2.0) * 30.0, -40.0),
				"vel": Vector2(0.0, speed), "life": 5.0, "size": 3.0, "behavior": "homing"})
	return out

static func _green_heal(count: int, speed: float, origin: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in count:
		var angle := TAU * float(i) / float(count)
		var vel := Vector2.from_angle(angle) * speed
		out.append({"pos": origin, "vel": vel, "life": 4.0, "size": 4.0,
				"type": Bullet.Type.RING, "rule": Bullet.Rule.GREEN})
	return out

static func _gray_pass(count: int, speed: float, origin: Vector2, heart_pos: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var dir := (heart_pos - origin).normalized()
	for i in count:
		var t := -0.5 + float(i) / float(maxi(count - 1, 1))
		out.append({"pos": origin + Vector2(0.0, -60.0),
				"vel": dir.rotated(deg_to_rad(8.0) * t) * speed,
				"life": 5.0, "size": 3.0, "rule": Bullet.Rule.GRAY})
	return out

static func _edit(count: int, speed: float, rule: int, btype: int, edit_at: float,
		origin: Vector2, heart_pos: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in count:
		var angle := (TAU / count) * i
		var vel := Vector2.from_angle(angle) * speed
		out.append({
			"pos": heart_pos, "vel": vel, "life": 4.0, "size": 3.0,
			"type": btype, "rule": rule,
			"behavior": "edit",
			"edit_at": edit_at + i * 0.08,
			"edit_btype": btype,
			"edit_rule": Bullet.Rule.ORANGE if rule == Bullet.Rule.BLUE else Bullet.Rule.BLUE,
			"edit_vel": vel.rotated(PI * 0.5),
			"phase": 0.0,
		})
	return out
