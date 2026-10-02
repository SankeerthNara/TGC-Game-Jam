class_name SimonTask
extends TaskBase
## Watch the lanterns flash, then repeat the pattern. Five rounds.

const LAMP_COLORS := [Color("e63946"), Color("3a86ff"), Color("2dc653"), Color("ffd23f")]
const ROUNDS := 5

var _seq: Array[int] = []
var _round := 1
var _showing := true
var _show_i := 0
var _show_t := -0.6
var _input_i := 0
var _lit := -1
var _lit_t := 0.0


func _begin() -> void:
	title = "REPEAT THE LANTERN CODE"
	hint = "Click the lanterns (or use the arrow keys) in the order they flashed."
	for i in ROUNDS:
		_seq.append(randi() % 4)
	_start_show()


func _start_show() -> void:
	_showing = true
	_show_i = 0
	_show_t = -0.7
	_input_i = 0


func _pos(i: int) -> Vector2:
	var c := panel.get_center() + Vector2(0, 45)
	return c + [Vector2(0, -105), Vector2(135, 0), Vector2(0, 105), Vector2(-135, 0)][i]


func _update(delta: float) -> void:
	_lit_t = maxf(0.0, _lit_t - delta)
	if _lit_t <= 0.0 and not _showing:
		_lit = -1
	if _showing:
		_show_t += delta
		if _show_t >= 0.0:
			if _show_i >= _round:
				_showing = false
				_lit = -1
			else:
				_lit = _seq[_show_i]
				_lit_t = 0.45
				_show_i += 1
				_show_t = -0.3


func _press(i: int) -> void:
	if _showing or _done:
		return
	_lit = i
	_lit_t = 0.3
	if i == _seq[_input_i]:
		_input_i += 1
		if _input_i >= _round:
			_round += 1
			if _round > ROUNDS:
				succeed()
			else:
				flash("NICE!")
				_start_show()
	else:
		flash("WRONG! WATCH AGAIN", 10.0)
		_start_show()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in 4:
			if event.position.distance_to(_pos(i)) < 58.0:
				_press(i)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_UP:
			_press(0)
		KEY_RIGHT:
			_press(1)
		KEY_DOWN:
			_press(2)
		KEY_LEFT:
			_press(3)


func _draw_task() -> void:
	_centered("ROUND %d / %d   %s" % [mini(_round, ROUNDS), ROUNDS, "WATCH..." if _showing else "YOUR TURN!"], panel.position.y + 100, 30, INK, FONT_SHOUT)
	for i in 4:
		var p := _pos(i)
		var lit := _lit == i
		var col: Color = LAMP_COLORS[i]
		if lit:
			_glow(p, 120.0, Color(col.r, col.g, col.b, 0.9))
		draw_rect(Rect2(p + Vector2(-5, -86), Vector2(10, 26)), INK)
		draw_circle(p, 58.0, INK)
		draw_circle(p, 50.0, col if lit else col.darkened(0.55))
		draw_circle(p + Vector2(-16, -16), 10.0, Color(1, 1, 1, 0.5 if lit else 0.2))
