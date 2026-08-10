extends RefCounted
class_name WispAudio

# Procedural 4-note leitmotif for the Wisp companion. Pitch is shaped by
# mood (0..100). Cooldown-gated so rapid hum presses do not stack.

const MOTIF := [0, 4, 7, 12]
const BASE_HZ := 261.63  # C4
const NOTE_DURATION := 0.18
const REENTRY_COOLDOWN := 1.5

static var _last_play_ms: int = -99999

static func play_hum(mood: int) -> void:
	var now := Time.get_ticks_msec()
	if now - _last_play_ms < REENTRY_COOLDOWN * 1000.0:
		return
	_last_play_ms = now
	var base := BASE_HZ * _pitch_for_mood(mood)
	for i in MOTIF.size():
		var hz := base * pow(2.0, MOTIF[i] / 12.0)
		_spawn_note(hz)

static func _pitch_for_mood(mood: int) -> float:
	var t := clampf(float(mood) / 100.0, 0.0, 1.0)
	return lerpf(0.5, 1.5, t)

static func _spawn_note(hz: float) -> void:
	var stream := AudioStreamWAV.new()
	var sample_rate := 22050
	var sample_count := int(sample_rate * NOTE_DURATION)
	stream.mix_rate = sample_rate
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	var bytes := PackedByteArray()
	bytes.resize(sample_count)
	for i in sample_count:
		var t := float(i) / float(sample_rate)
		var env := exp(-3.0 * t)
		var sample := sin(2.0 * PI * hz * t) * env
		bytes[i] = int(clampf(sample * 127.0 + 128.0, 0.0, 255.0))
	stream.data = bytes
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	tree.root.add_child(player)
	player.play()
	player.finished.connect(player.queue_free)