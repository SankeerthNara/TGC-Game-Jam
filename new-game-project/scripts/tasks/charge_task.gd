class_name ChargeTask
extends TaskBase
## Hold Space (or the mouse button) to charge. Keep the level inside the moving green zone.

var NEED := 3.5
var LIMIT := 24.0

var _level := 0.0
var _good := 0.0
var _left := LIMIT
var _holding := false


func _begin() -> void:
	NEED = 3.0 + 0.7 * difficulty
	LIMIT = 24.0 - 2.0 * difficulty
	_left = LIMIT
	title = "CHARGE THE TORCH"
	hint = "Hold SPACE or the mouse button to charge. Keep the level inside the green zone!"


func _zone() -> Vector2:
	var sp := 1.0 + 0.2 * difficulty
	var center := 0.5 + sin(_t * 0.9 * sp) * 0.28 + sin(_t * 2.3 * sp) * 0.06
	var half := 0.11 - 0.015 * difficulty
	return Vector2(center - half, center + half)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_holding = event.pressed


func _update(delta: float) -> void:
	var down := _holding or Input.is_key_pressed(KEY_SPACE)
	_level = clampf(_level + (0.7 if down else -0.42) * delta, 0.0, 1.0)
	var z := _zone()
	if _level >= z.x and _level <= z.y:
		_good += delta
	_left -= delta
	if _good >= NEED:
		succeed()
	elif _left <= 0.0:
		_left = LIMIT
		_good = 0.0
		flash("OUT OF TIME! AGAIN", 8.0)


func _draw_task() -> void:
	var gauge := Rect2(Vector2(panel.position.x + 110, panel.position.y + 110), Vector2(90, 340))
	draw_rect(gauge, INK)
	draw_rect(gauge.grow(-8), Color("2b2d42"))
	var inner := gauge.grow(-8)
	var z := _zone()
	draw_rect(Rect2(inner.position.x, inner.end.y - z.y * inner.size.y, inner.size.x, (z.y - z.x) * inner.size.y), Color(0.2, 0.8, 0.4, 0.6))
	draw_rect(Rect2(inner.position.x, inner.end.y - _level * inner.size.y, inner.size.x, _level * inner.size.y), GOLD)
	var my := inner.end.y - _level * inner.size.y
	draw_rect(Rect2(gauge.position.x - 14, my - 5, gauge.size.x + 28, 10), RED)
	# the torch that brightens with the charge
	var base := Vector2(panel.get_center().x + 40, panel.position.y + 420)
	draw_line(base, base + Vector2(0, -170), INK, 38.0)
	draw_line(base, base + Vector2(0, -170), Color("a0522d"), 26.0)
	var ok := _level >= z.x and _level <= z.y
	var fl := 1.0 + sin(_t * 15.0) * 0.06
	var h := (60.0 + 140.0 * _level) * fl
	var top := base + Vector2(0, -170)
	_glow(top + Vector2(0, -h * 0.4), 60.0 + 150.0 * _level, Color(1, 0.75, 0.3, 0.5 + 0.4 * _level))
	draw_colored_polygon(PackedVector2Array([top + Vector2(-44, 0), top + Vector2(0, -h), top + Vector2(44, 0)]), INK)
	draw_colored_polygon(PackedVector2Array([top + Vector2(-36, -4), top + Vector2(0, -h + 14), top + Vector2(36, -4)]), Color("ff8c1a"))
	draw_colored_polygon(PackedVector2Array([top + Vector2(-18, -6), top + Vector2(0, -h * 0.6), top + Vector2(18, -6)]), Color("ffe066"))
	# progress + timer
	var bar := Rect2(Vector2(panel.end.x - 250, panel.position.y + 130), Vector2(190, 30))
	draw_rect(bar, INK)
	draw_rect(Rect2(bar.position + Vector2(4, 4), Vector2((bar.size.x - 8) * clampf(_good / NEED, 0, 1), bar.size.y - 8)), Color("2dc653"))
	_text("HOLD IN THE ZONE", Vector2(bar.position.x - 6, bar.position.y - 10), 22, INK, FONT_SHOUT)
	_text("TIME %d" % int(ceil(_left)), Vector2(bar.position.x, bar.end.y + 40), 28, RED if _left < 6 else INK, FONT_SHOUT)
	_text("IN THE ZONE!" if ok else "...", Vector2(bar.position.x, bar.end.y + 80), 26, GREEN if ok else Color("8d99ae"), FONT_SHOUT)
