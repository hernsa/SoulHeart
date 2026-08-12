class_name DodgeBox
extends Control

signal player_hit
signal heal_requested(amount: int)

const HEART_SPEED := 128.0
const BOX_RECT := Rect2(162, 220, 316, 190)
const BOX_INNER := Rect2(167, 225, 306, 180)
const HEART_START := Vector2(320, 315)
const INVULN_TIME := 1.0
const STAGGER_TIME := 0.2
const KNOCKBACK := 6.0
const GRAVITY := 900.0
const JUMP_VEL := -330.0
const RAIL_COUNT := 4
const YELLOW_FIRE_CD := 0.35

var heart: Sprite2D
var bullets: Array = []
var invuln := 0.0
var active := false
var mode := "red"
var _stagger := 0.0
var last_heart_pos := HEART_START
var _soul_vel := Vector2.ZERO
var _rail_index := 2
var _shield_dir := Vector2.UP
var _yellow_cd := 0.0
var _shots: Array = []

func _ready() -> void:
	size = Vector2(640, 480)
	_build_frame()
	heart = Sprite2D.new()
	heart.texture = Sprites.soul_texture("Red")
	heart.position = HEART_START
	add_child(heart)
	visible = false

func _build_frame() -> void:
	var white := Color(1, 1, 1)
	for rect in [
			Rect2(BOX_RECT.position, Vector2(BOX_RECT.size.x, 5)),
			Rect2(Vector2(BOX_RECT.position.x, BOX_RECT.end.y - 5), Vector2(BOX_RECT.size.x, 5)),
			Rect2(BOX_RECT.position, Vector2(5, BOX_RECT.size.y)),
			Rect2(Vector2(BOX_RECT.end.x - 5, BOX_RECT.position.y), Vector2(5, BOX_RECT.size.y))]:
		var bar := ColorRect.new()
		bar.color = white
		bar.position = rect.position
		bar.size = rect.size
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bar)

func set_active(a: bool) -> void:
	active = a
	visible = a
	if a:
		position = Vector2(0, 300)
		if is_inside_tree():
			var tw := create_tween()
			tw.tween_property(self, "position", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		position = Vector2.ZERO
		_clear_bullets()

func set_mode(m: String) -> void:
	mode = m
	heart.texture = Sprites.soul_texture(m.capitalize())
	_soul_vel = Vector2.ZERO
	heart.rotation = PI if m == "yellow" else 0.0
	if m == "purple":
		_rail_index = clampi(_rail_index, 0, RAIL_COUNT - 1)
		heart.position.y = _rail_y(_rail_index)
	elif m == "green":
		heart.position = HEART_START
	elif m == "red" or m == "blue":
		heart.position.y = BOX_INNER.end.y - 4.0 if m == "blue" else HEART_START.y

func _rail_y(i: int) -> float:
	var inset := 24.0
	var span := BOX_INNER.size.y - inset * 2.0
	return BOX_INNER.position.y + inset + span * float(i) / float(RAIL_COUNT - 1)

func _cycle_dir(d: Vector2) -> Vector2:
	if d == Vector2.UP: return Vector2.DOWN
	if d == Vector2.DOWN: return Vector2.LEFT
	if d == Vector2.LEFT: return Vector2.RIGHT
	return Vector2.UP

func _fire_yellow() -> void:
	_yellow_cd = YELLOW_FIRE_CD
	var b := Bullet.new()
	b.setup({"pos": heart.position,
			"vel": (Vector2(216, 136) - heart.position).normalized() * 380.0,
			"life": 1.2, "size": 3.0, "type": Bullet.Type.PELLET, "rule": Bullet.Rule.YELLOW})
	add_child(b)
	_shots.append(b)

func spawn_patterns(data: Array[Dictionary]) -> void:
	for d in data:
		var b := Bullet.new()
		b.setup(d)
		add_child(b)
		bullets.append(b)

func heart_position() -> Vector2:
	return heart.position

func has_bullets() -> bool:
	return bullets.size() > 0

func _process(delta: float) -> void:
	if not active:
		return
	invuln = maxf(0.0, invuln - delta)
	_stagger = maxf(0.0, _stagger - delta)
	heart.visible = (invuln <= 0.0) or (int(invuln * 10.0) % 2 == 0)
	for b in bullets:
		if b.delay > 0.0:
			b.delay -= delta
			if b.delay <= 0.0:
				b._sprite.visible = true
			continue
		b.phase += delta
		match b.behavior:
			"sine":
				b.position += b.vel * delta
				b.position.y += sin(b.phase * 6.0) * 40.0 * delta
			"homing":
				var to: Vector2 = (heart.position - b.position).normalized() * b.vel.length()
				b.vel = b.vel.move_toward(to, 60.0 * delta)
				b.position += b.vel * delta
			"gravity":
				b.vel.y += 120.0 * delta
				b.position += b.vel * delta
			"orbit":
				b.position = b.orbit_center + Vector2.from_angle(b.phase * b.orbit_speed) * b.orbit_radius
			"edit":
				if not b.edited and b.phase >= b.edit_at:
					b._apply_edit()
				b.position += b.vel * delta
			_:
				b.position += b.vel * delta
		b.life -= delta
	if _stagger > 0.0:
		_remove_dead()
		return
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	match mode:
		"blue":
			_soul_vel.y += GRAVITY * delta
			if Input.is_action_just_pressed("confirm") and heart.position.y >= BOX_INNER.end.y - 6.0:
				_soul_vel.y = JUMP_VEL
			heart.position.x = clampf(heart.position.x + input.x * HEART_SPEED * 0.8 * delta,
					BOX_INNER.position.x, BOX_INNER.end.x)
			heart.position.y = clampf(heart.position.y + _soul_vel.y * delta,
					BOX_INNER.position.y, BOX_INNER.end.y - 4.0)
			if heart.position.y >= BOX_INNER.end.y - 4.0:
				_soul_vel.y = 0.0
		"purple":
			if Input.is_action_just_pressed("move_up") and _rail_index > 0:
				_rail_index -= 1
			elif Input.is_action_just_pressed("move_down") and _rail_index < RAIL_COUNT - 1:
				_rail_index += 1
			heart.position.y = move_toward(heart.position.y, _rail_y(_rail_index), 260.0 * delta)
			heart.position.x = clampf(heart.position.x + input.x * HEART_SPEED * delta,
					BOX_INNER.position.x, BOX_INNER.end.x)
		"green":
			if Input.is_action_just_pressed("confirm"):
				_shield_dir = _cycle_dir(_shield_dir)
		"yellow":
			heart.position = CombatMath.clamp_to_box(heart.position + input * HEART_SPEED * delta, BOX_INNER)
			_yellow_cd -= delta
			if Input.is_action_just_pressed("confirm") and _yellow_cd <= 0.0:
				_fire_yellow()
		_:
			heart.position = CombatMath.clamp_to_box(heart.position + input * HEART_SPEED * delta, BOX_INNER)
	for s in _shots:
		s.position += s.vel * delta
	var heart_vel := (heart.position - last_heart_pos) / delta
	last_heart_pos = heart.position
	var hit_bullet: Bullet = null
	for b in bullets:
		if b.dead():
			continue
		if mode == "green":
			var to_b: Vector2 = (b.position - heart.position)
			if to_b.length() > 0.0 and (to_b / to_b.length()).dot(_shield_dir) > 0.7:
				b.life = 0.0
				continue
		var hit := CombatMath.circle_hit(heart.position, maxf(heart.texture.get_width(), heart.texture.get_height()) * 0.45, b.position, b.size)
		if hit and _bullet_damages(b, heart_vel):
			hit_bullet = b
			break
		elif hit and b.rule == Bullet.Rule.GREEN:
			heal_requested.emit(2)
			b.life = 0.0
	if hit_bullet != null and invuln <= 0.0:
		_on_hit()
		var away := (heart.position - hit_bullet.position).normalized()
		heart.position = CombatMath.clamp_to_box(heart.position + away * KNOCKBACK, BOX_INNER)
	var keep_shots: Array = []
	for s in _shots:
		var hit_target: Bullet = null
		for b in bullets:
			if not b.dead() and CombatMath.circle_hit(s.position, 3.0, b.position, b.size):
				hit_target = b
				break
		if hit_target != null:
			hit_target.life = 0.0
			s.queue_free()
			Audio.play_sfx("whoosh")
		elif BOX_RECT.grow(4.0).has_point(s.position):
			keep_shots.append(s)
		else:
			s.queue_free()
	_shots = keep_shots
	_remove_dead()

func _on_hit() -> void:
	invuln = INVULN_TIME
	_stagger = STAGGER_TIME
	player_hit.emit()

func _bullet_damages(b: Bullet, heart_vel: Vector2) -> bool:
	match b.rule:
		Bullet.Rule.GRAY:
			return false
		Bullet.Rule.GREEN:
			return false
		Bullet.Rule.BLUE:
			return heart_vel.length() > 8.0
		Bullet.Rule.ORANGE:
			return heart_vel.length() <= 8.0
	return true

func show_telegraph(duration: float) -> void:
	Audio.play_sfx("warn")
	var frame := ColorRect.new()
	frame.color = Color(1, 0, 0, 0.25)
	frame.position = BOX_RECT.position + Vector2(40, 20)
	frame.size = BOX_RECT.size - Vector2(80, 40)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	var label := Label.new()
	label.text = "!"
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	label.position = frame.position + frame.size / 2 - Vector2(10, 24)
	frame.add_child(label)
	await get_tree().create_timer(duration).timeout
	frame.queue_free()

func _remove_dead() -> void:
	var keep: Array = []
	for b in bullets:
		var on_screen := BOX_RECT.grow(4.0).has_point(b.position)
		var entering: bool = b.phase < 1.5 and BOX_RECT.grow(100.0).has_point(b.position)
		if not b.dead() and (on_screen or entering):
			keep.append(b)
		else:
			b.queue_free()
	bullets = keep

func fade_out_bullets() -> void:
	for b in bullets:
		if is_inside_tree():
			var tw := create_tween()
			tw.tween_property(b, "modulate:a", 0.0, 0.4)
			tw.tween_callback(b.queue_free)
		else:
			b.queue_free()
	bullets = []
	for s in _shots:
		s.queue_free()
	_shots = []

func _clear_bullets() -> void:
	for b in bullets:
		b.queue_free()
	bullets = []
	for s in _shots:
		s.queue_free()
	_shots = []
