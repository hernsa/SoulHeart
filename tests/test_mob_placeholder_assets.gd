extends RefCounted

const NEW_IDS := [
	"reminisc", "hushroom", "paneic", "squish", "sentimint",
	"repeato", "toadally", "punkin", "nullaby", "quibble",
	"margin", "lookey", "remembran",
]

func test_each_new_mob_has_frame_dir() -> void:
	for mob_id in NEW_IDS:
		var dir := "res://assets/sprites/enemies/frames/%s/" % mob_id
		TestHelper.is_true(DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir)),
				"%s must have frames/ dir" % mob_id)
		TestHelper.is_true(FileAccess.file_exists(dir + "%s_000.png" % mob_id),
				"%s must have %s_000.png" % [mob_id, mob_id])

func test_each_new_mob_loads_as_texture() -> void:
	for mob_id in NEW_IDS:
		var tex := Sprites.battle_enemy_texture(mob_id, false)
		TestHelper.is_true(tex != null, "%s must have a battle texture" % mob_id)
