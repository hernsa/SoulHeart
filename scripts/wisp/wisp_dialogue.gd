extends RefCounted
class_name WispDialogue

# Context -> line dispatch for the Wisp companion. File-backed contexts
# (intro/drizzle/grumble/echo/hometown/canon/cracks) cycle through their
# .dlg lines; hum contexts are inline fallbacks.

const INTRO_PATH := "res://dialogue/wisp_intro.dlg"
const DRIZZLE_PATH := "res://dialogue/wisp_drizzle.dlg"
const GRUMBLE_PATH := "res://dialogue/wisp_grumble.dlg"
const ECHO_PATH := "res://dialogue/wisp_echo.dlg"
const HOMETOWN_PATH := "res://dialogue/wisp_hometown.dlg"
const CANON_PATH := "res://dialogue/wisp_canon.dlg"
const CRACKS_PATH := "res://dialogue/wisp_cracks.dlg"

const HUM_LOW := "* Wisp dims a little. The air around it feels like a question mark."
const HUM_HIGH := "* Wisp glows brighter. You can hear the hum through your teeth."
const HUM_READY := "* Wisp pulses once. It is ready to be heard."

static var _intro_idx: int = 0
static var _drizzle_idx: int = 0
static var _grumble_idx: int = 0
static var _echo_idx: int = 0
static var _hometown_idx: int = 0
static var _canon_idx: int = 0
static var _cracks_idx: int = 0

static func get_line(context: String) -> String:
	match context:
		"intro":
			return _pick(INTRO_PATH, _intro_idx, func(i: int) -> void: _intro_idx = i)
		"drizzle":
			return _pick(DRIZZLE_PATH, _drizzle_idx, func(i: int) -> void: _drizzle_idx = i)
		"grumble":
			return _pick(GRUMBLE_PATH, _grumble_idx, func(i: int) -> void: _grumble_idx = i)
		"echo":
			return _pick(ECHO_PATH, _echo_idx, func(i: int) -> void: _echo_idx = i)
		"hometown":
			return _pick(HOMETOWN_PATH, _hometown_idx, func(i: int) -> void: _hometown_idx = i)
		"canon":
			return _pick(CANON_PATH, _canon_idx, func(i: int) -> void: _canon_idx = i)
		"cracks":
			return _pick(CRACKS_PATH, _cracks_idx, func(i: int) -> void: _cracks_idx = i)
		"hum_low":
			return HUM_LOW
		"hum_high":
			return HUM_HIGH
		"hum_ready":
			return HUM_READY
		_:
			return "* Wisp flickers, unsure."

static func _pick(path: String, current_idx: int, advance: Callable) -> String:
	var lines: Array[Dictionary] = DialogueParser.parse_file(path)
	if lines.is_empty():
		return "* Wisp is silent."
	var entry: Dictionary = lines[current_idx % lines.size()]
	advance.call((current_idx + 1) % lines.size())
	var speaker: String = str(entry.get("speaker", ""))
	var text: String = str(entry.get("text", ""))
	if speaker.is_empty():
		return text
	return "%s: %s" % [speaker, text]