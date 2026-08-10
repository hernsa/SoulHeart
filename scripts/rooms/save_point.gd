extends Area2D

var _star: Sprite2D

func _ready() -> void:
	_star = Sprite2D.new()
	_star.name = "StarSprite"
	_star.texture = Sprites.save_point_texture()
	_star.scale = Vector2(1.5, 1.5)
	add_child(_star)
	var pulse := create_tween()
	pulse.set_loops()
	pulse.tween_property(_star, "scale", Vector2(1.8, 1.8), 0.5)
	pulse.tween_property(_star, "scale", Vector2(1.5, 1.5), 0.5)
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
			Audio.play_sfx("save")
			_show_banner("Game saved.")

func _show_banner(text: String) -> void:
	var panel := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0)
	sb.set_border_width_all(1)
	sb.border_color = Color(1, 1, 1)
	panel.add_theme_stylebox_override("panel", sb)
	panel.position = Vector2(24, 404)
	panel.size = Vector2(120, 32)
	add_child(panel)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	label.position = Vector2(30, 410)
	panel.add_child(label)
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_property(panel, "modulate:a", 0.0, 0.8)
	tw.tween_callback(panel.queue_free)
