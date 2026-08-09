extends Area2D

@export var dialogue_file: String = ""

func _spawn_sprite(texture: Texture2D, sprite_scale: Vector2) -> Sprite2D:
	var spr := Sprite2D.new()
	spr.texture = texture
	spr.scale = sprite_scale
	add_child(spr)
	return spr

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var lines: Array = DialogueParser.parse_file(dialogue_file)
		var ui: Node = load("res://scripts/dialogue/dialogue_ui.gd").new()
		ui.layer = 10
		get_tree().current_scene.add_child(ui)
		ui.open(lines)
		await ui.finished
		ui.queue_free()
