extends RefCounted

func test_chars_over_time() -> void:
	var tw := Typewriter.new()
	tw.chars_per_second = 10.0
	tw.start("hello")
	tw.advance(0.3)
	TestHelper.eq(tw.visible_chars(), 3, "3 chars after 0.3s")
	tw.advance(0.4)
	TestHelper.eq(tw.visible_chars(), 5, "capped at length")
	TestHelper.is_true(tw.is_done(), "done after full length")

func test_skip_and_restart() -> void:
	var tw := Typewriter.new()
	tw.chars_per_second = 10.0
	tw.start("abc")
	tw.advance(0.1)
	tw.skip()
	TestHelper.is_true(tw.is_done(), "skip completes")
	TestHelper.eq(tw.visible_chars(), 3, "skip shows all chars")
	tw.start("xyz")
	TestHelper.is_true(not tw.is_done(), "restart resets done")
	TestHelper.eq(tw.visible_chars(), 0, "restart resets progress")
