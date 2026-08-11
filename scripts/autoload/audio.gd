extends Node

const MUSIC := {
	"title": preload("res://assets/audio/music/mus_t.ogg"),
	"drizzle": preload("res://assets/audio/music/mus_room.ogg"),
	"grumble": preload("res://assets/audio/music/mus_snowdin.ogg"),
	"echo": preload("res://assets/audio/music/mus_echo.wav"),
	"hometown": preload("res://assets/audio/music/mus_hometown.wav"),
	"battle": preload("res://assets/audio/music/mus_battle1.ogg"),
	"death": preload("res://assets/audio/music/mus_dontgiveup.ogg"),
	"door_open": preload("res://assets/audio/music/mus_dooropen.ogg"),
	"door_close": preload("res://assets/audio/music/mus_doorclose.ogg"),
	"canon": preload("res://assets/audio/music/mus_canon.wav"),
	"cracks": preload("res://assets/audio/music/mus_cracks.wav"),
	"credits": preload("res://assets/audio/music/mus_credits.wav"),
	"hollow": preload("res://assets/audio/music/mus_hollow.wav"),
	"wisp": preload("res://assets/audio/music/mus_wisp.wav"),
}

const SFX := {
	"blip": preload("res://assets/audio/sfx/blip.wav"),
	"confirm": preload("res://assets/audio/sfx/confirm.wav"),
	"select": preload("res://assets/audio/sfx/select.wav"),
	"cancel": preload("res://assets/audio/sfx/cancel.wav"),
	"hurt": preload("res://assets/audio/sfx/hurt.wav"),
	"heal": preload("res://assets/audio/sfx/heal.wav"),
	"save": preload("res://assets/audio/sfx/save.wav"),
	"sting": preload("res://assets/audio/sfx/sting.wav"),
	"flee": preload("res://assets/audio/sfx/flee.wav"),
	"whoosh": preload("res://assets/audio/sfx/whoosh.wav"),
	"bone_clack": preload("res://assets/audio/sfx/bone_clack.wav"),
	"laser": preload("res://assets/audio/sfx/laser.wav"),
	"warn": preload("res://assets/audio/sfx/warn.wav"),
	"slice": preload("res://assets/audio/sfx/slice.wav"),
	"vaporize": preload("res://assets/audio/sfx/vaporize.wav"),
	"levelup": preload("res://assets/audio/sfx/levelup.wav"),
	"edit_bell": preload("res://assets/audio/sfx/edit_bell.wav"),
	"door_seal": preload("res://assets/audio/sfx/door_seal.wav"),
}

const SFX_POOL_SIZE := 8
const MUSIC_FADE := 0.3

var _music: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_index := 0
var _warned: Dictionary = {}

func _ready() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_pool.append(p)

func _ensure_bus(name: String) -> void:
	for i in AudioServer.bus_count:
		if AudioServer.get_bus_name(i) == name:
			return
	AudioServer.add_bus()
	AudioServer.set_bus_name(AudioServer.bus_count - 1, name)

func play_music(id: String) -> void:
	var stream: AudioStream = MUSIC.get(id)
	if stream == null:
		_warn_once("play_music", id)
		return
	if _music == null or _music.stream == stream:
		return
	_music_swap_prev(_music.stream)
	_music.stream = stream
	setup_stream_loop(stream)
	_music.volume_db = 0.0
	_music.play()

func _music_swap_prev(prev: AudioStream) -> void:
	if prev == null:
		return
	var fade_node := AudioStreamPlayer.new()
	fade_node.bus = "Music"
	fade_node.stream = prev
	fade_node.volume_db = 0.0
	add_child(fade_node)
	fade_node.play()
	var tw := create_tween()
	tw.tween_property(fade_node, "volume_db", -60.0, MUSIC_FADE)
	tw.tween_callback(fade_node.queue_free)

func stop_music(fade: float = MUSIC_FADE) -> void:
	if _music == null or _music.stream == null:
		return
	_music_swap_prev(_music.stream)
	_music.stop()
	_music.stream = null

func play_sfx(id: String, pitch: float = 1.0) -> void:
	var stream: AudioStream = SFX.get(id)
	if stream == null:
		stream = MUSIC.get(id)
	if stream == null:
		_warn_once("play_sfx", id)
		return
	if _sfx_pool.is_empty():
		return
	var p := _sfx_pool[_sfx_index % _sfx_pool.size()]
	_sfx_index += 1
	p.stream = stream
	p.pitch_scale = pitch
	p.play()

static func setup_stream_loop(stream: AudioStream) -> void:
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD

func _warn_once(what: String, id: String) -> void:
	var key := what + ":" + id
	if _warned.has(key):
		return
	_warned[key] = true
	push_warning("Audio: unknown id %s for %s" % [id, what])
