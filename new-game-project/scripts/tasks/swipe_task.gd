class_name SwipeTask
extends TaskBase
## Swipe the card through the reader: not too fast, not too slow.

var MIN_TIME := 0.18
var MAX_TIME := 1.5

var _card_x := 0.0
var _dragging := false
var _grab_dx := 0.0
var _start_t := -1.0
var _passed_left := false


func _begin() -> void:
	MIN_TIME = 0.18 + 0.05 * difficulty
	MAX_TIME = 1.5 - 0.2 * difficulty
	title = "SWIPE THE PANTRY CARD"
	hint = "Press on the card and drag it right through the reader at a steady speed."
	_card_x = _rail().position.x + 20.0


func _rail() -> Rect2:
	return Rect2(Vector2(panel.position.x + 70, panel.position.y + 240), Vector2(panel.size.x - 140, 100))


func _reader() -> Rect2:
	var r := _rail()
	return Rect2(Vector2(r.get_center().x - 130, r.position.y - 60), Vector2(260, 220))


func _gui_input(event: InputEvent) -> void:
	if _done:
		return
	var r := _rail()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if Rect2(Vector2(_card_x, r.position.y), Vector2(150, r.size.y)).has_point(event.position):
				_dragging = true
				_grab_dx = _card_x - event.position.x
				_start_t = -1.0
				_passed_left = false
		elif _dragging:
			_dragging = false
			if _card_x < r.end.x - 170.0:
				flash("BAD SWIPE. AGAIN!", 6.0)
			_card_x = r.position.x + 20.0
	elif event is InputEventMouseMotion and _dragging:
		_card_x = clampf(event.position.x + _grab_dx, r.position.x + 10.0, r.end.x - 160.0)
		var rd := _reader()
		if not _passed_left and _card_x + 150.0 > rd.position.x + 10.0:
			_passed_left = true
			_start_t = _t
		if _passed_left and _card_x > rd.end.x - 160.0 and _start_t >= 0.0:
			var dur := _t - _start_t
			_dragging = false
			if dur < MIN_TIME:
				flash("TOO FAST! (%.2fs)" % dur, 8.0)
				_card_x = r.position.x + 20.0
			elif dur > MAX_TIME:
				flash("TOO SLOW! (%.2fs)" % dur, 8.0)
				_card_x = r.position.x + 20.0
			else:
				succeed()


func _draw_task() -> void:
	var r := _rail()
	draw_rect(r, Color("c9ada7"))
	draw_rect(r, INK, false, 4.0)
	var rd := _reader()
	draw_rect(Rect2(rd.position + Vector2(8, 8), rd.size), Color(0, 0, 0, 0.35))
	draw_rect(rd, Color("4a4e69"))
	draw_rect(rd, INK, false, 6.0)
	draw_rect(Rect2(rd.position + Vector2(20, 70), Vector2(rd.size.x - 40, 40)), INK)
	var lamp_ok := _passed_left
	draw_circle(rd.position + Vector2(rd.size.x - 34, 30), 14.0, INK)
	draw_circle(rd.position + Vector2(rd.size.x - 34, 30), 10.0, Color("2dc653") if lamp_ok else RED)
	var card := Rect2(Vector2(_card_x, r.position.y + 12), Vector2(150, 76))
	draw_rect(Rect2(card.position + Vector2(4, 5), card.size), Color(0, 0, 0, 0.35))
	draw_rect(card, Color("fff9e6"))
	draw_rect(card, INK, false, 4.0)
	draw_rect(Rect2(card.position + Vector2(0, 12), Vector2(card.size.x, 14)), INK)
	draw_circle(card.position + Vector2(28, 52), 12.0, GOLD)
	draw_rect(Rect2(card.position + Vector2(56, 44), Vector2(76, 8)), Color("c9ada7"))
	draw_rect(Rect2(card.position + Vector2(56, 58), Vector2(52, 8)), Color("c9ada7"))
	_centered("SWIPE  ->", panel.position.y + 125, 44, INK, FONT_SHOUT)
