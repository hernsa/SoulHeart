extends RefCounted

const SAVE_SCRIPT := "res://scripts/rooms/save_point.gd"

func test_echo_pool_size() -> void:
	var script: GDScript = load(SAVE_SCRIPT)
	TestHelper.eq(script.ECHO_LINES.size(), 8, "echo pool has 8 lines")
	TestHelper.eq(script.ECHO_NAMES.size(), 4, "echo name cycle has 4 names")

func test_echo_foreshadow_line() -> void:
	var script: GDScript = load(SAVE_SCRIPT)
	TestHelper.eq(script.echo_for(3), "* You will choose. You have already chosen.", "index 3 is the un-named foreshadow")

func test_echo_names_cycle() -> void:
	var script: GDScript = load(SAVE_SCRIPT)
	TestHelper.is_true(script.echo_for(0).contains("Merritt"), "index 0 speaks as Merritt")
	TestHelper.is_true(script.echo_for(1).contains("Anja"), "index 1 speaks as Anja")
	TestHelper.is_true(script.echo_for(2).contains("Silas"), "index 2 speaks as Silas")
	TestHelper.is_true(script.echo_for(7).contains("Ro"), "index 7 speaks as Ro")
	TestHelper.is_true(script.echo_for(4).contains("Merritt"), "names wrap at 4: index 4 speaks as Merritt")
	TestHelper.eq(script.echo_for(11), script.echo_for(3), "pool wraps at 8")

func test_echo_foreshadow_has_no_name() -> void:
	var script: GDScript = load(SAVE_SCRIPT)
	var line: String = script.echo_for(3)
	TestHelper.is_true(not line.contains("Merritt"), "foreshadow line has no Merritt")
	TestHelper.is_true(not line.contains("Anja"), "foreshadow line has no Anja")
	TestHelper.is_true(not line.contains("Silas"), "foreshadow line has no Silas")
	TestHelper.is_true(not line.contains("Ro"), "foreshadow line has no Ro")

func test_advance_echo_increments() -> void:
	GameState.reset()
	var script: GDScript = load(SAVE_SCRIPT)
	TestHelper.eq(script.advance_echo(), 0, "first echo index is 0")
	TestHelper.eq(int(GameState.flags.get("echo_index", 0)), 1, "echo_index flag advanced to 1")
	TestHelper.eq(script.advance_echo(), 1, "second echo index is 1")
	TestHelper.eq(int(GameState.flags.get("echo_index", 0)), 2, "echo_index flag advanced to 2")

func test_save_point_hooks_echoes() -> void:
	var source: String = FileAccess.get_file_as_string(SAVE_SCRIPT)
	TestHelper.is_true(source.contains("echo_for(index)"), "save handler shows echo")
	TestHelper.is_true(source.contains("advance_echo()"), "save handler advances echo index")
	TestHelper.is_true(source.contains("echo_for"), "save_point defines echo_for")
