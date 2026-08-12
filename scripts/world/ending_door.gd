class_name EndingDoor
extends Area2D

@export var door_id := "wanderer"
@export var locked_text := "The way is sealed."

func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 12.0
	shape.shape = circ
	add_child(shape)
	body_entered.connect(_on_body_entered)
	var spr := Sprite2D.new()
	spr.name = "DoorSprite"
	spr.texture = Sprites.prop_texture("door_%s.png" % door_id)
	spr.scale = Vector2(1.5, 1.5)
	add_child(spr)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if not Ending.door_unlocked(door_id):
		Audio.play_sfx("sting")
		_show_banner(locked_text)
		return
	if door_id == "keeper":
		Ending.flag_keeper_battle(str(GameState.flags.get("current_room", "")))
		Audio.play_sfx("door_seal")
		Fade.fade_to_black(0.67)
		await get_tree().create_timer(0.8).timeout
		if not is_inside_tree():
			return
		_show_banner("You step through.")
		await get_tree().create_timer(1.0).timeout
		if get_tree() != null:
			get_tree().change_scene_to_file("res://scenes/Battle.tscn")
		return
	Audio.play_sfx("door_seal")
	_show_banner("You step through.")
	await get_tree().create_timer(0.9).timeout
	await Ending.play_ending(door_id, get_tree())

func _show_banner(text: String) -> void:
	var panel := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0)
	sb.set_border_width_all(1)
	sb.border_color = Color(1, 1, 1)
	panel.add_theme_stylebox_override("panel", sb)
	panel.position = Vector2(24, 404)
	panel.size = Vector2(330, 32)
	add_child(panel)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 8)
	label.position = Vector2(30, 406)
	panel.add_child(label)
	var tw := create_tween()
	tw.tween_interval(1.2)
	tw.tween_property(panel, "modulate:a", 0.0, 0.8)
	tw.tween_callback(panel.queue_free)