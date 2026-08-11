extends SceneTree

func _initialize() -> void:
	print("=== INPUT MAP ===")
	for action in ["move_left", "move_right", "move_up", "move_down"]:
		var parts: Array[String] = []
		for ev in InputMap.action_get_events(action):
			var k: InputEventKey = ev
			parts.append("%s(phys=%s)" % [OS.get_keycode_string(k.physical_keycode), int(k.physical_keycode)])
		print("  %s: %s" % [action, ", ".join(parts)])
	var sheet := Image.load_from_file("res://assets/sprites/overworld/frisk_sheet.png")
	print("=== FRISK SHEET %dx%d ===" % [sheet.get_width(), sheet.get_height()])
	var row2 := Image.create(19, 29, false, Image.FORMAT_RGBA8)
	row2.blit_rect(sheet, Rect2i(0, 2 * 29, 19, 29), Vector2i.ZERO)
	row2.resize(76, 116)
	row2.save_png("res://tools/row2.png")
	var row3 := Image.create(19, 29, false, Image.FORMAT_RGBA8)
	row3.blit_rect(sheet, Rect2i(0, 3 * 29, 19, 29), Vector2i.ZERO)
	row3.resize(76, 116)
	row3.save_png("res://tools/row3.png")
	print("saved row2.png + row3.png")
	quit(0)