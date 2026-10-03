class_name SafeTask
extends TaskBase
## College task (logic): crack the 3 digit code. Each try tells you how many digits are right and
## how many are in the right place.

const DIGITS := 3
const SHOWN := 8

var _code: Array[int] = []
var _guess: Array[int] = [0, 0, 0]
var _history: Array[Dictionary] = []


func _begin() -> void:
	title = "CRACK THE SAFE"
	hint = "3 different digits. Click arrows or use Up/Down + Left/Right, then TRY or Enter."
	var pool := range(10)
	pool.shuffle()
	for i in DIGITS:
		_code.append(int(pool[i]))
	_sel = 0


var _sel := 0


func _up(i: int) -> Rect2:
	return Rect2(Vector2(panel.position.x + 70 + i * 110, panel.position.y + 130), Vector2(80, 40))


func _down(i: int) -> Rect2:
	return Rect2(Vector2(panel.position.x + 70 + i * 110, panel.position.y + 270), Vector2(80, 40))


func _try_btn() -> Rect2:
	return Rect2(Vector2(panel.position.x + 70, panel.position.y + 380), Vector2(300, 64))


func _gui_input(event: InputEvent) -> void:
	if _done:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in DIGITS:
			if _up(i).has_point(event.position):
				_guess[i] = (_guess[i] + 1) % 10
			elif _down(i).has_point(event.position):
				_guess[i] = (_guess[i] + 9) % 10
		if _try_btn().has_point(event.position):
			_submit()


func _unhandled_input(event: InputEvent) -> void:
	if _done or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_LEFT:
			_sel = (_sel + DIGITS - 1) % DIGITS
		KEY_RIGHT:
			_sel = (_sel + 1) % DIGITS
		KEY_UP:
			_guess[_sel] = (_guess[_sel] + 1) % 10
		KEY_DOWN:
			_guess[_sel] = (_guess[_sel] + 9) % 10
		KEY_ENTER, KEY_KP_ENTER:
			_submit()


func _submit() -> void:
	var exact := 0
	var misplaced := 0
	var left_code: Array[int] = []
	var left_guess: Array[int] = []
	for i in DIGITS:
		if _guess[i] == _code[i]:
			exact += 1
		else:
			left_code.append(_code[i])
			left_guess.append(_guess[i])
	for g in left_guess:
		if left_code.has(g):
			misplaced += 1
			left_code.erase(g)
	_history.append({"g": _guess.duplicate(), "exact": exact, "misplaced": misplaced})
	if exact == DIGITS:
		succeed()
	elif exact == 0 and misplaced == 0:
		flash("NONE OF THOSE DIGITS", 3.0)


func _draw_task() -> void:
	_text("TRIES: %d" % _history.size(), panel.position + Vector2(70, 100), 26, INK, FONT_SHOUT)
	var plate := Rect2(panel.position + Vector2(50, 118), Vector2(340, 235))
	draw_rect(plate, Color("8d99ae"))
	draw_rect(plate, INK, false, 5.0)
	for i in DIGITS:
		var u := _up(i)
		var d := _down(i)
		draw_colored_polygon(PackedVector2Array([u.position + Vector2(40, 6), u.position + Vector2(74, 36), u.position + Vector2(6, 36)]), INK)
		draw_colored_polygon(PackedVector2Array([d.position + Vector2(40, 34), d.position + Vector2(74, 4), d.position + Vector2(6, 4)]), INK)
		var box := Rect2(Vector2(u.position.x, u.end.y + 6), Vector2(80, 84))
		draw_rect(box, Color("fff9e6"))
		draw_rect(box, GOLD if i == _sel else INK, false, 5.0)
		_text(str(_guess[i]), box.position + Vector2(0, 66), 64, INK, FONT_SHOUT, HORIZONTAL_ALIGNMENT_CENTER, box.size.x)
	var b := _try_btn()
	draw_rect(b, GOLD)
	draw_rect(b, INK, false, 4.0)
	_text("TRY", b.position + Vector2(0, 48), 40, INK, FONT_SHOUT, HORIZONTAL_ALIGNMENT_CENTER, b.size.x)
	# history: newest first, a coloured dot per digit (green = right place, gold = wrong place)
	var hx := panel.position.x + 440.0
	_text("HISTORY", Vector2(hx, panel.position.y + 100), 26, INK, FONT_SHOUT)
	draw_circle(Vector2(hx + 6, panel.position.y + 128), 7, GREEN)
	_text("right place", Vector2(hx + 20, panel.position.y + 134), 17, Color("5c5470"), FONT_BODY)
	draw_circle(Vector2(hx + 130, panel.position.y + 128), 7, GOLD)
	draw_circle(Vector2(hx + 130, panel.position.y + 128), 7, INK, false, 2.0)
	_text("wrong place", Vector2(hx + 144, panel.position.y + 134), 17, Color("5c5470"), FONT_BODY)
	for k in mini(_history.size(), SHOWN):
		var h: Dictionary = _history[_history.size() - 1 - k]
		var g: Array = h["g"]
		var y := panel.position.y + 170.0 + k * 38.0
		_text("%d %d %d" % [g[0], g[1], g[2]], Vector2(hx, y + 26), 30, INK, FONT_SHOUT)
		var n := 0
		for j in int(h["exact"]):
			draw_circle(Vector2(hx + 130 + n * 26, y + 14), 10, GREEN)
			n += 1
		for j in int(h["misplaced"]):
			draw_circle(Vector2(hx + 130 + n * 26, y + 14), 10, GOLD)
			draw_circle(Vector2(hx + 130 + n * 26, y + 14), 10, INK, false, 2.0)
			n += 1
		if n == 0:
			_text("none", Vector2(hx + 130, y + 22), 18, Color("5c5470"), FONT_BODY)
