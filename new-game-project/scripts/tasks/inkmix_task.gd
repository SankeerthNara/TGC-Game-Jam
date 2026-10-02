class_name InkMixTask
extends TaskBase
## Comic task: mix red, yellow and blue ink drops until your swatch matches the target colour.

const INKS := [Color("e63946"), Color("ffd23f"), Color("3a86ff")]
const NAMES := ["RED", "YELLOW", "BLUE"]

var _target_counts: Array[int] = [0, 0, 0]
var _counts: Array[int] = [0, 0, 0]
var _tol := 0.1


func _begin() -> void:
	title = "MIX THE INK"
	hint = "Add drops of red, yellow and blue until your colour matches the target."
	_tol = 0.1 - 0.012 * difficulty
	var total := 3 + difficulty
	while total > 0:
		_target_counts[randi() % 3] += 1
		total -= 1
	if _target_counts == [0, 0, 0]:
		_target_counts[0] = 2


func _mix(c: Array[int]) -> Color:
	var n := c[0] + c[1] + c[2]
	if n == 0:
		return Color("fff9e6")
	var r := 0.0
	var g := 0.0
	var b := 0.0
	for i in 3:
		r += INKS[i].r * c[i]
		g += INKS[i].g * c[i]
		b += INKS[i].b * c[i]
	return Color(r / n, g / n, b / n)


func _dist(a: Color, b: Color) -> float:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)


func _btn(i: int) -> Rect2:
	return Rect2(Vector2(panel.position.x + 70 + i * 220, panel.position.y + 360), Vector2(190, 70))


func _reset_btn() -> Rect2:
	return Rect2(Vector2(panel.end.x - 170, panel.position.y + 100), Vector2(120, 44))


func _gui_input(event: InputEvent) -> void:
	if _done:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in 3:
			if _btn(i).has_point(event.position):
				_counts[i] += 1
				if _dist(_mix(_counts), _mix(_target_counts)) < _tol * 3.0 and _counts[0] + _counts[1] + _counts[2] >= 2:
					succeed()
				elif _counts[0] + _counts[1] + _counts[2] >= 14:
					_counts = [0, 0, 0]
					flash("TOO MUCH INK! AGAIN", 6.0)
				return
		if _reset_btn().has_point(event.position):
			_counts = [0, 0, 0]


func _draw_task() -> void:
	var target := _mix(_target_counts)
	var mine := _mix(_counts)
	_text("TARGET", Vector2(panel.position.x + 120, panel.position.y + 130), 26, INK, FONT_SHOUT)
	draw_circle(Vector2(panel.position.x + 170, panel.position.y + 230), 70.0, INK)
	draw_circle(Vector2(panel.position.x + 170, panel.position.y + 230), 62.0, target)
	_text("YOURS", Vector2(panel.end.x - 270, panel.position.y + 130), 26, INK, FONT_SHOUT)
	draw_circle(Vector2(panel.end.x - 210, panel.position.y + 230), 70.0, INK)
	draw_circle(Vector2(panel.end.x - 210, panel.position.y + 230), 62.0, mine)
	var close := clampf(1.0 - _dist(mine, target) / 0.9, 0.0, 1.0)
	_centered("%d%% MATCH" % int(close * 100), panel.position.y + 250, 44, GREEN if close > 0.88 else INK, FONT_SHOUT)
	for i in 3:
		var r := _btn(i)
		draw_rect(Rect2(r.position + Vector2(4, 5), r.size), Color(0, 0, 0, 0.3))
		draw_rect(r, INKS[i])
		draw_rect(r, INK, false, 4.0)
		_text("%s  x%d" % [NAMES[i], _counts[i]], r.position + Vector2(0, 46), 30, INK if i != 2 else Color.WHITE, FONT_SHOUT, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	var rr := _reset_btn()
	draw_rect(rr, Color("fff9e6"))
	draw_rect(rr, INK, false, 3.0)
	_text("CLEAR", rr.position + Vector2(0, 32), 26, INK, FONT_SHOUT, HORIZONTAL_ALIGNMENT_CENTER, rr.size.x)
