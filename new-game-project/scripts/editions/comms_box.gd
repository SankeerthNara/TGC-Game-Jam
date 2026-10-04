class_name CommsBox
extends CanvasLayer
## The hero's comms machine: the Narrator's "friendly" voice guiding him through every edition.
## Shows a portrait, a name plate and the line typing out. Any "NARRATOR: ..." caption becomes a call.
## kill_signal() makes the machine crackle and die (the last level, before the reveal).

const FONT_SHOUT := preload("res://assets/fonts/Bangers-Regular.ttf")
const FONT_BODY := preload("res://assets/fonts/ComicNeue-Bold.ttf")
const INK := Color("18151d")
const PAPER := Color("fff3d1")
const GOLD := Color("ffd23f")
const PORTRAITS := "res://assets/editions/portraits/"
const CPS := 48.0

var dead := false
var _queue: Array[Dictionary] = []
var _cur := {}
var _t := 0.0
var _clock := 0.0
var _static := 0.0
var _draw_node: Control
var _tex := {}


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("comms")
	_draw_node = Control.new()
	_draw_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_draw_node.size = Vector2(1280, 720)
	_draw_node.draw.connect(_draw_box)
	add_child(_draw_node)
	for key in ["narrator_friendly", "narrator_evil", "hero", "ink_baron", "static_twins"]:
		var p: String = PORTRAITS + key + ".png"
		if ResourceLoader.exists(p):
			_tex[key] = load(p)
	EventBus.caption_changed.connect(_on_caption)


func _on_caption(text: String) -> void:
	if text.begins_with("NARRATOR:"):
		say(text.substr(9).strip_edges())


## Queues a line. who: narrator | narrator_evil | hero | ink_baron | static_twins
func say(text: String, who := "narrator", hold := 3.5) -> void:
	if dead and who == "narrator":
		return
	# a new line replaces an old one that is still waiting, so the box never lags behind the game
	if _queue.size() >= 2:
		_queue.pop_front()
	_queue.append({"text": text, "who": who, "hold": hold})
	if _cur.is_empty():
		_next()


func clear() -> void:
	_queue.clear()
	_cur = {}


func busy() -> bool:
	return not _cur.is_empty()


func kill_signal() -> void:
	_static = 2.0
	_queue.clear()
	_cur = {"text": "...hero... the sig... I can't... -", "who": "narrator", "hold": 2.5}
	_t = 0.0
	EventBus.sound_requested.emit("static")
	var tw := create_tween()
	tw.tween_interval(2.8)
	tw.tween_callback(func() -> void:
		dead = true
		_cur = {"text": "SIGNAL LOST", "who": "none", "hold": 2.5}
		_t = 0.0
		EventBus.sound_requested.emit("comms_dead"))


func _next() -> void:
	if _queue.is_empty():
		_cur = {}
		return
	_cur = _queue.pop_front()
	_t = 0.0
	EventBus.sound_requested.emit("comms_beep")


func _process(delta: float) -> void:
	_clock += delta
	_static = maxf(0.0, _static - delta * 0.5)
	if not _cur.is_empty():
		_t += delta
		var full := String(_cur["text"])
		if _t > full.length() / CPS + float(_cur["hold"]):
			_next()
	_draw_node.queue_redraw()


func _draw_box() -> void:
	if _cur.is_empty():
		return
	var ci := _draw_node
	var appear := clampf(_t / 0.18, 0.0, 1.0)
	var box := Rect2(Vector2(24, 586 + (1.0 - appear) * 40.0), Vector2(620, 112))
	var who := String(_cur["who"])
	var evil := who == "narrator_evil"
	ci.draw_rect(Rect2(box.position + Vector2(6, 6), box.size), Color(0, 0, 0, 0.5))
	ci.draw_rect(box, Color("14111b") if not evil else Color("2a0610"))
	ci.draw_rect(box, GOLD if not evil else Color("e63946"), false, 3.0)
	# portrait
	var pc := box.position + Vector2(56, 56)
	ci.draw_circle(pc, 44.0, INK)
	ci.draw_circle(pc, 40.0, Color("2d1f3d") if not evil else Color("4a0d1a"))
	var key := "narrator_friendly" if who == "narrator" else who
	if _tex.has(key):
		ci.draw_texture_rect(_tex[key], Rect2(pc - Vector2(40, 40), Vector2(80, 80)), false)
	elif who in ["narrator", "narrator_evil"]:
		ComicArt.narrator(ci, pc + Vector2(0, 2), 0.36, 1.0, "grin" if evil else "calm", _clock)
	elif who == "hero":
		ComicArt.hero_bust(ci, 0, pc + Vector2(0, -4), 0.36, "determined", _clock)
	ci.draw_arc(pc, 42.0, 0.0, TAU, 32, GOLD if not evil else Color("e63946"), 3.0)
	# static over the portrait when the signal is bad
	if _static > 0.0 or who == "none":
		for k in 10:
			var y := pc.y - 40.0 + fposmod(k * 9.0 + _clock * 300.0, 80.0)
			ci.draw_line(Vector2(pc.x - 40, y), Vector2(pc.x + 40, y), Color(1, 1, 1, 0.35), 2.0)
	# name plate and signal bars
	var names := {"narrator": "THE NARRATOR  -  COMMS", "narrator_evil": "THE NARRATOR", "hero": "YOU", "ink_baron": "THE INK BARON", "static_twins": "THE STATIC TWINS", "none": "COMMS"}
	ci.draw_string(FONT_SHOUT, box.position + Vector2(112, 30), String(names.get(who, "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, GOLD if not evil else Color("ff6b6b"))
	for k in 4:
		var on := not dead and _static <= 0.0 or (k == 0 and _static > 0.0 and int(_clock * 8.0) % 2 == 0)
		ci.draw_rect(Rect2(box.end - Vector2(64 - k * 12, 84 - (3 - k) * 5), Vector2(8, 10 + k * 5)), GOLD if on else Color(0.3, 0.3, 0.35))
	# the line typing out
	var full := String(_cur["text"])
	var shown := full.substr(0, int(_t * CPS))
	var lines := _wrap(shown, 480.0, 20)
	for i in mini(lines.size(), 3):
		ci.draw_string(FONT_BODY, box.position + Vector2(112, 58 + i * 22), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, PAPER)


func _wrap(text: String, width: float, fs: int) -> PackedStringArray:
	var out := PackedStringArray()
	var line := ""
	for word in text.split(" "):
		var test := word if line == "" else line + " " + word
		if FONT_BODY.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > width and line != "":
			out.append(line)
			line = word
		else:
			line = test
	if line != "":
		out.append(line)
	return out
