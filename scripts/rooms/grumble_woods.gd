extends Node2D
class_name GrumbleWoods

const ROOM_PATH := "res://scenes/rooms/GrumbleWoods.tscn"

const ENCOUNTER_ENEMIES: Array[String] = ["migosp", "loox"]

const DOOR_TARGETS: Array[Dictionary] = [
	{"target_room": "res://scenes/rooms/Echo.tscn", "target_spawn": Vector2(40, 232)},
	{"target_room": "res://scenes/rooms/DrizzleFields.tscn", "target_spawn": Vector2(520, 392)},
]

const LAYOUT := """
########################################
#......................................#
#..P.........TT.............TT.........#
#..T................T................T.#
#......T......TT..TT............T......#
#.........................T............#
#..TT.......T.......T..........TT......#
#..............T....T..................#
#......E..........TT..TT...........T...#
#..T..........T..............T........T#
#.....................T..T.............#
#...........TT..............TT.........#
#..T.....T..............T..............#
#..................T..T................#
#...........E..........T......T........#
#..TT..............T...........TT......#
#.........................T............#
#......T.....TT..TT............T.......#
#.................T....................#
#..T..........T......T..........T......#
#..............TT................TT....#
#..T.....T..............T..............#
#.........E...........T..T.............#
#.....................................D#
#......................TT........T.....#
#..T......T.......................T....#
#.............................T..T..D..#
#..T..............T........T...........#
#...............T.......T....T......T..#
########################################
"""

const DRIZZLE_SPAWN := Vector2(4 * 16 + 8, 24 * 16 + 8)  # (72, 392)
const SIGN_POS := Vector2(5 * 16 + 8, 2 * 16 + 8)  # (88, 40)

func _ready() -> void:
	var parsed := MapBuilder.parse_layout(LAYOUT)
	var start := _spawn_point(parsed["player_start"]) + Vector2(8, 8)
	var room := MapBuilder.build_room(parsed["grid"], GameTiles.SNOWDIN_STYLE)
	add_child(room["background"])
	add_child(room["tilemap"])
	for t in room["trees"]:
		add_child(t)
	var tint := CanvasModulate.new()
	tint.color = Color(0.85, 0.9, 1.0)
	add_child(tint)
	_spawn_player(start, parsed["grid"])
	_spawn_sign(SIGN_POS)
	_spawn_encounters(parsed["encounters"])
	_spawn_door(parsed["doors"])
	_spawn_props()
	_spawn_wisp(_player)
	GameState.set_flag("current_room", ROOM_PATH)
	Audio.play_music("grumble")
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
	WispState.set_area("grumble_woods")
	print(WispDialogue.get_line("drizzle"))

func _spawn_sign(pos: Vector2) -> void:
	var sign_npc = load("res://scripts/rooms/npc.gd").new()
	sign_npc.dialogue_file = "res://dialogue/grumble_sign.dlg"
	sign_npc.position = pos
	sign_npc._spawn_sprite(Sprites.star_texture(), Vector2(2, 2))
	add_child(sign_npc)

func _spawn_props() -> void:
	var spots: Array[Vector2] = [Vector2(48, 144), Vector2(240, 48), Vector2(352, 112), Vector2(416, 160)]
	for i in spots.size():
		var p := Sprite2D.new()
		p.name = "Prop" + str(i)
		p.texture = Sprites.prop_texture("golden_flowers.png" if i % 2 == 0 else "rock.png")
		p.scale = Vector2(0.5, 0.5)
		p.position = spots[i]
		add_child(p)

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
