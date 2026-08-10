extends Area2D
class_name Door

@export var target_room := ""
var target_spawn := Vector2(-1, -1)

func _ready() -> void:
	if target_spawn.x < 0 or target_spawn.y < 0:
		push_error("Door at %s has invalid target_spawn %s" % [position, target_spawn])
		target_spawn = _find_p_marker_spawn()
	var shape := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 10.0
	shape.shape = circ
	add_child(shape)
	var sprite := Sprite2D.new()
	sprite.texture = Sprites.door_texture()
	sprite.position = Vector2(0, 0)
	add_child(sprite)
	body_entered.connect(_on_body_entered)

func _find_p_marker_spawn() -> Vector2:
	var parent = get_parent()
	var layout = parent.get("LAYOUT") if parent else null
	if layout == null or not (layout is String):
		return Vector2(100, 100)
	var parsed := MapBuilder.parse_layout(layout)
	var ps: Vector2 = parsed["player_start"]
	return Vector2(ps.x + 8, ps.y + 8)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		GameState.set_flag("current_room", target_room)
		GameState.set_flag("save_point", [int(target_spawn.x), int(target_spawn.y)])
		Audio.play_sfx("door_open")
		Fade.fade_to_black(0.43)
		await get_tree().create_timer(0.43).timeout
		get_tree().change_scene_to_file(target_room)
