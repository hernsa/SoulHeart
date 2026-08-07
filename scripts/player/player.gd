extends CharacterBody2D

const SPEED := 140.0
const ACCEL := 1200.0

var facing := Vector2.DOWN

func _ready() -> void:
	$Sprite2D.texture = Sprites.player_texture()

func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	set_movement_input(input)
	move_and_slide()

func set_movement_input(dir: Vector2) -> void:
	if dir != Vector2.ZERO:
		facing = dir.normalized()
	velocity = velocity.move_toward(dir * SPEED, ACCEL * get_physics_process_delta_time())
