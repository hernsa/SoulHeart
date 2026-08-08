extends RefCounted

func test_soul_sprites_exist() -> void:
	for f in ["Red_SOUL_sprite.png", "Blue_SOUL_sprite.png", "Green_SOUL_sprite.png",
			"Light_blue_SOUL_sprite.png", "Orange_SOUL_sprite.png"]:
		var img := Image.load_from_file("res://assets/sprites/" + f)
		TestHelper.is_true(img != null, "soul asset loads: " + f)
		if img == null:
			continue
		TestHelper.eq(img.get_width(), 16, "soul width 16: " + f)
		TestHelper.eq(img.get_height(), 16, "soul height 16: " + f)

func test_button_sprites_exist() -> void:
	for f in ["FIGHT_sprite_button.png", "ACT_sprite_button.png",
			"ITEM_sprite_button.png", "MERCY_sprite_button.png"]:
		var img := Image.load_from_file("res://assets/sprites/" + f)
		TestHelper.is_true(img != null, "button asset loads: " + f)
		if img == null:
			continue
		TestHelper.eq(img.get_width(), 110, "button width 110: " + f)
		TestHelper.eq(img.get_height(), 42, "button height 42: " + f)
