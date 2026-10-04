class_name WhackTask
extends TaskBase
## Light task: lanterns flare up for a moment. Click them out before they burn the wall.

var NEED := 8
var MAX_MISS := 4

var _lit := -1
var _lit_t := 0.0
var _gap := 0.5
var _hit := 0
var _miss := 0


func _begin() -> void:
	NEED = 8 + difficulty * 2
	MAX_MISS = maxi(2, 4 - difficulty / 2)
	title = "WHACK THE LANTERNS"
	hint = "Click each lantern that flares up before it burns out!"


func _pos(i: int) -> Vector2:
	var c := panel.get_center() + Vector2(0, 30)
	return c + Vector2((i % 3 - 1) * 190.0, (i / 3 - 1) * 120.0)


func _update(delta: float) -> void:
	if _lit >= 0:
		_lit_t -= delta
		if _lit_t <= 0.0:
			_lit = -1
			_miss += 1
			flash("TOO SLOW!", 6.0)
			if _miss >= MAX_MISS:
				_miss = 0
				_hit = 0
				flash("IT BURNED OUT! AGAIN", 10.0)
			_gap = 0.35
	else:
		_gap -= delta
		if _gap <= 0.0:
			_lit = randi() % 9
			_lit_t = maxf(0.55, 1.1 - 0.12 * difficulty)


func _gui_input(event: InputEvent) -> void:
	if _done:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _lit >= 0 and event.position.distance_to(_pos(_lit)) < 52.0:
			_lit = -1
			_hit += 1
			_gap = 0.25
			if _hit >= NEED:
				succeed()
		elif _lit >= 0 or event.position.y > panel.position.y + 150:
			flash("WAIT FOR A LANTERN TO LIGHT!", 3.0)


func _draw_task() -> void:
	_text("OUT %d/%d" % [_hit, NEED], panel.position + Vector2(30, 112), 26, INK, FONT_SHOUT)
	_text("MISSED %d/%d" % [_miss, MAX_MISS], Vector2(panel.end.x - 210, panel.position.y + 112), 26, RED if _miss >= 2 else INK, FONT_SHOUT)
	for i in 9:
		var p := _pos(i)
		var on := i == _lit
		if on:
			_glow(p, 110.0, Color(1, 0.8, 0.3, 0.9))
		draw_rect(Rect2(p + Vector2(-7, -64), Vector2(14, 22)), INK)
		draw_circle(p, 46.0, INK)
		draw_circle(p, 38.0, Color("ffd23f") if on else Color("5a5470"))
		draw_circle(p + Vector2(-12, -12), 8.0, Color(1, 1, 1, 0.5 if on else 0.15))
