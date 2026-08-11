extends RefCounted

const BOSS_IDS := ["mourning_knight", "index_f1", "index_f2", "index_f3", "canon_true"]
const SIZES := {
	"mourning_knight": 32, "index_f1": 32, "index_f2": 32, "index_f3": 32,
	"canon_true": 40,
}

func test_boss_frames_exist() -> void:
	for id in BOSS_IDS:
		var path := "res://assets/sprites/enemies/frames/%s/%s_000.png" % [id, id]
		TestHelper.is_true(FileAccess.file_exists(path), "%s png exists" % id)
		var tex := load(path) as Texture2D
		TestHelper.is_true(tex != null, "%s png loads" % id)
		if tex == null:
			continue
		var img := tex.get_image()
		TestHelper.is_true(img != null, "%s has image" % id)
		if img == null:
			continue
		TestHelper.is_true(img.get_width() == int(SIZES[id]), "%s width %d" % [id, SIZES[id]])
		TestHelper.is_true(img.get_height() == int(SIZES[id]), "%s height %d" % [id, SIZES[id]])

func test_boss_frames_not_blank() -> void:
	for id in BOSS_IDS:
		var path := "res://assets/sprites/enemies/frames/%s/%s_000.png" % [id, id]
		var tex := load(path) as Texture2D
		if tex == null:
			continue
		var img := tex.get_image()
		if img == null:
			continue
		var lit := 0
		for y in img.get_height():
			for x in img.get_width():
				if img.get_pixel(x, y).a > 0.5:
					lit += 1
		TestHelper.is_true(lit > 100, "%s has drawn pixels (%d)" % [id, lit])

func test_battle_texture_non_null() -> void:
	for id in BOSS_IDS:
		TestHelper.is_true(Sprites.battle_enemy_texture(id, false) != null,
				"%s battle idle texture" % id)
		TestHelper.is_true(Sprites.battle_enemy_texture(id, true) != null,
				"%s battle hurt fallback texture" % id)