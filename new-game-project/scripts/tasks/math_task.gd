class_name MathTask
extends TaskBase
## College task: a pop quiz. Pick the right answer before the clock runs out.

var NEED := 4
var TIME_PER := 9.0

var _good := 0
var _a := 0
var _b := 0
var _op := "+"
var _answer := 0
var _options: Array[int] = []
var _left := 9.0


func _begin() -> void:
	NEED = 4 + difficulty / 2
	TIME_PER = 9.0 - 1.0 * difficulty
	title = "POP QUIZ"
	hint = "Click the right answer. A wrong answer or a timeout costs you a point."
	_next_q()


func _next_q() -> void:
	_op = ["+", "-", "x"][randi() % 3]
	match _op:
		"+":
			_a = randi_range(12, 49 + difficulty * 15)
			_b = randi_range(8, 39 + difficulty * 10)
			_answer = _a + _b
		"-":
			_a = randi_range(30, 99)
			_b = randi_range(5, _a - 5)
			_answer = _a - _b
		_:
			_a = randi_range(3, 9 + difficulty)
			_b = randi_range(3, 9 + difficulty)
			_answer = _a * _b
	_options.clear()
	_options.append(_answer)
	while _options.size() < 4:
		var w := _answer + randi_range(-9, 9)
		if w != _answer and w >= 0 and not _options.has(w):
			_options.append(w)
	_options.shuffle()
	_left = TIME_PER


func _opt(i: int) -> Rect2:
	return Rect2(Vector2(panel.position.x + 70 + (i % 2) * 330, panel.position.y + 290 + (i / 2) * 90), Vector2(300, 74))


func _update(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		_good = maxi(0, _good - 1)
		flash("TIME'S UP!", 6.0)
		_next_q()


func _gui_input(event: InputEvent) -> void:
	if _done:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in 4:
			if _opt(i).has_point(event.position):
				if _options[i] == _answer:
					_good += 1
					if _good >= NEED:
						succeed()
						return
				else:
					_good = maxi(0, _good - 1)
					flash("WRONG!", 6.0)
				_next_q()
				return


func _draw_task() -> void:
	_text("CORRECT %d / %d" % [_good, NEED], panel.position + Vector2(30, 112), 26, INK, FONT_SHOUT)
	_centered("%d %s %d = ?" % [_a, _op, _b], panel.position.y + 230, 84, INK, FONT_SHOUT)
	for i in 4:
		var r := _opt(i)
		draw_rect(Rect2(r.position + Vector2(4, 5), r.size), Color(0, 0, 0, 0.3))
		draw_rect(r, Color("fff9e6"))
		draw_rect(r, INK, false, 4.0)
		_text(str(_options[i]), r.position + Vector2(0, 52), 46, INK, FONT_SHOUT, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	var bar := Rect2(Vector2(panel.position.x + 70, panel.position.y + 262), Vector2(panel.size.x - 140, 12))
	draw_rect(bar, INK)
	draw_rect(Rect2(bar.position + Vector2(2, 2), Vector2((bar.size.x - 4) * clampf(_left / TIME_PER, 0.0, 1.0), bar.size.y - 4)), RED if _left < 3.0 else Color("2dc653"))
