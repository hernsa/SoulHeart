class_name ChoiceMenu
extends Control

signal chosen(choice: String)

var _options: Array[String] = []
var _prompt := ""
var _cursor := 0
var _labels: Array[Label] = []
var _sent := false

func open(prompt_text: String, options: Array[String]) -> void:
	_prompt = prompt_text
	_options = options
	set_process(true)
	var panel := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0)
	sb.set_border_width_all(1)
	sb.border_color = Color(1, 1, 1)
	panel.add_theme_stylebox_override("panel", sb)
	panel.position = Vector2(24, 300)
	panel.size = Vector2(330, 120)
	add_child(panel)
	var prompt_label := Label.new()
	prompt_label.text = _prompt
	prompt_label.add_theme_font_size_override("font_size", 14)
	prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt_label.size = Vector2(310, 50)
	prompt_label.position = Vector2(30, 306)
	panel.add_child(prompt_label)
	_labels.clear()
	for i in _options.size():
		var label := Label.new()
		label.text = _options[i]
		label.add_theme_font_size_override("font_size", 18)
		label.position = Vector2(42, 362 + i * 24)
		panel.add_child(label)
		_labels.append(label)
	_refresh()

func _process(_delta: float) -> void:
	if _sent:
		return
	if Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("move_left"):
		_cursor = (_cursor + _options.size() - 1) % _options.size()
		Audio.play_sfx("select")
		_refresh()
	elif Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("move_right"):
		_cursor = (_cursor + 1) % _options.size()
		Audio.play_sfx("select")
		_refresh()
	elif Input.is_action_just_pressed("confirm"):
		_send(_options[_cursor])
	elif Input.is_action_just_pressed("cancel"):
		_send("flee")

func _refresh() -> void:
	for i in _labels.size():
		_labels[i].modulate = Color(1, 1, 1, 1) if i == _cursor else Color(0.6, 0.6, 0.6, 1)
		_labels[i].text = (">" if i == _cursor else " ") + _options[i]

func _send(choice: String) -> void:
	if _sent:
		return
	_sent = true
	Audio.play_sfx("confirm")
	chosen.emit(choice)
	queue_free()