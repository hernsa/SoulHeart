# tests/test_area_music.gd
extends RefCounted

func test_music_files_exist() -> void:
	for f in ["mus_echo.wav", "mus_hometown.wav"]:
		TestHelper.is_true(ResourceLoader.exists("res://assets/audio/music/" + f),
			"missing music file: " + f)

func test_music_loads_as_wav() -> void:
	for id in ["mus_echo.wav", "mus_hometown.wav"]:
		var s := load("res://assets/audio/music/" + id)
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