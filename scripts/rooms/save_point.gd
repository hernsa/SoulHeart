extends Area2D

const ECHO_NAMES: Array[String] = ["Merritt", "Anja", "Silas", "Ro"]
const ECHO_LINES: Array[String] = [
	"* {name}: The stars are warm tonight. They remember you.",
	"* {name}: You came back. Again. You always come back.",
	"* {name}: Somewhere ahead, someone is waiting to be asked.",
	"* You will choose. You have already chosen.",
	"* {name}: The cracks breathe. They are counting you.",
	"* {name}: I wrote your name in the dust. It keeps smudging.",
	"* {name}: Keep walking. The quiet is almost done.",
	"* {name}: The wisp hums when you sleep. It knows the way home.",
]

var _star: Sprite2D

static func echo_for(index: int) -> String:
	var line := ECHO_LINES[index % ECHO_LINES.size()]
	return line.replace("{name}", ECHO_NAMES[index % ECHO_NAMES.size()])

static func advance_echo() -> int:
	var index := int(GameState.flags.get("echo_index", 0))
	GameState.set_flag("echo_index", index + 1)
	return index

func _ready() -> void:
	_star = Sprite2D.new()
	_star.name = "StarSprite"
	_star.texture = Sprites.save_point_texture()
	_star.scale = Vector2(1.5, 1.5)
	add_child(_star)
	var pulse := create_tween()
	pulse.set_loops()
	pulse.tween_property(_star, "scale", Vector2(1.8, 1.8), 0.5)
	pulse.tween_property(_star, "scale", Vector2(1.5, 1.5), 0.5)
	var shape := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 12.0
	shape.shape = circ
	add_child(shape)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		GameState.set_flag("save_point", [int(global_position.x), int(global_position.y)])
		if GameState.save_game():
			Audio.play_sfx("save")
			var index := advance_echo()
			_show_banner("Game saved.", echo_for(index))

func _show_banner(text: String, echo: String = "") -> void:
	var panel := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0)
	sb.set_border_width_all(1)
	sb.border_color = Color(1, 1, 1)
	panel.add_theme_stylebox_override("panel", sb)
	panel.position = Vector2(24, 404)
	panel.size = Vector2(330, 48) if not echo.is_empty() else Vector2(120, 32)
	add_child(panel)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	label.position = Vector2(30, 410)
	panel.add_child(label)
	if not echo.is_empty():
		var echo_label := Label.new()
		echo_label.text = echo
		echo_label.add_theme_font_size_override("font_size", 14)
		echo_label.position = Vector2(30, 430)
		panel.add_child(echo_label)
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_property(panel, "modulate:a", 0.0, 0.8)
	tw.tween_callback(panel.queue_free)
