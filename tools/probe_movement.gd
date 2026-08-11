extends Node2D

func _ready() -> void:
	var room: Node2D = load("res://scenes/rooms/GrumbleWoods.tscn").instantiate()
	add_child(room)
	await get_tree().process_frame
	await get_tree().physics_frame
	
	var player: CharacterBody2D = get_tree().get_first_node_in_group("player")
	if not player:
		print("NO PLAYER FOUND")
		get_tree().quit(1)
		return
	
	print("SPAWN pos=", player.global_position, " slide_cols=", player.get_slide_collision_count())
	
	for action: String in ["move_right", "move_left", "move_up", "move_down"]:
		Input.action_press(action)
		await get_tree().physics_frame
		await get_tree().physics_frame
		await get_tree().physics_frame
		var vel: Vector2 = player.velocity
		var cols: int = player.get_slide_collision_count()
		print("  ", action, " vel=", vel, " slide_cols=", cols)
		var before: Vector2 = player.global_position
		for i in 30:
			await get_tree().physics_frame
		var after: Vector2 = player.global_position
		var delta: Vector2 = after - before
		print("    delta=", delta)
		Input.action_release(action)
		await get_tree().physics_frame
	
	print("PROBE DONE")
	get_tree().quit(0)
