extends Node2D

var _started := false
var _hint: Label

func _ready() -> void:
	GameState.load_game()
	Audio.play_music("title")
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
	_hint = Label.new()
	_hint.text = "Press Z to fall"
	_hint.position = Vector2(260, 320)
	_hint.add_theme_font_size_override("font_size", 16)
	add_child(_hint)
	var version := Label.new()
	version.text = "SOULHEART v0.4"
	version.position = Vector2(160, 232)
	version.add_theme_font_size_override("font_size", 8)
	version.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	add_child(version)

func _process(_delta: float) -> void:
	_hint.visible = sin(Time.get_ticks_msec() * 0.004) > 0.0
	if not _started and Input.is_action_just_pressed("confirm"):
		_started = true
		Fade.fade_to_black(0.3)
		await get_tree().create_timer(0.3).timeout
		get_tree().change_scene_to_file("res://scenes/IntroCutscene.tscn")
