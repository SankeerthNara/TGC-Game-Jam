class_name RainTask
extends TaskBase
## Comic task: catch the falling ink drops in the bucket (Left / Right or the mouse). Dodge the red ones.

var NEED := 10

var _bucket := 0.0
var _drops: Array[Dictionary] = []
var _spawn := 0.4
var _caught := 0


func _begin() -> void:
	NEED = 10 + difficulty * 2
	title = "CATCH THE INK DROPS"
	hint = "LEFT / RIGHT or the mouse moves the bucket. Catch blue drops, dodge red ones!"
	_bucket = panel.get_center().x


func _update(delta: float) -> void:
	var dir := 0.0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		dir -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		dir += 1.0
	_bucket = clampf(_bucket + dir * 520.0 * delta, panel.position.x + 70.0, panel.end.x - 70.0)
	_spawn -= delta
	if _spawn <= 0.0:
		_spawn = maxf(0.28, 0.55 - 0.05 * difficulty)
		_drops.append({"x": randf_range(panel.position.x + 60, panel.end.x - 60), "y": panel.position.y + 80.0, "bad": randf() < 0.25, "v": randf_range(260.0, 340.0) + difficulty * 25.0})
	for d in _drops:
		d["y"] += d["v"] * delta
	var floor_y := panel.end.y - 70.0
	for d in _drops.duplicate():
		if d["y"] > floor_y - 20.0 and absf(d["x"] - _bucket) < 60.0 and d["y"] < floor_y + 20.0:
			_drops.erase(d)
			if d["bad"]:
				_caught = maxi(0, _caught - 2)
				flash("OUCH! RED INK", 6.0)
			else:
				_caught += 1
				if _caught >= NEED:
					succeed()
		elif d["y"] > panel.end.y:
			_drops.erase(d)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not _done:
		_bucket = clampf(event.position.x, panel.position.x + 70.0, panel.end.x - 70.0)


func _draw_task() -> void:
	_text("CAUGHT %d / %d" % [_caught, NEED], panel.position + Vector2(30, 112), 26, INK, FONT_SHOUT)
	for d in _drops:
		var p := Vector2(d["x"], d["y"])
		var col := RED if d["bad"] else Color("3a86ff")
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -22), p + Vector2(14, 4), p + Vector2(-14, 4)]), INK)
		draw_circle(p + Vector2(0, 6), 15.0, INK)
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -17), p + Vector2(10, 4), p + Vector2(-10, 4)]), col)
		draw_circle(p + Vector2(0, 6), 11.0, col)
	var b := Vector2(_bucket, panel.end.y - 70.0)
	draw_colored_polygon(PackedVector2Array([b + Vector2(-56, -20), b + Vector2(56, -20), b + Vector2(40, 34), b + Vector2(-40, 34)]), INK)
	draw_colored_polygon(PackedVector2Array([b + Vector2(-50, -14), b + Vector2(50, -14), b + Vector2(36, 28), b + Vector2(-36, 28)]), Color("c9ada7"))
	draw_rect(Rect2(b + Vector2(-56, -26), Vector2(112, 10)), INK)
