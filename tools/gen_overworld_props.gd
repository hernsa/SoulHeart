@tool
extends SceneTree

const OUT := "res://assets/sprites/overworld/"

func _init() -> void:
	_pine("tree_pine.png", Color8(0x2f, 0x4d, 0x2c), Color8(0x3f, 0x63, 0x38), Color8(0x1a, 0x2e, 0x1c), 0)
	_pine("tree_pine_b.png", Color8(0x3a, 0x59, 0x33), Color8(0x4c, 0x72, 0x40), Color8(0x1c, 0x32, 0x1e), 9)
	_birch("tree_birch.png")
	_dead("tree_dead.png")
	_bush("bush.png")
	_mushroom("mushroom.png")
	_grass("grass.png")
	print("Wrote 7 overworld sprites (trees 32x48)")
	quit()

func _save(img: Image, name: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var err := img.save_png(OUT + name)
	if err != OK:
		push_error("Failed to save %s: %d" % [name, err])

func _outline(img: Image, c: Color) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for y in h:
		for x in w:
			if img.get_pixel(x, y).a > 0.0:
				continue
			var dark := false
			var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
			for d: Vector2i in dirs:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx >= 0 and ny >= 0 and nx < w and ny < h and img.get_pixel(nx, ny).a > 0.0:
					dark = true
					break
			if dark:
				img.set_pixel(x, y, c)

func _pine(name: String, mid: Color, hi: Color, dark: Color, salt: int) -> void:
	var img := Image.create(32, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var taper: Array[int] = [3, 5, 8, 11, 14, 17, 20, 23, 26, 28, 30, 31, 31, 31, 31, 32, 32, 32, 32, 32, 32, 31, 30, 29, 27, 24]
	for y in 26:
		var wd: int = taper[y]
		var x0: int = 16 - wd / 2
		for i in wd:
			var x: int = x0 + i
			var inset := i == 0 or i == wd - 1
			var c: Color = mid
			if inset:
				c = dark
			elif (x + y + salt) % 4 == 0:
				c = hi
			img.set_pixel(x, y, c)
	for ty in 24:
		for tx in 6:
			var x := 13 + tx
			var y := 24 + ty
			if ty >= 23:
				continue
			var edgec: bool = tx == 0 or tx == 5 or ty >= 20
			img.set_pixel(x, y, dark if edgec else Color8(0x3e, 0x2b, 0x1c))
	_outline(img, Color8(0x12, 0x1e, 0x12))
	_save(img, name)

func _birch(name: String) -> void:
	var img := Image.create(32, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for ty in 47:
		for tx in 6:
			var x := 13 + tx
			var y := 1 + ty
			if tx == 0 or tx == 5 or ty == 0:
				img.set_pixel(x, y, Color8(0x41, 0x3a, 0x30))
			else:
				var speck: bool = (tx * 3 + ty * 5) % 11 == 0
				img.set_pixel(x, y, Color8(0x26, 0x22, 0x1e) if speck else Color8(0xc4, 0xbc, 0xa6))
	var blobs: Array[Rect2i] = [
		Rect2i(7, 1, 18, 10), Rect2i(4, 7, 12, 9), Rect2i(16, 7, 12, 9), Rect2i(10, 12, 12, 9),
	]
	for b: Rect2i in blobs:
		for y in range(b.position.y, b.position.y + b.size.y):
			for x in range(b.position.x, b.position.x + b.size.x):
				var dx: float = x - (b.position.x + b.size.x / 2.0)
				var dy: float = y - (b.position.y + b.size.y / 2.0)
				if dx * dx + dy * dy <= (b.size.x / 2.0) * (b.size.x / 2.0) * 0.7:
					var edge: bool = absf(dx) > b.size.x / 2.0 - 2.0 or absf(dy) > b.size.y / 2.0 - 2.0
					var c: Color = Color8(0x2c, 0x3a, 0x26) if edge else (Color8(0x4a, 0x66, 0x38) if (x + y) % 4 == 0 else Color8(0x3d, 0x56, 0x30))
					img.set_pixel(x, y, c)
	_outline(img, Color8(0x14, 0x1c, 0x12))
	_save(img, name)

func _dead(name: String) -> void:
	var img := Image.create(32, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for ty in 46:
		for tx in 6:
			var x := 13 + tx
			var y := 2 + ty
			var edgec: bool = tx == 0 or tx == 5 or ty == 0
			img.set_pixel(x, y, Color8(0x12, 0x0d, 0x09) if edgec else Color8(0x3c, 0x2a, 0x1c))
	var branches: Array[Array] = [
		[Vector2i(13, 8), Vector2i(-1, -1), 5], [Vector2i(17, 5), Vector2i(-1, -1), 4],
		[Vector2i(15, 12), Vector2i(1, -1), 5], [Vector2i(18, 16), Vector2i(1, -1), 4],
		[Vector2i(12, 20), Vector2i(-1, -1), 4], [Vector2i(19, 24), Vector2i(1, -1), 4],
		[Vector2i(14, 3), Vector2i(1, -1), 3], [Vector2i(16, 20), Vector2i(-1, -1), 3],
	]
	for b in branches:
		var pos: Vector2i = b[0]
		var dir: Vector2i = b[1]
		var len: int = b[2]
		for k in len:
			var x: int = pos.x + dir.x * k
			var y: int = pos.y + dir.y * (k + 1)
			img.set_pixel(x, y, Color8(0x33, 0x23, 0x17))
			if k == len - 1:
				for t in 2:
					img.set_pixel(x + (1 if dir.x < 0 else -1) + t - 1, y + 1, Color8(0x2a, 0x1c, 0x12))
	_outline(img, Color8(0x0f, 0x0a, 0x07))
	_save(img, name)

func _bush(name: String) -> void:
	var img := Image.create(12, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 8:
		var w := 12 if y >= 6 else (10 if y >= 4 else 6)
		var x0 := 6 - w / 2
		for i in w:
			var x: int = x0 + i
			var edge := i == 0 or i == w - 1 or y >= 6
			var c := Color8(0x1c, 0x30, 0x1c) if edge else (Color8(0x3e, 0x5c, 0x30) if (x + y) % 3 == 0 else Color8(0x2c, 0x48, 0x26))
			img.set_pixel(x, y, c)
	_save(img, name)

func _mushroom(name: String) -> void:
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 8:
		for x in 8:
			if y >= 4 and x >= 3 and x <= 4 and y <= 6:
				img.set_pixel(x, y, Color8(0xe8, 0xe0, 0xc8))
			elif y >= 5 and y <= 6 and x == 2:
				img.set_pixel(x, y, Color8(0xe8, 0xe0, 0xc8))
			elif y <= 4:
				var dx := x - 3.5
				var dy := y - 4.0
				if dx * dx + dy * dy <= 12.0:
					var spot := (x + y) % 6 == 0 and y < 4 and x > 1 and x < 6
					var edgec := dx * dx + dy * dy > 9.0
					var c: Color
					if spot:
						c = Color8(0xf0, 0xe8, 0xd8)
					elif edgec:
						c = Color8(0x7a, 0x18, 0x18)
					else:
						c = Color8(0xc8, 0x34, 0x30)
					img.set_pixel(x, y, c)
	_save(img, name)

func _grass(name: String) -> void:
	var img := Image.create(10, 6, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for b in 3:
		var bx := 1 + b * 4
		for k in 5:
			var y := 1 + k
			var t := 0 if k < 3 else 1
			var gx: int = bx + t
			if gx < 10:
				img.set_pixel(gx, y, Color8(0x2c, 0x4a, 0x22) if k == 4 else (Color8(0x4a, 0x6e, 0x2e) if (k + b) % 2 == 0 else Color8(0x3a, 0x5c, 0x28)))
	_save(img, name)