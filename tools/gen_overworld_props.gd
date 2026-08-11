@tool
extends SceneTree

const OUT := "res://assets/sprites/overworld/"

func _init() -> void:
	_pine("tree_pine.png", Color8(0x2f, 0x5a, 0x2f), Color8(0x44, 0x74, 0x3c), Color8(0x1c, 0x36, 0x1e), 0)
	_pine("tree_pine_b.png", Color8(0x3a, 0x66, 0x38), Color8(0x52, 0x82, 0x48), Color8(0x20, 0x3c, 0x22), 7)
	_birch("tree_birch.png")
	_dead("tree_dead.png")
	_bush("bush.png")
	_mushroom("mushroom.png")
	_grass("grass.png")
	print("Wrote 7 overworld sprites")
	quit()

func _save(img: Image, name: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var err := img.save_png(OUT + name)
	if err != OK:
		push_error("Failed to save %s: %d" % [name, err])

static func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)

func _pine(name: String, mid: Color, hi: Color, dark: Color, salt: int) -> void:
	var img := Image.create(24, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var taper: Array[int] = [4, 6, 8, 10, 12, 14, 16, 18, 18, 20, 20, 21, 21, 22, 22, 22, 23, 23, 23, 23, 24, 24, 24, 24]
	for y in 24:
		var w: int = taper[y]
		var x0: int = 12 - w / 2
		for i in w:
			var x: int = x0 + i
			var edge: bool = i == 0 or i == w - 1 or y >= 20
			var c: Color = dark if edge else (hi if (x + y + salt) % 3 == 0 else mid)
			_px(img, x, y, c)
	for ty in 24:
		for tx in 6:
			var x := 9 + tx
			var y := 24 + ty
			var trunk: bool = ty < 22
			if not trunk:
				continue
			var edgec: bool = tx == 0 or tx == 5 or ty == 21
			var c: Color = Color8(0x2a, 0x1a, 0x10) if edgec else Color8(0x4a, 0x32, 0x20)
			_px(img, x, y, c)
	_save(img, name)

func _birch(name: String) -> void:
	var img := Image.create(24, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for ty in 34:
		for tx in 8:
			var x := 8 + tx
			var y := 14 + ty
			if tx == 0 or tx == 7 or ty == 0 or ty == 33:
				_px(img, x, y, Color8(0x5a, 0x50, 0x42))
			else:
				var speck: bool = (tx * 3 + ty * 5) % 11 == 0
				_px(img, x, y, Color8(0x2e, 0x28, 0x22) if speck else Color8(0xc9, 0xc2, 0xb0))
	var blobs: Array[Rect2i] = [Rect2i(6, 0, 12, 8), Rect2i(3, 5, 8, 8), Rect2i(13, 5, 8, 8), Rect2i(8, 8, 10, 7)]
	for b: Rect2i in blobs:
		for y in range(b.position.y, b.position.y + b.size.y):
			for x in range(b.position.x, b.position.x + b.size.x):
				var dx: float = x - (b.position.x + b.size.x / 2.0)
				var dy: float = y - (b.position.y + b.size.y / 2.0)
				if dx * dx + dy * dy <= (b.size.x / 2.0) * (b.size.x / 2.0) * 0.8:
					var edge: bool = absf(dx) > b.size.x / 2.0 - 2.0 or absf(dy) > b.size.y / 2.0 - 2.0
					_px(img, x, y, Color8(0x2e, 0x3a, 0x28) if edge else Color8(0x55, 0x72, 0x42))
	_save(img, name)

func _dead(name: String) -> void:
	var img := Image.create(24, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for ty in 34:
		for tx in 6:
			var x := 9 + tx
			var y := 14 + ty
			var edgec: bool = tx == 0 or tx == 5 or ty == 0 or ty == 33
			_px(img, x, y, Color8(0x1e, 0x14, 0x0e) if edgec else Color8(0x4a, 0x34, 0x22))
	var branches: Array[Vector2i] = [Vector2i(9, 14), Vector2i(8, 10), Vector2i(6, 7), Vector2i(4, 5), Vector2i(11, 12), Vector2i(13, 9), Vector2i(15, 6), Vector2i(17, 4)]
	for i in branches.size():
		var b: Vector2i = branches[i]
		var len := 2 if i < 4 else 3
		var dir: Vector2i = Vector2i(-1, -1) if i < 4 else Vector2i(1, -1)
		for k in len:
			_px(img, b.x + dir.x * k, b.y + dir.y * k, Color8(0x3c, 0x28, 0x18))
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
			_px(img, x, y, c)
	_save(img, name)

func _mushroom(name: String) -> void:
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 8:
		for x in 8:
			if y >= 4 and x >= 3 and x <= 4 and y <= 6:
				_px(img, x, y, Color8(0xe8, 0xe0, 0xc8))
			elif y >= 5 and y <= 6 and x == 2:
				_px(img, x, y, Color8(0xe8, 0xe0, 0xc8))
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
					_px(img, x, y, c)
	_save(img, name)

func _grass(name: String) -> void:
	var img := Image.create(10, 6, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for b in 3:
		var bx := 1 + b * 4
		for k in 5:
			var y := 1 + k
			var t := 0 if k < 3 else 1
			_px(img, bx + t, y, Color8(0x2c, 0x4a, 0x22) if k == 4 else (Color8(0x4a, 0x6e, 0x2e) if (k + b) % 2 == 0 else Color8(0x3a, 0x5c, 0x28)))
	_save(img, name)