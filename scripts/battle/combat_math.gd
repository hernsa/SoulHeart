class_name CombatMath

static func calculate_damage(atk: int, defense: int, intent: float) -> int:
	var base := maxi(1, atk - defense)
	return maxi(1, int(round(float(base) * clampf(intent, 0.0, 1.0))))

static func clamp_to_box(pos: Vector2, box: Rect2) -> Vector2:
	return Vector2(
		clampf(pos.x, box.position.x, box.position.x + box.size.x - 1.0),
		clampf(pos.y, box.position.y, box.position.y + box.size.y - 1.0)
	)

static func clamp_to_box_inset(pos: Vector2, box: Rect2, left: float, top: float, right: float, bottom: float) -> Vector2:
	var inner: Rect2 = Rect2(box.position + Vector2(left, top), box.size - Vector2(left - right, top - bottom))
	return clamp_to_box(pos, inner)

static func circle_hit(center_a: Vector2, radius_a: float, center_b: Vector2, radius_b: float) -> bool:
	var r := radius_a + radius_b
	return center_a.distance_squared_to(center_b) <= r * r

static func drain_toward(current: float, target: float, delta: float, rate: float = 40.0) -> float:
	var step := rate * delta
	if current > target:
		return maxf(target, current - step)
	return minf(target, current + step)
