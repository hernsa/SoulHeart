extends SceneTree

const OUT_DIR := "res://assets/audio/sfx/"
const RATE := 44100

func _initialize() -> void:
	gen("blip", 0.12, 0.5, 0.4, [
		{"freq": 880.0, "dur": 0.04, "vol": 1.0},
		{"freq": 1318.0, "dur": 0.04, "vol": 0.8},
		{"freq": 1760.0, "dur": 0.04, "vol": 0.6},
	], "square")
	gen("confirm", 0.08, 0.5, 0.3, [{"freq": 660.0, "dur": 0.08, "vol": 1.0}], "square")
	gen("select", 0.07, 0.5, 0.3, [{"freq": 440.0, "dur": 0.035, "vol": 1.0}, {"freq": 880.0, "dur": 0.035, "vol": 1.0}], "square")
	gen("cancel", 0.1, 0.5, 0.3, [{"freq": 330.0, "dur": 0.05, "vol": 1.0}, {"freq": 247.0, "dur": 0.05, "vol": 0.9}], "square")
	gen("hurt", 0.22, 0.7, 0.25, [{"freq": 300.0, "dur": 0.22, "vol": 1.0}], "saw", 120.0)
	gen("heal", 0.24, 0.5, 0.35, [
		{"freq": 523.0, "dur": 0.08, "vol": 1.0},
		{"freq": 659.0, "dur": 0.08, "vol": 1.0},
		{"freq": 784.0, "dur": 0.08, "vol": 1.0},
	], "square")
	gen("save", 0.3, 0.5, 0.3, [
		{"freq": 784.0, "dur": 0.1, "vol": 1.0},
		{"freq": 988.0, "dur": 0.1, "vol": 1.0},
		{"freq": 1175.0, "dur": 0.1, "vol": 1.0},
	], "triangle")
	gen("sting", 0.3, 0.8, 0.4, [{"freq": 120.0, "dur": 0.3, "vol": 1.0}], "saw", 60.0)
	gen("flee", 0.18, 0.6, 0.3, [{"freq": 440.0, "dur": 0.09, "vol": 1.0}, {"freq": 880.0, "dur": 0.09, "vol": 1.0}], "square")
	quit(0)

func gen(id: String, total: float, attack: float, decay: float, notes: Array, wave: String, glide := 0.0) -> void:
	var samples := PackedFloat32Array()
	for note in notes:
		var note_n := int(note["dur"] * RATE)
		var start_freq: float = note["freq"]
		var end_freq := start_freq + glide
		for i in note_n:
			var t := float(i) / RATE
			var freq := lerpf(start_freq, end_freq, t / note["dur"])
			var phase := fmod(t * freq, 1.0)
			var v: float
			match wave:
				"square": v = 1.0 if phase < 0.5 else -1.0
				"saw": v = phase * 2.0 - 1.0
				"triangle": v = 4.0 * absf(phase - 0.5) - 1.0
			var env := minf(1.0, t / attack)
			if t > note["dur"] * (1.0 - decay):
				env *= 1.0 - (t - note["dur"] * (1.0 - decay)) / (note["dur"] * decay)
			samples.append(v * env * note["vol"])
	_write_wav(OUT_DIR + id + ".wav", samples)

func _write_wav(path: String, samples: PackedFloat32Array) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	var data_size := samples.size() * 2
	f.store_buffer("RIFF".to_ascii_buffer())
	f.store_32(36 + data_size)
	f.store_buffer("WAVEfmt ".to_ascii_buffer())
	f.store_32(16)
	f.store_16(1)
	f.store_16(1)
	f.store_32(RATE)
	f.store_32(RATE * 2)
	f.store_16(2)
	f.store_16(16)
	f.store_buffer("data".to_ascii_buffer())
	f.store_32(data_size)
	for s in samples:
		f.store_16(clampi(int(s * 32767.0), -32768, 32767))
	f.close()
