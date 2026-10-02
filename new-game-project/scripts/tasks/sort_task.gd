class_name SortTask
extends TaskBase
## College task (library): shelve the books in ascending call-number order. Click two books to swap them.

var COUNT := 5

var _nums: Array[int] = []
var _sel := -1
var _swaps := 0


func _begin() -> void:
	COUNT = 5 + difficulty
	title = "SHELVE THE BOOKS"
	hint = "Click two books to swap them. Smallest call number on the left!"
	var pool := range(1, 99)
	pool.shuffle()
	for i in COUNT:
		_nums.append(int(pool[i]) * 7 % 900 + 10)
	while _is_sorted():
		_nums.shuffle()


func _is_sorted() -> bool:
	for i in range(1, _nums.size()):
		if _nums[i - 1] > _nums[i]:
			return false
	return true


func _book(i: int) -> Rect2:
	var w := 78.0
	var gap := 12.0
	var total := COUNT * w + (COUNT - 1) * gap
	var h := 150.0 + (_nums[i] % 5) * 12.0
	return Rect2(Vector2(panel.get_center().x - total * 0.5 + i * (w + gap), panel.position.y + 340 - h), Vector2(w, h))


func _gui_input(event: InputEvent) -> void:
	if _done:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in COUNT:
			if _book(i).grow(4).has_point(event.position):
				if _sel < 0:
					_sel = i
				elif _sel == i:
					_sel = -1
				else:
					var tmp := _nums[_sel]
					_nums[_sel] = _nums[i]
					_nums[i] = tmp
					_swaps += 1
					_sel = -1
					if _is_sorted():
						succeed()


func _draw_task() -> void:
	_text("SWAPS: %d" % _swaps, panel.position + Vector2(30, 112), 26, INK, FONT_SHOUT)
	var shelf_y := panel.position.y + 344
	draw_rect(Rect2(Vector2(panel.position.x + 40, shelf_y), Vector2(panel.size.x - 80, 18)), Color("8d5524"))
	draw_rect(Rect2(Vector2(panel.position.x + 40, shelf_y), Vector2(panel.size.x - 80, 18)), INK, false, 4.0)
	var cols := [Color("e63946"), Color("3a86ff"), Color("ffd23f"), Color("2dc653"), Color("9b5de5"), Color("ff7bd5"), Color("fb8500")]
	for i in COUNT:
		var r := _book(i)
		draw_rect(Rect2(r.position + Vector2(4, 4), r.size), Color(0, 0, 0, 0.25))
		draw_rect(r, cols[_nums[i] % cols.size()])
		draw_rect(r, INK, false, 5.0 if _sel == i else 3.5)
		if _sel == i:
			draw_rect(r.grow(6), GOLD, false, 4.0)
		draw_rect(Rect2(r.position + Vector2(0, 18), Vector2(r.size.x, 8)), INK)
		draw_rect(Rect2(r.position + Vector2(0, r.size.y - 28), Vector2(r.size.x, 8)), INK)
		_text("%03d" % _nums[i], r.position + Vector2(0, r.size.y * 0.5 + 10), 30, INK, FONT_SHOUT, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	_centered("CALL NUMBER  ->  small to big", panel.end.y - 80, 24, Color("8d99ae"), FONT_SHOUT)
