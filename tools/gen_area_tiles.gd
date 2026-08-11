@tool
extends SceneTree

# Deterministic torus-noise 16x16 floor tiles. Seamless by construction:
# the noise hash is periodic in both axes mod 16, so edges always match.

var STYLES := {
	"echo":     {"base": Color8(38, 42, 72),   "hi": Color8(58, 64, 104)},
	"hometown": {"base": Color8(92, 74, 54),   "hi": Color8(116, 94, 68)},
	"canon":    {"base": Color8(70, 56, 38),   "hi": Color8(94, 76, 52)},
	"cracks":   {"base": Color8(22, 22, 32),   "hi": Color8(48, 40, 66)},
}

func _init() -> void:
	for style in STYLES:
		var cfg: Dictionary = STYLES[style]
		_make(style, cfg["base"], cfg["hi"], 0)
		_make(style, cfg["base"], cfg["hi"], 7)
	quit()

func _hash(x: int, y: int, salt: int) -> int:
	var h := (x * 374761393 + y * 668265263 + salt * 1442695041) & 0x7fffffff
	h = ((h >> 13) ^ h) * 1274126177 & 0x7fffffff
	return h

func _make(style: String, base: Color, hi: Color, salt: int) -> void:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in 16:
		for x in 16:
			var hx := x % 15
			var hy := y % 15
			var n := float(_hash(hx, hy, salt)) / float(0x7fffffff)
			var v := 0.55 + 0.45 * n
			var c := Color8(int(base.r * 255.0 * v), int(base.g * 255.0 * v), int(base.b * 255.0 * v))
			if (hx + hy + salt) % 5 == 0:
				c = Color8(int(hi.r * 255.0 * v), int(hi.g * 255.0 * v), int(hi.b * 255.0 * v))
			img.set_pixel(x, y, c)
	var dir_path := "res://assets/sprites/tiles/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
	var variant := "floor" if salt == 0 else "floor_b"
	var err := img.save_png("res://assets/sprites/tiles/%s_%s.png" % [style, variant])
	if err != OK:
		push_error("Failed to save %s_%s.png: %d" % [style, variant, err])
