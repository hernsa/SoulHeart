@tool
extends SceneTree

func _initialize() -> void:
	var sheet: Image = Image.load_from_file("res://assets/sprites/overworld/frisk_sheet.png")
	if sheet == null:
		print("NO SHEET")
		quit(1)
		return
	
	# Row 2, step 0
	var rect2: Rect2i = Rect2i(0, 2 * 29, 19, 29)
	var row2: Image = Image.create(19, 29, false, Image.FORMAT_RGBA8)
	row2.blit_rect(sheet, rect2, Vector2i.ZERO)
	row2.save_png("res://tools/row2_verify.png")
	
	print("SAVED row2_verify.png")
	quit(0)
