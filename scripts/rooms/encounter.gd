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
		_show_bang()
		Audio.play_sfx("sting")
		Fade.flash(0.15)
		await get_tree().create_timer(0.4).timeout
		get_tree().change_scene_to_file("res://scenes/Battle.tscn")

func _show_bang() -> void:
	var label := Label.new()
	label.text = "!"
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	var player := get_tree().get_first_node_in_group("player")
	if player:
		label.global_position = player.global_position + Vector2(6, -30)
	get_tree().current_scene.add_child(label)
