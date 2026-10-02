class_name DialTask
extends TaskBase
## Telescope alignment: steer the beam with Left/Right (or the mouse) and keep it on the drifting star.

var NEED := 3.0

var _angle := -40.0
var _lock := 0.0


func _begin() -> void:
	title = "ALIGN THE TELESCOPE"
	hint = "LEFT / RIGHT (or move the mouse) to aim. Keep the beam on the star!"
	NEED = 2.5 + 0.5 * difficulty
	_angle = [-50.0, 45.0][randi() % 2]


func _star_angle() -> float:
	var sp := 1.0 + 0.25 * difficulty
	return sin(_t * 0.8 * sp) * 45.0 + sin(_t * 1.9 * sp + 1.0) * 14.0


func _update(delta: float) -> void:
	var dir := 0.0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		dir -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		dir += 1.0
	_angle = clampf(_angle + dir * 70.0 * delta, -75.0, 75.0)
	if absf(_angle - _star_angle()) < (5.5 - 0.5 * difficulty):
		_lock += delta
		if _lock >= NEED:
			succeed()
	else:
		_lock = maxf(0.0, _lock - delta * 0.9)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not _done:
		var base := Vector2(panel.get_center().x, panel.end.y - 60)
		var v: Vector2 = event.position - base
		_angle = clampf(rad_to_deg(atan2(v.x, -v.y)), -75.0, 75.0)


func _draw_task() -> void:
	var base := Vector2(panel.get_center().x, panel.end.y - 60)
	var length := 330.0
	# sky
	draw_rect(Rect2(panel.position + Vector2(10, 70), Vector2(panel.size.x - 20, panel.size.y - 160)), Color("14123a"))
	for k in 30:
		var p := panel.position + Vector2(30 + fmod(k * 197.0, panel.size.x - 60), 90 + fmod(k * 83.0, panel.size.y - 200))
		draw_circle(p, 1.5 + (k % 3), Color(1, 1, 1, 0.5 + 0.4 * sin(_t * 2.0 + k)))
	var sa := deg_to_rad(_star_angle())
	var star := base + Vector2(sin(sa), -cos(sa)) * length
	var aligned := absf(_angle - _star_angle()) < (5.5 - 0.5 * difficulty)
	_glow(star, 70.0 if aligned else 45.0, Color(1, 0.9, 0.5, 0.9 if aligned else 0.5))
	var pts := PackedVector2Array()
	for k in 10:
		var r := 22.0 if k % 2 == 0 else 9.0
		var a := -PI / 2.0 + k * PI / 5.0
		pts.append(star + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, GOLD if aligned else Color("c9b458"))
	var a2 := deg_to_rad(_angle)
	var tip := base + Vector2(sin(a2), -cos(a2)) * length
	draw_line(base, tip, Color(1, 0.95, 0.6, 0.25), 30.0)
	draw_line(base, tip, Color(1, 0.9, 0.4, 0.8 if aligned else 0.55), 10.0)
	draw_line(base, tip, Color.WHITE, 3.0)
	# telescope body
	draw_set_transform(base, a2)
	draw_rect(Rect2(-24, -70, 48, 90), INK)
	draw_rect(Rect2(-18, -66, 36, 82), Color("8d99ae"))
	draw_rect(Rect2(-28, -84, 56, 22), INK)
	draw_set_transform(Vector2.ZERO)
	draw_circle(base, 36.0, INK)
	draw_circle(base, 28.0, Color("c1121f"))
	var bar := Rect2(Vector2(panel.position.x + 40, panel.position.y + 85), Vector2(220, 26))
	draw_rect(bar, INK)
	draw_rect(Rect2(bar.position + Vector2(3, 3), Vector2((bar.size.x - 6) * clampf(_lock / NEED, 0, 1), bar.size.y - 6)), Color("2dc653"))
