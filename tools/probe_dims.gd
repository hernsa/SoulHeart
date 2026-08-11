extends SceneTree
func _init() -> void:
	var names := ["tree_pine.png", "rock.png", "golden_flowers.png", "echo_flower.png", "froggit_npc.png", "shadow_ellipse.png", "old_dreamer.png"]
	for n in names:
		var img := Image.load_from_file("res://assets/sprites/overworld/" + n)
		if img == null:
			print(n + ": MISSING")
		else:
			print(n + ": " + str(img.get_width()) + "x" + str(img.get_height()))
	var img2 := Image.load_from_file("res://assets/sprites/shadow_ellipse.png")
	if img2 != null:
		print("shadow_ellipse(root): " + str(img2.get_width()) + "x" + str(img2.get_height()))
	quit()
