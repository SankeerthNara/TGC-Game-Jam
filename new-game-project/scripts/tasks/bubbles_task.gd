class_name BubblesTask
extends TaskBase
## Comic lettering: fill speech bubbles with the word that completes each line.

const BANK := [
	["DON'T PANIC! I'LL ____ THE LIGHTS ON!", "FLIP"],
	["THE ____ IS DUE AT MIDNIGHT!", "ASSIGNMENT"],
	["KA-____! THE DOOR BURST OPEN!", "POW"],
	["WHO TURNED OFF THE ____?!", "LIGHTS"],
	["I NEED MORE ____ FOR THE EXAM.", "COFFEE"],
	["MEET ME IN THE ____ AFTER CLASS.", "LIBRARY"],
	["THE VILLAIN ESCAPED THE LAST ____!", "PANEL"],
	["MY TORCH WENT ____ IN THE DARK.", "OUT"],
]

var _pick: Array = []
var _chips: Array[String] = []
var _filled: Array[String] = []
var _bubble_count := 2
var _held := -1


func _begin() -> void:
	title = "FILL THE SPEECH BUBBLES"
	hint = "Click a word, then click the bubble where it belongs."
	_bubble_count = 2 + difficulty
	_filled.clear()
	for _i in _bubble_count:
		_filled.append("")
	var bank := BANK.duplicate()
	bank.shuffle()
	_pick = bank.slice(0, _bubble_count)
	_chips.clear()
	for pair in _pick:
		_chips.append(pair[1])
	# Extra words make the choice harder without making the controls crowded.
	for pair in bank.slice(_bubble_count, mini(_bubble_count + 2, bank.size())):
		_chips.append(pair[1])
	_chips.shuffle()


func _bubble(i: int) -> Rect2:
	var usable_h := 292.0
	var pitch := usable_h / _bubble_count
	var bubble_h := minf(70.0, pitch - 7.0)
	return Rect2(Vector2(panel.position.x + 48, panel.position.y + 82 + pitch * i), Vector2(panel.size.x - 96, bubble_h))


func _chip(i: int) -> Rect2:
	var row: int = i / 4
	var col: int = i % 4
	var count_in_row := mini(4, _chips.size() - row * 4)
	var gap := 8.0
	var w := minf(170.0, (panel.size.x - 80.0 - gap * (count_in_row - 1)) / count_in_row)
	var total := count_in_row * w + (count_in_row - 1) * gap
	var x := panel.get_center().x - total * 0.5 + col * (w + gap)
	var y := panel.end.y - 128.0 + row * 48.0
	return Rect2(Vector2(x, y), Vector2(w, 38))


func _gui_input(event: InputEvent) -> void:
	if _done:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in _chips.size():
			if _chip(i).has_point(event.position) and not _filled.has(_chips[i]):
				_held = i
				return
		for b in _bubble_count:
			if _bubble(b).has_point(event.position) and _held >= 0 and _filled[b] == "":
				if _chips[_held] == _pick[b][1]:
					_filled[b] = _chips[_held]
					_held = -1
					if not _filled.has(""):
						succeed()
				else:
					flash("NOT THAT ONE!", 8.0)
					_held = -1


func _draw_task() -> void:
	for b in _bubble_count:
		var r := _bubble(b)
		var done := _filled[b] != ""
		draw_rect(Rect2(r.position + Vector2(5, 6), r.size), Color(0, 0, 0, 0.25))
		draw_rect(r, Color("e8ffe8") if done else Color.WHITE)
		draw_rect(r, INK, false, 4.0)
		draw_colored_polygon(PackedVector2Array([r.position + Vector2(40, r.size.y - 2), r.position + Vector2(78, r.size.y - 2), r.position + Vector2(36, r.size.y + 20)]), INK)
		draw_colored_polygon(PackedVector2Array([r.position + Vector2(44, r.size.y - 4), r.position + Vector2(72, r.size.y - 4), r.position + Vector2(42, r.size.y + 14)]), Color("e8ffe8") if done else Color.WHITE)
		var text: String = _pick[b][0]
		if done:
			text = text.replace("____", _filled[b])
		_text(text, r.position + Vector2(24, r.size.y * 0.68), 26, GREEN if done else INK, FONT_SHOUT)
	for i in _chips.size():
		var c := _chip(i)
		var used := _filled.has(_chips[i])
		var sel := _held == i
		draw_rect(Rect2(c.position + Vector2(3, 4), c.size), Color(0, 0, 0, 0.25))
		draw_rect(c, Color("bdbdbd") if used else (GOLD if sel else Color("fff9e6")))
		draw_rect(c, INK, false, 3.0)
		var font_size := 22
		while font_size > 14 and FONT_SHOUT.get_string_size(_chips[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > c.size.x - 8.0:
			font_size -= 1
		_text(_chips[i], Vector2(c.position.x, c.position.y + 27), font_size, INK, FONT_SHOUT, HORIZONTAL_ALIGNMENT_CENTER, c.size.x)
