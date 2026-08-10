extends RefCounted

func test_wisp_idle_png_exists() -> void:
    TestHelper.is_true(FileAccess.file_exists("res://assets/sprites/wisp/wisp_idle.png"),
        "wisp_idle.png must exist at res://assets/sprites/wisp/")

func test_wisp_lit_png_exists() -> void:
    TestHelper.is_true(FileAccess.file_exists("res://assets/sprites/wisp/wisp_lit.png"),
        "wisp_lit.png must exist at res://assets/sprites/wisp/")

func test_wisp_idle_dimensions() -> void:
    var img := Image.new()
    var err := img.load("res://assets/sprites/wisp/wisp_idle.png")
    TestHelper.eq(err, OK, "wisp_idle.png must load without error")
    TestHelper.eq(img.get_width(), 16, "wisp_idle.png width must be 16")
    TestHelper.eq(img.get_height(), 16, "wisp_idle.png height must be 16")

func test_wisp_lit_dimensions() -> void:
    var img := Image.new()
    var err := img.load("res://assets/sprites/wisp/wisp_lit.png")
    TestHelper.eq(err, OK, "wisp_lit.png must load without error")
    TestHelper.eq(img.get_width(), 16, "wisp_lit.png width must be 16")
    TestHelper.eq(img.get_height(), 16, "wisp_lit.png height must be 16")
