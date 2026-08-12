extends Node2D
class_name Wisp

@export var target_player: NodePath
@export var lerp_speed: float = 4.0
@export var follow_offset: Vector2 = Vector2(8, -12)
@export var hum_mood_gain: int = 15

var _player: Node2D
var _sprite: Sprite2D
var _last_mood_band: int = -1
var _children_ready: bool = false

func _ready() -> void:
	_ensure_children()
	if not target_player.is_empty():
		_player = get_node_or_null(target_player) as Node2D

func _process(delta: float) -> void:
	_ensure_children()
	if _player == null:
		_try_acquire_player()
		return
	var target_pos: Vector2 = _player.position + follow_offset
	position = position.lerp(target_pos, clampf(lerp_speed * delta, 0.0, 1.0))
	_maybe_handle_hum()
	_update_sprite_for_mood()

func _ensure_children() -> void:
	if _children_ready:
		return
	_children_ready = true
	_sprite = Sprite2D.new()
	_sprite.texture = Sprites.wisp_texture()
	_sprite.centered = true
	add_child(_sprite)
	var area := Area2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 12.0
	shape.shape = circle
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_body_entered)

func _try_acquire_player() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var players := tree.get_nodes_in_group("player")
	if players.is_empty():
		return
	_player = players[0] as Node2D

func _maybe_handle_hum() -> void:
	if not InputMap.has_action("hum"):
		return
	if not Input.is_action_just_pressed("hum"):
		return
	if DialogueUI.open_count > 0:
		return
	if WispState.hum():
		WispState.add_hum(hum_mood_gain)
		WispAudio.play_hum(WispState.mood())

func _update_sprite_for_mood() -> void:
	var band := _mood_band(WispState.mood())
	if band == _last_mood_band:
		return
	_last_mood_band = band
	match band:
		0, 1:
			_sprite.texture = Sprites.wisp_texture()
		2:
			_sprite.texture = _lit_texture()

func _mood_band(mood: int) -> int:
	if mood < 33:
		return 0
	if mood < 66:
		return 1
	return 2

func _lit_texture() -> Texture2D:
	var tex := load("res://assets/sprites/wisp/wisp_lit.png") as Texture2D
	if tex == null:
		return Sprites.wisp_texture()
	return tex

var _wisp_ui: Node
var _pulse_shown := false

func show_line(context: String) -> void:
	if not is_instance_valid(_wisp_ui):
		_wisp_ui = load("res://scripts/dialogue/dialogue_ui.gd").new()
		add_child(_wisp_ui)
	_wisp_ui.open_wisp(WispDialogue.get_line(context))
	await _wisp_ui.finished

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not _pulse_shown:
		_pulse_shown = true
		show_line("hum_ready")