extends RefCounted
class_name WispState

# Static-state singleton for the Wisp companion. Avoids adding a 5th autoload.
# Mood is 0..100; hum() gates WispAudio.play_hum and mood gain on a cooldown.

static var _mood: int = 0
static var _last_hum_ms: int = -99999
static var _hum_cooldown_ms: int = 1500
static var _area: String = ""
static var _now_ms: Callable = func() -> int: return Time.get_ticks_msec()

static func reset() -> void:
	_mood = 0
	_last_hum_ms = -99999
	_area = ""

static func mood() -> int:
	return _mood

static func set_mood(v: int) -> void:
	_mood = clampi(v, 0, 100)

static func add_hum(amount: int) -> void:
	set_mood(_mood + amount)

static func hum() -> bool:
	var now: int = _now_ms.call()
	if now - _last_hum_ms < _hum_cooldown_ms:
		return false
	_last_hum_ms = now
	return true

static func last_area() -> String:
	return _area

static func set_area(name: String) -> void:
	_area = name
