class_name EnemyLibrary

static func get_enemy(id: String) -> EnemyStats:
	match id:
		"willowisp":
			return willowisp()
		_:
			return willowisp()

static func willowisp() -> EnemyStats:
	var e := EnemyStats.new()
	e.enemy_id = "willowisp"
	e.display_name = "Willowisp"
	e.max_hp = 8
	e.hp = 8
	e.attack = 3
	e.defense = 0
	e.acts = [
		{"id": "check", "label": "Check", "mood": 0,
		 "text": "WILLOWISP - ATK 3 DEF 0. A lost wisp. It just wants to be remembered."},
		{"id": "hum", "label": "Hum", "mood": 1,
		 "text": "You hum a quiet note. Willowisp wavers, humming back."},
	]
	e.spare_after_acts = 2
	e.intro_line = "Willowisp drifts into view, trailing light."
	e.attack_lines = [
		"Willowisp wavers.",
		"Its light flickers, hurt.",
	]
	e.patterns = [
		{"type": "burst", "count": 5, "speed": 90.0, "dir": [0.0, 1.0]},
		{"type": "fan", "count": 7, "spread": 70.0, "speed": 110.0, "dir": [0.0, 1.0]},
	]
	return e
