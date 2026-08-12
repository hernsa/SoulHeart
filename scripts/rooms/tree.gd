class_name RoomTree
extends Sprite2D

var _shadow: Sprite2D

func _init() -> void:
	texture = load("res://assets/sprites/overworld/tree_pine.png")
	z_index = 0
	y_sort_enabled = true
	_shadow = Sprite2D.new()
	_shadow.texture = load("res://assets/sprites/shadow_ellipse.png")
	_shadow.position = Vector2(0, 24)
	_shadow.scale = Vector2(2, 1)
	_shadow.modulate = Color(0, 0, 0, 0.3)
	_shadow.z_index = -1
	add_child(_shadow)
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(8, 24)
	shape.shape = rect
	shape.position = Vector2(0, 12)
	body.add_child(shape)
	add_child(body)
