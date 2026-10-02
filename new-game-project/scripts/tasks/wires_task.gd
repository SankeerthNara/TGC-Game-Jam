class_name WiresTask
extends TaskBase
## Drag each wire to the socket of the same colour.

const WIRE_COLORS := [Color("e63946"), Color("3a86ff"), Color("ffd23f"), Color("ff7bd5")]

var _right: Array[int] = [0, 1, 2, 3] ## colour index at each right socket
var _link: Array[int] = [-1, -1, -1, -1] ## right socket reached by each left wire
var _drag := -1
var _mouse := Vector2.ZERO


func _begin() -> void:
	title = "REWIRE THE PANEL"
	hint = "Drag each wire to the matching colour on the right."
	while _right == [0, 1, 2, 3]:
		_right.shuffle()


func _left_pos(i: int) -> Vector2:
	return Vector2(panel.position.x + 120, panel.position.y + 165 + i * 88)


func _right_pos(j: int) -> Vector2:
	return Vector2(panel.end.x - 120, panel.position.y + 165 + j * 88)


func _gui_input(event: InputEvent) -> void:
	if _done:
		return
	if event is InputEventMouseMotion:
		_mouse = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_mouse = event.position
		if event.pressed:
			for i in 4:
				if _link[i] < 0 and _mouse.distance_to(_left_pos(i)) < 34.0:
					_drag = i
		elif _drag >= 0:
			var hit := -1
			for j in 4:
				if _mouse.distance_to(_right_pos(j)) < 38.0:
					hit = j
			if hit >= 0 and _right[hit] == _drag and not _link.has(hit):
				_link[_drag] = hit
				if not _link.has(-1):
					succeed()
			elif hit >= 0:
				flash("WRONG SOCKET!", 8.0)
			_drag = -1


func _draw_task() -> void:
	for i in 4:
		var lp := _left_pos(i)
		var col: Color = WIRE_COLORS[i]
		if _link[i] >= 0:
			_wire(lp, _right_pos(_link[i]), col)
		elif _drag == i:
			_wire(lp, _mouse, col)
		draw_rect(Rect2(lp + Vector2(-46, -22), Vector2(40, 44)), INK)
		draw_circle(lp, 20.0, INK)
		draw_circle(lp, 15.0, col)
	for j in 4:
		var rp := _right_pos(j)
		var col2: Color = WIRE_COLORS[_right[j]]
		draw_rect(Rect2(rp + Vector2(6, -22), Vector2(40, 44)), INK)
		draw_circle(rp, 22.0, INK)
		draw_circle(rp, 15.0, col2)
		if _link.has(j):
			draw_circle(rp, 7.0, Color.WHITE)


func _wire(a: Vector2, b: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 25:
		var t := k / 24.0
		var p := a.lerp(b, t)
		p.y += sin(t * PI) * -18.0 * (1.0 if b.x > a.x else 0.0)
		pts.append(p)
	draw_polyline(pts, INK, 14.0, true)
	draw_polyline(pts, col, 8.0, true)
	draw_polyline(pts, Color(1, 1, 1, 0.5), 2.0, true)
