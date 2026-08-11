@tool
extends SceneTree

# 8-note leitmotifs, synthesized to 8-bit mono WAVs.
# Echo: watery descending arpeggio (minor). Hometown: warm rising major motif.
# Plan D additions: canon, cracks, credits, hollow, wisp area themes.
# SFX: edit_bell (2-tone chime), door_seal (low thud).

const MOTIFS := {
	"echo": [440.0, 349.23, 293.66, 220.0, 261.63, 329.63, 293.66, 220.0],
	"hometown": [261.63, 329.63, 392.0, 523.25, 392.0, 329.63, 261.63, 392.0],
	"canon": [196.0, 196.0, 233.08, 233.08, 293.66, 261.63, 233.08, 196.0],
	"cracks": [440.0, 0.0, 523.25, 0.0, 440.0, 0.0, 587.33, 0.0],
	"credits": [261.63, 329.63, 392.0, 523.25, 659.25, 523.25, 392.0, 329.63],
	"hollow": [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 440.0],
	"wisp": [523.25, 659.25, 783.99, 659.25, 523.25, 659.25, 783.99, 659.25],
}

# Short SFX: list of [freq, dur_seconds] pairs per clip.
const SFX_CLIPS := {
	"edit_bell": [[660.0, 0.18], [880.0, 0.22]],
	"door_seal": [[110.0, 0.35]],
}

const RATE := 22050
const NOTE_LEN := 0.22
const GAP := 0.03

func _init() -> void:
	for id in MOTIFS:
		_save(id)
	for id in SFX_CLIPS:
		_save_sfx(id)
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
			var val := 0.5
			if f > 0.0:
				val = 0.6 * sin(TAU * f * t) + 0.4 * sin(TAU * f * 2.0 * t) * 0.35
				val = val * env
			data[idx] = int(clamp((val + 1.0) * 127.5, 0.0, 255.0))
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

func _save_sfx(id: String) -> void:
	var clips: Array = SFX_CLIPS[id]
	var total_samples := 0
	for c in clips:
		total_samples += int(float(c[1]) * RATE) + int(GAP * RATE)
	var data := PackedByteArray()
	data.resize(total_samples)
	var idx := 0
	for c in clips:
		var f: float = c[0]
		var dur: float = c[1]
		var n := int(dur * RATE)
		for i in n:
			var t := float(i) / float(RATE)
			var env := exp(-3.0 * t)
			var val := sin(TAU * f * t) * env
			data[idx] = int(clamp((val + 1.0) * 127.5, 0.0, 255.0))
			idx += 1
		for i in int(GAP * RATE):
			data[idx] = 128
			idx += 1
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = RATE
	wav.data = data
	var err := wav.save_to_wav("res://assets/audio/sfx/%s.wav" % id)
	if err != OK:
		push_error("save_to_wav sfx failed for %s: %d" % [id, err])