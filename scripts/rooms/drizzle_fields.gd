extends Node2D
class_name DrizzleFields

const ROOM_PATH := "res://scenes/rooms/DrizzleFields.tscn"

# Kept for legacy test_door_spawn.gd which asserts the spawn cell is walkable.
const GRUMBLE_SPAWN := Vector2(32 * 16 + 8, 24 * 16 + 8)  # (520, 392)

# Snowdin exit target. Required by tests/test_snowdin.gd (file-text assertion)
# and validated in _ready: the composed objects must include an exit targeting it.
const SNOWDIN_EXIT := "res://scenes/rooms/Snowdin.tscn"

# Runtime tree-border thickness in cells. The composed world is wrapped in this
# many cells of pine trees on every side so the camera (clamped to the bordered
# size) never reveals the edge-of-world void. Tests compose unbordered and stay green.
const EDGE_TREES := 2

func _ready() -> void:
    var sections: Array = DrizzleSections.SECTIONS
    var adjacency: Array = DrizzleSections.ADJACENCY
    var composed: Dictionary = SectionMap.compose(sections, adjacency)
    if composed.has("error"):
        push_error("SectionMap failed: " + str(composed["error"]))
        return

    var bordered: Dictionary = _wrap_with_trees(composed)
    var master_grid: Array = _tile_grid_from(bordered["grid"])
    var room: Dictionary = MapBuilder.build_room(master_grid, GameTiles.DRIZZLE_STYLE)
    add_child(_make_backdrop(bordered["grid"]))
    add_child(room["background"])
    add_child(room["tilemap"])
    for t in room["trees"]:
        add_child(t)
    for pr in room["props"]:
        add_child(pr)

    var tint := CanvasModulate.new()
    tint.color = Color(0.97, 0.91, 0.78)
    add_child(tint)

    var start: Vector2 = _spawn_point_for(bordered)
    _spawn_player(start, master_grid)

    SectionPlacer.spawn_all(self, bordered["objects"], bordered["flavor"], composed["layout_meta"])

    var has_snowdin_exit := false
    for obj in bordered["objects"]:
        if obj["type"] == "exit" and str(obj["data"].get("target", "")) == SNOWDIN_EXIT:
            has_snowdin_exit = true
    if not has_snowdin_exit:
        push_error("DrizzleFields: no composed exit targets " + SNOWDIN_EXIT)

    _spawn_wisp(_player)
    GameState.set_flag("current_room", ROOM_PATH)
    GameState.set_flag("whisperglen_pine_armed", true)
    Audio.play_music("drizzle")
    Fade.fade_from_black(0.67)

# Fresh entries spawn at the meadow's dedicated "spawn" object (open field,
# sightline to the grove). Door arrivals honor door.gd's pre-set save_point so
# returning players land on the door's target_spawn instead of the meadow.
func _spawn_point_for(composed: Dictionary) -> Vector2:
    if GameState.flags.has("current_room") and str(GameState.flags["current_room"]) == ROOM_PATH and GameState.flags.has("save_point"):
        var sp: Array = GameState.flags["save_point"]
        return Vector2(float(sp[0]), float(sp[1]))
    var cell: Vector2i = _spawn_cell_for(composed)
    return Vector2(cell.x * 16 + 8, cell.y * 16 + 8)

# Insets the composed world in a ring of pine trees and re-bases every object
# and flavor cell by the same offset, so spawners and doors land on the bordered
# grid exactly as they would on the raw one.
func _wrap_with_trees(composed: Dictionary) -> Dictionary:
    var grid: Array = composed["grid"]
    var w: int = 0
    for row in grid:
        w = maxi(w, (row as String).length())
    var h: int = grid.size()
    var border_line: String = "t".repeat(w + EDGE_TREES * 2)
    var rows: Array = []
    for i in EDGE_TREES:
        rows.append(border_line)
    for line in grid:
        var pad: String = ".".repeat(maxi(w - (line as String).length(), 0))
        rows.append("t".repeat(EDGE_TREES) + (line as String) + pad + "t".repeat(EDGE_TREES))
    for i in EDGE_TREES:
        rows.append(border_line)
    var offset := Vector2i(EDGE_TREES, EDGE_TREES)
    var objects: Array = []
    for obj in composed["objects"]:
        var copy: Dictionary = obj.duplicate()
        copy["cell"] = (obj["cell"] as Vector2i) + offset
        objects.append(copy)
    var flavor: Array = []
    for fl in composed["flavor"]:
        var copy: Dictionary = fl.duplicate()
        copy["cell"] = (fl["cell"] as Vector2i) + offset
        flavor.append(copy)
    return {"grid": rows, "objects": objects, "flavor": flavor}

func _spawn_cell_for(composed: Dictionary) -> Vector2i:
    for obj in composed["objects"]:
        if obj["type"] == "spawn":
            return obj["cell"]
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

func _spawn_player(start: Vector2, grid: Array) -> void:
    var player = load("res://scenes/Player.tscn").instantiate()
    player.position = start
    add_child(player)
    _player = player
    var cam := Camera2D.new()
    cam.position = start
    var size: Vector2 = MapBuilder.room_pixel_size(grid)
    cam.limit_left = 0
    cam.limit_top = 0
    cam.limit_right = int(size.x)
    cam.limit_bottom = int(size.y)
    add_child(cam)
    if cam.is_inside_tree():
        cam.make_current()

func _spawn_wisp(player: Node2D) -> void:
    var wisp := preload("res://scenes/Wisp.tscn").instantiate()
    add_child(wisp)
    wisp.target_player = wisp.get_path_to(player)
    WispState.set_area("drizzle_fields")
    wisp.show_line("intro")
