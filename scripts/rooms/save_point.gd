extends Area2D

func _ready() -> void:
	var spr := Sprite2D.new()
	spr.texture = Sprites.star_texture()
	spr.scale = Vector2(1.5, 1.5)
	add_child(spr)
	var shape := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 12.0
	shape.shape = circ
	add_child(shape)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		GameState.set_flag("save_point", [int(global_position.x), int(global_position.y)])
		if GameState.save_game():
			_show_banner("Game saved.")

func _show_banner(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	label.position = Vector2(270, 240)
	add_child(label)
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_property(label, "modulate:a", 0.0, 0.8)
	tw.tween_callback(label.queue_free)
