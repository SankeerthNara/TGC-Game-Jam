class_name SafeTask
extends TaskBase
## College task (logic): crack the 3 digit code. Each try tells you how many digits are right and
## how many are in the right place.

const DIGITS := 3
var MAX_TRIES := 8

var _code: Array[int] = []
var _guess: Array[int] = [0, 0, 0]
var _history: Array[Dictionary] = []


func _begin() -> void:
	MAX_TRIES = 8 - difficulty / 2
	title = "CRACK THE SAFE"
	hint = "Set the digits (click arrows, or Up/Down and Left/Right) and press TRY or Enter."
	var pool := range(10)
	pool.shuffle()
	for i in DIGITS:
		_code.append(int(pool[i]))
	_sel = 0


var _sel := 0


func _up(i: int) -> Rect2:
	return Rect2(Vector2(panel.position.x + 90 + i * 110, panel.position.y + 120), Vector2(80, 40))


func _down(i: int) -> Rect2:
	return Rect2(Vector2(panel.position.x + 90 + i * 110, panel.position.y + 250), Vector2(80, 40))


func _try_btn() -> Rect2:
	return Rect2(Vector2(panel.position.x + 90, panel.position.y + 310), Vector2(300, 60))


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
	for i in DIGITS:
		if _guess[i] == _code[i]:
			exact += 1
		elif _code.has(_guess[i]):
			misplaced += 1
	_history.append({"g": _guess.duplicate(), "exact": exact, "misplaced": misplaced})
	if exact == DIGITS:
		succeed()
	elif _history.size() >= MAX_TRIES:
		_history.clear()
		var pool := range(10)
		pool.shuffle()
		for i in DIGITS:
			_code[i] = int(pool[i])
		flash("OUT OF TRIES! NEW CODE", 8.0)


func _draw_task() -> void:
	_text("TRIES %d / %d" % [_history.size(), MAX_TRIES], panel.position + Vector2(30, 112), 26, INK, FONT_SHOUT)
	draw_rect(Rect2(panel.position + Vector2(70, 115), Vector2(340, 190)), Color("8d99ae"))
	draw_rect(Rect2(panel.position + Vector2(70, 115), Vector2(340, 190)), INK, false, 5.0)
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
	_text("TRY", b.position + Vector2(0, 44), 40, INK, FONT_SHOUT, HORIZONTAL_ALIGNMENT_CENTER, b.size.x)
	_text("HISTORY", Vector2(panel.end.x - 300, panel.position.y + 132), 26, INK, FONT_SHOUT)
	for k in _history.size():
		var h: Dictionary = _history[_history.size() - 1 - k]
		if k > 6:
			break
		var g: Array = h["g"]
		_text("%d %d %d" % [g[0], g[1], g[2]], Vector2(panel.end.x - 300, panel.position.y + 170 + k * 36), 28, INK, FONT_SHOUT)
		_text("%d right place, %d wrong place" % [h["exact"], h["misplaced"]], Vector2(panel.end.x - 210, panel.position.y + 168 + k * 36), 17, Color("5c5470"), FONT_BODY)
