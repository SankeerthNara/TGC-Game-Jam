class_name RunChase
extends ChaseBase
## Level 3 chase, free-running style: the ninja sprints over the rooftops by himself. Jump over
## crates and gaps, slide under pipes, and close the gap to the villain before he reaches the end.
## Hitting an obstacle makes you stumble and lose ground; a clean vault gives a burst of speed.

const SPEED := 470.0
const GRAV := 2500.0
const JUMP := -880.0
const STAND_H := 92.0
const SLIDE_H := 40.0
const HERO_X := 330.0 ## where the hero runs on screen

var _roofs: Array[Rect2] = [] ## x, top y, width
var _crates: Array[Rect2] = []
var _bars: Array[Rect2] = []
var _course := 9000.0
var _x := 0.0 ## hero position along the course
var _y := 560.0 ## feet
var _vy := 0.0
var _ground := true
var _slide := 0.0
var _stumble := 0.0
var _boost := 0.0
var _villain_x := 0.0
var _villain_speed := 0.0
var _cleared := {} ## crate index -> true once jumped over
var _anim := 0.0
var _fall_t := 0.0


func title() -> String:
	return "RUN HIM DOWN!"


func controls() -> String:
	return "you run by yourself     SPACE / UP jump crates and gaps     DOWN slide under pipes"


func limit() -> float:
	return (_course - 700.0) / _villain_speed if _villain_speed > 0.0 else 60.0


func time_left() -> float:
	return (_course - _villain_x) / _villain_speed


func progress() -> float:
	return 1.0 - clampf((_villain_x - _x) / 760.0, 0.0, 1.0)


func _build() -> void:
	var rng := RandomNumberGenerator.new()
	if course_seed >= 0:
		rng.seed = course_seed
	else:
		rng.randomize()
	# the hero is only a little faster than the villain: a clean run catches him in about
	# 20 seconds, every crash costs about 6, and he escapes after about 40
	_villain_speed = SPEED * (1.0 + 0.03 * difficulty) * 0.93
	_course = 700.0 + _villain_speed * (44.0 - 2.0 * difficulty)
	var x := -400.0
	var y := 560.0
	while x < _course + 800.0:
		var w := rng.randf_range(700.0, 1300.0)
		_roofs.append(Rect2(x, y, w, 600.0))
		# obstacles on this roof, never too close to its edges or to each other
		var ox := x + 380.0
		while ox < x + w - 260.0 and x > 0.0:
			var r := rng.randf()
			if r < 0.45:
				_crates.append(Rect2(ox, y - 56.0, 64.0, 56.0))
			elif r < 0.8:
				_bars.append(Rect2(ox, y - 150.0, 48.0, 84.0))
			ox += rng.randf_range(340.0, 520.0 - 30.0 * difficulty)
		x += w + rng.randf_range(150.0, 210.0 + 20.0 * difficulty)
		y = clampf(y + rng.randf_range(-90.0, 90.0), 470.0, 610.0)
	_villain_x = _x + 700.0


func _roof_at(x: float) -> Rect2:
	for r in _roofs:
		if x >= r.position.x - 10.0 and x <= r.end.x + 10.0:
			return r
	return Rect2()


func _speed() -> float:
	var s := SPEED * (1.0 + 0.03 * difficulty)
	if _stumble > 0.0:
		s *= 0.3
	elif _boost > 0.0:
		s *= 1.22
	return s


func _step(delta: float) -> void:
	_anim += delta
	_slide = maxf(0.0, _slide - delta)
	_stumble = maxf(0.0, _stumble - delta)
	_boost = maxf(0.0, _boost - delta)
	_villain_x += _villain_speed * delta
	if _fall_t > 0.0:
		_fall_t -= delta
		_y += 900.0 * delta
		if _fall_t <= 0.0:
			# back on the next rooftop, having lost ground
			var nx := _x
			for r in _roofs:
				if r.position.x > _x - 40.0:
					nx = r.position.x + 40.0
					_y = r.position.y
					break
			_x = nx
			_vy = 0.0
			_stumble = 0.6
		return
	var prev_x := _x
	_x += _speed() * delta
	# vertical
	var prev_y := _y
	_vy += GRAV * delta
	_y += _vy * delta
	var roof := _roof_at(_x)
	_ground = false
	if roof.size.x > 0.0:
		if _y >= roof.position.y and prev_y <= roof.position.y + 6.0:
			_y = roof.position.y
			_vy = 0.0
			_ground = true
		elif _y > roof.position.y + 6.0 and prev_y > roof.position.y + 6.0 and _roof_at(prev_x).position != roof.position:
			# ran into the side of a higher roof: climb it, slower if you did not jump
			if _y - roof.position.y < 160.0:
				_y = roof.position.y
				_vy = 0.0
				_ground = true
				if _stumble <= 0.0:
					_stumble = 0.45
					flash("SCRAMBLE!", 0.6, RED)
	if _y > 760.0:
		_fall_t = 0.5
		flash("MISSED THE JUMP!", 1.0, RED)
		_shake = 10.0
		return
	# obstacles
	var h := SLIDE_H if _slide > 0.0 else STAND_H
	var body := Rect2(Vector2(_x - 18.0, _y - h), Vector2(36.0, h))
	for k in _crates.size():
		var c := _crates[k]
		if _cleared.has(k):
			continue
		if body.intersects(c):
			_cleared[k] = true
			_hit("CRASH!")
		elif _x > c.end.x and prev_x <= c.end.x:
			_cleared[k] = true
			_boost = 0.6
			flash("VAULT!", 0.5)
	for b in _bars:
		if body.intersects(b) and _stumble <= 0.0:
			_hit("BONK!")
	if _x >= _villain_x - 30.0:
		win("GOTCHA!")


func _hit(text: String) -> void:
	_stumble = 0.7
	_shake = 8.0
	flash(text, 0.7, RED)


func _unhandled_input(event: InputEvent) -> void:
	if not playing() or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode in [KEY_SPACE, KEY_UP, KEY_W] and _ground and _fall_t <= 0.0:
		_vy = JUMP
		_ground = false
		_slide = 0.0
	elif event.keycode in [KEY_DOWN, KEY_S]:
		_slide = 0.65
		if not _ground:
			_vy = maxf(_vy, 700.0) # slam down


func _draw_world() -> void:
	var cam := _x - HERO_X
	var vp := size
	draw_sky(Color("2b1055"), Color("d7385e"), cam)
	draw_city(cam, Color("3a1c4f"), Color("4b1d52"), 470.0)
	var off := Vector2(-cam, 0)
	# speed lines
	for k in 14:
		var y := 120.0 + fposmod(k * 53.0, vp.y - 200.0)
		var x := fposmod(-cam * 1.4 + k * 211.0, vp.x + 300.0) - 150.0
		draw_line(Vector2(x, y), Vector2(x + 120.0, y), Color(1, 1, 1, 0.12), 3.0)
	for r in _roofs:
		var rr := Rect2(r.position + off, r.size)
		if rr.end.x < -40.0 or rr.position.x > vp.x + 40.0:
			continue
		draw_rect(rr, Color("1f1235"))
		draw_rect(Rect2(rr.position, Vector2(rr.size.x, 16.0)), Color("f77f00"))
		draw_rect(rr, INK, false, 5.0)
		for wy in range(int(rr.position.y) + 50, int(vp.y), 60):
			for wx in range(int(rr.position.x) + 30, int(rr.end.x) - 40, 70):
				draw_rect(Rect2(wx, wy, 22, 30), Color(1, 0.8, 0.4, 0.25))
	for k in _crates.size():
		var c := Rect2(_crates[k].position + off, _crates[k].size)
		if c.end.x < -40.0 or c.position.x > vp.x + 40.0:
			continue
		if _cleared.has(k) and _x > _crates[k].end.x and _stumble > 0.0 and _x - _crates[k].end.x < 60.0:
			continue # smashed
		draw_rect(c, Color("bc6c25"))
		draw_rect(c, INK, false, 4.0)
		draw_line(c.position, c.end, INK, 3.0)
		draw_line(Vector2(c.end.x, c.position.y), Vector2(c.position.x, c.end.y), INK, 3.0)
	for b in _bars:
		var rb := Rect2(b.position + off, b.size)
		if rb.end.x < -40.0 or rb.position.x > vp.x + 40.0:
			continue
		draw_rect(Rect2(rb.position.x + 6.0, rb.end.y, 8.0, 70.0), Color("6c757d"))
		draw_rect(Rect2(rb.end.x - 14.0, rb.end.y, 8.0, 70.0), Color("6c757d"))
		draw_rect(rb, Color("8d99ae"))
		draw_rect(rb, INK, false, 4.0)
		draw_rect(Rect2(rb.position + Vector2(0, rb.size.y * 0.4), Vector2(rb.size.x, 10.0)), GOLD)
	# the villain runs ahead
	var vroof := _roof_at(_villain_x)
	var vy := vroof.position.y if vroof.size.x > 0.0 else 560.0
	draw_villain(Vector2(_villain_x, vy) + off, 1.1, true)
	_draw_ninja(Vector2(_x, _y) + off)
	# distance read-out
	var gap := maxi(0, int((_villain_x - _x) / 10.0))
	draw_string(FONT_SHOUT, Vector2(30, 130), "GAP %d m" % gap, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, GOLD if gap > 20 else Color("2dc653"))


## The ninja: navy body, orange headband with flowing tails; run, jump, slide and stumble poses.
func _draw_ninja(f: Vector2) -> void:
	var navy := Color("1f2a44")
	var orange := Color("f77f00")
	draw_set_transform(f + Vector2(0, 4), 0.0, Vector2(1.0, 0.25))
	draw_circle(Vector2.ZERO, 22.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO)
	if _slide > 0.0 and _ground:
		var b := f + Vector2(0, -20)
		draw_line(b + Vector2(-34, 6), b + Vector2(20, 0), INK, 22.0)
		draw_line(b + Vector2(-34, 6), b + Vector2(20, 0), navy, 16.0)
		draw_circle(b + Vector2(30, -6), 15.0, INK)
		draw_circle(b + Vector2(30, -6), 12.0, navy)
		draw_line(b + Vector2(18, -12), b + Vector2(-20, -24 + sin(_anim * 30.0) * 4.0), orange, 5.0)
		return
	var tilt := 0.35 if _stumble > 0.0 else 0.12
	var hip := f + Vector2(0, -40)
	var neck := hip + Vector2(sin(tilt) * 40.0, -40.0)
	var ph := _anim * 16.0
	var legs := [Vector2(sin(ph) * 22.0, 0), Vector2(-sin(ph) * 22.0, 0)]
	if not _ground:
		legs = [Vector2(14, -14), Vector2(-10, -6)]
	for k in 2:
		var foot: Vector2 = f + legs[k]
		var knee := (hip + foot) * 0.5 + Vector2(10, -6)
		draw_polyline(PackedVector2Array([hip, knee, foot]), INK, 12.0)
		draw_polyline(PackedVector2Array([hip, knee, foot]), navy, 7.0)
	draw_line(hip, neck, INK, 22.0)
	draw_line(hip, neck, navy, 16.0)
	draw_line(hip + Vector2(-2, -14), neck + Vector2(8, 10), orange, 5.0)
	for k in 2:
		var sw := sin(ph + PI * k) * 18.0
		draw_line(neck + Vector2(0, 6), neck + Vector2(-sw - 6, 34), INK, 10.0)
		draw_line(neck + Vector2(0, 6), neck + Vector2(-sw - 6, 34), navy, 5.0)
	var head := neck + Vector2(4, -16)
	draw_circle(head, 17.0, INK)
	draw_circle(head, 14.0, navy)
	draw_rect(Rect2(head + Vector2(-2, -6), Vector2(14, 6)), Color("ffd2a6"))
	draw_circle(head + Vector2(7, -3), 2.5, INK)
	draw_line(head + Vector2(-14, -10), head + Vector2(14, -10), orange, 5.0)
	var w := sin(_anim * 25.0) * 5.0
	draw_line(head + Vector2(-12, -10), head + Vector2(-40, -16 + w), orange, 5.0)
	draw_line(head + Vector2(-12, -8), head + Vector2(-36, -2 - w), orange, 4.0)
