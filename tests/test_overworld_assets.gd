extends RefCounted

func test_overworld_assets_exist() -> void:
	for f in ["frisk_sheet.png", "save_point.gif", "rock.png",
			"golden_flowers.png", "echo_flower.png", "froggit_npc.png",
			"tree_pine.png"]:
		TestHelper.is_true(FileAccess.file_exists("res://assets/sprites/overworld/" + f),
				"overworld asset: " + f)

func test_frisk_dimensions() -> void:
	var img := Image.load_from_file("res://assets/sprites/overworld/frisk_sheet.png")
	TestHelper.is_true(img != null, "frisk_sheet loads")
	if img == null:
		return
	TestHelper.eq(img.get_width(), 57, "frisk_sheet width 57 (3 cols of 19)")
	TestHelper.eq(img.get_height(), 116, "frisk_sheet height 116 (4 rows of 29)")

func test_prop_dimensions() -> void:
	var img := Image.load_from_file("res://assets/sprites/overworld/rock.png")
	TestHelper.is_true(img != null, "rock loads")
	if img == null:
		return
	TestHelper.eq(img.get_width(), 40, "rock width 40")
	TestHelper.eq(img.get_height(), 36, "rock height 36")
