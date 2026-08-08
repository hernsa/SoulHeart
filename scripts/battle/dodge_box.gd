class_name DodgeBox
extends Control

signal player_hit

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

func has_bullets() -> bool:
	return bullets.size() > 0

func _process(delta: float) -> void:
	if not active:
		return
	invuln = maxf(0.0, invuln - delta)
	_stagger = maxf(0.0, _stagger - delta)
	heart.visible = (invuln <= 0.0) or (int(invuln * 10.0) % 2 == 0)
	for b in bullets:
		b.position += b.vel * delta
		b.life -= delta
	if _stagger > 0.0:
		_remove_dead()
		return
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	heart.position = CombatMath.clamp_to_box_inset(heart.position + input * HEART_SPEED * delta, BOX_RECT, 4.0, 4.0, -16.0, -16.0)
	var hit := false
	var hit_bullet: Bullet = null
	for b in bullets:
		if CombatMath.circle_hit(heart.position, 4.0, b.position, b.size):
			hit = true
			hit_bullet = b
			break
	if hit and invuln <= 0.0:
		invuln = INVULN_TIME
		_stagger = STAGGER_TIME
		if hit_bullet:
			var away := (heart.position - hit_bullet.position).normalized()
			heart.position = CombatMath.clamp_to_box(heart.position + away * KNOCKBACK, BOX_RECT)
		player_hit.emit()
	_remove_dead()

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
