extends Node2D
class_name Canon

const ROOM_PATH := "res://scenes/rooms/Canon.tscn"

const ENCOUNTER_ENEMIES: Array[String] = ["nullaby", "quibble", "margin"]

const BOSSES: Array[Dictionary] = [
	{"id": "mourning_knight", "pos": Vector2(328, 248)},
]

const EDIT_EVENTS: Array[Dictionary] = [
	{"id": "shelf_book", "pos": Vector2(72, 40), "prompt": "A bookshelf gains a book you might have read."},
	{"id": "wall_window", "pos": Vector2(584, 40), "prompt": "A wall gains a window. Outside, it is raining somewhere."},
	{"id": "door_moves", "pos": Vector2(72, 424), "prompt": "A door that led somewhere now leads elsewhere."},
	{"id": "name_changes", "pos": Vector2(584, 424), "prompt": "A sign's name changes. The old name was almost yours."},
	{"id": "portrait", "pos": Vector2(296, 72), "prompt": "A portrait appears on the wall. It is not anyone you know."},
	{"id": "floor_crack", "pos": Vector2(360, 424), "prompt": "A crack in the floor closes. The floor is still deciding."},
]

const DOOR_TARGETS: Array[Dictionary] = [
	{"target_room": "res://scenes/rooms/Hometown.tscn", "target_spawn": Vector2(600, 232)},
	{"target_room": "res://scenes/rooms/Cracks.tscn", "target_spawn": Vector2(40, 232)},
]

const LAYOUT := """
########################################
#......................................#
#..P....................................
#......................................#
#.............E........................#
#......................................#
#......................................#
#........S.............................#
#......................................#
#.............E........................#
#......................................#
#......................................#
#......................................#
#......................................#
#D...................................D.#
#......................................#
#......................................#
#.............E........................#
#......................................#
#......................................#
#......................................#
#......................................#
#......................................#
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
	var room := MapBuilder.build_room(parsed["grid"], GameTiles.CANON_STYLE)
	add_child(room["background"])
	add_child(room["tilemap"])
	for t in room["trees"]:
		add_child(t)
	for pr in room["props"]:
		add_child(pr)
	var tint := CanvasModulate.new()
	tint.color = Color(0.92, 0.85, 0.72)
	add_child(tint)
	_spawn_player(start, parsed["grid"])
	_spawn_save_points(parsed["save_points"])
	_spawn_encounters(parsed["encounters"])
	_spawn_bosses()
	_spawn_door(parsed["doors"])
	_spawn_props()
	_spawn_edit_events()
	_spawn_wisp(_player)
	GameState.set_flag("current_room", ROOM_PATH)
	Audio.play_music("canon")
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
	WispState.set_area("canon")
	wisp.show_line("canon")


func _spawn_props() -> void:
	var spots: Array[Vector2] = [Vector2(160, 320), Vector2(416, 416)]
	for i in spots.size():
		var p := Sprite2D.new()
		p.name = "Prop" + str(i)
		p.texture = Sprites.prop_texture("rock.png")
		p.scale = Vector2(0.5, 0.5)
		p.position = spots[i]
		add_child(p)

func _spawn_edit_events() -> void:
	for e in EDIT_EVENTS:
		var ev = load("res://scripts/world/edit_event.gd").new()
		ev.event_id = str(e["id"])
		ev.prompt = str(e["prompt"])
		ev.position = e["pos"]
		add_child(ev)

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

func _spawn_bosses() -> void:
	for b in BOSSES:
		var enc = load("res://scripts/rooms/encounter.gd").new()
		enc.enemy_id = str(b["id"])
		enc.boss = true
		enc.position = b["pos"]
		add_child(enc)

func _spawn_door(doors: Array) -> void:
	for i in doors.size():
		var cfg: Dictionary = DOOR_TARGETS[i % DOOR_TARGETS.size()]
		var door = load("res://scripts/rooms/door.gd").new()
		door.target_room = cfg["target_room"]
		door.target_spawn = cfg["target_spawn"]
		door.position = doors[i]["pos"]
		add_child(door)




