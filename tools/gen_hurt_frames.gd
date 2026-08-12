extends SceneTree

const IDS := ["mourning_knight", "index_f1", "index_f2", "index_f3", "canon_true", "moldsmal"]

func _init() -> void:
	for id in IDS:
		var src := Image.load_from_file(
				"res://assets/sprites/enemies/frames/%s/%s_000.png" % [id, id])
		for y in src.get_height():
			for x in src.get_width():
				var px := src.get_pixel(x, y)
				if px.a > 0.0 and px.get_luminance() > 0.1:
					src.set_pixel(x, y, px.lerp(Color(1, 1, 1, px.a), 0.6))
		var err := src.save_png("res://assets/sprites/enemies/%s_hurt.png" % id)
		if err == OK:
			print("wrote %s_hurt.png" % id)
		else:
			push_error("Failed to save %s_hurt.png: %d" % [id, err])
	quit()
