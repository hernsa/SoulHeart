class_name Typewriter

signal finished

var text: String = ""
var chars_per_second := 24.0
var _elapsed := 0.0
var _done := false

func start(new_text: String) -> void:
	text = new_text
	_elapsed = 0.0
	_done = false

func advance(delta: float) -> void:
	if _done:
		return
	_elapsed += delta
	if visible_chars() >= text.length():
		_done = true
		finished.emit()

func visible_chars() -> int:
	return clampi(int(_elapsed * chars_per_second), 0, text.length())

func is_done() -> bool:
	return _done

func skip() -> void:
	_elapsed = float(text.length()) / maxf(chars_per_second, 0.001)
	_done = true
