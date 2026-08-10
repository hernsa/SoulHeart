extends RefCounted

func test_prop_textures_load() -> void:
	for name: String in ["rock.png", "golden_flowers.png", "froggit_npc.png"]:
		var tex: Texture2D = Sprites.prop_texture(name)
		TestHelper.is_true(tex != null, "prop loads: " + name)

func test_save_point_uses_rip() -> void:
	var sp: Node2D = load("res://scripts/rooms/save_point.gd").new()
	sp._ready()
	var spr: Node = sp.get_node_or_null("StarSprite")
	TestHelper.is_true(spr != null, "save star sprite exists")
	if spr != null:
		var star: Sprite2D = spr as Sprite2D
		TestHelper.is_true(star.texture != null, "save star uses texture")
	sp.free()

func test_rooms_have_props() -> void:
	var drizzle: Node2D = load("res://scripts/rooms/drizzle_fields.gd").new()
	drizzle._ready()
	var count := 0
	for child: Node in drizzle.get_children():
		if child is Sprite2D and child.name.begins_with("Prop"):
			count += 1
	TestHelper.is_true(count >= 3, "drizzle has at least 3 props: " + str(count))
	drizzle.free()
