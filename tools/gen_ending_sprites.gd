extends SceneTree

const OUT_DIR := "res://assets/sprites/overworld/"

const SPRITES: Dictionary = {
	"door_keeper": Color8(232, 163, 60),
	"door_wanderer": Color8(90, 123, 216),
	"door_hollow": Color8(10, 10, 14),
	"old_dreamer": Color8(184, 167, 216),
}

func _initialize() -> void:
	for key in SPRITES:
		var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		img.fill(SPRITES[key])
		if str(key).begins_with("door"):
			_draw_handle(img)
		img.save_png(OUT_DIR + str(key) + ".png")
	print("Wrote %d ending sprites" % SPRITES.size())
	quit(0)

func _draw_handle(img: Image) -> void:
	var c := Color(0, 0, 0, 0.35)
	for i in 4:
		img.set_pixel(12, 6 + i, c)