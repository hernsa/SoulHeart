extends Node

const SAVE_PATH := "user://save.json"

var player_stats: Dictionary = {}
var inventory: Array[Dictionary] = []
var flags: Dictionary = {}
var kills: int = 0
var spares: int = 0

func _ready() -> void:
	reset()
	_ensure_input_actions()

func reset() -> void:
	player_stats = {"hp": 20, "max_hp": 20, "atk": 1, "def": 0, "gold": 0}
	inventory = [
		{"id": "dream_candy", "name": "Dream Candy", "heal": 6, "count": 1},
		{"id": "stick", "name": "Stick", "heal": 0, "count": 1},
	]
	flags = {}
	kills = 0
	spares = 0

func set_flag(key: String, value: Variant) -> void:
	flags[key] = value

func add_kill() -> void:
	kills += 1

func add_spare() -> void:
	spares += 1

func change_hp(amount: int) -> void:
	player_stats["hp"] = clampi(player_stats["hp"] + amount, 0, player_stats["max_hp"])

func heal_full() -> void:
	player_stats["hp"] = player_stats["max_hp"]

func use_item(index: int) -> Dictionary:
	if index < 0 or index >= inventory.size():
		return {}
	var item: Dictionary = inventory[index]
	if int(item.get("heal", 0)) > 0:
		change_hp(int(item["heal"]))
	inventory.remove_at(index)
	return item

func save_game(path: String = SAVE_PATH) -> bool:
	var data := {
		"stats": player_stats,
		"inventory": inventory,
		"flags": flags,
		"kills": kills,
		"spares": spares,
	}
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("Could not open save file: %s" % path)
		return false
	f.store_string(JSON.stringify(data))
	f.close()
	return true

func load_game(path: String = SAVE_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var data: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		return false
	data = _normalize_saved(data)
	player_stats = data["stats"]
	inventory.assign(data["inventory"])
	flags = data["flags"]
	kills = data["kills"]
	spares = data["spares"]
	return true

func _normalize_saved(data: Variant) -> Variant:
	if data is Array:
		var out: Array = []
		for v in data:
			out.append(_normalize_saved(v))
		return out
	if data is Dictionary:
		var out := {}
		for k in data:
			out[k] = _normalize_saved(data[k])
		return out
	if typeof(data) == TYPE_FLOAT and is_finite(data) and data == floor(data):
		return int(data)
	return data

func _ensure_input_actions() -> void:
	_ensure_action("move_up", [KEY_W, KEY_UP])
	_ensure_action("move_down", [KEY_S, KEY_DOWN])
	_ensure_action("move_left", [KEY_A, KEY_LEFT])
	_ensure_action("move_right", [KEY_D, KEY_RIGHT])
	_ensure_action("confirm", [KEY_Z, KEY_ENTER, KEY_KP_ENTER])
	_ensure_action("cancel", [KEY_X, KEY_SHIFT])
	_ensure_action("hum", [KEY_Z])

func _ensure_action(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		if not _action_has_key(action, key):
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)

func _action_has_key(action: StringName, key: Key) -> bool:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey and (ev as InputEventKey).physical_keycode == key:
			return true
	return false
