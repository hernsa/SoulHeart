extends Node2D
class_name Hometown

const ROOM_PATH := "res://scenes/rooms/Hometown.tscn"

const ENCOUNTER_ENEMIES: Array[String] = ["toadally", "vegetoid", "punkin"]

const DOOR_TARGETS: Array[Dictionary] = [
	{"target_room": "res://scenes/rooms/Echo.tscn", "target_spawn": Vector2(600, 232)},
	{"target_room": "res://scenes/rooms/Canon.tscn", "target_spawn": Vector2(40, 232)},
]

const LAYOUT := """
########################################
#......................................#
#.P.TT..................................
#......................................#
#.............E........................#
#......................................#
#..........TT..........................#
#........S.............................#
#......................................#
#.............E........................#
#......................................#
#......................................#
#................TT....................#
#......................................#
#D...................................D.#
#......................................#
#......................................#
#.............E........................#
#......................................#
#......................................#
#......................................#
#......................................#
#..........TT..........................#
#......................................#
#...........E..........................#
#......................................#
#......................................#
#......................................#
#......................................#
########################################
"""

func _ready() -> void:
	var parsed := MapBuilder.parse_layout(LAYOUT)
	var start := _spawn_point(parsed["player_start"]) + Vector2(8, 8)
	var room := MapBuilder.build_room(parsed["grid"], GameTiles.HOMETOWN_STYLE)
	add_child(room["background"])
	add_child(room["tilemap"])
	for t in room["trees"]:
		add_child(t)
	for pr in room["props"]:
		add_child(pr)
	var tint := CanvasModulate.new()
	tint.color = Color(1.0, 0.93, 0.82)
	add_child(tint)
	_spawn_player(start, parsed["grid"])
	_spawn_save_points(parsed["save_points"])
	_spawn_encounters(parsed["encounters"])
	_spawn_door(parsed["doors"])
	_spawn_props()
	_spawn_wisp(_player)
	GameState.set_flag("current_room", ROOM_PATH)
	Audio.play_music("hometown")
	Audio.play_sfx("door_close")
	Fade.fade_from_black(0.67)

func _spawn_point(fallback: Vector2) -> Vector2:
	if GameState.flags.has("current_room") and str(GameState.flags["current_room"]) == ROOM_PATH and GameState.flags.has("save_point"):
		var sp: Array = GameState.flags["save_point"]
		return Vector2(float(sp[0]), float(sp[1]))
	return fallback

var _player: Node2D

func _spawn_player(start: Vector2, grid: Array) -> void:
	var player = load("res://scenes/Player.tscn").instantiate()
	player.position = start
	add_child(player)
	_player = player
	var cam := Camera2D.new()
	var room := MapBuilder.room_pixel_size(grid)
	cam.position = (room / 2.0).round()
	add_child(cam)
	if cam.is_inside_tree():
		cam.make_current()

func _spawn_wisp(player: Node2D) -> void:
	var wisp := preload("res://scenes/Wisp.tscn").instantiate()
	add_child(wisp)
	wisp.target_player = wisp.get_path_to(player)
	WispState.set_area("hometown")
	print(WispDialogue.get_line("hometown"))

func _spawn_props() -> void:
	var spots: Array[Vector2] = [Vector2(96, 96), Vector2(160, 320), Vector2(480, 160), Vector2(560, 400)]
	for i in spots.size():
		var p := Sprite2D.new()
		p.name = "Prop" + str(i)
		p.texture = Sprites.prop_texture("golden_flowers.png" if i % 2 == 0 else "rock.png")
		p.scale = Vector2(0.5, 0.5)
		p.position = spots[i]
		add_child(p)

func _spawn_save_points(points: Array) -> void:
	for p in points:
		var sp = load("res://scripts/rooms/save_point.gd").new()
		sp.position = p
		add_child(sp)

func _spawn_encounters(points: Array) -> void:
	for i in points.size():
		var enc = load("res://scripts/rooms/encounter.gd").new()
		enc.enemy_id = ENCOUNTER_ENEMIES[i % ENCOUNTER_ENEMIES.size()]
		enc.position = points[i]
		add_child(enc)

func _spawn_door(doors: Array) -> void:
	for i in doors.size():
		var cfg: Dictionary = DOOR_TARGETS[i % DOOR_TARGETS.size()]
		var door = load("res://scripts/rooms/door.gd").new()
		door.target_room = cfg["target_room"]
		door.target_spawn = cfg["target_spawn"]
		door.position = doors[i]["pos"]
		add_child(door)




