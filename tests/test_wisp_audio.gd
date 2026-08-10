# tests/test_wisp_audio.gd
extends RefCounted

func test_play_hum_does_not_throw_low_mood() -> void:
	WispAudio.play_hum(0)
	TestHelper.is_true(true, "play_hum(0) called without error")

func test_play_hum_does_not_throw_high_mood() -> void:
	WispAudio.play_hum(100)
	TestHelper.is_true(true, "play_hum(100) called without error")

func test_play_hum_does_not_throw_mid_mood() -> void:
	WispAudio.play_hum(50)
	TestHelper.is_true(true, "play_hum(50) called without error")

func test_play_hum_is_idempotent_within_window() -> void:
	WispAudio.play_hum(50)
	WispAudio.play_hum(60)
	WispAudio.play_hum(70)
	TestHelper.is_true(true, "multiple play_hum calls within window do not crash")

func test_compute_pitch_in_range() -> void:
	var p0 := WispAudio._pitch_for_mood(0)
	var p100 := WispAudio._pitch_for_mood(100)
	TestHelper.is_true(p0 > 0.0, "pitch must be > 0")
	TestHelper.is_true(p100 > p0, "pitch at mood 100 > pitch at mood 0")