class_name SectionPlacer extends RefCounted

const _CELL := 16

# Spawn everything in `objects` and `flavor` under `parent`. `layout_meta` is
# passed through so a future version can read per-section extras to drive
# ambience, lighting, etc. For now it is unused at the runtime layer.
static func spawn_all(parent: Node, objects: Array, flavor: Array, _layout_meta: Dictionary) -> void:
    for obj in objects:
        _spawn_object(parent, obj)
    for fl in flavor:
        _spawn_flavor(parent, fl)

static func _cell_to_pixel(cell: Vector2i) -> Vector2:
    return Vector2(cell.x * _CELL + 8, cell.y * _CELL + 8)

static func _spawn_object(parent: Node, obj: Dictionary) -> void:
    var cell: Vector2i = obj["cell"]
    var pos := _cell_to_pixel(cell)
    var t: String = obj["type"]
    match t:
        "save":
            var sp = load("res://scripts/rooms/save_point.gd").new()
            sp.position = pos
            parent.add_child(sp)
        "npc":
            var npc = load("res://scripts/rooms/npc.gd").new()
            var d: Dictionary = obj["data"]
            npc.dialogue_file = _dialogue_for(d.get("id", "wisp"))
            npc.position = pos
            npc._spawn_sprite(Sprites.prop_texture("froggit_npc.png"), Vector2(1.0, 1.0))
            parent.add_child(npc)
        "exit":
            var door = load("res://scripts/rooms/door.gd").new()
            var dd: Dictionary = obj["data"]
            door.target_room = str(dd["target"])
            door.target_spawn = Vector2(int(dd["target_spawn"].x), int(dd["target_spawn"].y))
            door.position = pos
            parent.add_child(door)
        "encounter":
            var enc = load("res://scripts/rooms/encounter.gd").new()
            enc.enemy_id = _encounter_enemy_for(obj.get("section_id", ""))
            enc.position = pos
            parent.add_child(enc)
        "landmark":
            var sprite := Sprite2D.new()
            sprite.name = "Landmark"
            sprite.texture = Sprites.prop_texture("golden_flowers.png")
            sprite.position = pos
            sprite.modulate = Color(1, 1, 0.6, 1)
            sprite.scale = Vector2(0.4, 0.4)
            parent.add_child(sprite)

static func _spawn_flavor(parent: Node, fl: Dictionary) -> void:
    var cell: Vector2i = fl["cell"]
    var pos := _cell_to_pixel(cell)
    var kind: String = fl["kind"]
    var sprite := Sprite2D.new()
    sprite.name = "Flavor_" + kind
    sprite.position = pos
    sprite.texture = _flavor_texture(kind)
    sprite.scale = Vector2(0.5, 0.5)
    parent.add_child(sprite)

static func _flavor_texture(kind: String) -> Texture2D:
    match kind:
        "tall_grass": return Sprites.prop_texture("tallgrass_0.png")
        "old_boot":   return Sprites.prop_texture("rock.png")
        "stick_circle": return Sprites.prop_texture("mushroom.png")
        "snapped_branch": return Sprites.prop_texture("tree_dead.png")
        "rock_pile":  return Sprites.prop_texture("rock.png")
        "cattail":    return Sprites.prop_texture("tallgrass_1.png")
        "pine_cone":  return Sprites.prop_texture("rock.png")
        "gnarled_root": return Sprites.prop_texture("tree_gnarled_b.png")
        "withered_flower": return Sprites.prop_texture("golden_flowers_dark.png")
    return Sprites.prop_texture("grass.png")

static func _dialogue_for(npc_id: String) -> String:
    match npc_id:
        "wisp": return "res://dialogue/wisp_intro.dlg"
    return "res://dialogue/drizzle_toad.dlg"

static func _encounter_enemy_for(section_id: String) -> String:
    var pool: Array[String] = ["froggit", "whimsun", "vegetoid", "loox"]
    var idx: int = 0
    for ch in section_id:
        idx = (idx + ch.unicode_at(0)) % pool.size()
    return pool[idx]