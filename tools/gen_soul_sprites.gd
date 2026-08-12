extends SceneTree

func _init() -> void:
	for color in ["Purple", "Yellow"]:
		var src := Image.load_from_file("res://assets/sprites/Red_SOUL_sprite.png")
		var tint := Color(0.72, 0.35, 0.9) if color == "Purple" else Color(1.0, 0.9, 0.2)
		for y in src.get_height():
			for x in src.get_width():
				var px := src.get_pixel(x, y)
				if px.a > 0.0:
					var lum := px.r * 0.299 + px.g * 0.587 + px.b * 0.114
					var f := lum / maxf(px.r + px.g + px.b, 0.001)
					src.set_pixel(x, y, Color(tint.r * f, tint.g * f, tint.b * f, px.a))
		src.save_png("res://assets/sprites/%s_SOUL_sprite.png" % color)
		print("wrote %s_SOUL_sprite.png" % color)
	quit()
