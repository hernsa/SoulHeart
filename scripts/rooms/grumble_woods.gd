extends Node2D

const ROOM_PATH := "res://scenes/rooms/GrumbleWoods.tscn"

const LAYOUT := """
##############################
#......T...........T.........#
#..T...............T......D..#
#........T......T............#
#..T................T....T...#
#...........T....T...........#
#.................T..........#
#...........T...........T....#
#..T.......T.................#
#...................T........#
#........T........T..........#
#..................T....T....#
##############################
"""

func _ready() -> void:
	var parsed := MapBuilder.parse_layout(LAYOUT)
	var start := _spawn_point(parsed["player_start"])
	add_child(MapBuilder.build_tilemap(parsed["grid"]))
	_spawn_player(start, parsed["grid"])
	_spawn_sign(Vector2(18 * 16, 4 * 16))
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
	cam.limit_top = -144
	cam.limit_right = int(room.x)
	cam.limit_bottom = 144
	player.add_child(cam)
	cam.make_current()

func _spawn_sign(pos: Vector2) -> void:
	var sign_npc = load("res://scripts/rooms/npc.gd").new()
	sign_npc.dialogue_file = "res://dialogue/grumble_sign.dlg"
	sign_npc.position = pos
	var spr := Sprite2D.new()
	spr.texture = Sprites.star_texture()
	spr.scale = Vector2(2, 2)
	sign_npc.add_child(spr)
	add_child(sign_npc)

func _spawn_door(doors: Array) -> void:
	if doors.is_empty():
		return
	var door = load("res://scripts/rooms/door.gd").new()
	door.target_room = "res://scenes/rooms/DrizzleFields.tscn"
	door.target_spawn = Vector2(32, 448)
	door.position = doors[0]["pos"]
	add_child(door)
