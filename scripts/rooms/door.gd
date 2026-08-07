extends Area2D

@export var target_room := ""
var target_spawn := Vector2(160, 100)

func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 10.0
	shape.shape = circ
	add_child(shape)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		GameState.set_flag("current_room", target_room)
		GameState.set_flag("save_point", [int(target_spawn.x), int(target_spawn.y)])
		Audio.play_sfx("door_open")
		get_tree().change_scene_to_file(target_room)
