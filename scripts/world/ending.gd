class_name Ending

const BATTLE_SCENE := "res://scenes/Battle.tscn"
const MAIN_SCENE := "res://scenes/Main.tscn"

static func door_unlocked(door_id: String) -> bool:
	match door_id:
		"keeper":
			return EditEvent.count("edit_refuses") >= 4
		"hollow":
			return EditEvent.count("edit_accepts") >= 6
		"wanderer":
			return true
	return false

static func flag_keeper_battle(from_room: String) -> void:
	GameState.set_flag("pending_enemy", "canon_true")
	GameState.set_flag("from_room", from_room)
	GameState.set_flag("last_boss_save", "canon_true")
	GameState.save_game()

static func end_for_victory(enemy_id: String) -> String:
	if enemy_id == "canon_true":
		return "keeper"
	return ""

static func wipe_save() -> void:
	GameState.reset()
	if FileAccess.file_exists(GameState.SAVE_PATH):
		DirAccess.remove_absolute(GameState.SAVE_PATH)

static func ending_lines(id: String) -> Array[Dictionary]:
	match id:
		"keeper":
			return [
				{"speaker": "", "text": "* The quill settles onto the desk. It stays."},
				{"speaker": "", "text": "* The cracks stay open. The world breathes through them."},
				{"speaker": "", "text": "* You leave the world plural, waiting to be dreamed fully."},
				{"speaker": "", "text": "* Somewhere in it, you are still deciding. That is enough."},
			]
		"wanderer":
			return [
				{"speaker": "", "text": "* One crack closes behind you. Just one."},
				{"speaker": "", "text": "* The world half-remembers you, the way you half-remember it."},
				{"speaker": "", "text": "* The save points remember you. Not why."},
				{"speaker": "", "text": "* The wisp hums alone, a small light in the quiet."},
			]
		"hollow":
			return [
				{"speaker": "", "text": "* There is one thing now, instead of a world."},
				{"speaker": "", "text": "* It is quiet. It is perfect."},
				{"speaker": "", "text": "* You wake in a bed that smells of dust and rain."},
				{"speaker": "", "text": "* You don't remember falling. You don't remember playing."},
			]
	return []

static func credits_lines() -> Array[Dictionary]:
	return [
		{"speaker": "", "text": "* SOULHEART — a small game about a red heart and the edits of a dream."},
		{"speaker": "", "text": "* Built in Godot 4, with music synthesized in-engine."},
		{"speaker": "", "text": "* The keeper, the wanderer, and the hollow: three endings."},
		{"speaker": "", "text": "* Six edits remembered. Four names at the save points."},
		{"speaker": "", "text": "* You will choose. You have already chosen."},
		{"speaker": "", "text": "* The wisp hums because you kept walking."},
		{"speaker": "", "text": "* Merritt, Anja, Silas, Ro — the stars remember you."},
		{"speaker": "", "text": "* Thank you for playing."},
	]

static func play_ending(id: String, tree: SceneTree) -> void:
	if tree == null or id == "":
		return
	var current := tree.current_scene
	if current == null:
		return
	Fade.fade_to_black(0.67)
	await tree.create_timer(0.8).timeout
	if not is_instance_valid(current) or not current.is_inside_tree():
		return
	Audio.play_music("hollow" if id == "hollow" else "credits")
	var ui: Node = load("res://scripts/dialogue/dialogue_ui.gd").new()
	ui.layer = 10
	current.add_child(ui)
	ui.open(ending_lines(id))
	await ui.finished
	ui.queue_free()
	if not is_instance_valid(current) or not current.is_inside_tree():
		return
	if id == "hollow":
		wipe_save()
	await tree.create_timer(0.4).timeout
	tree.change_scene_to_file(MAIN_SCENE)