extends RefCounted

func test_font_file_exists() -> void:
	TestHelper.is_true(FileAccess.file_exists("res://assets/fonts/DMT-Mono.ttf"), "font file exists")

func test_theme_font_configured() -> void:
	var p: String = ProjectSettings.get_setting("gui/theme/custom_font", "")
	TestHelper.eq(p, "res://assets/fonts/DMT-Mono.ttf", "custom font path set in project.godot")

func test_font_resource_loads() -> void:
	var f := ResourceLoader.load("res://assets/fonts/DMT-Mono.ttf")
	TestHelper.is_true(f != null, "font resource loads after import")
