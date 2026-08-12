extends RefCounted

func test_intro_scene_exists() -> void:
	var ok := ResourceLoader.exists("res://scenes/IntroCutscene.tscn")
	TestHelper.is_true(ok, "intro cutscene scene file must exist")

func test_intro_script_loads() -> void:
	var s := load("res://scripts/cutscene/intro.gd")
	TestHelper.is_true(s != null, "intro script must load")

func test_main_falls_through_to_intro() -> void:
	var src := FileAccess.get_file_as_string("res://scripts/main.gd")
	TestHelper.is_true(src.find("IntroCutscene.tscn") != -1, "main.gd must launch intro cutscene")

func test_intro_lifts_fade_veil() -> void:
	var src := FileAccess.get_file_as_string("res://scripts/cutscene/intro.gd")
	TestHelper.is_true(src.find("fade_from_black") != -1, "intro must clear the title's fade veil")
