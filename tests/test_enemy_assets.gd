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
