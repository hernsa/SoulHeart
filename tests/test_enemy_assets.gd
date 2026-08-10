extends RefCounted

func test_enemy_sprites_downloaded() -> void:
	for f in ["froggit_hurt.png", "whimsun_hurt.png", "loox_hurt.png",
			"vegetoid_hurt.png", "migosp_hurt.png"]:
		TestHelper.is_true(FileAccess.file_exists("res://assets/sprites/enemies/" + f),
				"enemy sprite exists: " + f)

func test_enemy_frame_sequences() -> void:
	var counts := {"froggit": 38, "whimsun": 65, "moldsmal": 44, "loox": 9,
			"vegetoid": 5, "migosp": 19, "napstablook": 2}
	for id in counts:
		var d := DirAccess.open("res://assets/sprites/enemies/frames/" + id)
		TestHelper.is_true(d != null, "frames dir exists: " + id)
		if d == null:
			continue
		var pngs := 0
		for f in d.get_files():
			if f.ends_with(".png"):
				pngs += 1
		TestHelper.eq(pngs, counts[id], "frame count for " + id)

func test_enemy_idle_cutout_removes_black_bg() -> void:
	var anim := Sprites._enemy_idle_texture("froggit")
	var img := anim.get_frame_texture(0).get_image()
	img.convert(Image.FORMAT_RGBA8)
	var corner := img.get_pixel(0, 0)
	TestHelper.is_true(corner.a == 0.0,
			"Enemy idle frame corner alpha should be 0 after cutout, got %f" % corner.a)

func test_enemy_idle_cutout_preserves_white_body() -> void:
	var anim := Sprites._enemy_idle_texture("froggit")
	var img := anim.get_frame_texture(0).get_image()
	img.convert(Image.FORMAT_RGBA8)
	var found := false
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var px := img.get_pixel(x, y)
			if px.a > 0.5 and px.r > 0.5:
				found = true
				break
		if found:
			break
	TestHelper.is_true(found, "Enemy idle frame should keep white silhouette pixels")

func test_enemy_hurt_cutout_removes_black_bg() -> void:
	var tex := Sprites.battle_enemy_texture("froggit", true)
	var img := tex.get_image()
	img.convert(Image.FORMAT_RGBA8)
	var corner := img.get_pixel(0, 0)
	TestHelper.is_true(corner.a == 0.0,
			"Enemy hurt texture corner alpha should be 0 after cutout, got %f" % corner.a)
