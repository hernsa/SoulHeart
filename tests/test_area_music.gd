# tests/test_area_music.gd
extends RefCounted

const NEW_MUSIC_IDS := ["canon", "cracks", "credits", "hollow", "wisp"]
const NEW_SFX_IDS := ["edit_bell", "door_seal"]

func test_music_files_exist() -> void:
	for f in ["mus_echo.wav", "mus_hometown.wav"]:
		TestHelper.is_true(ResourceLoader.exists("res://assets/audio/music/" + f),
			"missing music file: " + f)

func test_new_music_files_exist() -> void:
	for id in NEW_MUSIC_IDS:
		var path := "res://assets/audio/music/mus_%s.wav" % id
		TestHelper.is_true(ResourceLoader.exists(path), "missing new music file: " + id)

func test_new_sfx_files_exist() -> void:
	for id in NEW_SFX_IDS:
		var path := "res://assets/audio/sfx/%s.wav" % id
		TestHelper.is_true(ResourceLoader.exists(path), "missing new sfx file: " + id)

func test_music_loads_as_wav() -> void:
	for id in ["mus_echo.wav", "mus_hometown.wav"]:
		var s := load("res://assets/audio/music/" + id)
		TestHelper.is_true(s is AudioStreamWAV, "%s must load as AudioStreamWAV" % id)
		TestHelper.is_true((s as AudioStreamWAV).data.size() > 0, "%s has sample data" % id)

func test_new_music_loads_as_wav() -> void:
	for id in NEW_MUSIC_IDS:
		var path := "res://assets/audio/music/mus_%s.wav" % id
		var s := load(path)
		TestHelper.is_true(s is AudioStreamWAV, "%s must load as AudioStreamWAV" % id)
		TestHelper.is_true((s as AudioStreamWAV).data.size() > 0, "%s has sample data" % id)

func test_setup_stream_loop_sets_wav_loop() -> void:
	var s: AudioStreamWAV = load("res://assets/audio/music/mus_echo.wav")
	Audio.setup_stream_loop(s)
	TestHelper.eq(s.loop_mode, AudioStreamWAV.LOOP_FORWARD, "wav loop set to forward")

func test_play_music_echo_sets_looping_stream() -> void:
	if Audio._music == null:
		return
	Audio.play_music("echo")
	TestHelper.is_true(Audio._music.stream != null, "echo stream assigned")
	var wav := Audio._music.stream as AudioStreamWAV
	TestHelper.eq(wav.loop_mode, AudioStreamWAV.LOOP_FORWARD, "echo wav loops")

func test_audio_keys_registered() -> void:
	for id in NEW_MUSIC_IDS:
		TestHelper.is_true(Audio.MUSIC.has(id), "Audio.MUSIC missing key: " + id)
	for id in NEW_SFX_IDS:
		TestHelper.is_true(Audio.SFX.has(id), "Audio.SFX missing key: " + id)

func test_canon_uses_canon_music() -> void:
	var src := FileAccess.get_file_as_string("res://scripts/rooms/canon.gd")
	TestHelper.is_true(src.contains('play_music("canon")'), "canon.gd uses canon music key")

func test_cracks_uses_cracks_music() -> void:
	var src := FileAccess.get_file_as_string("res://scripts/rooms/cracks.gd")
	TestHelper.is_true(src.contains('play_music("cracks")'), "cracks.gd uses cracks music key")
