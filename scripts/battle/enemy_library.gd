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
	"reminisc": _make_mob(
		"reminisc", "Reminisc", 12, 4, 2, 4, "reminisc",
		[
			{"id": "recall", "label": "* Recall", "mood": 2,
			 "text": "* You ask it to recall something. The word 'remember' flickers in its eye."},
			{"id": "study", "label": "* Study", "mood": 1,
			 "text": "* It looks like a faded photograph. The edges are soft."},
			{"id": "hum", "label": "* Hum", "mood": 2,
			 "text": "* You hum. It relaxes, almost imperceptibly."},
		],
		[
			"* It whispers your name. (You never told it.)",
			"* It reaches for something behind you that isn't there.",
		],
		[
			{"type": "aimed", "count": 4, "speed": 70.0, "rule": Bullet.Rule.BLUE},
			{"type": "ring", "count": 8, "speed": 35.0},
		],
		"* A Reminisc flickers into view. It looks like it's remembering you from somewhere you haven't been.",
	),
	"hushroom": _make_mob(
		"hushroom", "Hushroom", 8, 3, 1, 3, "hushroom",
		[
			{"id": "quiet", "label": "* Quiet it", "mood": 2,
			 "text": "* You ask it to be quieter. It tries. The ringing stops for a moment."},
			{"id": "smell", "label": "* Smell", "mood": 1,
			 "text": "* It smells like damp moss and old bells."},
		],
		[
			"* A high tone rings out from its cap.",
			"* It vibrates. Your ears ache.",
		],
		[
			{"type": "sine", "count": 6, "speed": 60.0, "rule": Bullet.Rule.BLUE},
			{"type": "fan", "count": 5, "spread": 34.0, "speed": 80.0, "rule": Bullet.Rule.ORANGE},
		],
		"* A Hushroom tilts its cap toward you. It hums at a frequency just out of hearing.",
	),
	"paneic": _make_mob(
		"paneic", "Pane-ic", 10, 5, 1, 4, "paneic",
		[
			{"id": "breathe", "label": "* Breathe", "mood": 2,
			 "text": "* You remind it to breathe. It exhales — the glass fogs."},
			{"id": "tilt", "label": "* Tilt", "mood": 1,
			 "text": "* You tilt the pane. Nothing changes. It was always this way."},
		],
		[
			"* It looks out at something you can't see.",
			"* Its surface ripples. There are people behind it.",
		],
		[
			{"type": "aimed", "count": 3, "speed": 90.0},
			{"type": "ring", "count": 6, "speed": 30.0, "rule": Bullet.Rule.BLUE},
		],
		"* Pane-ic stands in front of you. It is exactly the size of a doorway.",
	),
	"squish": _make_mob(
		"squish", "Squi-sh", 14, 4, 3, 5, "squish",
		[
			{"id": "compliment", "label": "* Compliment", "mood": 2,
			 "text": "* You tell it it's doing its best. It blooms a little."},
			{"id": "squeeze", "label": "* Squeeze", "mood": 1,
			 "text": "* You squeeze it gently. It says 'thank you' in two octaves."},
		],
		[
			"* It bounces in place. That's the attack.",
			"* It flattens, then springs back. Bullets fly.",
		],
		[
			{"type": "burst", "count": 8, "speed": 80.0, "rule": Bullet.Rule.ORANGE},
			{"type": "spiral", "count": 12, "speed": 50.0},
		],
		"* Squi-sh jiggles nervously. It has not been squeezed in a long time.",
	),
	"sentimint": _make_mob(
		"sentimint", "Senti-mint", 11, 5, 2, 5, "sentimint",
		[
			{"id": "savor", "label": "* Savor", "mood": 2,
			 "text": "* You let it sit on your tongue. It's the taste of an apology you never got."},
			{"id": "crush", "label": "* Crush", "mood": 1,
			 "text": "* You crush it between your fingers. The air smells like the last day of summer."},
		],
		[
			"* It breathes out cold air. Your eyes water.",
			"* The room smells like every goodbye you've had.",
		],
		[
			{"type": "fan", "count": 7, "spread": 46.0, "speed": 70.0, "rule": Bullet.Rule.BLUE},
			{"type": "aimed", "count": 5, "speed": 85.0, "rule": Bullet.Rule.ORANGE},
		],
		"* Senti-mint rests on your tongue. The first thing it tastes like is the word 'almost.'",
	),
	"repeato": _make_mob(
		"repeato", "Repeato", 9, 3, 2, 4, "repeato",
		[
			{"id": "echo", "label": "* Echo", "mood": 2,
			 "text": "* You say 'hello.' It says 'hello.' You say 'hello' again. It is happy."},
			{"id": "break", "label": "* Break the loop", "mood": 1,
			 "text": "* You stay silent. It tries to fill the gap. It can't."},
		],
		[
			"* It says something. You didn't hear it the first time.",
			"* It says it again, louder.",
		],
		[
			{"type": "ring", "count": 10, "speed": 40.0},
			{"type": "sine", "count": 6, "speed": 60.0, "rule": Bullet.Rule.ORANGE},
		],
		"* Repeato opens its mouth. It is going to say something you've heard before.",
	),
	"toadally": _make_mob(
		"toadally", "Toadally", 16, 6, 3, 6, "toadally",
		[
			{"id": "agree", "label": "* Agree", "mood": 2,
			 "text": "* You nod. It nods. The nod spreads."},
			{"id": "refuse", "label": "* Refuse", "mood": 1,
			 "text": "* You say no. It says 'totally.' It was waiting for you to say no."},
		],
		[
			"* It croaks a syllable you've been avoiding.",
			"* It points at the thing behind you. (There is nothing behind you.)",
		],
		[
			{"type": "aimed", "count": 6, "speed": 80.0, "rule": Bullet.Rule.GREEN},
			{"type": "burst", "count": 10, "speed": 70.0, "rule": Bullet.Rule.BLUE},
		],
		"* Toadally sits on a rock. It has been sitting on this rock for some time.",
	),
	"punkin": _make_mob(
		"punkin", "Pun-kin", 13, 5, 2, 5, "punkin",
		[
			{"id": "laugh", "label": "* Laugh", "mood": 2,
			 "text": "* You laugh at the joke. The joke gets louder."},
			{"id": "groan", "label": "* Groan", "mood": 1,
			 "text": "* You groan. It beams. It loves a groan."},
		],
		[
			"* Why did the skeleton go to the party? He had no body to go with.",
			"* Knock knock. (Who's there?) Boo. (Boo who?) Don't cry, it's just a pun.",
		],
		[
			{"type": "bone_wall", "count": 7, "speed": 70.0},
			{"type": "fan", "count": 5, "spread": 29.0, "speed": 80.0, "rule": Bullet.Rule.ORANGE},
		],
		"* A Pun-kin waddles in. It is absolutely going to say something.",
	),
	"nullaby": _make_mob(
		"nullaby", "Nullaby", 7, 2, 1, 3, "nullaby",
		[
			{"id": "shush", "label": "* Shush", "mood": 2,
			 "text": "* You shush it. It tries harder to be silent. The room gets quieter."},
			{"id": "rock", "label": "* Rock", "mood": 2,
			 "text": "* You rock it. It almost coos. Almost."},
		],
		[
			"* It whimpers. The whimpers are shaped like bullets.",
			"* It reaches for you. You are not what it wants.",
		],
		[
			{"type": "aimed", "count": 2, "speed": 50.0, "rule": Bullet.Rule.BLUE},
			{"type": "sine", "count": 4, "speed": 40.0},
		],
		"* Nullaby is very small. It has not slept in a long time.",
	),
	"quibble": _make_mob(
		"quibble", "Quibble", 10, 4, 2, 4, "quibble",
		[
			{"id": "agree", "label": "* Agree", "mood": 2,
			 "text": "* You agree with it. It is furious. It wanted to argue."},
			{"id": "disagree", "label": "* Disagree", "mood": 1,
			 "text": "* You disagree. It smiles. It found an opponent."},
		],
		[
			"* Technically speaking, you are wrong.",
			"* But on the other hand, you are also wrong.",
		],
		[
			{"type": "spear_volley", "count": 5, "speed": 90.0, "rule": Bullet.Rule.ORANGE},
			{"type": "aimed", "count": 4, "speed": 75.0, "rule": Bullet.Rule.BLUE},
		],
		"* Quibble clears its throat. It has been waiting for someone to be wrong at.",
	),
	"margin": _make_mob(
		"margin", "Mar-gin", 8, 4, 1, 4, "margin",
		[
			{"id": "annotate", "label": "* Annotate", "mood": 2,
			 "text": "* You draw a small note in its margin. It pretends not to notice."},
			{"id": "fold", "label": "* Fold", "mood": 1,
			 "text": "* You fold the corner. It flinches. Pages rustle in sympathy."},
		],
		[
			"* A footnote materializes above your head.",
			"* The text starts to crawl.",
		],
		[
			{"type": "laser_sweep", "rule": Bullet.Rule.ORANGE},
			{"type": "aimed", "count": 3, "speed": 60.0, "rule": Bullet.Rule.BLUE},
		],
		"* Mar-gin unrolls itself across the floor. It is older than the room.",
	),
	"lookey": _make_mob(
		"lookey", "Loo-key", 12, 5, 2, 5, "lookey",
		[
			{"id": "fit", "label": "* Fit it", "mood": 2,
			 "text": "* You offer it a lock. It clicks, satisfied. (The lock was yours.)"},
			{"id": "jiggle", "label": "* Jiggle", "mood": 1,
			 "text": "* You jiggle it. It jiggles back. Nothing opens."},
		],
		[
			"* It turns slowly. Nothing fits.",
			"* It tries every key it has.",
		],
		[
			{"type": "ring", "count": 8, "speed": 50.0, "rule": Bullet.Rule.GRAY},
			{"type": "fan", "count": 6, "spread": 40.0, "speed": 80.0},
		],
		"* Loo-key floats in front of you. It is the right key. Nothing here is the right lock.",
	),
	"remembran": _make_mob(
		"remembran", "Re-mem-bran", 18, 7, 4, 7, "remembran",
		[
			{"id": "remind", "label": "* Remind", "mood": 3,
			 "text": "* You remind it of what it said yesterday. It is surprised you remember."},
			{"id": "forgive", "label": "* Forgive", "mood": 4,
			 "text": "* You forgive it. The forgiveness is louder than the attack."},
		],
		[
			"* It says your name. (You never told it.)",
			"* It lists things you have lost. It is correct.",
		],
		[
			{"type": "spiral", "count": 14, "speed": 60.0, "rule": Bullet.Rule.BLUE},
			{"type": "burst", "count": 12, "speed": 85.0, "rule": Bullet.Rule.ORANGE},
			{"type": "aimed", "count": 6, "speed": 90.0, "rule": Bullet.Rule.GRAY},
		],
		"* Re-mem-bran stands very still. It is remembering something it will not tell you.",
	),
	"mourning_knight": {
		"id": "mourning_knight", "name": "Mourning Knight",
		"hp": 60, "atk": 5, "def": 2, "spare_after": 6,
		"acts": [{"id": "mourn", "label": "* Mourn", "mood": 3,
				"text": "* You kneel beside the empty armor. It sighs like a bell. The clank is smaller now."}],
		"attack_lines": ["* It kneels. The grief is the attack.", "* It raises its visor. There is no one inside."],
		"patterns": [{"type": "fan", "count": 4, "spread": 60.0, "speed": 50.0, "rule": Bullet.Rule.BLUE},
				{"type": "aimed", "count": 2, "speed": 70.0, "rule": Bullet.Rule.ORANGE}],
		"intro_line": "* Mourning Knight. The armor remembers someone.",
		"sprite_id": "mourning_knight",
		"boss": true, "no_flee": true,
		"monologue": [
			{"at": 0.75, "speaker": "Knight", "text": "* I do not know if I am mourning them, or if they are mourning me."},
			{"at": 0.50, "speaker": "Knight", "text": "* Every room I walk through, I ruin."},
			{"at": 0.25, "speaker": "Knight", "text": "* ... if you would remember me, I would not have to."},
		],
	},
	"index": {
		"id": "index", "name": "The Index — Cross-Out",
		"hp": 40, "atk": 7, "def": 3, "spare_after": 5,
		"acts": [{"id": "read", "label": "* Read", "mood": 2,
				"text": "* You read aloud. The page tears itself before you finish."}],
		"attack_lines": ["* It crosses out a word. The word obeys."],
		"patterns": [{"type": "edit", "count": 5, "speed": 90.0, "rule": Bullet.Rule.ORANGE, "edit_at": 0.5},
				{"type": "aimed", "count": 4, "speed": 80.0, "rule": Bullet.Rule.BLUE}],
		"intro_line": "* The Index — Page One. It opens itself to a blank.",
		"sprite_id": "index_f1",
		"boss": true, "no_flee": true,
		"forms": [
			{"name": "The Index — Cross-Out", "hp": 40, "def": 3,
			 "spare_after": 5,
			 "acts": [{"id": "read", "label": "* Read", "mood": 2,
				   "text": "* You read aloud. The page tears itself before you finish."}],
			 "attack_lines": ["* It crosses out a word. The word obeys."],
			 "patterns": [{"type": "edit", "count": 5, "speed": 90.0, "rule": Bullet.Rule.ORANGE, "edit_at": 0.5},
				      {"type": "aimed", "count": 4, "speed": 80.0, "rule": Bullet.Rule.BLUE}],
			 "intro_line": "* The Index — Page One. It opens itself to a blank.",
			 "sprite_id": "index_f1"},
			{"name": "The Index — Edit", "hp": 50, "def": 4,
			 "spare_after": 4,
			 "acts": [{"id": "edit", "label": "* Edit", "mood": 2,
				   "text": "* You write in the margin. It writes back."}],
			 "attack_lines": ["* It edits a memory. The memory stands corrected."],
			 "patterns": [{"type": "edit", "count": 7, "speed": 100.0, "rule": Bullet.Rule.BLUE, "edit_at": 0.4},
				      {"type": "ring", "count": 6, "speed": 70.0, "rule": Bullet.Rule.ORANGE}],
			 "intro_line": "* The Index — Page Two. It edits what was.",
			 "sprite_id": "index_f2"},
			{"name": "The Index — Accept", "hp": 60, "def": 5,
			 "spare_after": 3,
			 "acts": [{"id": "accept", "label": "* Accept", "mood": 3,
				   "text": "* You accept the corrections. The page is quiet."}],
			 "attack_lines": ["* It offers you a final reading. There is no choice in accepting it."],
			 "patterns": [{"type": "edit", "count": 9, "speed": 110.0, "rule": Bullet.Rule.ORANGE, "edit_at": 0.35},
				      {"type": "spiral", "count": 8, "speed": 90.0, "rule": Bullet.Rule.BLUE}],
			 "intro_line": "* The Index — Page Three. It opens itself to you.",
			 "sprite_id": "index_f3"},
		],
	},
	"canon_true": {
		"id": "canon_true", "name": "Canon",
		"hp": 120, "atk": 9, "def": 6, "spare_after": 6,
		"acts": [{"id": "accept", "label": "* Accept", "mood": 3,
				"text": "* You accept what was. The Canon softens."},
			 {"id": "refuse", "label": "* Refuse", "mood": 3,
				"text": "* You refuse the Canon. It is impressed."}],
		"attack_lines": ["* The Canon rewrites a wall. The wall remembers.",
				"* The Canon speaks a name that does not exist anymore."],
		"patterns": [{"type": "burst", "count": 12, "speed": 100.0, "rule": Bullet.Rule.ORANGE},
				{"type": "spiral", "count": 14, "speed": 110.0, "rule": Bullet.Rule.BLUE}],
		"intro_line": "* Canon. The shape of what was, if what was had a shape.",
		"sprite_id": "canon_true",
		"boss": true, "no_flee": true,
	},
}

static func _make_mob(p_id: String, p_name: String, p_hp: int, p_atk: int, p_def: int,
		p_spare: int, p_sprite: String, p_acts: Array, p_lines: Array,
		p_patterns: Array, p_intro: String) -> Dictionary:
	return {
		"id": p_id, "name": p_name, "hp": p_hp, "atk": p_atk, "def": p_def,
		"acts": p_acts, "spare_after": p_spare, "intro_line": p_intro,
		"attack_lines": p_lines, "sprite_id": p_sprite, "patterns": p_patterns,
	}

static func ids() -> Array[String]:
	return enemy_ids()

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

static func apply_form(target: Dictionary, form: Dictionary) -> Dictionary:
	for key in ["name", "hp", "def", "spare_after", "acts", "attack_lines",
			"patterns", "intro_line", "sprite_id"]:
		if form.has(key):
			target[key] = form[key]
	return target

static func monologue_lines(monologue: Array, hp_frac: float, shown: Array) -> Array:
	var out: Array = []
	for line in monologue:
		var at: float = float(line.get("at", 1.0))
		if at >= hp_frac and not shown.has(at):
			out.append(line)
	return out
