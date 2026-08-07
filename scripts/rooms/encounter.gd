extends Area2D

@export var enemy_id := "willowisp"
var used := false

func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 8.0
	shape.shape = circ
	add_child(shape)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not used:
		used = true
		GameState.set_flag("pending_enemy", enemy_id)
		GameState.set_flag("from_room", str(GameState.flags.get("current_room", "res://scenes/rooms/DrizzleFields.tscn")))
		get_tree().change_scene_to_file("res://scenes/Battle.tscn")
