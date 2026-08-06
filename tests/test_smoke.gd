extends RefCounted

func test_runner_works() -> void:
	TestHelper.eq(1 + 1, 2, "smoke")
