extends RefCounted


func test_player_uses_frisk_rip() -> void:
	for frame in 4:
		var tex := Sprites.player_frisk_texture(frame)
		TestHelper.is_true(tex != null, "frisk frame " + str(frame) + " loads")
		if tex != null:
			var img := tex.get_image()
			TestHelper.eq(img.get_width(), 19, "frame width 19")
			TestHelper.eq(img.get_height(), 29, "frame height 29")


func test_frames_are_distinct() -> void:
	var datas: Array = []
	for frame in 4:
		datas.append(Sprites.player_frisk_texture(frame).get_image().get_data())
	var distinct: int = 0
	var seen: Array = []
	for i in datas.size():
		var is_new: bool = true
		for j in seen.size():
			if datas[i] == seen[j]:
				is_new = false
				break
		if is_new:
			seen.append(datas[i])
			distinct += 1
	TestHelper.is_true(distinct >= 3, "at least 3 distinct directions: " + str(distinct))


func test_aux_textures_exist() -> void:
	TestHelper.is_true(Sprites.player_shadow_texture() != null, "shadow exists")
	TestHelper.is_true(Sprites.door_texture() != null, "door exists")
