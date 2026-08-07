extends RefCounted

const PlayerScript := preload("res://scripts/player/player.gd")

func _new_player() -> CharacterBody2D:
	return PlayerScript.new()

func test_default_facing() -> void:
	var p := _new_player()
	TestHelper.eq(p.facing, Vector2.DOWN, "faces down by default")
	p.free()

func test_facing_updates() -> void:
	var p := _new_player()
	p.set_movement_input(Vector2.RIGHT)
	TestHelper.eq(p.facing, Vector2.RIGHT, "faces right")
	p.set_movement_input(Vector2.UP)
	TestHelper.eq(p.facing, Vector2.UP, "faces up")
	p.free()

func test_zero_input_keeps_facing() -> void:
	var p := _new_player()
	p.set_movement_input(Vector2.LEFT)
	p.set_movement_input(Vector2.ZERO)
	TestHelper.eq(p.facing, Vector2.LEFT, "facing preserved on no input")
	p.free()

func test_input_normalized() -> void:
	var p := _new_player()
	p.set_movement_input(Vector2(1, 1))
	TestHelper.is_true(
		absf(p.facing.x - 0.707106) < 0.0001 and absf(p.facing.y - 0.707106) < 0.0001,
		"diagonal normalized"
	)
	p.free()
