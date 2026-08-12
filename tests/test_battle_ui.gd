extends RefCounted

func test_authentic_box_geometry() -> void:
	TestHelper.eq(DodgeBox.BOX_RECT, Rect2(162, 220, 316, 190), "box 316x190 at 162,220")
	TestHelper.eq(DodgeBox.BOX_INNER, Rect2(167, 225, 306, 180), "inner playfield inset by 5px frame")
	TestHelper.eq(DodgeBox.HEART_START, Vector2(320, 315), "heart starts centered")
	TestHelper.is_true(DodgeBox.BOX_RECT.size.x / DodgeBox.BOX_RECT.size.y < 2.0, "box wider than tall but under 2:1")
	TestHelper.is_true(DodgeBox.BOX_RECT.size.x / DodgeBox.BOX_RECT.size.y > 1.4, "box keeps wide feel")

func test_hp_bar_dimensions() -> void:
	var battle := preload("res://scripts/battle/battle.gd").new()
	battle.max_hp = 20
	battle.hp = 12
	battle._build_hud()
	var underlay: ColorRect = battle.get_node("HPUnderlay")
	var fill: ColorRect = battle.get_node("HPFill")
	TestHelper.eq(underlay.size, Vector2(20.0 * 1.25, 21.0), "underlay 1.25px/HP, 21 tall")
	TestHelper.eq(fill.size, Vector2(12.0 * 1.25, 21.0), "fill tracks hp")
	TestHelper.eq(underlay.color, Color(0.753, 0.0, 0.0), "underlay is undertale red")
	TestHelper.eq(fill.color, Color(1.0, 1.0, 0.0), "fill is yellow")
	var name_label: Label = battle.get_node("NameLabel")
	TestHelper.eq(name_label.text, "DREAMCATCHER LV 1", "name label shows LV")
	var hp_label: Label = battle.get_node("HPLabel")
	TestHelper.eq(hp_label.text, "12 / 20", "hp label shows current/max")
	battle.free()

func test_fight_buttons_load_rips() -> void:
	var battle := preload("res://scripts/battle/battle.gd").new()
	battle._build_menu()
	for name in ["FIGHT", "ACT", "ITEM", "MERCY"]:
		var spr: Sprite2D = battle.get_node("MenuButtons/" + name)
		TestHelper.is_true(spr != null, "button node: " + name)
		if spr != null:
			var img := spr.texture.get_image()
			TestHelper.eq(img.get_width(), 110, "button 110 wide: " + name)
			TestHelper.eq(img.get_height(), 42, "button 42 tall: " + name)
	battle.free()

func test_menu_buttons_dim_unselected() -> void:
	var battle := preload("res://scripts/battle/battle.gd").new()
	battle._build_menu()
	var fight: Sprite2D = battle.get_node("MenuButtons/FIGHT")
	var act: Sprite2D = battle.get_node("MenuButtons/ACT")
	var item: Sprite2D = battle.get_node("MenuButtons/ITEM")
	TestHelper.eq(fight.modulate.a, 1.0, "FIGHT at full alpha when selected (index 0)")
	TestHelper.eq(act.modulate.a, 0.5, "ACT dimmed when unselected")
	TestHelper.eq(item.modulate.a, 0.5, "ITEM dimmed when unselected")
	battle._menu_index = 1
	battle._update_menu_colors()
	TestHelper.eq(fight.modulate.a, 0.5, "FIGHT dimmed after moving selection away")
	TestHelper.eq(act.modulate.a, 1.0, "ACT at full alpha after selection moves to index 1")
	battle.free()
