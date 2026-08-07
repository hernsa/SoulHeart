extends Node2D

var _started := false

func _ready() -> void:
	GameState.load_game()
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 1)
	bg.size = Vector2(640, 480)
	add_child(bg)
	var title := Label.new()
	title.text = "SoulHeart"
	title.add_theme_font_size_override("font_size", 48)
	title.position = Vector2(215, 170)
	add_child(title)
	var sub := Label.new()
	sub.text = "a dream about the ones you left behind"
	sub.add_theme_font_size_override("font_size", 16)
	sub.position = Vector2(150, 240)
	add_child(sub)
	var hint := Label.new()
	hint.text = "Press Z to fall"
	hint.add_theme_font_size_override("font_size", 16)
	hint.position = Vector2(260, 320)
	add_child(hint)

func _process(_delta: float) -> void:
	if not _started and Input.is_action_just_pressed("confirm"):
		_started = true
		get_tree().change_scene_to_file("res://scenes/rooms/DrizzleFields.tscn")
