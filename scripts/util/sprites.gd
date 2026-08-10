class_name Sprites

static var _soul_cache := {}

static func soul_texture(color_name: String) -> Texture2D:
	if _soul_cache.has(color_name):
		return _soul_cache[color_name]
	var path := "res://assets/sprites/" + color_name + "_SOUL_sprite.png"
	var tex := load(path) as Texture2D
	if tex == null:
		tex = load("res://assets/sprites/Red_SOUL_sprite.png") as Texture2D
	_soul_cache[color_name] = tex
	return tex

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

static func bullet_texture_for(t: int) -> Texture2D:
	match t:
		Bullet.Type.BONE:
			return bone_texture()
		Bullet.Type.SPEAR:
			return spear_texture()
		Bullet.Type.RING:
			return ring_texture()
		Bullet.Type.LASER:
			return laser_texture()
		Bullet.Type.ARROW:
			return arrow_texture()
	return bullet_texture()

static func bone_texture() -> Texture2D:
	var img := Image.create(14, 10, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 10:
		for x in 14:
			var fill := false
			if y >= 2 and y <= 7:
				fill = true
			elif (x >= 2 and x <= 11) and (y == 1 or y == 8):
				fill = true
			elif (x >= 4 and x <= 9) and (y == 0 or y == 9):
				fill = true
			if fill:
				img.set_pixel(x, y, Color.WHITE)
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)

static func spear_texture() -> Texture2D:
	var img := Image.create(6, 22, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 22:
		var w := 1
		if y == 0:
			w = 5
		elif y < 4:
			w = 3
		elif y < 8:
			w = 2
		elif y < 20:
			w = 2
		for x in range(3 - w / 2, 3 + w / 2 + 1):
			if x >= 0 and x < 6:
				img.set_pixel(x, y, Color.WHITE)
	return ImageTexture.create_from_image(img)

static func ring_texture() -> Texture2D:
	var img := Image.create(14, 14, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(6.5, 6.5)
	for y in 14:
		for x in 14:
			var d := Vector2(x, y).distance_to(c)
			if d >= 5.5 and d <= 6.5:
				img.set_pixel(x, y, Color.WHITE)
	return ImageTexture.create_from_image(img)

static func laser_texture() -> Texture2D:
	var img := Image.create(24, 90, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 90:
		for x in 24:
			if x >= 10 and x <= 13:
				img.set_pixel(x, y, Color.WHITE)
	return ImageTexture.create_from_image(img)

static func arrow_texture() -> Texture2D:
	var img := Image.create(14, 6, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 6:
		for x in 14:
			var fill := false
			if x >= 2 and x <= 11:
				fill = (y >= 2 and y <= 3)
			elif x <= 2:
				fill = (y >= 1 and y <= 4)
			elif x >= 11:
				fill = (y == 0 or y == 5) or (y >= 2 and y <= 3)
			if fill:
				img.set_pixel(x, y, Color.WHITE)
	return ImageTexture.create_from_image(img)

static var _enemy_cache := {}
static var _enemy_frames := {
	"froggit": 38,
	"whimsun": 65,
	"moldsmal": 44,
	"loox": 9,
	"vegetoid": 5,
	"migosp": 19,
	"napstablook": 2,
}

static func _enemy_idle_texture(id: String) -> AnimatedTexture:
	var anim := AnimatedTexture.new()
	var count: int = _enemy_frames.get(id, 0)
	anim.frames = count
	var frame_duration := 1.0 / 15.0
	for i in count:
		var path := "res://assets/sprites/enemies/frames/" + id + "/" + id + "_%03d.png" % i
		var img := (load(path) as Texture2D).get_image()
		if img != null:
			anim.set_frame_texture(i, ImageTexture.create_from_image(_cutout_black(img)))
		anim.set_frame_duration(i, frame_duration)
	return anim

static func _cutout_black(img: Image) -> Image:
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	for y in range(h):
		for x in range(w):
			var px := img.get_pixel(x, y)
			var lum := px.r * 0.299 + px.g * 0.587 + px.b * 0.114
			if lum < 0.10:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	return img

static func battle_enemy_texture(id: String, hurt: bool) -> Texture2D:
	var key := id + ("_hurt" if hurt else "_idle")
	if _enemy_cache.has(key):
		return _enemy_cache[key]
	var tex: Texture2D
	if hurt:
		var hurt_tex := load("res://assets/sprites/enemies/" + id + "_hurt.png") as Texture2D
		if hurt_tex == null:
			tex = battle_enemy_texture(id, false)
		else:
			tex = ImageTexture.create_from_image(_cutout_black(hurt_tex.get_image()))
	else:
		tex = _enemy_idle_texture(id)
	_enemy_cache[key] = tex
	return tex

static var _prop_cache: Dictionary = {}

static func prop_texture(name: String) -> Texture2D:
	if _prop_cache.has(name):
		return _prop_cache[name]
	var path := "res://assets/sprites/overworld/" + name
	var tex := load(path) as Texture2D
	_prop_cache[name] = tex
	return tex

static var _save_point_anim: AnimatedTexture

static func save_point_texture() -> AnimatedTexture:
	if _save_point_anim != null:
		return _save_point_anim
	var anim := AnimatedTexture.new()
	anim.frames = 4
	var frame_duration := 1.0 / 15.0
	for i in 4:
		anim.set_frame_texture(i, load("res://assets/sprites/overworld/frames/save_point/save_point_%03d.png" % i) as Texture2D)
		anim.set_frame_duration(i, frame_duration)
	_save_point_anim = anim
	return anim

static var _frisk_cache: Dictionary = {}

static func player_frisk_texture(frame: int) -> Texture2D:
	if _frisk_cache.has(frame):
		return _frisk_cache[frame]
	var img: Image = Image.load_from_file("res://assets/sprites/overworld/frisk.png")
	var cell: Rect2i = Rect2i((frame % 2) * 19, int(frame / 2) * 29, 19, 29)
	var out: Image = Image.create(19, 29, false, Image.FORMAT_RGBA8)
	for y in 29:
		for x in 19:
			out.set_pixel(x, y, img.get_pixel(cell.position.x + x, cell.position.y + y))
	var tex: Texture2D = ImageTexture.create_from_image(out)
	_frisk_cache[frame] = tex
	return tex
