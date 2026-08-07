class_name Bullet
extends Node2D

var vel := Vector2.ZERO
var life := 4.0
var size := 3.0

func setup(d: Dictionary) -> void:
	var pos: Vector2 = d.get("pos", Vector2.ZERO)
	position = Vector2(roundi(pos.x), roundi(pos.y))
	vel = d.get("vel", Vector2.ZERO)
	life = float(d.get("life", 4.0))
	size = float(d.get("size", 3.0))
	var spr := Sprite2D.new()
	spr.texture = Sprites.bullet_texture()
	add_child(spr)

func dead() -> bool:
	return life <= 0.0
