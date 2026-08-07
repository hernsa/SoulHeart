extends Node2D

const ROOM_PATH := "res://scenes/rooms/DrizzleFields.tscn"

const LAYOUT := """
########################################
#....P....TT..............TT......T....#
#..................T...................#
#......TT......TT......................#
#...T......................TT........E.#
#............................TT........#
#......TT....TT.......................T#
#..TT........................TT........#
#.................TT..........E........#
#..........TT........TT................#
#..E........................TT....T....#
#.................TT..........T........#
#....TT......................TT........#
#..........TT...S...TT..................#
#......................TT..............#
#...T....TT..............TT.......T....#
#...................TT.................#
#..TT.......TT.........................#
#............TT..........TT...D........#
#.....TT...........TT...................#
#..........................TT....TT....#
#....TT....TT.................TT.......#
#..........T............TT.............#
#..E.................TT........TT..T...#
#.......................TT.............#
#.....TT...........TT...........TT.....#
#..TT...........T...........TT.........#
#............TT................TT..T...#
#.....T......TT....................T...#
########################################
"""

func _ready() -> void:
	var parsed := MapBuilder.parse_layout(LAYOUT)
	var start := _spawn_point(parsed["player_start"])
	var tml := MapBuilder.build_tilemap(parsed["grid"])
	add_child(tml)
	_spawn_player(start, parsed["grid"])
	_spawn_npc(Vector2(6 * 16, 9 * 16), "res://dialogue/drizzle_toad.dlg")
	_spawn_save_points(parsed["save_points"])
	_spawn_encounters(parsed["encounters"])
	_spawn_door(parsed["doors"])
	GameState.set_flag("current_room", ROOM_PATH)

func _spawn_point(fallback: Vector2) -> Vector2:
	if GameState.flags.has("current_room") and str(GameState.flags["current_room"]) == ROOM_PATH and GameState.flags.has("save_point"):
		var sp: Array = GameState.flags["save_point"]
		return Vector2(float(sp[0]), float(sp[1]))
	return fallback

func _spawn_player(start: Vector2, grid: Array) -> void:
	var player = load("res://scenes/Player.tscn").instantiate()
	player.position = start
	add_child(player)
	var cam := Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	var room := MapBuilder.room_pixel_size(grid)
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(room.x)
	cam.limit_bottom = int(room.y)
	player.add_child(cam)
	cam.make_current()

func _spawn_npc(pos: Vector2, dlg: String) -> void:
	var npc = load("res://scripts/rooms/npc.gd").new()
	npc.dialogue_file = dlg
	npc.position = pos
	var spr := Sprite2D.new()
	spr.texture = Sprites.toad_texture()
	npc.add_child(spr)
	add_child(npc)

func _spawn_save_points(points: Array) -> void:
	for p in points:
		var sp = load("res://scripts/rooms/save_point.gd").new()
		sp.position = p
		add_child(sp)

func _spawn_encounters(points: Array) -> void:
	for p in points:
		var enc = load("res://scripts/rooms/encounter.gd").new()
		enc.position = p
		add_child(enc)

func _spawn_door(doors: Array) -> void:
	if doors.is_empty():
		return
	var door = load("res://scripts/rooms/door.gd").new()
	door.target_room = "res://scenes/rooms/GrumbleWoods.tscn"
	door.target_spawn = Vector2(160, 100)
	door.position = doors[0]["pos"]
	add_child(door)
