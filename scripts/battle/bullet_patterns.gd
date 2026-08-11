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
	for i in count:
		out.append({"pos": Vector2(-40.0, origin.y + i * 90.0), "vel": Vector2(180.0, 0.0),
				"life": 5.0, "size": 8.0})
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
