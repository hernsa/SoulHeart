extends RefCounted

func test_pulse_line_shows_once_per_wisp() -> void:
	var src := FileAccess.get_file_as_string("res://scripts/wisp/wisp.gd")
	TestHelper.is_true(src.contains("_pulse_shown"), "wisp tracks pulse-shown flag")
	TestHelper.is_true(src.contains("not _pulse_shown"), "body_entered gated on flag")
	TestHelper.is_true(src.contains("_pulse_shown = true"), "flag set on first trigger")
	TestHelper.is_true(not src.contains("_wisp(\"hum_ready\")"), "old ungated call removed")

func test_hum_gated_while_dialogue_open() -> void:
	var src := FileAccess.get_file_as_string("res://scripts/wisp/wisp.gd")
	TestHelper.is_true(src.contains("DialogueUI.open_count"), "hum checks open dialogue count")

func test_open_count_tracks_openings() -> void:
	var root := Engine.get_main_loop()
	var ui: Node = load("res://scripts/dialogue/dialogue_ui.gd").new()
	(root as SceneTree).root.add_child(ui)
	var before := DialogueUI.open_count
	ui.open([{"text": "hello"}])
	TestHelper.is_true(DialogueUI.open_count == before + 1, "open incremented counter")
	ui._index = 1
	ui._active = true
	ui._process(0.016)
	TestHelper.is_true(DialogueUI.open_count == before, "finish decremented counter")
	ui.queue_free()

func test_rooms_delegate_wisp_lines() -> void:
	for path in [
			"res://scripts/rooms/drizzle_fields.gd",
			"res://scripts/rooms/grumble_woods.gd",
			"res://scripts/rooms/echo.gd",
			"res://scripts/rooms/hometown.gd",
			"res://scripts/rooms/canon.gd",
			"res://scripts/rooms/cracks.gd"]:
		var src := FileAccess.get_file_as_string(path)
		var name := String(path).get_file()
		TestHelper.is_true(src.contains("wisp.show_line("), "%s delegates to wisp.show_line" % name)
		TestHelper.is_true(not src.contains("var _wisp_ui: Node"), "%s has no own dialogue ui" % name)
	var grumble := FileAccess.get_file_as_string("res://scripts/rooms/grumble_woods.gd")
	TestHelper.is_true(grumble.contains("show_line(\"grumble\")"), "grumble uses its own context")

func test_battle_text_label_wraps() -> void:
	var root := Engine.get_main_loop()
	var ui: Node = load("res://scripts/dialogue/dialogue_ui.gd").new()
	(root as SceneTree).root.add_child(ui)
	ui.open([{"speaker": "The Index — Cross-Out", "text": "You strike. The Index — Cross-Out takes 5 damage."}], true)
	var label: Label = ui.get_node("Label")
	TestHelper.is_true(label.autowrap_mode != TextServer.AUTOWRAP_OFF, "battle text wraps")
	TestHelper.is_true(label.size.y >= 50.0, "battle text label tall enough for 3 lines")
	ui.queue_free()

func test_tree_hitbox_reaches_ground() -> void:
	var t: RoomTree = RoomTree.new()
	var body: StaticBody2D = t.get_child(1)
	var shape: CollisionShape2D = body.get_child(0)
	var rect := shape.shape as RectangleShape2D
	TestHelper.is_true(rect.size.y >= 24.0, "tree collision covers full trunk height")
	TestHelper.is_true(shape.position.y + rect.size.y / 2.0 >= 24.0, "tree collision reaches ground level")
	t.free()