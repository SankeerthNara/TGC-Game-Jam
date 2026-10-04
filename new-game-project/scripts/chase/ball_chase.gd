class_name BallChase
extends ChaseBase
## Level 2 chase: the noir detective, rolled up into a bouncy ink ball (fedora and all), rolls over
## hills, slopes, gaps, bounce pads and moving platforms to reach the villain. Momentum matters.

const R := 26.0
const GRAV := 1650.0
const ACC := 1300.0
const AIR_ACC := 760.0
const MAXV := 540.0
const JUMP := -760.0
const PAD_JUMP := -1180.0
const DEATH_Y := 900.0

var _segs: Array[PackedVector2Array] = [] ## static ground segments [a, b]
var _grounds: Array[PackedVector2Array] = [] ## ground polylines, for drawing
var _spikes: Array[Rect2] = []
var _pads: Array[Rect2] = []
var _movers: Array[Dictionary] = [] ## {rect, x0, range, speed, dx}
var _flags: Array[Vector2] = []
var _flag_hit := 0
var _goal := Vector2.ZERO
var _pos := Vector2.ZERO
var _vel := Vector2.ZERO
var _spin := 0.0
var _ground_t := 0.0
var _jump_buf := 0.0
var _on_mover := -1
var _rain: Array[Vector2] = []


func title() -> String:
	return "ROLL AFTER HIM!"


func controls() -> String:
	return "LEFT / RIGHT roll (build up speed!)     SPACE / UP jump     yellow pads bounce you high"


func limit() -> float:
	return 58.0 - 3.0 * difficulty


func progress() -> float:
	return _pos.x / _goal.x


func _build() -> void:
	var rng := RandomNumberGenerator.new()
	if course_seed >= 0:
		rng.seed = course_seed
	else:
		rng.randomize()
	var x := -300.0
	var y := 560.0
	var line := PackedVector2Array([Vector2(x, y), Vector2(500, y)])
	x = 500.0
	_flags.append(Vector2(120, y - R))
	var pieces := 16 + difficulty * 3
	for i in pieces:
		var kind := rng.randi_range(0, 6)
		if i < 2:
			kind = 0 # an easy start
		match kind:
			0, 1: # hill or slope
				var len := rng.randf_range(260.0, 420.0)
				var dy := rng.randf_range(-130.0, 130.0)
				var ny := clampf(y + dy, 380.0, 620.0)
				var mid := Vector2(x + len * 0.5, (y + ny) * 0.5 - (rng.randf_range(20.0, 70.0) if kind == 1 else 0.0))
				line.append(mid)
				line.append(Vector2(x + len, ny))
				x += len
				y = ny
			2: # gap
				_close(line)
				x += rng.randf_range(130.0, 160.0 + 15.0 * difficulty)
				y = clampf(y + rng.randf_range(-40.0, 40.0), 400.0, 600.0)
				line = PackedVector2Array([Vector2(x, y)])
				x += 120.0
				line.append(Vector2(x, y))
			3: # flat with spikes
				var len3 := rng.randf_range(380.0, 520.0)
				line.append(Vector2(x + len3, y))
				_spikes.append(Rect2(x + len3 * 0.5 - 30.0, y - 22.0, 60.0 + 20.0 * difficulty, 22.0))
				x += len3
			4: # bounce pad in front of a tall step (only from low ground, so the step stays on screen)
				if y < 520.0:
					line.append(Vector2(x + 300.0, y))
					x += 300.0
					continue
				line.append(Vector2(x + 340.0, y))
				_pads.append(Rect2(x + 60.0, y - 14.0, 64.0, 14.0))
				x += 340.0
				_close(line)
				var top := y - 230.0
				var wall := PackedVector2Array([Vector2(x, top), Vector2(x, y)])
				_segs.append(wall)
				line = PackedVector2Array([Vector2(x, top), Vector2(x + 300.0, top)])
				x += 300.0
				y = top
			5: # moving platform over a wide gap
				_close(line)
				var gap := 420.0 + 40.0 * difficulty
				var pr := Rect2(x + 60.0, y - 10.0, 150.0, 24.0)
				_movers.append({"rect": pr, "x0": pr.position.x, "range": gap - 270.0, "speed": 0.9 + 0.15 * difficulty, "dx": 0.0})
				x += gap
				line = PackedVector2Array([Vector2(x, y), Vector2(x + 160.0, y)])
				x += 160.0
			6: # dip
				var len6 := rng.randf_range(300.0, 420.0)
				line.append(Vector2(x + len6 * 0.5, y + 90.0))
				line.append(Vector2(x + len6, y))
				x += len6
		if i % 5 == 4:
			_flags.append(Vector2(x - 60.0, y - R))
	line.append(Vector2(x + 700.0, y))
	_close(line)
	_goal = Vector2(x + 450.0, y)
	_pos = _flags[0]
	for i in 120:
		_rain.append(Vector2(randf() * 1400.0, randf() * 760.0))


## Finishes a ground polyline: its segments become solid.
func _close(line: PackedVector2Array) -> void:
	if line.size() < 2:
		return
	for k in line.size() - 1:
		_segs.append(PackedVector2Array([line[k], line[k + 1]]))
	_grounds.append(line)


func _step(delta: float) -> void:
	var dir := 0.0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		dir -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		dir += 1.0
	var grounded := _ground_t > 0.0
	_vel.x += dir * (ACC if grounded else AIR_ACC) * delta
	if dir == 0.0 and grounded:
		_vel.x *= pow(0.25, delta)
	_vel.x = clampf(_vel.x, -MAXV, MAXV)
	_vel.y += GRAV * delta
	_jump_buf = maxf(0.0, _jump_buf - delta)
	_ground_t = maxf(0.0, _ground_t - delta)
	if _jump_buf > 0.0 and _ground_t > 0.0:
		_vel.y = JUMP
		_jump_buf = 0.0
		_ground_t = 0.0
	# moving platforms
	for m: Dictionary in _movers:
		var r: Rect2 = m["rect"]
		var nx: float = float(m["x0"]) + (0.5 - 0.5 * cos(_t * float(m["speed"]))) * float(m["range"])
		m["dx"] = nx - r.position.x
		r.position.x = nx
		m["rect"] = r
	if _on_mover >= 0:
		_pos.x += float(_movers[_on_mover]["dx"])
	# move in small steps so fast rolling never tunnels through slopes
	var steps := 3
	_on_mover = -1
	for s in steps:
		_pos += _vel * delta / steps
		for seg in _segs:
			_collide(seg[0], seg[1], -1)
		for k in _movers.size():
			var r: Rect2 = _movers[k]["rect"]
			_collide(r.position, Vector2(r.end.x, r.position.y), k)
	_spin += _vel.x / R * delta
	# pads, spikes, falling, flags, goal
	for p in _pads:
		if p.grow(6.0).has_point(_pos + Vector2(0, R)) and _vel.y > -80.0:
			_vel.y = PAD_JUMP
			_ground_t = 0.0
			flash("BOING!", 0.6)
	for sp in _spikes:
		if sp.grow(-4.0).intersects(Rect2(_pos - Vector2(R, R) * 0.8, Vector2(R, R) * 1.6)):
			_respawn("OUCH! SPIKES!")
			return
	if _pos.y > DEATH_Y:
		_respawn("SPLASH! BACK TO THE FLAG")
		return
	for k in _flags.size():
		if k > _flag_hit and _pos.x >= _flags[k].x:
			_flag_hit = k
			flash("CHECKPOINT!", 0.9)
	if _pos.distance_to(_goal + Vector2(0, -R)) < 70.0 or _pos.x > _goal.x:
		win("GOTCHA!")


func _collide(a: Vector2, b: Vector2, mover: int) -> void:
	var ab := b - a
	var tt := clampf((_pos - a).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
	var q := a + ab * tt
	var d := _pos - q
	var dist := d.length()
	if dist >= R or dist < 0.001:
		return
	var n := d / dist
	_pos = q + n * R
	var vn := _vel.dot(n)
	if vn < 0.0:
		_vel -= n * vn * 1.05
	if n.y < -0.55:
		_ground_t = 0.12
		if mover >= 0:
			_on_mover = mover


var deaths: Array[String] = [] ## where and why the ball was sent back (for tests)


func _respawn(text: String) -> void:
	deaths.append("%s@%d" % [text.substr(0, 6), int(_pos.x)])
	_pos = _flags[_flag_hit]
	_vel = Vector2.ZERO
	penalty(2.0, text)


func _unhandled_input(event: InputEvent) -> void:
	if not playing() or not (event is InputEventKey):
		return
	if event.pressed and not event.echo and event.keycode in [KEY_SPACE, KEY_UP, KEY_W]:
		_jump_buf = 0.14
	elif not event.pressed and event.keycode in [KEY_SPACE, KEY_UP, KEY_W] and _vel.y < -300.0:
		_vel.y *= 0.55


func _cam() -> float:
	return clampf(_pos.x - 460.0, -200.0, _goal.x + 400.0 - size.x)


func _draw_world() -> void:
	var cam := _cam()
	var vp := size
	draw_sky(Color("1c1c24"), Color("4a4458"), cam)
	draw_city(cam, Color("2a2833"), Color("34313f"), 430.0)
	# rain, noir style
	for r in _rain:
		var p := Vector2(fposmod(r.x - cam * 0.6 - _t * 120.0, vp.x + 40.0) - 20.0, fposmod(r.y + _t * 700.0, vp.y))
		draw_line(p, p + Vector2(-5, 16), Color(0.8, 0.85, 1.0, 0.25), 1.5)
	var off := Vector2(-cam, 0)
	for line in _grounds:
		if line[line.size() - 1].x - cam < -50.0 or line[0].x - cam > vp.x + 50.0:
			continue
		var poly := PackedVector2Array()
		for p in line:
			poly.append(p + off)
		poly.append(Vector2(line[line.size() - 1].x, 1000.0) + off)
		poly.append(Vector2(line[0].x, 1000.0) + off)
		draw_colored_polygon(poly, Color("15151c"))
		var top := PackedVector2Array()
		for p in line:
			top.append(p + off)
		draw_polyline(top, Color("c2a878"), 18.0, true)
		draw_polyline(top, INK, 4.0, true)
	for m: Dictionary in _movers:
		var r: Rect2 = m["rect"]
		var rr := Rect2(r.position + off, r.size)
		draw_rect(rr, Color("c2a878"))
		draw_rect(rr, INK, false, 4.0)
		draw_line(rr.position + Vector2(rr.size.x * 0.5, 0), rr.position + Vector2(rr.size.x * 0.5, -400), Color(0, 0, 0, 0.5), 2.0)
	for p in _pads:
		var rr := Rect2(p.position + off, p.size)
		draw_rect(rr, GOLD)
		draw_rect(rr, INK, false, 3.0)
		for k in 3:
			draw_line(rr.position + Vector2(10 + k * 20, rr.size.y), rr.position + Vector2(20 + k * 20, rr.size.y + 10), INK, 3.0)
	for sp in _spikes:
		var r := Rect2(sp.position + off, sp.size)
		var n := int(r.size.x / 20.0)
		for k in n:
			var x0 := r.position.x + k * r.size.x / n
			var tri := PackedVector2Array([Vector2(x0, r.end.y), Vector2(x0 + r.size.x / n * 0.5, r.position.y), Vector2(x0 + r.size.x / n, r.end.y)])
			draw_colored_polygon(tri, RED)
			draw_polyline(PackedVector2Array([tri[0], tri[1], tri[2]]), INK, 3.0)
	for k in _flags.size():
		var f := _flags[k] + off + Vector2(0, R)
		draw_line(f, f + Vector2(0, -70), INK, 6.0)
		draw_colored_polygon(PackedVector2Array([f + Vector2(0, -70), f + Vector2(46, -56), f + Vector2(0, -42)]), Color("2dc653") if k <= _flag_hit else Color("8d99ae"))
	draw_villain(_goal + off, 1.2, _won)
	if not _won:
		shout("CATCH ME, DETECTIVE!", _goal + off + Vector2(0, -150), 28, Color("ffe066"), 8)
	_draw_ball(_pos + off)


## The noir detective as a bouncy ball: rolling stripe, a face that stays upright, and his fedora.
func _draw_ball(c: Vector2) -> void:
	draw_circle(c + Vector2(4, R + 2), R * 0.9, Color(0, 0, 0, 0.25))
	draw_circle(c, R + 3.0, INK)
	draw_circle(c, R, Color("c2a878"))
	var a := Vector2.from_angle(_spin)
	draw_line(c - a * R * 0.95, c + a * R * 0.95, Color("8a6f4a"), 7.0)
	draw_line(c - a.orthogonal() * R * 0.95, c + a.orthogonal() * R * 0.95, Color("8a6f4a"), 4.0)
	draw_circle(c + Vector2(-R * 0.35, -R * 0.35), R * 0.22, Color(1, 1, 1, 0.45))
	var look := clampf(_vel.x / MAXV, -1.0, 1.0) * 4.0
	for side in [-1.0, 1.0]:
		draw_circle(c + Vector2(side * 8.0 + look, -2), 6.0, Color.WHITE)
		draw_circle(c + Vector2(side * 8.0 + look * 1.4, -1), 3.0, INK)
	draw_arc(c + Vector2(look, 8), 7.0, 0.3, PI - 0.3, 8, INK, 2.5)
	# fedora
	var h := c + Vector2(0, -R + 2)
	draw_colored_polygon(PackedVector2Array([h + Vector2(-26, 2), h + Vector2(26, 2), h + Vector2(22, -4), h + Vector2(-22, -4)]), Color("3d3f4a"))
	draw_colored_polygon(PackedVector2Array([h + Vector2(-15, -3), h + Vector2(-13, -22), h + Vector2(0, -17), h + Vector2(13, -22), h + Vector2(15, -3)]), Color("3d3f4a"))
	draw_rect(Rect2(h + Vector2(-14, -9), Vector2(28, 5)), Color("1b1b22"))
	draw_polyline(PackedVector2Array([h + Vector2(-26, 2), h + Vector2(-15, -3), h + Vector2(-13, -22), h + Vector2(0, -17), h + Vector2(13, -22), h + Vector2(15, -3), h + Vector2(26, 2), h + Vector2(-26, 2)]), INK, 2.5)
