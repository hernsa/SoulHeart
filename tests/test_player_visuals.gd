extends RefCounted


func test_frisk_sheet_loads() -> void:
	var tex := load("res://assets/sprites/overworld/frisk_sheet.png")
	TestHelper.is_true(tex != null, "frisk_sheet.png should load")


func test_frisk_all_facings_have_content() -> void:
	for facing in 4:
		for step in 3:
			var tex := Sprites.player_frisk_texture(facing, step)
			TestHelper.is_true(tex != null, "frisk texture facing=%d step=%d" % [facing, step])
			if tex == null:
				continue
			var img := tex.get_image()
			img.convert(Image.FORMAT_RGBA8)
			var found_body := false
			for y in range(10, 29):
				for x in range(2, 17):
					if img.get_pixel(x, y).a > 0.5:
						found_body = true
						break
				if found_body:
					break
			TestHelper.is_true(found_body,
					"Frisk facing=%d step=%d should have body content" % [facing, step])


func test_frisk_walk_steps_distinct() -> void:
	var datas: Array = []
	for step in 3:
		datas.append(Sprites.player_frisk_texture(0, step).get_image().get_data())
	var distinct := 0
	var seen: Array = []
	for i in datas.size():
		var is_new := true
		for j in seen.size():
			if datas[i] == seen[j]:
				is_new = false
				break
		if is_new:
			seen.append(datas[i])
			distinct += 1
	TestHelper.eq(distinct, 3, "down walk should have 3 distinct frames, got " + str(distinct))


func test_aux_textures_exist() -> void:
	TestHelper.is_true(Sprites.player_shadow_texture() != null, "shadow exists")
	TestHelper.is_true(Sprites.door_texture() != null, "door exists")
