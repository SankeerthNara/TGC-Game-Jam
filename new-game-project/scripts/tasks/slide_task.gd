class_name SlideTask
extends TaskBase
## Comic task: slide the panels back into order (1 to 8, blank last).

const N := 3

var _tiles: Array[int] = [] ## 0 is the blank
var _moves := 0


func _begin() -> void:
	title = "SLIDE THE COMIC PANELS"
	hint = "Click a panel next to the gap to slide it. Put 1 to 8 in order."
	for i in N * N:
		_tiles.append((i + 1) % (N * N))
	var blank := N * N - 1
	var last := -1
	for k in 16 + difficulty * 8:
		var opts: Array[int] = []
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nx: int = blank % N + d.x
			var ny: int = blank / N + d.y
			var ni := ny * N + nx
			if nx >= 0 and ny >= 0 and nx < N and ny < N and ni != last:
				opts.append(ni)
		var pick: int = opts[randi() % opts.size()]
		_tiles[blank] = _tiles[pick]
		_tiles[pick] = 0
		last = blank
		blank = pick
	if _solved():
		_tiles[N * N - 1] = _tiles[N * N - 2]
		_tiles[N * N - 2] = 0


func _solved() -> bool:
	for i in N * N - 1:
		if _tiles[i] != i + 1:
			return false
	return true


func _cell(i: int) -> Rect2:
	var s := 118.0
	var total := N * s + (N - 1) * 10.0
	var o := Vector2(panel.get_center().x - total * 0.5, panel.position.y + 100 + (400.0 - total) * 0.5)
	return Rect2(o + Vector2((i % N) * (s + 10.0), (i / N) * (s + 10.0)), Vector2(s, s))


func _gui_input(event: InputEvent) -> void:
	if _done:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var blank := _tiles.find(0)
		for i in N * N:
			if _cell(i).has_point(event.position) and _tiles[i] != 0:
				var d := Vector2i(i % N - blank % N, i / N - blank / N)
				if absi(d.x) + absi(d.y) == 1:
					_tiles[blank] = _tiles[i]
					_tiles[i] = 0
					_moves += 1
					if _solved():
						succeed()
				else:
					flash("THAT PANEL CAN'T REACH THE GAP!", 4.0)
				return


func _draw_task() -> void:
	_text("MOVES %d" % _moves, panel.position + Vector2(30, 112), 26, INK, FONT_SHOUT)
	var cols := [Color("e63946"), Color("ffd23f"), Color("3a86ff"), Color("2dc653"), Color("ff7bd5"), Color("fb8500"), Color("9b5de5"), Color("4cc9f0")]
	for i in N * N:
		var r := _cell(i)
		if _tiles[i] == 0:
			draw_rect(r, Color(0, 0, 0, 0.1))
			continue
		draw_rect(Rect2(r.position + Vector2(4, 5), r.size), Color(0, 0, 0, 0.3))
		draw_rect(r, cols[(_tiles[i] - 1) % cols.size()])
		draw_rect(r, INK, false, 4.0)
		draw_rect(Rect2(r.position + Vector2(8, 8), r.size - Vector2(16, 16)), Color(1, 1, 1, 0.25), false, 3.0)
		_text(str(_tiles[i]), r.position + Vector2(0, r.size.y * 0.66), 64, INK, FONT_SHOUT, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
