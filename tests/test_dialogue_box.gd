extends RefCounted

var _ui: Node
var _finished: bool = false

func _make_ui() -> void:
	_ui = load("res://scripts/dialogue/dialogue_ui.gd").new()
	_ui._ready()
	_ui.finished.connect(func() -> void: _finished = true)

func test_battle_box_geometry() -> void:
	_make_ui()
	_ui.open([{"speaker": "", "text": "Hello."}], true)
	TestHelper.eq(_ui._panel.position, Vector2(322, 388), "battle box position")
	TestHelper.eq(_ui._panel.size, Vector2(290, 78), "battle box size")
	TestHelper.is_true(_ui.visible, "ui visible while typing")

func test_overworld_box_geometry() -> void:
	_make_ui()
	_ui.open([{"speaker": "", "text": "Hello."}])
	TestHelper.eq(_ui._panel.position, Vector2(24, 404), "overworld box position")
	TestHelper.eq(_ui._panel.size, Vector2(592, 64), "overworld box size")

func test_solid_black_fill() -> void:
	_make_ui()
	TestHelper.eq(_ui._panel.get_theme_stylebox("panel").bg_color, Color(0, 0, 0, 1), "box fill is solid black")

func test_hides_itself_when_finished() -> void:
	_make_ui()
	_ui.open([{"speaker": "", "text": "Hi."}])
	_ui._index = 1
	_ui._process(0.0)
	TestHelper.is_true(_finished, "finished emitted at end")
	TestHelper.is_true(not _ui.visible, "ui hides when finished (does not free)")
