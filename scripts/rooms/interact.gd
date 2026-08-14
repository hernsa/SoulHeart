extends Area2D

@export var kind: String = "stick_circle"

const _SPRITES := {
	"lone_pine": "singletree.png",
	"ridge_sign": "ridge_sign.png",
	"stick_circle": "mushroom.png",
	"lostword": "echoflower_glow.png",
}

const _DIALOGUES := {
	"lone_pine": "res://dialogue/lone_pine.dlg",
	"lone_pine_quiet": "res://dialogue/lone_pine_quiet.dlg",
	"ridge_sign": "res://dialogue/ridge_sign.dlg",
	"stick_circle": "res://dialogue/stick_circle.dlg",
	"lostword": "res://dialogue/lostword_echo.dlg",
}

func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 10
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	var spr := Sprite2D.new()
	spr.texture = Sprites.prop_texture(str(_SPRITES.get(kind, "mushroom.png")))
	spr.scale = Vector2(0.5, 0.5)
	add_child(spr)

func _dialogue_file() -> String:
	if kind == "lone_pine":
		if GameState.flags.get("whisperglen_pine_armed", false):
			return str(_DIALOGUES["lone_pine"])
		return str(_DIALOGUES["lone_pine_quiet"])
	return str(_DIALOGUES.get(kind, _DIALOGUES["stick_circle"]))

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	var lines: Array = DialogueParser.parse_file(_dialogue_file())
	var ui: Node = load("res://scripts/dialogue/dialogue_ui.gd").new()
	ui.layer = 10
	get_tree().current_scene.add_child(ui)
	ui.open(lines)
	await ui.finished
	ui.queue_free()
	if kind == "lone_pine" and GameState.flags.get("whisperglen_pine_armed", false):
		GameState.set_flag("whisperglen_pine_armed", false)
		_drop_golden_petal()

func _drop_golden_petal() -> void:
	var petal := Sprite2D.new()
	petal.texture = Sprites.prop_texture("golden_flowers.png")
	petal.scale = Vector2(0.25, 0.25)
	petal.position = Vector2(0, 16)
	petal.modulate = Color(1, 0.85, 0.4, 1)
	add_child(petal)
