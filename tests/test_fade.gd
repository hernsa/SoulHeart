extends RefCounted

func test_initial_state_and_noop() -> void:
	var fade = load("res://scripts/autoload/fade.gd").new()
	fade._ready()
	TestHelper.is_true(not fade.is_black(), "starts transparent")
	fade.fade_from_black(0.1)
	TestHelper.is_true(not fade.is_black(), "fade_from_black no-ops when transparent")
	fade.free()

func test_set_black_drives_state() -> void:
	var fade = load("res://scripts/autoload/fade.gd").new()
	fade._ready()
	fade.set_black(1.0)
	TestHelper.is_true(fade.is_black(), "black after set_black(1)")
	fade.set_black(0.0)
	TestHelper.is_true(not fade.is_black(), "transparent after set_black(0)")
	fade.free()
