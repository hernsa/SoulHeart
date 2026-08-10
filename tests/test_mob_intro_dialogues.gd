# tests/test_mob_intro_dialogues.gd
extends RefCounted

const INTROS := [
	["reminisc", "Reminisc"],
	["hushroom", "Hushroom"],
	["paneic", "Pane-ic"],
]

func test_each_intro_has_lines() -> void:
	for entry in INTROS:
		var path := "res://dialogue/%s_intro.dlg" % entry[0]
		var lines := DialogueParser.parse_file(path)
		TestHelper.is_true(lines.size() >= 2,
			"%s_intro.dlg must have >= 2 lines" % entry[0])

func test_intro_first_line_has_speaker_and_star_text() -> void:
	for entry in INTROS:
		var path := "res://dialogue/%s_intro.dlg" % entry[0]
		var lines := DialogueParser.parse_file(path)
		TestHelper.eq(lines[0]["speaker"], entry[1],
			"%s first line speaker must be '%s'" % [entry[0], entry[1]])
		TestHelper.is_true(str(lines[0]["text"]).begins_with("*"),
			"%s first line text must begin with '*'" % entry[0])