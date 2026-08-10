# tests/test_wisp_follower.gd
extends RefCounted

const WispScene := preload("res://scenes/Wisp.tscn")

func test_wisp_scene_loads() -> void:
	var wisp := WispScene.instantiate()
	TestHelper.is_true(wisp != null, "Wisp.tscn must instantiate")
	TestHelper.is_true(wisp is Node2D, "Wisp root must be Node2D")
	wisp.free()

func test_wisp_has_target_player_property() -> void:
	var wisp: Node2D = WispScene.instantiate()
	TestHelper.is_true("target_player" in wisp, "Wisp must expose 'target_player' property")
	wisp.free()

func test_wisp_lerp_speed_property() -> void:
	var wisp: Node2D = WispScene.instantiate()
	TestHelper.is_true("lerp_speed" in wisp, "Wisp must expose 'lerp_speed' property")
	TestHelper.is_true(wisp.lerp_speed > 0.0, "lerp_speed must be positive")
	wisp.free()

func test_wisp_moves_toward_player() -> void:
	var wisp: Node2D = WispScene.instantiate()
	wisp.position = Vector2(0, 0)
	var stub := Node2D.new()
	stub.position = Vector2(100, 0)
	stub.add_to_group("player")
	wisp._player = stub
	wisp._process(0.1)
	TestHelper.is_true(wisp.position.x > 0.0, "wisp must move toward player x")
	TestHelper.is_true(wisp.position.x < 100.0, "wisp must not overshoot")
	wisp.free()
	stub.free()

func test_wisp_sprite_switches_at_high_mood() -> void:
	WispState.reset()
	var wisp: Node2D = WispScene.instantiate()
	wisp._ensure_children()
	TestHelper.is_true(wisp._sprite != null, "wisp must build its sprite")
	WispState.set_mood(80)
	wisp._update_sprite_for_mood()
	var lit_img := Image.load_from_file("res://assets/sprites/wisp/wisp_lit.png")
	var lit_tex := ImageTexture.create_from_image(lit_img) if lit_img != null else null
	if lit_tex != null:
		TestHelper.is_true(wisp._sprite.texture.get_image().get_pixel(3, 3) != Color(0, 0, 0), "lit sprite not black at pixel 3,3")
	wisp.free()
	WispState.reset()