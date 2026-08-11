extends Node2D

var _log: FileAccess

func _w(line: String) -> void:
	print(line)
	if _log:
		_log.store_line(line)

func _ready() -> void:
	_log = FileAccess.open("res://tools/probe_log.txt", FileAccess.WRITE)
	var room = load("res://scenes/rooms/GrumbleWoods.tscn").instantiate()
	add_child(room)
	await get_tree().create_timer(0.5).timeout
	var player: CharacterBody2D = get_tree().get_first_node_in_group("player")
	var tml: TileMapLayer = room.get_node("TileMapLayer")
	for cell in [Vector2i(3, 0), Vector2i(0, 1), Vector2i(3, 1)]:
		var td := tml.get_cell_tile_data(cell)
		if td == null:
			_w("cell %s: NO TILE DATA" % cell)
			continue
		_w("cell %s: layers=%d" % [cell, td.get_collision_polygons_count(0)])
		for li in 4:
			var n: int = td.get_collision_polygons_count(li)
			if n > 0:
				_w("  layer %d: %d polygons" % [li, n])
				for pi in n:
					_w("    poly %d points: %s" % [pi, td.get_collision_polygon_points(li, pi)])
	var space := player.get_world_2d().direct_space_state
	var q := PhysicsShapeQueryParameters2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(10, 14)
	q.shape = shape
	q.transform = Transform2D(0, player.global_position + Vector2(0, -1))
	q.collision_mask = 1
	var hits := space.intersect_shape(q, 32)
	_w("INTERSECT SHAPE at player: %d hits" % hits.size())
	for h in hits:
		_w("  hit: %s at %s" % [h.collider, h.collider.global_position])
	_w("PROBE DONE")
	get_tree().quit(0)