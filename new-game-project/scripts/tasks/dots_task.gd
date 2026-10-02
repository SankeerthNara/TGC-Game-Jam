class_name DotsTask
extends TaskBase
## Comic task: connect the numbered dots in order to reveal the picture.

var _pts: Array[Vector2] = []
var _next := 0
var _count := 8


func _begin() -> void:
	title = "CONNECT THE DOTS"
	hint = "Click the dots in number order, 1, 2, 3 ..."
	_count = 8 + difficulty * 2
	var c := panel.get_center() + Vector2(0, 20)
	var offset := randf() * TAU
	for i in _count:
		var a := offset + i * TAU / _count
		var r := 160.0 if i % 2 == 0 else 85.0
		_pts.append(c + Vector2(cos(a), sin(a)) * r * Vector2(1.5, 1.0))


func _gui_input(event: InputEvent) -> void:
	if _done:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in _count:
			if event.position.distance_to(_pts[i]) < 24.0:
				if i == _next:
					_next += 1
					if _next >= _count:
						succeed()
				elif i > _next:
					flash("IN ORDER, PLEASE!", 6.0)
				return


func _draw_task() -> void:
	for i in range(1, _next):
		draw_line(_pts[i - 1], _pts[i], INK, 6.0)
	if _next >= _count:
		draw_line(_pts[_count - 1], _pts[0], INK, 6.0)
		draw_colored_polygon(PackedVector2Array(_pts), Color(1, 0.85, 0.3, 0.6))
	for i in _count:
		var done := i < _next
		draw_circle(_pts[i], 20.0, INK)
		draw_circle(_pts[i], 16.0, GOLD if done else (Color("e63946") if i == _next else Color.WHITE))
		_text(str(i + 1), _pts[i] + Vector2(-8 if i < 9 else -13, 8), 20, INK, FONT_SHOUT)
