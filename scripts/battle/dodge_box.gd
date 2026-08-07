class_name DodgeBox
extends Control

signal player_hit

const HEART_SPEED := 160.0
const BOX_RECT := Rect2(200, 60, 240, 220)

var heart: Sprite2D
var bullets: Array = []
var invuln := 0.0
var active := false

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
	heart.texture = Sprites.heart_texture()
	heart.position = BOX_RECT.get_center()
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
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	heart.position = CombatMath.clamp_to_box(heart.position + input * HEART_SPEED * delta, BOX_RECT)
	for b in bullets:
		b.position += b.vel * delta
		b.life -= delta
	var hit := false
	for b in bullets:
		if CombatMath.circle_hit(heart.position, 4.0, b.position, b.size):
			hit = true
			break
	if hit and invuln <= 0.0:
		invuln = 0.5
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
