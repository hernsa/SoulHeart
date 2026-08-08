class_name DodgeBox
extends Control

signal player_hit
signal heal_requested(amount: int)

const HEART_SPEED := 160.0
const BOX_RECT := Rect2(32, 250, 570, 135)
const HEART_START := Vector2(317, 317)
const INVULN_TIME := 1.0
const STAGGER_TIME := 0.2
const KNOCKBACK := 6.0

var heart: Sprite2D
var bullets: Array = []
var invuln := 0.0
var active := false
var _stagger := 0.0
var last_heart_pos := HEART_START

func _ready() -> void:
	size = Vector2(640, 480)
	var panel := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 1)
	sb.set_border_width_all(1)
	sb.border_color = Color.WHITE
	panel.add_theme_stylebox_override("panel", sb)
	panel.position = BOX_RECT.position
	panel.size = BOX_RECT.size
	add_child(panel)
	heart = Sprite2D.new()
	heart.texture = Sprites.soul_texture("Red")
	heart.position = HEART_START
	add_child(heart)
	visible = false

func set_active(a: bool) -> void:
	active = a
	visible = a
	if not a:
		_clear_bullets()

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
				b.position = b.orbit_center + Vector2.from_angle(b.phase * 2.0) * 80.0
			_:
				b.position += b.vel * delta
		b.life -= delta
	if _stagger > 0.0:
		_remove_dead()
		return
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	heart.position = CombatMath.clamp_to_box_inset(heart.position + input * HEART_SPEED * delta, BOX_RECT, 4.0, 4.0, -16.0, -16.0)
	var heart_vel := (heart.position - last_heart_pos) / delta
	last_heart_pos = heart.position
	var hit_bullet: Bullet = null
	for b in bullets:
		if b.dead():
			continue
		var hit := CombatMath.circle_hit(heart.position, 4.0, b.position, b.size)
		if hit and _bullet_damages(b, heart_vel):
			hit_bullet = b
			break
		elif hit and b.rule == Bullet.Rule.GREEN:
			heal_requested.emit(2)
			b.life = 0.0
	if hit_bullet != null and invuln <= 0.0:
		_on_hit()
		var away := (heart.position - hit_bullet.position).normalized()
		heart.position = CombatMath.clamp_to_box(heart.position + away * KNOCKBACK, BOX_RECT)
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
		if not b.dead() and BOX_RECT.grow(4.0).has_point(b.position):
			keep.append(b)
		else:
			b.queue_free()
	bullets = keep

func _clear_bullets() -> void:
	for b in bullets:
		b.queue_free()
	bullets = []
