class_name SfxPlayer
extends Node
## EventBus-driven one-shot sound pool. Missing audio files are safely ignored.

const POOL_SIZE := 8

const VOLUME_DB := {
	"task_success": -3.0, "task_mistake": -7.0, "vampire_spotted": -4.0,
	"reveal_friend": -4.0, "reveal_villain": -4.0, "kill": -3.0,
	"key_get": -4.0, "explosion": -2.0, "friend_assigned": -8.0,
	"friend_done": -6.0, "page_turn": -8.0, "comic_pop": -5.0,
	"key_click": -8.0, "chase_jump": -6.0, "chase_bounce": -3.0,
	"chase_fall": -5.0, "chase_checkpoint": -5.0, "chase_hit": -3.0,
	"chase_vault": -6.0, "chase_slide": -7.0, "chase_win": -3.0,
	"chase_lose": -5.0, "web_attach": -7.0, "web_shoot": -6.0,
	"web_hit": -4.0, "task_open": -8.0, "sabotage_alarm": -5.0,
	"sabotage_fixed": -4.0, "heart_lost": -4.0, "death": -4.0,
	"item_collected": -7.0, "trade_made": -7.0, "door_unlocked": -5.0,
}

var _players: Array[AudioStreamPlayer] = []
var _gains: Array[float] = []
var _muted := false
var _next := 0
var _cache: Dictionary = {}


func _ready() -> void:
	add_to_group("sfx")
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_players.append(player)
		_gains.append(-80.0)
	EventBus.sound_requested.connect(play)
	EventBus.task_started.connect(func(_id: String) -> void: play("task_open"))
	EventBus.sabotage_started.connect(func(_name: String, _seconds: float) -> void: play("sabotage_alarm"))
	EventBus.sabotage_resolved.connect(func(_name: String) -> void: play("sabotage_fixed"))
	EventBus.sabotage_failed.connect(func(_name: String, _health: int) -> void: play("heart_lost"))
	EventBus.player_died.connect(func() -> void: play("death"))
	EventBus.item_collected.connect(func(_type: String) -> void: play("item_collected"))
	EventBus.trade_made.connect(func(_key: String) -> void: play("trade_made"))
	EventBus.door_unlocked.connect(func(_index: int) -> void: play("door_unlocked"))


func play(sound_name: String) -> void:
	var player_index := _next
	_next = (_next + 1) % POOL_SIZE
	var audio: AudioStream = _stream_for(sound_name)
	if audio == null:
		return
	var player := _players[player_index]
	player.stop()
	player.stream = audio
	_gains[player_index] = float(VOLUME_DB.get(sound_name, -6.0))
	player.volume_db = -80.0 if _muted else _gains[player_index]
	player.pitch_scale = randf_range(0.95, 1.05)
	player.play()


func _stream_for(sound_name: String) -> AudioStream:
	if _cache.has(sound_name):
		return _cache[sound_name]
	var path := "res://assets/audio/sfx_%s.wav" % sound_name
	if not ResourceLoader.exists(path):
		return null
	var stream := load(path) as AudioStream
	if stream != null:
		_cache[sound_name] = stream
	return stream


func set_muted(on: bool) -> void:
	_muted = on
	for i in _players.size():
		_players[i].volume_db = -80.0 if _muted else _gains[i]
