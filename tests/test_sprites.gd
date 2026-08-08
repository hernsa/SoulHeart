extends RefCounted

func _size(tex: Texture2D) -> Vector2i:
	return tex.get_image().get_size()

func test_sprite_sizes() -> void:
	TestHelper.eq(_size(Sprites.heart_texture()), Vector2i(14, 12), "heart 14x12")
	TestHelper.eq(_size(Sprites.player_texture()), Vector2i(8, 12), "player 8x12")
	TestHelper.eq(_size(Sprites.bullet_texture()), Vector2i(8, 8), "bullet 8x8")
	TestHelper.eq(_size(Sprites.star_texture()), Vector2i(5, 5), "star 5x5")
	TestHelper.eq(_size(Sprites.wisp_texture()), Vector2i(16, 16), "wisp 16x16")
	TestHelper.eq(_size(Sprites.toad_texture()), Vector2i(16, 16), "toad 16x16")

func test_heart_has_red_pixels() -> void:
	var img := Sprites.heart_texture().get_image()
	TestHelper.is_true(img.get_pixel(3, 2).r > 0.5, "heart center is reddish")
