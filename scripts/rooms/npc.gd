extends Area2D

@export var dialogue_file := ""

func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 10.0
	shape.shape = circ
	add_child(shape)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		var lines := DialogueParser.parse_file(dialogue_file)
		var ui = load("res://scripts/dialogue/dialogue_ui.gd").new()
		get_tree().current_scene.add_child(ui)
		ui.open(lines)
