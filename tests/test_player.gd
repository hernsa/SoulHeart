extends RefCounted

const PlayerScript := preload("res://scripts/player/player.gd")

func _new_player() -> CharacterBody2D:
	return PlayerScript.new()

func test_default_facing() -> void:
	var p := _new_player()
	TestHelper.eq(p.facing, 0, "faces down by default (frame 0)")
	p.free()

func test_facing_mapping() -> void:
	var p := _new_player()
	p.set_movement_input(Vector2.RIGHT)
	TestHelper.eq(p.facing, 3, "right -> frame 3")
	p.set_movement_input(Vector2.UP)
	TestHelper.eq(p.facing, 1, "up -> frame 1")
	p.set_movement_input(Vector2.DOWN)
	TestHelper.eq(p.facing, 0, "down -> frame 0")
	p.free()

func test_zero_input_keeps_facing() -> void:
	var p := _new_player()
	p.set_movement_input(Vector2.LEFT)
	p.set_movement_input(Vector2.ZERO)
	TestHelper.eq(p.facing, 2, "facing preserved on no input (frame 2)")
	p.free()

func test_diagonal_falls_to_vertical() -> void:
	var p := _new_player()
	p.set_movement_input(Vector2(1, 1))
	TestHelper.eq(p.facing, 0, "diagonal (1,1) faces down")
	p.set_movement_input(Vector2(-1, -1))
	TestHelper.eq(p.facing, 1, "diagonal (-1,-1) faces up")
	p.free()
