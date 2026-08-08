class_name DialogueUI
extends CanvasLayer

signal finished

const OVERWORLD_BOX := Rect2(24, 404, 592, 64)
const BATTLE_BOX := Rect2(30, 390, 290, 75)

var _lines: Array = []
var _index: int = 0
var _tw := Typewriter.new()
var _panel: Panel
var _label: Label
var _speaker_label: Label
var _active: bool = false
var _prev_chars: int = 0

func _ready() -> void:
	layer = 10
	_panel = Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 1)
	sb.set_border_width_all(1)
	sb.border_color = Color.WHITE
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.position = OVERWORLD_BOX.position
	_panel.size = OVERWORLD_BOX.size
	add_child(_panel)
	_speaker_label = Label.new()
	_speaker_label.position = Vector2(36, 408)
	_speaker_label.add_theme_font_size_override("font_size", 16)
	add_child(_speaker_label)
	_label = Label.new()
	_label.position = Vector2(36, 430)
	_label.size = Vector2(560, 30)
	_label.add_theme_font_size_override("font_size", 16)
	add_child(_label)
	visible = false

func open(lines: Array, battle: bool = false) -> void:
	_lines = lines
	_index = 0
	if _lines.is_empty():
		finished.emit()
		visible = false
		return
	_panel.position = BATTLE_BOX.position if battle else OVERWORLD_BOX.position
	_panel.size = BATTLE_BOX.size if battle else OVERWORLD_BOX.size
	var inset := 20 if battle else 12
	_speaker_label.position = Vector2(BATTLE_BOX.position.x + inset, BATTLE_BOX.position.y + 2) if battle else Vector2(36, 408)
	_label.position = Vector2(BATTLE_BOX.position.x + inset, BATTLE_BOX.position.y + inset + 2) if battle else Vector2(36, 430)
	_label.size = Vector2((BATTLE_BOX.size.x if battle else 560) - inset - 10, 30)
	visible = true
	_active = true
	_prev_chars = 0
	_show_current()

func _process(delta: float) -> void:
	if not _active:
		return
	if _index >= _lines.size():
		_active = false
		visible = false
		finished.emit()
		return
	var line: Dictionary = _lines[_index]
	_tw.advance(delta)
	var vis := _tw.visible_chars()
	var text: String = str(line.get("text", ""))
	if vis > _prev_chars and _prev_chars < text.length():
		var ch := text.substr(_prev_chars, 1)
		if not (ch == " " or ch == "\t" or ch == "\n"):
			Audio.play_sfx("blip", randf_range(0.9, 1.1))
	_prev_chars = vis
	_label.text = text.substr(0, vis)
	if Input.is_action_just_pressed("confirm") or Input.is_action_just_pressed("cancel"):
		if _tw.is_done():
			_index += 1
			if _index < _lines.size():
				_prev_chars = 0
				_show_current()
		else:
			_tw.skip()

func _show_current() -> void:
	var line: Dictionary = _lines[_index]
	_speaker_label.text = str(line.get("speaker", ""))
	_speaker_label.visible = str(line.get("speaker", "")) != ""
	_label.text = ""
	_tw.start(str(line.get("text", "")))
