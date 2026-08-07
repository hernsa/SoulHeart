extends RefCounted

func test_marker_moves_and_bounces() -> void:
	var bar := FightBar.new()
	bar.speed = 1.0
	bar.tick(0.25)
	TestHelper.eq(bar.marker, 0.25, "moves right")
	bar.tick(1.0)
	TestHelper.eq(bar.marker, 1.0, "clamps at 1")
	bar.tick(0.5)
	TestHelper.eq(bar.marker, 0.5, "bounces back")
	bar.tick(1.0)
	TestHelper.eq(bar.marker, 0.0, "clamps at 0")

func test_press_values() -> void:
	var bar := FightBar.new()
	bar.marker = 0.5
	TestHelper.eq(bar.press(), 1.0, "center is perfect")
	bar.marker = 0.0
	TestHelper.eq(bar.press(), 0.0, "left edge is miss")
	bar.marker = 1.0
	TestHelper.eq(bar.press(), 0.0, "right edge is miss")
	bar.marker = 0.25
	TestHelper.eq(bar.press(), 0.5, "quarter point")
