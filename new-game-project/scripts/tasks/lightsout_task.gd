class_name LightsOutTask
extends TaskBase
## Light task: pressing a bulb flips it and its four neighbours. Turn every bulb on.

var _n := 3
var _on: Array[bool] = []


func _begin() -> void:
	title = "LIGHTS OUT"
	hint = "Click a bulb: it flips itself and its neighbours. Light them all!"
	_n = 3 if difficulty < 2 else 4
	for i in _n * _n:
		_on.append(true)
	var presses := 0
	while presses < 4 + difficulty or not _on.has(false):
		_press(randi() % (_n * _n))
		presses += 1


func _press(i: int) -> void:
	var x := i % _n
	var y := i / _n
	for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var nx: int = x + d.x
		var ny: int = y + d.y
		if nx >= 0 and ny >= 0 and nx < _n and ny < _n:
			_on[ny * _n + nx] = not _on[ny * _n + nx]


func _cell(i: int) -> Rect2:
	var s := 96.0 if _n == 3 else 82.0
	var total := _n * s + (_n - 1) * 14.0
	var o := Vector2(panel.get_center().x - total * 0.5, panel.position.y + 100 + (400.0 - total) * 0.5)
	return Rect2(o + Vector2((i % _n) * (s + 14.0), (i / _n) * (s + 14.0)), Vector2(s, s))


func _gui_input(event: InputEvent) -> void:
	if _done:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in _n * _n:
			if _cell(i).has_point(event.position):
				_press(i)
				if not _on.has(false):
					succeed()
				return


func _draw_task() -> void:
	for i in _n * _n:
		var r := _cell(i)
		var lit := _on[i]
		if lit:
			_glow(r.get_center(), r.size.x * 0.9, Color(1, 0.9, 0.4, 0.7))
		draw_rect(Rect2(r.position + Vector2(4, 5), r.size), Color(0, 0, 0, 0.3))
		draw_rect(r, Color("ffd23f") if lit else Color("4a4e69"))
		draw_rect(r, INK, false, 4.0)
		draw_circle(r.get_center(), r.size.x * 0.2, Color("fffbe6") if lit else Color("2b2d42"))
