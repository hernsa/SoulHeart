extends CharacterBody2D

const SPEED := 140.0
const ACCEL := 1200.0

var facing := Vector2.DOWN
var _last_dir := ""
var _anim_time: float = 0.0
var _frame: int = 0
var _moving: bool = false
var _sprite: Sprite2D
var _shadow: Sprite2D

func _ready() -> void:
	_sprite = $Sprite2D
	_sprite.texture = Sprites.player_texture_frame(0)
	_shadow = Sprite2D.new()
	_shadow.texture = Sprites.player_shadow_texture()
	_shadow.position = Vector2(0, 9)
	add_child(_shadow)

static func resolve_direction4(just_pressed: PackedStringArray, held: PackedStringArray, last: String) -> Array:
	var new_last := last
	for action in just_pressed:
		if action in ["move_up", "move_down", "move_left", "move_right"]:
			new_last = action
	var chosen := new_last
	if chosen == "" or not held.has(chosen):
		chosen = ""
		for action in held:
			if action in ["move_up", "move_down", "move_left", "move_right"]:
				chosen = action
				break
	match chosen:
		"move_up": return [Vector2.UP, new_last]
		"move_down": return [Vector2.DOWN, new_last]
		"move_left": return [Vector2.LEFT, new_last]
		"move_right": return [Vector2.RIGHT, new_last]
	return [Vector2.ZERO, new_last]

func _physics_process(delta: float) -> void:
	var just := PackedStringArray()
	var held := PackedStringArray()
	for action in ["move_up", "move_down", "move_left", "move_right"]:
		if Input.is_action_pressed(action):
			held.append(action)
		if Input.is_action_just_pressed(action):
			just.append(action)
	var res: Array = resolve_direction4(just, held, _last_dir)
	_last_dir = str(res[1])
	set_movement_input(res[0])
	if res[0] != Vector2.ZERO:
		_moving = true
		_anim_time += get_physics_process_delta_time()
		_frame = int(_anim_time / 0.15) % 2
		_sprite.texture = Sprites.player_texture_frame(_frame)
		_sprite.flip_h = res[0].x < 0
	else:
		_moving = false
		_sprite.texture = Sprites.player_texture_frame(0)
	move_and_slide()

func set_movement_input(dir: Vector2) -> void:
	if dir != Vector2.ZERO:
		facing = dir.normalized()
	velocity = velocity.move_toward(dir * SPEED, ACCEL * get_physics_process_delta_time())
