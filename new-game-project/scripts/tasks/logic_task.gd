class_name LogicTask
extends TaskBase
## College task (digital logic): flip the inputs so the output lamp lights. Two circuits.

## Each circuit: inputs, a list of expressions rendered as text, and an evaluator id.
const CIRCUITS := [
	{"inputs": ["A", "B", "C"], "text": "OUT = (A AND B) OR C", "id": 0},
	{"inputs": ["A", "B", "C"], "text": "OUT = (A OR B) AND (NOT C)", "id": 1},
	{"inputs": ["A", "B", "C", "D"], "text": "OUT = (A AND NOT B) OR (C AND D)", "id": 2},
	{"inputs": ["A", "B", "C"], "text": "OUT = NOT (A AND B) AND C", "id": 3},
	{"inputs": ["A", "B", "C", "D"], "text": "OUT = (A XOR B) AND (C OR D)", "id": 4},
]
var ROUNDS := 1

var _round := 0
var _deck: Array = []
var _cur: Dictionary = {}
var _state: Array[bool] = []


func _begin() -> void:
	ROUNDS = 1 + (difficulty + 1) / 2
	title = "WIRE THE LOGIC GATES"
	hint = "Click the switches. Make the OUT lamp light up!"
	_deck = CIRCUITS.duplicate()
	_deck.shuffle()
	_load_round()


func _load_round() -> void:
	_cur = _deck[_round]
	_state.clear()
	for i in _cur["inputs"].size():
		_state.append(false)
	while _eval():
		for i in _state.size():
			_state[i] = randf() < 0.5


func _eval() -> bool:
	var s := _state
	match int(_cur["id"]):
		0:
			return (s[0] and s[1]) or s[2]
		1:
			return (s[0] or s[1]) and not s[2]
		2:
			return (s[0] and not s[1]) or (s[2] and s[3])
		3:
			return (not (s[0] and s[1])) and s[2]
		4:
			return (s[0] != s[1]) and (s[2] or s[3])
	return false


func _switch(i: int) -> Rect2:
	var n: int = _state.size()
	var w := 90.0
	var gap := 40.0
	var total := n * w + (n - 1) * gap
	return Rect2(Vector2(panel.get_center().x - total * 0.5 + i * (w + gap), panel.position.y + 352), Vector2(w, 90))


func _gui_input(event: InputEvent) -> void:
	if _done:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in _state.size():
			if _switch(i).has_point(event.position):
				_state[i] = not _state[i]
				if _eval():
					_round += 1
					if _round >= ROUNDS:
						succeed()
					else:
						flash("CIRCUIT FIXED!")
						_load_round()


func _draw_task() -> void:
	_text("CIRCUIT %d / %d" % [_round + 1, ROUNDS], panel.position + Vector2(30, 112), 26, INK, FONT_SHOUT)
	_centered(_cur["text"], panel.position.y + 165, 36, INK, FONT_SHOUT)
	# the output lamp
	var lamp := Vector2(panel.get_center().x, panel.position.y + 262.0)
	var on := _eval()
	if on:
		_glow(lamp, 90.0, Color(1, 0.9, 0.4, 0.9))
	draw_circle(lamp, 38.0, INK)
	draw_circle(lamp, 31.0, GOLD if on else Color("4a4e69"))
	_text("OUT", lamp + Vector2(52, 10), 30, INK, FONT_SHOUT)
	# the switches with wires up to the lamp
	for i in _state.size():
		var r := _switch(i)
		var col := GOLD if _state[i] else Color("8d99ae")
		var wire := PackedVector2Array([Vector2(r.get_center().x, r.position.y), Vector2(r.get_center().x, lamp.y + 70), Vector2(lamp.x, lamp.y + 70), lamp + Vector2(0, 38)])
		draw_polyline(wire, INK, 7.0)
		draw_polyline(wire, col, 3.5)
		draw_rect(Rect2(r.position + Vector2(4, 5), r.size), Color(0, 0, 0, 0.3))
		draw_rect(r, Color("fff9e6"))
		draw_rect(r, INK, false, 4.0)
		draw_rect(Rect2(r.position + Vector2(r.size.x * 0.5 - 14, 14), Vector2(28, r.size.y - 28)), INK)
		var ky := r.position.y + (22.0 if _state[i] else r.size.y - 22.0)
		draw_circle(Vector2(r.get_center().x, ky), 15.0, RED if not _state[i] else Color("2dc653"))
		_text("%s = %d" % [_cur["inputs"][i], 1 if _state[i] else 0], r.position + Vector2(8, r.size.y + 30), 26, INK, FONT_SHOUT)
