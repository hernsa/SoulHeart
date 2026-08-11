@tool
extends SceneTree

# Deterministic torus-noise 16x16 floor tiles. Seamless by construction:
# the noise hash is periodic in both axes mod 16, so edges always match.

var STYLES := {
	"ruins":    {"base": Color8(104, 100, 120), "hi": Color8(126, 122, 142)},
	"snowdin":  {"base": Color8(64, 68, 88),    "hi": Color8(88, 94, 118)},
	"echo":     {"base": Color8(40, 44, 72),    "hi": Color8(56, 62, 98)},
	"hometown": {"base": Color8(102, 86, 64),   "hi": Color8(124, 106, 80)},
	"canon":    {"base": Color8(78, 64, 46),    "hi": Color8(96, 80, 58)},
	"cracks":   {"base": Color8(24, 24, 32),    "hi": Color8(40, 34, 54)},
}

func _init() -> void:
	for style in STYLES:
		var cfg: Dictionary = STYLES[style]
		_make(style, cfg["base"], cfg["hi"], 0)
		_make(style, cfg["base"], cfg["hi"], 7)
	print("Regenerated %d floor pairs" % STYLES.size())
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
			var v := 0.76 + 0.24 * n
			var c := Color8(int(base.r * 255.0 * v), int(base.g * 255.0 * v), int(base.b * 255.0 * v))
			if (hx + hy + salt) % 7 == 0:
				c = Color8(int(hi.r * 255.0 * v), int(hi.g * 255.0 * v), int(hi.b * 255.0 * v))
			img.set_pixel(x, y, c)
	var dir_path := "res://assets/sprites/tiles/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
	var variant := "floor" if salt == 0 else "floor_b"
	var err := img.save_png("res://assets/sprites/tiles/%s_%s.png" % [style, variant])
	if err != OK:
		push_error("Failed to save %s_%s.png: %d" % [style, variant, err])
