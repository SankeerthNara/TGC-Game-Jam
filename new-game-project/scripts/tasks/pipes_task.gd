class_name PipesTask
extends TaskBase
## Light/ink task: rotate the pipe pieces so the ink flows from the left tap to the right drain.

var _n := 4
var _type: Array[String] = [] ## "S" straight or "C" corner
var _rot: Array[int] = []
var _flow: Array[int] = [] ## cells the ink currently reaches


func _begin() -> void:
	title = "CONNECT THE INK PIPES"
	hint = "Click a pipe to rotate it. Connect the left tap to the right drain."
	_n = 3 + difficulty
	for i in _n * _n:
		_type.append("S" if randf() < 0.5 else "C")
		_rot.append(randi() % 4)
	# a random monotone route from the top-left cell to the bottom-right cell
	var x := 0
	var y := 0
	var in_side := 3 # entering from the west
	while true:
		var go_right := false
		if x == _n - 1 and y == _n - 1:
			var out_side := 1
			_set_piece(x, y, in_side, out_side)
			break
		elif x == _n - 1:
			go_right = false
		elif y == _n - 1:
			go_right = true
		else:
			go_right = randf() < 0.5
		var out_dir := 1 if go_right else 2
		_set_piece(x, y, in_side, out_dir)
		if go_right:
			x += 1
			in_side = 3
		else:
			y += 1
			in_side = 0
	for i in _n * _n:
		_rot[i] = (_rot[i] + 1 + randi() % 3) % 4 if _is_route(i) else randi() % 4
	_recompute()
	if _flow.has(_n * _n - 1) and _reaches_end():
		_rot[0] = (_rot[0] + 1) % 4
		_recompute()


var _route: Array[int] = []


func _is_route(i: int) -> bool:
	return _route.has(i)


func _set_piece(x: int, y: int, a: int, b: int) -> void:
	var i := y * _n + x
	_route.append(i)
	if (a + 2) % 4 == b:
		_type[i] = "S"
		_rot[i] = 0 if a % 2 == 1 else 1
	else:
		_type[i] = "C"
		for r in 4:
			var s1 := r
			var s2 := (r + 1) % 4
			if (s1 == a and s2 == b) or (s1 == b and s2 == a):
				_rot[i] = r


func _open(i: int) -> Array[int]:
	var out: Array[int] = []
	var r := _rot[i]
	if _type[i] == "S":
		if r % 2 == 0:
			out = [1, 3]
		else:
			out = [0, 2]
	else:
		out = [r, (r + 1) % 4]
	return out


func _recompute() -> void:
	_flow.clear()
	var x := 0
	var y := 0
	var enter := 3
	for step in _n * _n + 2:
		if x < 0 or y < 0 or x >= _n or y >= _n:
			return
		var i := y * _n + x
		var o := _open(i)
		if not o.has(enter):
			return
		_flow.append(i)
		var ex: int = o[1] if o[0] == enter else o[0]
		match ex:
			0:
				y -= 1
			1:
				x += 1
			2:
				y += 1
			3:
				x -= 1
		enter = (ex + 2) % 4


func _reaches_end() -> bool:
	if not _flow.has(_n * _n - 1):
		return false
	var o := _open(_n * _n - 1)
	return o.has(1)


func _cell(i: int) -> Rect2:
	var available_h := 360.0
	var s := minf(84.0, available_h / _n)
	var total := _n * s
	var o := Vector2(panel.get_center().x - total * 0.5, panel.position.y + 100 + (available_h - total) * 0.5)
	return Rect2(o + Vector2((i % _n) * s, (i / _n) * s), Vector2(s, s))


func _gui_input(event: InputEvent) -> void:
	if _done:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in _n * _n:
			if _cell(i).has_point(event.position):
				var old_flow := _flow.size()
				_rot[i] = (_rot[i] + 1) % 4
				_recompute()
				if _reaches_end():
					succeed()
				elif _flow.size() < old_flow:
					flash("THE INK FLOW STOPPED EARLY!", 4.0)
				return


func _draw_task() -> void:
	for i in _n * _n:
		var r := _cell(i)
		draw_rect(r, Color("fffdf2"))
		draw_rect(r, Color(0, 0, 0, 0.35), false, 1.5)
		var c := r.get_center()
		var wet := _flow.has(i)
		var col := Color("ffd23f") if wet else Color("3a86ff")
		for side: int in _open(i):
			var d := [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)][side] as Vector2
			draw_line(c, c + d * r.size.x * 0.5, INK, 22.0)
		for side: int in _open(i):
			var d2 := [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)][side] as Vector2
			draw_line(c, c + d2 * r.size.x * 0.5, col, 13.0)
		draw_circle(c, 13.0, INK)
		draw_circle(c, 9.0, col)
	var first := _cell(0)
	var last := _cell(_n * _n - 1)
	draw_rect(Rect2(first.position + Vector2(-34, first.size.y * 0.5 - 14), Vector2(34, 28)), INK)
	_text("TAP", first.position + Vector2(-54, first.size.y * 0.5 - 24), 22, INK, FONT_SHOUT)
	draw_rect(Rect2(last.position + Vector2(last.size.x, last.size.y * 0.5 - 14), Vector2(34, 28)), INK)
	_text("DRAIN", last.position + Vector2(last.size.x + 4, last.size.y * 0.5 - 24), 22, INK, FONT_SHOUT)
