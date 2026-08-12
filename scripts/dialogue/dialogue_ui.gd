class_name DialogueUI
extends CanvasLayer

signal finished

static var open_count := 0

const OVERWORLD_BOX := Rect2(24, 404, 592, 64)
const BATTLE_BOX := Rect2(322, 388, 290, 78)

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
	_speaker_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_speaker_label)
	_label = Label.new()
	_label.position = Vector2(36, 430)
	_label.size = Vector2(560, 30)
	_label.add_theme_font_size_override("font_size", 16)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_label)
	visible = false

func open_wisp(text: String) -> void:
	var parts: PackedStringArray = text.split(": ", false, 1)
	if parts.size() < 2:
		open([{"speaker": "", "text": text}], false)
		return
	open([{"speaker": str(parts[0]), "text": str(parts[1])}], false)

func open(lines: Array, battle: bool = false) -> void:
	_lines = lines
	_index = 0
	if _lines.is_empty():
		finished.emit()
		visible = false
		return
	open_count += 1
	if _panel == null:
		await ready
	_panel.position = BATTLE_BOX.position if battle else OVERWORLD_BOX.position
	_panel.size = BATTLE_BOX.size if battle else OVERWORLD_BOX.size
	var inset := 20 if battle else 12
	var fs := 16 if battle else 8
	_speaker_label.add_theme_font_size_override("font_size", fs)
	_label.add_theme_font_size_override("font_size", fs)
	_speaker_label.position = Vector2(BATTLE_BOX.position.x + inset, BATTLE_BOX.position.y + 2) if battle else Vector2(36, 408)
	_label.position = Vector2(BATTLE_BOX.position.x + inset, BATTLE_BOX.position.y + inset + 2) if battle else Vector2(36, 430)
	_speaker_label.size = Vector2(BATTLE_BOX.size.x - inset - 10, 26) if battle else Vector2(560, 26)
	_label.size = Vector2(BATTLE_BOX.size.x if battle else 560, 50 if battle else 30) - Vector2(inset + 10, 0)
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
		open_count = maxi(open_count - 1, 0)
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
