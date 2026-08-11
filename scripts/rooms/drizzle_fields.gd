extends Node2D
class_name DrizzleFields

const ROOM_PATH := "res://scenes/rooms/DrizzleFields.tscn"

const ENCOUNTER_ENEMIES: Array[String] = ["froggit", "whimsun", "vegetoid", "loox"]

const LAYOUT := """
########################################
#...g.........t.................t....T.#
#..P..T..........tt..............t.....#
#....g...........E.....................#
#..t.....t....TT...t....t.....t........#
#............t.................g.......#
#..B.....g..t......t.....t...B.........#
#.............t....t......t..t.........#
#..g..............g..................g.#
#..t..................t......t.........#
#......t....t...........tt......t......#
#..B..t......t.........................#
#...........t.......E....t.....t.......#
#..t....t.................tt...........#
#............g..........t..............#
#..t..........t...........t....t.......#
#......t......t..t.....................#
#..B......g.........t......t...........#
#...........t..........t..t......B.....#
#..t..........t.g......................#
#......t.....t......E.......t....t.....#
#.....................t................#
#..t..........t......t..t....t.........#
#.............g................g.......#
#...........S.....t...........t......D.#
#..t..............t....................#
#......t......t..........t.............#
#..g..........t....t...................#
#....t.............t..t.....g..........#
########################################
"""

const NPC_POS := Vector2(96, 144)
const GRUMBLE_SPAWN := Vector2(32 * 16 + 8, 24 * 16 + 8)  # (520, 392)

func _ready() -> void:
	var parsed := MapBuilder.parse_layout(LAYOUT)
	var start := _spawn_point(parsed["player_start"]) + Vector2(8, 8)
	var room := MapBuilder.build_room(parsed["grid"], GameTiles.RUINS_STYLE)
	add_child(room["background"])
	add_child(room["tilemap"])
	for t in room["trees"]:
		add_child(t)
	for pr in room["props"]:
		add_child(pr)
	var tint := CanvasModulate.new()
	tint.color = Color(0.8, 0.78, 1.0)
	add_child(tint)
	_spawn_player(start, parsed["grid"])
	_spawn_npc(NPC_POS, "res://dialogue/drizzle_toad.dlg")
	_spawn_save_points(parsed["save_points"])
	_spawn_encounters(parsed["encounters"])
	_spawn_door(parsed["doors"])
	_spawn_props()
	_spawn_wisp(_player)
	GameState.set_flag("current_room", ROOM_PATH)
	Audio.play_music("drizzle")
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
	WispState.set_area("drizzle_fields")
	print(WispDialogue.get_line("intro"))

func _spawn_npc(pos: Vector2, dlg: String) -> void:
	var npc = load("res://scripts/rooms/npc.gd").new()
	npc.dialogue_file = dlg
	npc.position = pos
	npc._spawn_sprite(Sprites.prop_texture("froggit_npc.png"), Vector2(1.0, 1.0))
	add_child(npc)

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
	if doors.is_empty():
		return
	var door = load("res://scripts/rooms/door.gd").new()
	door.target_room = "res://scenes/rooms/GrumbleWoods.tscn"
	door.target_spawn = GRUMBLE_SPAWN
	door.position = doors[0]["pos"]
	add_child(door)




