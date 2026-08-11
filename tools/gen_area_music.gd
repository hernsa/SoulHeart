@tool
extends SceneTree

# 8-note leitmotifs, synthesized to 8-bit mono WAVs.
# Echo: watery descending arpeggio (minor). Hometown: warm rising major motif.

const MOTIFS := {
	"echo": [440.0, 349.23, 293.66, 220.0, 261.63, 329.63, 293.66, 220.0],
	"hometown": [261.63, 329.63, 392.0, 523.25, 392.0, 329.63, 261.63, 392.0],
}

const RATE := 22050
const NOTE_LEN := 0.22
const GAP := 0.03

func _init() -> void:
	for id in MOTIFS:
		_save(id)
	quit()

func _save(id: String) -> void:
	var freqs: Array = MOTIFS[id]
	var per_note := int((NOTE_LEN + GAP) * RATE)
	var total := per_note * freqs.size()
	var data := PackedByteArray()
	data.resize(total)
	var idx := 0
	for f: float in freqs:
		var n := int(NOTE_LEN * RATE)
		for i in n:
			var t := float(i) / float(RATE)
			var env := exp(-2.2 * t)
			var s := 0.6 * sin(TAU * f * t) + 0.4 * sin(TAU * f * 2.0 * t) * 0.35
			data[idx] = int(clamp((s * env + 1.0) * 127.5, 0.0, 255.0))
			idx += 1
		for i in int(GAP * RATE):
			data[idx] = 128
			idx += 1
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = RATE
	wav.data = data
	var err := wav.save_to_wav("res://assets/audio/music/mus_%s.wav" % id)
	if err != OK:
		push_error("save_to_wav failed for %s: %d" % [id, err])