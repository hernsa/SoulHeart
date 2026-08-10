@tool
extends SceneTree

func _init() -> void:
    _make_wisp("res://assets/sprites/wisp/wisp_idle.png", Color8(255, 216, 160))
    _make_wisp("res://assets/sprites/wisp/wisp_lit.png",  Color8(255, 238, 192))
    quit()

func _make_wisp(path: String, fill: Color) -> void:
    var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
    img.fill(Color8(0, 0, 0))
    for y in range(2, 14):
        for x in range(2, 14):
            img.set_pixel(x, y, fill)
    var dir_path := path.get_base_dir()
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
    var err := img.save_png(path)
    if err != OK:
        push_error("Failed to save %s: %d" % [path, err])