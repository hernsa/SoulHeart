extends Node

const VIEW := Vector2(640, 480)

var _layer: CanvasLayer
var _black: ColorRect
var _white: ColorRect
var _tween: Tween

func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 100
	add_child(_layer)
	_black = ColorRect.new()
	_black.color = Color(0, 0, 0, 0)
	_black.size = VIEW
	_layer.add_child(_black)
	_white = ColorRect.new()
	_white.color = Color(1, 1, 1, 0)
	_white.size = VIEW
	_layer.add_child(_white)

func is_black() -> bool:
	return _black != null and _black.color.a > 0.01

func set_black(alpha: float) -> void:
	_black.color.a = alpha

func fade_to_black(dur: float = 0.3) -> void:
	_tween_alpha(_black, 1.0, dur)

func fade_from_black(dur: float = 0.3) -> void:
	if not is_black():
		return
	_tween_alpha(_black, 0.0, dur)

func flash(dur: float = 0.15) -> void:
	_tween_alpha(_white, 1.0, dur * 0.5, dur)

func _tween_alpha(rect: ColorRect, target: float, dur: float, hold: float = 0.0) -> void:
	if rect == null or not is_inside_tree():
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	if is_equal_approx(rect.color.a, target) and hold <= 0.0:
		return
	_tween = create_tween()
	_tween.tween_property(rect, "color:a", target, dur)
	if hold > 0.0:
		_tween.tween_interval(hold)
		_tween.tween_property(rect, "color:a", 0.0, dur)
