@tool
extends SceneTree

const BOSSES := [
	["mourning_knight", 32],
	["index_f1", 32],
	["index_f2", 32],
	["index_f3", 32],
	["canon_true", 40],
]

func _init() -> void:
	for entry in BOSSES:
		_make_boss(str(entry[0]), int(entry[1]))
	quit()

func _make_boss(boss_id: String, size: int) -> void:
	var dir := "res://assets/sprites/enemies/frames/%s/" % boss_id
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 1))
	match boss_id:
		"mourning_knight":
			_knight(img)
		"index_f1", "index_f2", "index_f3":
			_index(img, boss_id)
		"canon_true":
			_canon_true(img)
	var err := img.save_png(dir + "%s_000.png" % boss_id)
	if err != OK:
		push_error("Failed to save %s_000.png: %d" % [boss_id, err])

func _knight(img: Image) -> void:
	var armor := Color(0.353, 0.369, 0.4)
	var dark := Color(0.173, 0.18, 0.2)
	var light := Color(0.431, 0.447, 0.502)
	for y in range(8, 17):
		for x in range(11, 21):
			img.set_pixel(x, y, armor)
	for y in range(13, 16):
		for x in range(13, 19):
			img.set_pixel(x, y, Color(0, 0, 0, 0))
	for y in range(17, 20):
		for x in range(9, 23):
			img.set_pixel(x, y, light)
	for y in range(20, 28):
		for x in range(12, 20):
			img.set_pixel(x, y, armor)
	for y in range(6, 26):
		img.set_pixel(25, y, armor)
	for y in range(26, 28):
		img.set_pixel(25, y, dark)

func _index(img: Image, boss_id: String) -> void:
	var robe := Color(0.102, 0.102, 0.133)
	var quill := Color(0.91, 0.91, 0.933)
	if boss_id == "index_f2":
		robe = Color(0.102, 0.133, 0.267)
	elif boss_id == "index_f3":
		robe = Color(0.267, 0.102, 0.133)
	for y in range(10, 31):
		for x in range(12, 20):
			img.set_pixel(x, y, robe)
	for y in range(4, 10):
		for x in range(14, 18):
			img.set_pixel(x, y, robe.lightened(0.1))
	var hand := Vector2i(20, 24)
	var nib := Vector2i(27, 15)
	if boss_id == "index_f2":
		hand = Vector2i(20, 26)
		nib = Vector2i(25, 22)
	elif boss_id == "index_f3":
		hand = Vector2i(20, 22)
		nib = Vector2i(28, 14)
	img.set_pixel(hand.x, hand.y, quill)
	var dx := signi(nib.x - hand.x)
	var dy := signi(nib.y - hand.y)
	var px := hand.x
	var py := hand.y
	while px != nib.x or py != nib.y:
		img.set_pixel(px, py, quill)
		if px != nib.x:
			px += dx
		if py != nib.y:
			py += dy
	img.set_pixel(nib.x, nib.y, quill.darkened(0.25))

func _canon_true(img: Image) -> void:
	var coat := Color(0.114, 0.098, 0.141)
	var brim := Color(0.102, 0.094, 0.129)
	var glint := Color(0.941, 0.91, 0.816)
	for y in range(16, 38):
		for x in range(14, 27):
			img.set_pixel(x, y, coat)
	for y in range(4, 10):
		for x in range(17, 23):
			img.set_pixel(x, y, coat)
	for y in range(8, 14):
		for x in range(10, 30):
			img.set_pixel(x, y, brim)
	for y in range(15, 18):
		for x in range(20, 26):
			img.set_pixel(x, y, coat.lightened(0.15))
	img.set_pixel(24, 16, glint)
	img.set_pixel(25, 16, glint.darkened(0.2))