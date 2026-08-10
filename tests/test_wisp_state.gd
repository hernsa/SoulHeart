# tests/test_wisp_state.gd
extends RefCounted

func test_initial_mood_zero() -> void:
	WispState.reset()
	TestHelper.eq(WispState.mood(), 0, "fresh mood is 0")

func test_set_mood_clamps_high() -> void:
	WispState.reset()
	WispState.set_mood(150)
	TestHelper.eq(WispState.mood(), 100, "mood clamps to 100")

func test_set_mood_clamps_low() -> void:
	WispState.reset()
	WispState.set_mood(-30)
	TestHelper.eq(WispState.mood(), 0, "mood clamps to 0")

func test_add_hum_increments() -> void:
	WispState.reset()
	WispState.add_hum(20)
	TestHelper.eq(WispState.mood(), 20, "add_hum raises mood")
	WispState.add_hum(50)
	TestHelper.eq(WispState.mood(), 70, "add_hum accumulates")
	WispState.add_hum(50)
	TestHelper.eq(WispState.mood(), 100, "add_hum clamps at 100")

func test_hum_cooldown() -> void:
	WispState.reset()
	TestHelper.is_true(WispState.hum(), "first hum returns true")
	TestHelper.is_true(not WispState.hum(), "second hum within cooldown returns false")

func test_area_tracking() -> void:
	WispState.reset()
	WispState.set_area("drizzle_fields")
	TestHelper.eq(WispState.last_area(), "drizzle_fields", "area recorded")

func test_reset_clears_mood() -> void:
	WispState.set_mood(80)
	WispState.reset()
	TestHelper.eq(WispState.mood(), 0, "reset zeroes mood")
