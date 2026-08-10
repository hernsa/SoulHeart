@tool
extends SceneTree

const MOBS := [
    ["reminisc",  Color(0.7, 0.7, 0.8)],
    ["hushroom",  Color(0.7, 0.4, 0.86)],
    ["paneic",    Color(0.7, 0.78, 0.86)],
    ["squish",    Color(0.9, 0.51, 0.59)],
    ["sentimint", Color(0.59, 0.9, 0.67)],
    ["repeato",   Color(0.78, 0.78, 0.78)],
    ["toadally",  Color(0.51, 0.78, 0.51)],
    ["punkin",    Color(0.94, 0.71, 0.24)],
    ["nullaby",   Color(0.71, 0.71, 0.86)],
    ["quibble",   Color(0.9, 0.55, 0.39)],
    ["margin",    Color(0.86, 0.78, 0.63)],
    ["lookey",    Color(0.78, 0.71, 0.39)],
    ["remembran", Color(0.63, 0.63, 0.78)],
]

func _init() -> void:
    for entry in MOBS:
        _make_mob(entry[0], entry[1])
    quit()

func _make_mob(mob_id: String, fill: Color) -> void:
    var dir := "res://assets/sprites/enemies/frames/%s/" % mob_id
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
    var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
    img.fill(Color(0, 0, 0))
    for y in range(4, 28):
        for x in range(4, 28):
            img.set_pixel(x, y, fill)
    var err := img.save_png(dir + "%s_000.png" % mob_id)
    if err != OK:
        push_error("Failed to save %s_000.png: %d" % [mob_id, err])
