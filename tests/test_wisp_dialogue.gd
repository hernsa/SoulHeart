# tests/test_wisp_dialogue.gd
extends RefCounted

func test_intro_line_non_empty() -> void:
	var line := WispDialogue.get_line("intro")
	TestHelper.is_true(line.length() > 0, "intro line must be non-empty")

func test_drizzle_line_non_empty() -> void:
	var line := WispDialogue.get_line("drizzle")
	TestHelper.is_true(line.length() > 0, "drizzle line must be non-empty")

func test_grumble_line_non_empty() -> void:
	var line := WispDialogue.get_line("grumble")
	TestHelper.is_true(line.length() > 0, "grumble line must be non-empty")

func test_hum_low_non_empty() -> void:
	var line := WispDialogue.get_line("hum_low")
	TestHelper.is_true(line.length() > 0, "hum_low line must be non-empty")

func test_hum_high_non_empty() -> void:
	var line := WispDialogue.get_line("hum_high")
	TestHelper.is_true(line.length() > 0, "hum_high line must be non-empty")

func test_hum_ready_non_empty() -> void:
	var line := WispDialogue.get_line("hum_ready")
	TestHelper.is_true(line.length() > 0, "hum_ready line must be non-empty")

func test_intro_line_starts_with_speaker() -> void:
	var line := WispDialogue.get_line("intro")
	TestHelper.is_true(line.begins_with("Wisp:") or line.begins_with("*"),
		"intro line must start with 'Wisp:' or '*'")

func test_lines_cycle_through_file() -> void:
	var first := WispDialogue.get_line("drizzle")
	var second := WispDialogue.get_line("drizzle")
	TestHelper.is_true(first != second, "sequential drizzle lines must differ (cycle)")