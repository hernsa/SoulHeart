extends Area2D

@export var dialogue_file: String = ""

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var lines: Array = DialogueParser.parse_file(dialogue_file)
		var ui: Node = load("res://scripts/dialogue/dialogue_ui.gd").new()
		ui.layer = 10
		get_tree().current_scene.add_child(ui)
		ui.open(lines)
		await ui.finished
		ui.queue_free()
