extends RefCounted

const AUDIO_SCRIPT := "res://scripts/autoload/audio.gd"

func test_music_registry_loaded() -> void:
	var S := load(AUDIO_SCRIPT)
	for id in ["title", "drizzle", "grumble", "battle", "death", "door_open", "door_close"]:
		var stream: AudioStream = S.MUSIC.get(id)
		TestHelper.is_true(stream != null, "music stream exists for " + id)
		if stream:
			TestHelper.is_true(stream.get_length() > 0.0, "music stream has duration for " + id)

func test_sfx_registry_loaded() -> void:
	var S := load(AUDIO_SCRIPT)
	for id in ["blip", "confirm", "select", "cancel", "hurt", "heal", "save", "sting", "flee"]:
		var stream: AudioStream = S.SFX.get(id)
		TestHelper.is_true(stream != null, "sfx stream exists for " + id)
		if stream:
			TestHelper.is_true(stream.get_length() > 0.0, "sfx stream has duration for " + id)

func test_unknown_id_is_safe() -> void:
	var a = load(AUDIO_SCRIPT).new()
	var before := TestHelper.failures
	a.play_sfx("does_not_exist", 1.0)
	a.play_music("does_not_exist")
	a.stop_music(0.1)
	TestHelper.eq(TestHelper.failures, before, "unknown ids never crash or assert")

func test_attack_sfx_registered() -> void:
	var S := load(AUDIO_SCRIPT)
	for id in ["whoosh", "bone_clack", "laser", "warn", "slice", "vaporize", "levelup"]:
		var stream: AudioStream = S.SFX.get(id)
		TestHelper.is_true(stream != null, "attack sfx registered: " + id)
		if stream:
			TestHelper.is_true(stream.get_length() > 0.0, "attack sfx has duration: " + id)
