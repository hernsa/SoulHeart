class_name Sprites

static func heart_texture() -> Texture2D:
	var img := Image.create(14, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rows := [
		"....XXXXXX....",
		"....XXXXXX....",
		"..XXXXXXXXXX..",
		"..XXXXXXXXXX..",
		"XXXXXXXXXXXXXX",
		"XXXXXXXXXXXXXX",
		"XXXXXXXXXXXXXX",
		"XXXXXXXXXXXXXX",
		"..XXXXXXXXXX..",
		"..XXXXXXXXXX..",
		"....XXXXXX....",
		"....XXXXXX...."
	]
	for y in rows.size():
		for x in 14:
			if rows[y][x] == "X":
				var is_edge := y == 0 or y == rows.size() - 1 or x == 0 or x == 13
				img.set_pixel(x, y, Color(0.45, 0.05, 0.05) if is_edge else Color(0.85, 0.15, 0.15))
	return ImageTexture.create_from_image(img)

static func player_texture() -> Texture2D:
	var img := Image.create(8, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in 8:
		for y in 12:
			var c := Color(0.95, 0.8, 0.65)
			if y < 2:
				c = Color(0.25, 0.15, 0.1)
			elif y >= 4:
				c = Color(0.3, 0.45, 0.8) if y % 2 == 1 else Color(0.95, 0.95, 0.95)
			img.set_pixel(x, y, c)
	img.set_pixel(2, 3, Color(0.1, 0.1, 0.1))
	img.set_pixel(5, 3, Color(0.1, 0.1, 0.1))
	return ImageTexture.create_from_image(img)

static func bullet_texture() -> Texture2D:
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	for x in 8:
		for y in 8:
			if x == 0 or x == 7 or y == 0 or y == 7:
				img.set_pixel(x, y, Color(0.1, 0.1, 0.1))
	return ImageTexture.create_from_image(img)

static func star_texture() -> Texture2D:
	var img := Image.create(5, 5, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rows := ["..X..", ".XXX.", "XXXXX", ".XXX.", "..X.."]
	for y in rows.size():
		for x in 5:
			if rows[y][x] == "X":
				img.set_pixel(x, y, Color(1.0, 0.9, 0.2))
	return ImageTexture.create_from_image(img)

static func wisp_texture() -> Texture2D:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in 16:
		for y in 16:
			var dx := x - 8.0
			var dy := y - 9.0
			if dx * dx + dy * dy <= 36.0:
				img.set_pixel(x, y, Color(0.75, 0.9, 1.0, 0.95))
	for i in 2:
		img.set_pixel(8, 14 + i, Color(0.75, 0.9, 1.0, 0.7))
	return ImageTexture.create_from_image(img)

static func toad_texture() -> Texture2D:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in 16:
		for y in 16:
			var dx := x - 8.0
			var dy := y - 10.0
			if dx * dx + dy * dy <= 36.0:
				img.set_pixel(x, y, Color(0.3, 0.6, 0.35))
			elif y > 9 and y < 14 and absf(dx) <= 1.0:
				img.set_pixel(x, y, Color(0.3, 0.6, 0.35))
	img.set_pixel(6, 4, Color(0.1, 0.1, 0.1))
	img.set_pixel(10, 4, Color(0.1, 0.1, 0.1))
	return ImageTexture.create_from_image(img)

static func player_texture_frame(frame: int) -> ImageTexture:
	var img := Image.create(8, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 12:
		for x in 8:
			var hair := y < 2
			var body := y >= 2 and y < 10
			var leg_row := y >= 10
			var color := Color(0, 0, 0, 0)
			if hair:
				color = Color(0.25, 0.15, 0.1)
			elif body:
				if y % 2 == 1:
					color = Color(0.3, 0.45, 0.8)
				else:
					color = Color(0.95, 0.8, 0.65)
			elif leg_row:
				color = Color(0.2, 0.12, 0.08)
			img.set_pixel(x, y, color)
	if frame == 1:
		img.set_pixel(3, 11, Color(0, 0, 0, 0))
		img.set_pixel(4, 10, Color(0.2, 0.12, 0.08))
		img.set_pixel(2, 11, Color(0.2, 0.12, 0.08))
	img.set_pixel(2, 3, Color(0, 0, 0, 0))
	img.set_pixel(5, 3, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)

static func player_shadow_texture() -> ImageTexture:
	var img := Image.create(6, 3, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in 6:
		for y in 3:
			if not (x == 0 or x == 5 or (y == 0 and (x == 1 or x == 4))):
				img.set_pixel(x, y, Color(0, 0, 0, 0.4))
	return ImageTexture.create_from_image(img)

static func door_texture() -> ImageTexture:
	var img := Image.create(16, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var wood := Color(0.45, 0.3, 0.15)
	var dark := Color(0.3, 0.2, 0.1)
	for y in 32:
		for x in 16:
			var edge := x == 0 or x == 15 or y == 0 or y == 31
			var seam := x == 7 or x == 8
			var frame_dark := x == 1 or x == 14
			if edge:
				img.set_pixel(x, y, Color.WHITE)
			elif seam or frame_dark:
				img.set_pixel(x, y, dark)
			else:
				img.set_pixel(x, y, wood)
	img.set_pixel(8, 24, Color(0.9, 0.85, 0.4))
	img.set_pixel(8, 23, Color(0.9, 0.85, 0.4))
	return ImageTexture.create_from_image(img)
