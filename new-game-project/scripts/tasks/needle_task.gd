class_name NeedleTask
extends TaskBase
## College task (physics lab): stop the swinging needle inside the green zone. Three clean hits.

var NEED := 3

var _pos := 0.0 ## 0..1 along the gauge
var _dir := 1.0
var _speed := 0.9
var _zone_c := 0.5
var _zone_w := 0.18
var _hits := 0


func _begin() -> void:
	NEED = 3 + difficulty / 2
	_speed = 0.9 + 0.25 * difficulty
	_zone_w = 0.2 - 0.025 * difficulty
	title = "CALIBRATE THE GAUGE"
	hint = "Press SPACE (or click) to stop the needle in the green zone."
	_new_zone()


func _new_zone() -> void:
	_zone_c = randf_range(0.2, 0.8)


func _update(delta: float) -> void:
	_pos += _dir * _speed * delta
	if _pos > 1.0:
		_pos = 1.0
		_dir = -1.0
	elif _pos < 0.0:
		_pos = 0.0
		_dir = 1.0


func _stop() -> void:
	if _done:
		return
	if absf(_pos - _zone_c) <= _zone_w * 0.5:
		_hits += 1
		if _hits >= NEED:
			succeed()
		else:
			flash("PERFECT!")
			_new_zone()
	else:
		_hits = maxi(0, _hits - 1)
		flash("MISSED!", 8.0)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_stop()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		_stop()


func _draw_task() -> void:
	_text("HITS %d / %d" % [_hits, NEED], panel.position + Vector2(30, 112), 26, INK, FONT_SHOUT)
	var bar := Rect2(Vector2(panel.position.x + 70, panel.position.y + 240), Vector2(panel.size.x - 140, 90))
	draw_rect(Rect2(bar.position + Vector2(5, 6), bar.size), Color(0, 0, 0, 0.3))
	draw_rect(bar, Color("fff9e6"))
	draw_rect(bar, INK, false, 5.0)
	draw_rect(Rect2(bar.position.x + bar.size.x * (_zone_c - _zone_w * 0.5), bar.position.y + 4, bar.size.x * _zone_w, bar.size.y - 8), Color(0.2, 0.8, 0.4, 0.7))
	for k in 11:
		var x := bar.position.x + bar.size.x * k / 10.0
		draw_line(Vector2(x, bar.end.y - 4), Vector2(x, bar.end.y - (22 if k % 5 == 0 else 12)), INK, 2.0)
	var nx := bar.position.x + bar.size.x * _pos
	draw_line(Vector2(nx, bar.position.y - 24), Vector2(nx, bar.end.y), RED, 6.0)
	draw_colored_polygon(PackedVector2Array([Vector2(nx, bar.position.y - 6), Vector2(nx - 12, bar.position.y - 30), Vector2(nx + 12, bar.position.y - 30)]), RED)
