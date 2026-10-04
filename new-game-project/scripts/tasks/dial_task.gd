class_name DialTask
extends TaskBase
## Telescope alignment: aim the beam at a drifting star and lock several observations.

var _angle := -40.0
var _hits := 0
var _hits_needed := 2


func _begin() -> void:
	title = "ALIGN THE TELESCOPE"
	hint = "Aim with LEFT / RIGHT or the mouse. Click or press SPACE to lock the star."
	_hits_needed = 2 + difficulty
	_angle = [-50.0, 45.0][randi() % 2]


func _star_angle() -> float:
	var sp := 1.0 + 0.22 * difficulty
	var phase := _t * 0.8 * sp + _hits * 1.37
	return sin(phase) * 45.0 + sin(phase * 2.3 + 1.0) * 14.0


func _tolerance() -> float:
	return 8.0 - 1.0 * difficulty


func _attempt() -> void:
	if absf(_angle - _star_angle()) <= _tolerance():
		_hits += 1
		if _hits >= _hits_needed:
			succeed()
		else:
			flash("STAR LOCKED!", 2.0)
	else:
		flash("AIM AT THE STAR!", 5.0)


func _update(delta: float) -> void:
	var dir := 0.0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		dir -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		dir += 1.0
	_angle = clampf(_angle + dir * 70.0 * delta, -75.0, 75.0)


func _input(event: InputEvent) -> void:
	super(event)
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
		_attempt()
		get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if _done:
		return
	if event is InputEventMouseMotion:
		var base := Vector2(panel.get_center().x, panel.end.y - 60)
		var v: Vector2 = event.position - base
		_angle = clampf(rad_to_deg(atan2(v.x, -v.y)), -75.0, 75.0)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_attempt()


func _draw_task() -> void:
	var base := Vector2(panel.get_center().x, panel.end.y - 60)
	var length := 330.0
	draw_rect(Rect2(panel.position + Vector2(10, 70), Vector2(panel.size.x - 20, panel.size.y - 160)), Color("14123a"))
	for k in 30:
		var p := panel.position + Vector2(30 + fmod(k * 197.0, panel.size.x - 60), 90 + fmod(k * 83.0, panel.size.y - 200))
		draw_circle(p, 1.5 + (k % 3), Color(1, 1, 1, 0.5 + 0.4 * sin(_t * 2.0 + k)))
	var star_angle := _star_angle()
	var sa := deg_to_rad(star_angle)
	var star := base + Vector2(sin(sa), -cos(sa)) * length
	var aligned := absf(_angle - star_angle) <= _tolerance()
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
	draw_set_transform(base, a2)
	draw_rect(Rect2(-24, -70, 48, 90), INK)
	draw_rect(Rect2(-18, -66, 36, 82), Color("8d99ae"))
	draw_rect(Rect2(-28, -84, 56, 22), INK)
	draw_set_transform(Vector2.ZERO)
	draw_circle(base, 36.0, INK)
	draw_circle(base, 28.0, Color("c1121f"))
	var bar := Rect2(Vector2(panel.position.x + 40, panel.position.y + 85), Vector2(220, 26))
	draw_rect(bar, INK)
	draw_rect(Rect2(bar.position + Vector2(3, 3), Vector2((bar.size.x - 6) * float(_hits) / _hits_needed, bar.size.y - 6)), Color("2dc653"))
	_text("LOCKED %d / %d" % [_hits, _hits_needed], bar.position + Vector2(230, 20), 20, Color.WHITE)
