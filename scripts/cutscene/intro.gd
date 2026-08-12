extends Node2D

const STORY_LINES := [
	"Long ago, two races ruled the earth.",
	"Humans and dreamers.",
	"One day, they fell.",
	"And then...",
]

var _label: Label
var _advance := false

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 1)
	bg.size = Vector2(640, 480)
	add_child(bg)
	_label = Label.new()
	_label.position = Vector2(80, 224)
	_label.size = Vector2(480, 30)
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label)
	for line in STORY_LINES:
		await _show(line)
	await _fall_in()
	Fade.fade_to_black(0.4)
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/rooms/DrizzleFields.tscn")

func _show(line: String) -> void:
	_label.text = line
	_advance = false
	while not _advance:
		if Input.is_action_just_pressed("confirm"):
			_advance = true
		await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout

func _fall_in() -> void:
	var heart := Sprite2D.new()
	heart.texture = Sprites.soul_texture("Red")
	heart.position = Vector2(320, -16)
	add_child(heart)
	var t := create_tween()
	t.tween_property(heart, "position", Vector2(320, 380), 1.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await t.finished
