extends RefCounted

func _size(tex: Texture2D) -> Vector2i:
	return tex.get_image().get_size()

func test_sprite_sizes() -> void:
	TestHelper.eq(_size(Sprites.soul_texture("Red")), Vector2i(16, 16), "soul 16x16")
	TestHelper.eq(_size(Sprites.player_texture()), Vector2i(8, 12), "player 8x12")
	TestHelper.eq(_size(Sprites.bullet_texture()), Vector2i(8, 8), "bullet 8x8")
	TestHelper.eq(_size(Sprites.star_texture()), Vector2i(5, 5), "star 5x5")
	TestHelper.eq(_size(Sprites.wisp_texture()), Vector2i(16, 16), "wisp 16x16")
	TestHelper.eq(_size(Sprites.toad_texture()), Vector2i(16, 16), "toad 16x16")

func test_soul_texture_is_ripped_heart() -> void:
	var tex := Sprites.soul_texture("Red")
	TestHelper.is_true(tex != null, "soul texture loads")
	if tex == null:
		return
	var img := tex.get_image()
	TestHelper.eq(img.get_width(), 16, "soul is 16px wide")
	TestHelper.eq(img.get_height(), 16, "soul is 16px tall")
	TestHelper.is_true(img.get_pixel(8, 4).r > 0.9, "heart body is bright red at (8,4)")
	TestHelper.is_true(img.get_pixel(7, 0).a < 0.1, "lobe notch (7,0) is transparent")
	TestHelper.is_true(img.get_pixel(8, 0).a < 0.1, "lobe notch (8,0) is transparent")

func test_soul_texture_fallback() -> void:
	var tex := Sprites.soul_texture("Nonexistent")
	TestHelper.is_true(tex != null, "fallback loads red soul")
