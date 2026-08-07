extends RefCounted

const P := "res://scripts/player/player.gd"

func test_no_input() -> void:
	var r: Array = load(P).resolve_direction4(PackedStringArray(), PackedStringArray(), "")
	TestHelper.eq(r[0], Vector2.ZERO, "no input = zero")
	TestHelper.eq(r[1], "", "no input keeps last empty")

func test_single_axis() -> void:
	var r: Array = load(P).resolve_direction4(PackedStringArray(), PackedStringArray(["move_right"]), "")
	TestHelper.eq(r[0], Vector2.RIGHT, "held right -> right")

func test_last_pressed_wins() -> void:
	var held := PackedStringArray(["move_up", "move_right"])
	var r: Array = load(P).resolve_direction4(PackedStringArray(["move_right"]), held, "move_up")
	TestHelper.eq(r[0], Vector2.RIGHT, "last pressed right beats up")
	TestHelper.eq(r[1], "move_right", "last updated")

func test_last_released_falls_back() -> void:
	var r: Array = load(P).resolve_direction4(PackedStringArray(), PackedStringArray(["move_left", "move_down"]), "move_up")
	TestHelper.eq(r[0], Vector2.LEFT, "falls back to first held when last released")

func test_never_diagonal() -> void:
	var held := PackedStringArray(["move_left", "move_up", "move_right", "move_down"])
	var r: Array = load(P).resolve_direction4(PackedStringArray(), held, "move_down")
	var d: Vector2 = r[0]
	TestHelper.is_true(d.x == 0.0 or d.y == 0.0, "result is single-axis")
