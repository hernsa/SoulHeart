extends RefCounted


func test_player_frames_exist() -> void:
	TestHelper.is_true(Sprites.player_texture_frame(0) != null, "frame 0 exists")
	TestHelper.is_true(Sprites.player_texture_frame(1) != null, "frame 1 exists")


func test_player_frames_differ() -> void:
	var a: Image = Sprites.player_texture_frame(0).get_image()
	var b: Image = Sprites.player_texture_frame(1).get_image()
	TestHelper.is_true(a.get_data() != b.get_data(), "walk frames differ")


func test_aux_textures_exist() -> void:
	TestHelper.is_true(Sprites.player_shadow_texture() != null, "shadow exists")
	TestHelper.is_true(Sprites.door_texture() != null, "door exists")
