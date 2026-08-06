class_name DialogueUI

extends CanvasLayer

signal finished

var _lines: Array[Dictionary] = []
var _index := 0
var _tw := Typewriter.new()
var _label: Label
var _speaker_label: Label
var _active := false

func _ready() -> void:
	layer = 10
	var box := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.85)
	sb.set_border_width_all(1)
	sb.border_color = Color.WHITE
	box.add_theme_stylebox_override("panel", sb)
	box.position = Vector2(24, 404)
	box.size = Vector2(592, 64)
	add_child(box)
	_speaker_label = Label.new()
	_speaker_label.add_theme_font_size_override("font_size", 16)
	_speaker_label.position = Vector2(36, 408)
	add_child(_speaker_label)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 16)
	_label.position = Vector2(36, 430)
	add_child(_label)

func open(lines: Array[Dictionary]) -> void:
	if lines.is_empty():
		finished.emit()
		queue_free()
		return
	_lines = lines
	_index = 0
	_active = true
	_show_current()

func _process(delta: float) -> void:
	if not _active:
		return
	if _index >= _lines.size():
		_active = false
		finished.emit()
		queue_free()
		return
	var line := _lines[_index]
	_tw.advance(delta)
	_label.text = str(line.get("text", "")).substr(0, _tw.visible_chars())
	if Input.is_action_just_pressed("confirm"):
		if _tw.is_done():
			_index += 1
			if _index < _lines.size():
				_show_current()
		else:
			_tw.skip()
	elif Input.is_action_just_pressed("cancel"):
		if _tw.is_done():
			_index = _lines.size()
		else:
			_tw.skip()

func _show_current() -> void:
	var line := _lines[_index]
	_speaker_label.text = str(line.get("speaker", ""))
	_tw.start(str(line.get("text", "")))
	_label.text = ""
