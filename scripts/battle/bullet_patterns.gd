class_name BulletPatterns

static func make(pattern: Dictionary) -> Array[Dictionary]:
	var dir_arr: Array = pattern.get("dir", [0.0, 1.0])
	var dir := Vector2(float(dir_arr[0]), float(dir_arr[1])).normalized()
	var count := int(pattern.get("count", 5))
	var speed := float(pattern.get("speed", 100.0))
	match str(pattern.get("type", "burst")):
		"fan":
			return fan(count, float(pattern.get("spread", 60.0)), speed, dir)
		_:
			return burst(count, speed, dir)

static func burst(count: int, speed: float, direction: Vector2, origin := Vector2(320, 90)) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in count:
		out.append({"pos": origin, "vel": direction * speed, "life": 4.0, "size": 3.0})
	return out

static func fan(count: int, spread_deg: float, speed: float, direction: Vector2, origin := Vector2(320, 90)) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if count <= 1:
		return burst(1, speed, direction, origin)
	var base := direction.angle()
	for i in count:
		var t := -0.5 + float(i) / float(count - 1)
		var vel := Vector2.from_angle(base + deg_to_rad(spread_deg) * t) * speed
		out.append({"pos": origin, "vel": vel, "life": 4.0, "size": 3.0})
	return out
