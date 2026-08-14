extends Node2D
class_name DrizzleFields

const ROOM_PATH := "res://scenes/rooms/DrizzleFields.tscn"

# Kept for legacy test_door_spawn.gd which asserts the spawn cell is walkable.
const GRUMBLE_SPAWN := Vector2(32 * 16 + 8, 24 * 16 + 8)  # (520, 392)

# Snowdin exit target. Required by tests/test_snowdin.gd (file-text assertion)
# and validated in _ready: the composed objects must include an exit targeting it.
const SNOWDIN_EXIT := "res://scenes/rooms/Snowdin.tscn"

func _ready() -> void:
    var sections: Array = DrizzleSections.SECTIONS
    var adjacency: Array = DrizzleSections.ADJACENCY
    var composed: Dictionary = SectionMap.compose(sections, adjacency)
    if composed.has("error"):
        push_error("SectionMap failed: " + str(composed["error"]))
        return

    var master_grid: Array = _tile_grid_from(composed["grid"])
    var room: Dictionary = MapBuilder.build_room(master_grid, GameTiles.DRIZZLE_STYLE)
    add_child(_make_backdrop(composed["grid"]))
    add_child(room["background"])
    add_child(room["tilemap"])
    for t in room["trees"]:
        add_child(t)
    for pr in room["props"]:
        add_child(pr)

    var tint := CanvasModulate.new()
    tint.color = Color(0.97, 0.91, 0.78)
    add_child(tint)

    var spawn_cell: Vector2i = _spawn_cell_for(composed)
    var start := Vector2(spawn_cell.x * 16 + 8, spawn_cell.y * 16 + 8)
    _spawn_player(start)

    SectionPlacer.spawn_all(self, composed["objects"], composed["flavor"], composed["layout_meta"])

    var has_snowdin_exit := false
    for obj in composed["objects"]:
        if obj["type"] == "exit" and str(obj["data"].get("target", "")) == SNOWDIN_EXIT:
            has_snowdin_exit = true
    if not has_snowdin_exit:
        push_error("DrizzleFields: no composed exit targets " + SNOWDIN_EXIT)

    _spawn_wisp(_player)
    GameState.set_flag("current_room", ROOM_PATH)
    GameState.set_flag("whisperglen_pine_armed", true)
    Audio.play_music("drizzle")
    Fade.fade_from_black(0.67)

func _spawn_cell_for(composed: Dictionary) -> Vector2i:
    for obj in composed["objects"]:
        if obj["type"] == "save":
            return obj["cell"]
    return Vector2i(4, 4)

func _make_backdrop(master: Array) -> Node2D:
    var sprite := Sprite2D.new()
    sprite.texture = load("res://assets/sprites/backdrop/bg_firstroom.png") as Texture2D
    sprite.z_index = -2
    var h: int = master.size()
    var w: int = 0
    for row in master:
        w = maxi(w, (row as String).length())
    sprite.scale = Vector2(w * 16.0 / 680.0, 0.6)
    sprite.position = Vector2(w * 8, (h * 16.0) * 0.12)
    return sprite

func _tile_grid_from(master: Array) -> Array:
    var rows: Array = []
    for line in master:
        var row: Array = []
        for ch in (line as String):
            var tile: int = int(GameTiles.Tile.FLOOR)
            match ch:
                "#":
                    tile = int(GameTiles.Tile.WALL)
                "t":
                    tile = int(GameTiles.Tile.PINE2)
                "T":
                    tile = int(GameTiles.Tile.TREE)
                "b":
                    tile = int(GameTiles.Tile.BIRCH)
                "d":
                    tile = int(GameTiles.Tile.DEAD)
                "B":
                    tile = int(GameTiles.Tile.BUSH)
                "M":
                    tile = int(GameTiles.Tile.MUSHROOM)
                "g":
                    tile = int(GameTiles.Tile.GRASS)
            row.append(tile)
        rows.append(row)
    return rows

var _player: Node2D

func _spawn_player(start: Vector2) -> void:
    var player = load("res://scenes/Player.tscn").instantiate()
    player.position = start
    add_child(player)
    _player = player
    var cam := Camera2D.new()
    cam.position = start
    add_child(cam)
    if cam.is_inside_tree():
        cam.make_current()

func _spawn_wisp(player: Node2D) -> void:
    var wisp := preload("res://scenes/Wisp.tscn").instantiate()
    add_child(wisp)
    wisp.target_player = wisp.get_path_to(player)
    WispState.set_area("drizzle_fields")
    wisp.show_line("intro")
