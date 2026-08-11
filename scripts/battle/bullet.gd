class_name Bullet
extends Node2D

enum Type { PELLET, BONE, SPEAR, RING, LASER, ARROW }
enum Rule { NONE, BLUE, ORANGE, GRAY, GREEN }

var vel := Vector2.ZERO
var life := 4.0
var size := 3.0
var btype := Type.PELLET
var rule := Rule.NONE
var behavior := "straight"
var phase := 0.0
var orbit_center := Vector2.ZERO
var edit_at := -1.0
var edit_btype := Type.PELLET
var edit_rule := Rule.NONE
var edit_vel := Vector2.ZERO
var edited := false
var _sprite: Sprite2D

func setup(d: Dictionary) -> void:
	var pos: Vector2 = d.get("pos", Vector2.ZERO)
	position = Vector2(roundi(pos.x), roundi(pos.y))
	vel = d.get("vel", Vector2.ZERO)
	life = float(d.get("life", 4.0))
	size = float(d.get("size", 3.0))
	btype = int(d.get("type", Type.PELLET))
	rule = int(d.get("rule", Rule.NONE))
	behavior = str(d.get("behavior", "straight"))
	phase = float(d.get("phase", 0.0))
	orbit_center = d.get("orbit_center", Vector2.ZERO)
	var spr := Sprite2D.new()
	spr.texture = Sprites.bullet_texture_for(btype)
	add_child(spr)
	_sprite = spr
	if behavior == "edit":
		edit_at = float(d.get("edit_at", 0.5))
		edit_btype = int(d.get("edit_btype", btype))
		edit_rule = int(d.get("edit_rule", Rule.NONE))
		edit_vel = d.get("edit_vel", vel)
		edited = false

func _apply_edit() -> void:
	if edited:
		return
	edited = true
	btype = edit_btype
	rule = edit_rule
	vel = edit_vel
	if _sprite != null:
		_sprite.texture = Sprites.bullet_texture_for(btype)

func dead() -> bool:
	return life <= 0.0
