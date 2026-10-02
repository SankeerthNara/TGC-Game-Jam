class_name BubblesTask
extends TaskBase
## Comic lettering: fill the blanks of three speech bubbles with the right word chips.

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
var _filled: Array[String] = ["", "", ""]
var _held := -1


func _begin() -> void:
	title = "FILL THE SPEECH BUBBLES"
	hint = "Click a word, then click the bubble where it belongs."
	var bank := BANK.duplicate()
	bank.shuffle()
	_pick = bank.slice(0, 3)
	for p in _pick:
		_chips.append(p[1])
	for extra in bank.slice(3, 5):
		_chips.append(extra[1])
	_chips.shuffle()


func _bubble(i: int) -> Rect2:
	return Rect2(Vector2(panel.position.x + 60, panel.position.y + 95 + i * 98), Vector2(panel.size.x - 120, 78))


func _chip(i: int) -> Rect2:
	var w := 140.0
	var gap := 12.0
	var total := _chips.size() * w + (_chips.size() - 1) * gap
	return Rect2(Vector2(panel.get_center().x - total * 0.5 + i * (w + gap), panel.end.y - 112), Vector2(w, 46))


func _gui_input(event: InputEvent) -> void:
	if _done:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in _chips.size():
			if _chip(i).has_point(event.position) and not _filled.has(_chips[i]):
				_held = i
				return
		for b in 3:
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
	for b in 3:
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
		_text(text, r.position + Vector2(24, 48), 28, GREEN if done else INK, FONT_SHOUT)
	for i in _chips.size():
		var c := _chip(i)
		var used := _filled.has(_chips[i])
		var sel := _held == i
		draw_rect(Rect2(c.position + Vector2(3, 4), c.size), Color(0, 0, 0, 0.25))
		draw_rect(c, Color("bdbdbd") if used else (GOLD if sel else Color("fff9e6")))
		draw_rect(c, INK, false, 3.0)
		_text(_chips[i], c.position + Vector2(0, 33), 24, INK, FONT_SHOUT, HORIZONTAL_ALIGNMENT_CENTER, c.size.x)
