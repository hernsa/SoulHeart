class_name EditEvent
extends Area2D

const EVENT_IDS: Array[String] = [
	"shelf_book", "wall_window", "door_moves", "name_changes", "portrait", "floor_crack",
]

@export var event_id: String = ""
@export var prompt: String = ""

var _deco: Sprite2D
var _resolved := false

func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 12.0
	shape.shape = circ
	add_child(shape)
	body_entered.connect(_on_body_entered)
	if not event_id.is_empty() and GameState.flags.has("edit_event_%s" % event_id):
		_resolved = true
		_apply_world_change(str(GameState.flags["edit_event_%s" % event_id]))

static func choose(event_id: String, choice: String) -> String:
	if choice != "accept" and choice != "refuse":
		choice = "flee"
	GameState.set_flag("edit_event_%s" % event_id, choice)
	var key := "edit_accepts"
	if choice == "refuse":
		key = "edit_refuses"
	elif choice == "flee":
		key = "edit_flees"
	GameState.set_flag(key, int(GameState.flags.get(key, 0)) + 1)
	return choice

static func count(choice_key: String) -> int:
	return int(GameState.flags.get(choice_key, 0))

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player") or event_id.is_empty():
		return
	if _resolved:
		_show_banner(_resolved_banner(str(GameState.flags["edit_event_%s" % event_id])))
		return
	var menu := ChoiceMenu.new()
	menu.layer = 20
	add_child(menu)
	menu.open(prompt, ["Flee", "Refuse", "Accept"])
	var choice: String = await menu.chosen
	_resolved = true
	choose(event_id, choice)
	_apply_world_change(choice)
	Audio.play_sfx("edit_bell")
	_show_banner(_result_banner(choice))

func _result_banner(choice: String) -> String:
	match choice:
		"accept":
			return "* It stays."
		"refuse":
			return "* You refuse. It flickers."
		_:
			return "* You walk away."

func _resolved_banner(choice: String) -> String:
	match choice:
		"accept":
			return "* It stays. It will always stay."
		"refuse":
			return "* You refused. It remembers."
		_:
			return "* You walked away. It noticed."

func _apply_world_change(choice: String) -> void:
	if not is_inside_tree():
		return
	_rebuild_deco(choice == "accept")

func _rebuild_deco(visible_deco: bool) -> void:
	if _deco != null:
		_deco.queue_free()
		_deco = null
	if not visible_deco:
		return
	_deco = Sprite2D.new()
	_deco.name = "Deco"
	_deco.texture = _deco_texture(event_id)
	_deco.position = Vector2(14, -14)
	add_child(_deco)

static func _deco_texture(id: String) -> Texture2D:
	var size := Vector2i(8, 8)
	var color := Color(0.9, 0.78, 0.5)
	match id:
		"shelf_book":
			color = Color(0.72, 0.55, 0.32)
		"wall_window":
			color = Color(0.55, 0.72, 0.9)
		"door_moves":
			color = Color(0.9, 0.64, 0.24)
		"name_changes":
			color = Color(0.92, 0.92, 0.85)
		"portrait":
			color = Color(0.6, 0.25, 0.22)
		"floor_crack":
			color = Color(0.08, 0.08, 0.1)
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)

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
	label.add_theme_font_size_override("font_size", 16)
	label.position = Vector2(30, 410)
	panel.add_child(label)
	var tw := create_tween()
	tw.tween_interval(1.2)
	tw.tween_property(panel, "modulate:a", 0.0, 0.8)
	tw.tween_callback(panel.queue_free)