extends RefCounted

func test_enemy_sprite_uses_animated_texture() -> void:
	var battle := Battle.new()
	battle._enemy = EnemyLibrary.get_enemy("froggit")
	battle._spawn_enemy_sprite()
	TestHelper.is_true(battle._enemy_sprite != null, "sprite exists")
	TestHelper.is_true(battle._enemy_sprite.texture is AnimatedTexture, "idle is animated")
	battle.free()

func test_hurt_frame_swap() -> void:
	var battle := Battle.new()
	battle._enemy = EnemyLibrary.get_enemy("froggit")
	battle._spawn_enemy_sprite()
	var idle_tex := battle._enemy_sprite.texture
	battle._on_enemy_hurt_frame()
	TestHelper.is_true(battle._enemy_sprite.texture != idle_tex, "hurt texture applied")
	battle._restore_enemy_frame()
	TestHelper.is_true(battle._enemy_sprite.texture == idle_tex, "idle restored")
	battle.free()

func test_vaporize_spawns_poof() -> void:
	var battle := Battle.new()
	battle._spawn_vaporize_poof(Vector2(200, 140))
	TestHelper.is_true(battle.get_node_or_null("VaporizePoof") != null, "poof node exists")
	battle.free()
