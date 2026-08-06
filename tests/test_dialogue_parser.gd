extends RefCounted

func test_parse_simple_lines() -> void:
	var lines := DialogueParser.parse_text("Hello there.\n# a comment\n\nToad: Ribbit! Ribbit!")
	TestHelper.eq(lines.size(), 2, "comment and blank skipped")
	TestHelper.eq(lines[0]["text"], "Hello there.", "plain line")
	TestHelper.eq(lines[0]["speaker"], "", "no speaker")
	TestHelper.eq(lines[1]["speaker"], "Toad", "speaker extracted")
	TestHelper.eq(lines[1]["text"], "Ribbit! Ribbit!", "speaker text")

func test_parse_first_colon_only() -> void:
	var lines := DialogueParser.parse_text("Wisp: Oh, it's you: the cat!?")
	TestHelper.eq(lines[0]["speaker"], "Wisp", "speaker before first colon")
	TestHelper.eq(lines[0]["text"], "Oh, it's you: the cat!?", "rest of line")

func test_parse_file() -> void:
	var lines := DialogueParser.parse_file("res://dialogue/sample.dlg")
	TestHelper.eq(lines.size(), 3, "sample has 3 lines")
	TestHelper.eq(lines[0]["speaker"], "Toad", "sample speaker")

func test_parse_missing_file() -> void:
	var lines := DialogueParser.parse_file("res://dialogue/nope.dlg")
	TestHelper.eq(lines.size(), 0, "missing file gives empty")
