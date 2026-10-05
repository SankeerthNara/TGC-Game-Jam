class_name VoPlayer
extends Node
## Voice-over: plays a recorded clip when a cutscene caption or speech bubble appears (or a comms line
## starts). Clips are looked up in res://assets/vo/vo_lines.json, either by the line's exact text or
## by an id ("book/1/0" = cutscene "book", page 1, the first caption/bubble on it):
##   { "Once, the Earth shone with light...": "book_01.mp3", "reveal/1/2": "reveal_03.ogg" }
## Files live in res://assets/vo/ (.mp3, .ogg or .wav). A line without a clip, or a missing file,
## simply stays silent. The music dips while a clip plays; volume is set from the pause menu.

const DIR := "res://assets/vo/"
const MAP := "res://assets/vo/vo_lines.json"

var volume := 1.0 ## 0..1 (pause menu: VOICE 100% / 50% / OFF)
var _map := {}
var _player: AudioStreamPlayer
var _cache := {}
var _queue: Array[AudioStream] = []


func _ready() -> void:
	add_to_group("vo")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	add_child(_player)
	if FileAccess.file_exists(MAP):
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(MAP))
		if data is Dictionary:
			for k: String in data:
				_map[_norm(k)] = String(data[k])


static func get_vo(tree: SceneTree) -> VoPlayer:
	return tree.get_first_node_in_group("vo") as VoPlayer


## The same line written with small differences (spacing, a "NARRATOR:" prefix) still matches.
static func _norm(text: String) -> String:
	var t := text.strip_edges()
	if t.begins_with("NARRATOR:"):
		t = t.substr(9).strip_edges()
	while t.contains("  "):
		t = t.replace("  ", " ")
	return t.to_lower()


func _stream(text: String, id := "") -> AudioStream:
	var file := ""
	if id != "" and _map.has(_norm(id)):
		file = _map[_norm(id)]
	elif _map.has(_norm(text)):
		file = _map[_norm(text)]
	if file == "":
		return null
	if not _cache.has(file):
		var path := DIR + file
		_cache[file] = load(path) if ResourceLoader.exists(path) else null
	return _cache[file]


func has_clip(text: String, id := "") -> bool:
	return _stream(text, id) != null


## Plays the clip for a line; returns its length in seconds (0 when there is none).
func play(text: String, id := "") -> float:
	var st := _stream(text, id)
	if st == null or volume <= 0.0:
		return 0.0
	_player.stop()
	_player.stream = st
	_player.volume_db = linear_to_db(volume)
	_player.play()
	return st.get_length()


## Plays the clip now, or after the clips already queued (lines that overlap don't cut each other off).
func queue(text: String, id := "") -> void:
	var st := _stream(text, id)
	if st == null or volume <= 0.0:
		return
	if busy():
		_queue.append(st)
	else:
		_start(st)


func _start(st: AudioStream) -> void:
	_player.stop()
	_player.stream = st
	_player.volume_db = linear_to_db(volume)
	_player.play()


func _process(_delta: float) -> void:
	if not _player.playing and not _queue.is_empty():
		_start(_queue.pop_front())


func stop() -> void:
	_queue.clear()
	_player.stop()


func busy() -> bool:
	return _player.playing or not _queue.is_empty()


func set_volume(v: float) -> void:
	volume = clampf(v, 0.0, 1.0)
	if volume <= 0.0:
		stop()
	else:
		_player.volume_db = linear_to_db(volume)
