class_name EnemyLibrary

static var _enemies := {
	"froggit": {
		"id": "froggit", "name": "FROGGIT", "hp": 20, "atk": 4, "def": 0,
		"acts": [
			{"id": "check", "label": "Check", "mood": 0,
			 "text": "* FROGGIT - ATK 4 DEF 0. A simple creature. It just wants to sing."},
			{"id": "ribbit", "label": "Ribbit", "mood": 1,
			 "text": "You ribbit. Froggit croaks back, delighted."},
		],
		"spare_after": 1,
		"intro_line": "Froggit hops into view, croaking softly.",
		"attack_lines": ["Froggit attacks!", "* Froggit is watching you."],
		"sprite_id": "froggit",
		"patterns": [
			{"type": "sine", "count": 5, "speed": 70.0, "rule": Bullet.Rule.BLUE},
			{"type": "aimed", "count": 3, "speed": 110.0},
		],
	},
	"whimsun": {
		"id": "whimsun", "name": "WHIMSUN", "hp": 12, "atk": 5, "def": 0,
		"acts": [
			{"id": "check", "label": "Check", "mood": 0,
			 "text": "* WHIMSUN - ATK 5 DEF 0. A crying cloud. Something is holding it back."},
			{"id": "calm", "label": "Calm", "mood": 1,
			 "text": "You soothe Whimsun. Its crying softens into hiccups."},
		],
		"spare_after": 1,
		"intro_line": "Whimsun drifts into view, weeping.",
		"attack_lines": ["Whimsun cries out!", "* Whimsun is frightened."],
		"sprite_id": "whimsun",
		"patterns": [
			{"type": "sine", "count": 6, "speed": 60.0},
			{"type": "ring", "count": 10, "speed": 80.0},
		],
	},
	"moldsmal": {
		"id": "moldsmal", "name": "MOLDSMAL", "hp": 30, "atk": 6, "def": 0,
		"acts": [
			{"id": "check", "label": "Check", "mood": 0,
			 "text": "* MOLDSMAL - ATK 6 DEF 0. A mold of thought. It is thinking of nothing."},
			{"id": "hug", "label": "Hug", "mood": 1,
			 "text": "You hug Moldsmal. It wobbles, pleased."},
		],
		"spare_after": 1,
		"intro_line": "Moldsmal slides into view, wobbling gently.",
		"attack_lines": ["Moldsmal wobbles!", "* Moldsmal is thinking of nothing."],
		"sprite_id": "moldsmal",
		"patterns": [
			{"type": "burst", "count": 4, "speed": 60.0},
			{"type": "burst", "count": 6, "speed": 90.0, "rule": Bullet.Rule.BLUE},
		],
	},
	"loox": {
		"id": "loox", "name": "LOOX", "hp": 40, "atk": 7, "def": 0,
		"acts": [
			{"id": "check", "label": "Check", "mood": 0,
			 "text": "* LOOX - ATK 7 DEF 0. An annoyed eye. It does not like you."},
			{"id": "dont_pick_on_me", "label": "Don't Pick On Me", "mood": 1,
			 "text": "You tell Loox to pick on someone else. It sulks, but its glare softens."},
		],
		"spare_after": 2,
		"intro_line": "Loox swivels into view, glaring at you.",
		"attack_lines": ["Loox shoots a mean look!", "* Loox does not like you."],
		"sprite_id": "loox",
		"patterns": [
			{"type": "fan", "count": 5, "spread": 50.0, "speed": 100.0},
			{"type": "aimed", "count": 4, "speed": 130.0, "rule": Bullet.Rule.ORANGE},
		],
	},
	"vegetoid": {
		"id": "vegetoid", "name": "VEGETOID", "hp": 18, "atk": 4, "def": 0,
		"acts": [
			{"id": "check", "label": "Check", "mood": 0,
			 "text": "* VEGETOID - ATK 4 DEF 0. It may or may not be a vegetable. It probably isn't."},
			{"id": "talk", "label": "Talk", "mood": 1,
			 "text": "You talk to Vegetoid. You try to relate to it. It's a vegetable."},
		],
		"spare_after": 1,
		"intro_line": "Vegetoid sprouts from the ground, rustling.",
		"attack_lines": ["Vegetoid sprouts!", "* Vegetoid is a vegetable."],
		"sprite_id": "vegetoid",
		"patterns": [
			{"type": "ring", "count": 8, "speed": 70.0, "rule": Bullet.Rule.GREEN},
			{"type": "fan", "count": 4, "spread": 40.0, "speed": 90.0},
		],
	},
	"migosp": {
		"id": "migosp", "name": "MIGOSP", "hp": 24, "atk": 5, "def": 0,
		"acts": [
			{"id": "check", "label": "Check", "mood": 0,
			 "text": "* MIGOSP - ATK 5 DEF 0. A quiet creature. There may be more of them."},
			{"id": "doubt", "label": "Doubt", "mood": 1,
			 "text": "You doubt Migosp. It skitters uncertainly."},
		],
		"spare_after": 1,
		"intro_line": "Migosp skitters into view, silent.",
		"attack_lines": ["Migosp skitters!", "* Migosp is silent."],
		"sprite_id": "migosp",
		"patterns": [
			{"type": "spiral", "count": 8, "speed": 60.0},
			{"type": "fan", "count": 6, "spread": 70.0, "speed": 110.0},
		],
	},
}

static func get_enemy(id: String) -> Dictionary:
	if not _enemies.has(id):
		return _enemies["froggit"].duplicate(true)
	return _enemies[id].duplicate(true)

static func enemy_ids() -> Array[String]:
	var out: Array[String] = []
	for k in _enemies:
		out.append(k)
	return out

static func act_labels(acts: Array) -> Array[String]:
	var out: Array[String] = []
	for act in acts:
		out.append(str(act.get("label", "?")))
	return out

static func act_by_label(acts: Array, label: String) -> Dictionary:
	for act in acts:
		if str(act.get("label", "")) == label:
			return act
	return {}
