@tool
extends SceneTree

func _initialize() -> void:
	var sheet: Image = Image.load_from_file("res://assets/sprites/overworld/frisk_sheet.png")
	if sheet == null:
		print("NO SHEET")
		quit(1)
		return
	
	# Row 3, step 0
	var rect3: Rect2i = Rect2i(0, 3 * 29, 19, 29)
	var row3: Image = Image.create(19, 29, false, Image.FORMAT_RGBA8)
	row3.blit_rect(sheet, rect3, Vector2i.ZERO)
	row3.save_png("res://tools/row3_raw.png")
	
	# Row 3 FLIPPED (as used for facing=3)
	var row3_flip: Image = Image.create(19, 29, false, Image.FORMAT_RGBA8)
	row3_flip.blit_rect(sheet, rect3, Vector2i.ZERO)
	row3_flip.flip_x()
	row3_flip.save_png("res://tools/row3_flipped.png")
	
	print("SAVED row3_raw + row3_flipped")
	quit(0)
