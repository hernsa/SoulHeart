extends SceneTree

const OUT_DIR := "res://assets/sprites/overworld/edits"

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	_save("shelf_book", _shelf_book())
	_save("wall_window", _wall_window())
	_save("door_moves", _door_moves())
	_save("name_changes", _name_changes())
	_save("portrait", _portrait())
	_save("floor_crack", _floor_crack())
	quit()

func _save(id: String, img: Image) -> void:
	var path := "%s/%s.png" % [OUT_DIR, id]
	img.save_png(path)
	print("wrote %s" % path)

func _new16() -> Image:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img

func _rect(img: Image, x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			img.set_pixel(x, y, c)

func _line(img: Image, from: Vector2i, to: Vector2i, c: Color) -> void:
	var steps := maxi(absi(to.x - from.x), absi(to.y - from.y))
	for i in steps + 1:
		var t := float(i) / float(steps)
		img.set_pixel(roundi(lerpf(from.x, to.x, t)), roundi(lerpf(from.y, to.y, t)), c)

func _shelf_book() -> Image:
	var img := _new16()
	_rect(img, 3, 6, 12, 12, Color(0.55, 0.35, 0.18))
	_rect(img, 4, 7, 11, 11, Color(0.95, 0.93, 0.88))
	_rect(img, 7, 6, 7, 12, Color(0.2, 0.11, 0.05))
	return img

func _wall_window() -> Image:
	var img := _new16()
	_rect(img, 2, 2, 13, 13, Color(1, 1, 1))
	_rect(img, 3, 3, 12, 12, Color(0.35, 0.55, 0.8))
	_rect(img, 7, 3, 7, 12, Color(1, 1, 1))
	_rect(img, 3, 7, 12, 7, Color(1, 1, 1))
	return img

func _door_moves() -> Image:
	var img := _new16()
	_rect(img, 4, 2, 11, 14, Color(0.05, 0.05, 0.05))
	_rect(img, 5, 3, 10, 13, Color(1, 1, 1))
	img.set_pixel(9, 8, Color(1, 0.8, 0.1))
	return img

func _name_changes() -> Image:
	var img := _new16()
	_rect(img, 2, 5, 13, 10, Color(0.9, 0.9, 0.7))
	_rect(img, 4, 7, 11, 7, Color(1, 1, 1))
	img.set_pixel(4, 9, Color(0.2, 0.2, 0.2))
	img.set_pixel(7, 9, Color(0.2, 0.2, 0.2))
	img.set_pixel(10, 9, Color(0.2, 0.2, 0.2))
	return img

func _portrait() -> Image:
	var img := _new16()
	_rect(img, 5, 7, 10, 12, Color(0.96, 0.82, 0.68))
	_rect(img, 4, 5, 11, 7, Color(0.32, 0.2, 0.13))
	img.set_pixel(6, 9, Color(0.12, 0.1, 0.09))
	img.set_pixel(9, 9, Color(0.12, 0.1, 0.09))
	img.set_pixel(7, 11, Color(0.6, 0.35, 0.3))
	return img

func _floor_crack() -> Image:
	var img := _new16()
	var pts: Array[Vector2i] = [
		Vector2i(2, 3), Vector2i(4, 3), Vector2i(5, 5), Vector2i(6, 5),
		Vector2i(7, 8), Vector2i(8, 8), Vector2i(9, 11), Vector2i(11, 11),
		Vector2i(12, 13),
	]
	for i in pts.size() - 1:
		_line(img, pts[i], pts[i + 1], Color(0.05, 0.05, 0.05))
	return img
