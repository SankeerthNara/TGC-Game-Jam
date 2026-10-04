class_name WebChase
extends ChaseBase
## Level 4 chase, web-slinger style: the space hero swings across the city on light-lines shot at
## glowing hooks, webs the villain's ink drones and goons out of the way, and lands on the villain.
## Abilities: SWING (hold), REEL IN (shift, pulls you up the line), WEB SHOT (X, auto-aims).

const GRAV := 1500.0
const RANGE := 430.0
const PUMP := 950.0
const AIR := 360.0
const MAXV := 980.0
const RUN := 380.0
const JUMP := -720.0
const SHOT_SPEED := 1250.0
const DEATH_Y := 780.0

var _hooks: Array[Vector2] = []
var _roofs: Array[Rect2] = []
var _enemies: Array[Dictionary] = [] ## {pos, base, kind: "drone"|"goon", webbed, t}
var _shots: Array[Dictionary] = [] ## {pos, vel, t}
var _flags: Array[Vector2] = []
var _flag_hit := 0
var _goal := Vector2.ZERO
var _pos := Vector2.ZERO
var _vel := Vector2.ZERO
var _hook := -1
var _rope := 0.0
var _ground := false
var _hurt_t := 0.0
var _shot_cd := 0.0
var _webbed := 0
var _held := false


func title() -> String:
	return "SWING AFTER HIM!"


func controls() -> String:
	return "hold SPACE swing on a hook     LEFT / RIGHT pump the swing     SHIFT reel in     X web shot"


func limit() -> float:
	return 62.0 - 2.0 * difficulty


func progress() -> float:
	return _pos.x / _goal.x


func _build() -> void:
	var rng := RandomNumberGenerator.new()
	if course_seed >= 0:
		rng.seed = course_seed
	else:
		rng.randomize()
	var length := 6800.0 + 700.0 * difficulty
	_roofs.append(Rect2(-300.0, 560.0, 1000.0, 400.0))
	_flags.append(Vector2(100.0, 560.0))
	var x := 420.0 # the first hooks hang over the starting roof
	while x < length:
		x += rng.randf_range(230.0, 300.0 + 20.0 * difficulty)
		_hooks.append(Vector2(x, rng.randf_range(120.0, 230.0)))
		if rng.randf() < 0.22:
			var w := rng.randf_range(260.0, 420.0)
			var ry := rng.randf_range(500.0, 600.0)
			_roofs.append(Rect2(x - w * 0.5, ry, w, 400.0))
			if rng.randf() < 0.5 + 0.1 * difficulty:
				_enemies.append({"pos": Vector2(x, ry), "base": Vector2(x, ry), "kind": "goon", "webbed": false, "t": 0.0})
			if x - _flags[_flags.size() - 1].x > 1600.0:
				_flags.append(Vector2(x, ry))
		elif rng.randf() < 0.35 + 0.1 * difficulty:
			var d := Vector2(x + 140.0, rng.randf_range(300.0, 440.0))
			_enemies.append({"pos": d, "base": d, "kind": "drone", "webbed": false, "t": rng.randf() * 6.0})
	_roofs.append(Rect2(length + 200.0, 540.0, 900.0, 400.0))
	_goal = Vector2(length + 600.0, 540.0)
	_pos = _flags[0] + Vector2(0, -30)


func _nearest_hook() -> int:
	var best := -1
	var best_score := 1e9
	for k in _hooks.size():
		var h := _hooks[k]
		var d := h.distance_to(_pos)
		if d > RANGE or h.y > _pos.y - 40.0:
			continue
		var score := d - (h.x - _pos.x) * 0.6 # prefer hooks ahead
		if score < best_score:
			best_score = score
			best = k
	return best


func _step(delta: float) -> void:
	_hurt_t = maxf(0.0, _hurt_t - delta)
	_shot_cd = maxf(0.0, _shot_cd - delta)
	var dir := 0.0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		dir -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		dir += 1.0
	_held = Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W)
	if _held and _hook < 0 and not _ground:
		_attach()
	if not _held and _hook >= 0:
		_hook = -1
		if _vel.y < 0.0:
			_vel.y -= 120.0 # a little hop when letting go on the upswing
	_vel.y += GRAV * delta
	if _hook >= 0:
		var h := _hooks[_hook]
		var n := (_pos - h).normalized()
		var tangent := Vector2(-n.y, n.x)
		_vel += tangent * dir * PUMP * delta * (1.0 if tangent.x > 0.0 else -1.0)
		if Input.is_key_pressed(KEY_SHIFT):
			_rope = maxf(110.0, _rope - 520.0 * delta)
	elif _ground:
		_vel.x = move_toward(_vel.x, dir * RUN, 2400.0 * delta)
	else:
		_vel.x += dir * AIR * delta
	_vel = _vel.limit_length(MAXV)
	var prev := _pos
	_pos += _vel * delta
	if _hook >= 0:
		var h := _hooks[_hook]
		var d := _pos - h
		if d.length() > _rope:
			var n := d.normalized()
			_pos = h + n * _rope
			var radial := _vel.dot(n)
			if radial > 0.0:
				_vel -= n * radial
	# rooftops
	_ground = false
	for r in _roofs:
		if _pos.x > r.position.x and _pos.x < r.end.x and _pos.y >= r.position.y and prev.y <= r.position.y + 4.0 and _vel.y >= 0.0:
			_pos.y = r.position.y
			_vel.y = 0.0
			_ground = true
			_hook = -1
	# enemies and shots
	for e: Dictionary in _enemies:
		e["t"] = float(e["t"]) + delta
		if e["webbed"]:
			e["pos"] = (e["pos"] as Vector2) + Vector2(0, 260.0 * delta)
			continue
		if e["kind"] == "drone":
			e["pos"] = (e["base"] as Vector2) + Vector2(sin(float(e["t"]) * 1.3) * 60.0, sin(float(e["t"]) * 2.1) * 70.0)
		if _hurt_t <= 0.0 and (e["pos"] as Vector2).distance_to(_pos + Vector2(0, -30)) < 46.0:
			_hurt_t = 1.2
			_vel = Vector2(-380.0, -420.0)
			_hook = -1
			penalty(3.0, "OUCH! -3 s")
	for s: Dictionary in _shots:
		s["t"] = float(s["t"]) + delta
		s["pos"] = (s["pos"] as Vector2) + (s["vel"] as Vector2) * delta
		for e: Dictionary in _enemies:
			if not e["webbed"] and (e["pos"] as Vector2).distance_to(s["pos"]) < 40.0:
				e["webbed"] = true
				s["t"] = 99.0
				_webbed += 1
				flash("THWIP!", 0.5)
	_shots = _shots.filter(func(s: Dictionary) -> bool: return float(s["t"]) < 0.8)
	if _pos.y > DEATH_Y:
		_pos = _flags[_flag_hit] + Vector2(0, -30)
		_vel = Vector2.ZERO
		_hook = -1
		penalty(2.5, "FELL! BACK TO THE FLAG")
		return
	for k in _flags.size():
		if k > _flag_hit and _pos.x >= _flags[k].x:
			_flag_hit = k
			flash("CHECKPOINT!", 0.9)
	if _pos.distance_to(_goal) < 80.0 or _pos.x > _goal.x:
		win("WEBBED HIM! GOTCHA!")


func _attach() -> void:
	var k := _nearest_hook()
	if k < 0:
		return
	_hook = k
	_rope = maxf(_hooks[k].distance_to(_pos), 110.0)


func _shoot() -> void:
	if _shot_cd > 0.0:
		return
	_shot_cd = 0.28
	var from := _pos + Vector2(10, -34)
	var aim := Vector2.RIGHT
	var best := 700.0
	for e: Dictionary in _enemies:
		var d := (e["pos"] as Vector2) + Vector2(0, -20) - from
		if not e["webbed"] and d.x > -20.0 and d.length() < best:
			best = d.length()
			aim = d.normalized()
	_shots.append({"pos": from, "vel": aim * SHOT_SPEED, "t": 0.0})


func _unhandled_input(event: InputEvent) -> void:
	if not playing() or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode in [KEY_X, KEY_K]:
		_shoot()
	elif event.keycode in [KEY_SPACE, KEY_UP, KEY_W] and _ground:
		if _nearest_hook() < 0:
			_vel.y = JUMP
			_ground = false
		else:
			_vel.y = JUMP * 0.6
			_ground = false
			_attach()


func _cam() -> Vector2:
	return Vector2(clampf(_pos.x - 480.0, -200.0, _goal.x + 500.0 - size.x), 0.0)


func _draw_world() -> void:
	var cam := _cam()
	var vp := size
	draw_sky(Color("0b132b"), Color("5a189a"), cam.x)
	draw_city(cam.x, Color("1c2541"), Color("3a506b"), 520.0)
	var off := -cam
	# the street far below
	draw_rect(Rect2(0, 740, vp.x, 40), Color(0.9, 0.3, 0.5, 0.35))
	for r in _roofs:
		var rr := Rect2(r.position + off, r.size)
		if rr.end.x < -40.0 or rr.position.x > vp.x + 40.0:
			continue
		draw_rect(rr, Color("1c2541"))
		draw_rect(Rect2(rr.position, Vector2(rr.size.x, 14.0)), Color("2ec4b6"))
		draw_rect(rr, INK, false, 5.0)
	for k in _hooks.size():
		var h := _hooks[k] + off
		if h.x < -40.0 or h.x > vp.x + 40.0:
			continue
		draw_line(Vector2(h.x, 74), h, Color(0.7, 0.7, 0.8, 0.5), 2.0)
		var lit := k == _hook or (k == _nearest_hook() and _hook < 0 and not _ground)
		draw_circle(h, 16.0 + (4.0 if lit else 0.0), Color(0.18, 0.77, 0.71, 0.3 if not lit else 0.6))
		draw_circle(h, 10.0, INK)
		draw_circle(h, 7.0, Color("2ec4b6") if not lit else GOLD)
	for f in _flags:
		var fp := f + off
		draw_line(fp, fp + Vector2(0, -70), INK, 6.0)
		draw_colored_polygon(PackedVector2Array([fp + Vector2(0, -70), fp + Vector2(46, -56), fp + Vector2(0, -42)]), Color("2dc653") if f.x <= _flags[_flag_hit].x else Color("8d99ae"))
	for e: Dictionary in _enemies:
		_draw_enemy(e, (e["pos"] as Vector2) + off)
	for s: Dictionary in _shots:
		var p: Vector2 = (s["pos"] as Vector2) + off
		var v: Vector2 = (s["vel"] as Vector2).normalized()
		draw_line(p - v * 30.0, p, Color(1, 1, 1, 0.6), 3.0)
		draw_circle(p, 8.0, Color.WHITE)
		draw_arc(p, 8.0, 0.0, TAU, 12, INK, 2.0)
	draw_villain(_goal + off, 1.25, _won)
	if not _won:
		shout("YOU'LL NEVER REACH ME!", _goal + off + Vector2(0, -160), 28, Color("ffe066"), 8)
	if _hook >= 0:
		var h2 := _hooks[_hook] + off
		var hand := _pos + off + Vector2(8, -50)
		draw_line(hand, h2, INK, 6.0)
		draw_line(hand, h2, Color("e0fbfc"), 3.0)
	_draw_hero(_pos + off)
	draw_string(FONT_SHOUT, Vector2(30, 130), "WEBBED %d" % _webbed, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("e0fbfc"))


func _draw_enemy(e: Dictionary, p: Vector2) -> void:
	if p.x < -60.0 or p.x > size.x + 60.0:
		return
	if e["kind"] == "drone":
		draw_circle(p, 24.0, INK)
		draw_circle(p, 20.0, Color("3c096c"))
		draw_circle(p + Vector2(-4, -2), 7.0, Color("ff2d2d"))
		for side in [-1.0, 1.0]:
			draw_line(p + Vector2(side * 18, -14), p + Vector2(side * 34, -22), INK, 4.0)
			draw_line(p + Vector2(side * 24, -24), p + Vector2(side * 44, -24 + sin(_t * 40.0) * 3.0), Color(1, 1, 1, 0.6), 3.0)
	else:
		var o := p + Vector2(0, -30)
		draw_colored_polygon(PackedVector2Array([o + Vector2(-18, -10), o + Vector2(18, -10), o + Vector2(22, 30), o + Vector2(-22, 30)]), Color("240046"))
		draw_polyline(PackedVector2Array([o + Vector2(-18, -10), o + Vector2(18, -10), o + Vector2(22, 30), o + Vector2(-22, 30), o + Vector2(-18, -10)]), INK, 3.0)
		draw_circle(o + Vector2(0, -24), 15.0, INK)
		draw_circle(o + Vector2(0, -24), 12.0, Color("9d4edd"))
		draw_line(o + Vector2(-8, -26), o + Vector2(8, -26), Color("ff2d2d"), 3.0)
	if e["webbed"]:
		for k in 5:
			draw_line(p + Vector2(-26, -44 + k * 12), p + Vector2(26, -38 + k * 12), Color(1, 1, 1, 0.85), 3.0)
		draw_arc(p + Vector2(0, -20), 30.0, 0.0, TAU, 16, Color(1, 1, 1, 0.7), 2.0)


## The space hero: pink suit, teal ring, round helmet; arms up while swinging.
func _draw_hero(f: Vector2) -> void:
	if _hurt_t > 0.0 and int(_t * 16.0) % 2 == 0:
		return
	var pink := Color("ff70a6")
	var teal := Color("2ec4b6")
	var lean := clampf(_vel.x / MAXV, -1.0, 1.0) * 0.35
	var hip := f + Vector2(0, -26)
	var neck := hip + Vector2(sin(lean) * 34.0, -34.0)
	var swing := _hook >= 0
	var legs := [Vector2(-10, 0), Vector2(12, -4)] if not _ground else [Vector2(sin(_t * 14.0) * 14.0 * signf(_vel.x), 0), Vector2(-sin(_t * 14.0) * 14.0 * signf(_vel.x), 0)]
	for k in 2:
		var foot: Vector2 = f + legs[k]
		draw_line(hip, foot, INK, 12.0)
		draw_line(hip, foot, pink, 7.0)
	draw_line(hip, neck, INK, 22.0)
	draw_line(hip, neck, pink, 16.0)
	draw_circle(hip + (neck - hip) * 0.55, 5.0, GOLD)
	var hand_a := neck + (Vector2(8, -30) if swing else Vector2(16, 18))
	var hand_b := neck + (Vector2(-14, -24) if swing else Vector2(-14, 20))
	for hnd in [hand_a, hand_b]:
		draw_line(neck + Vector2(0, 4), hnd, INK, 10.0)
		draw_line(neck + Vector2(0, 4), hnd, pink, 5.0)
	var head := neck + Vector2(2, -14)
	draw_arc(neck + Vector2(0, -2), 14.0, 0.0, TAU, 16, teal, 5.0)
	draw_circle(head, 18.0, INK)
	draw_circle(head, 15.0, Color(0.75, 0.95, 1.0, 0.6))
	draw_circle(head + Vector2(2, 2), 9.0, Color("ffd2a6"))
	draw_circle(head + Vector2(5, 0), 2.0, INK)
	draw_arc(head + Vector2(-5, -6), 9.0, PI * 1.05, PI * 1.45, 6, Color(1, 1, 1, 0.8), 3.0)
	draw_line(head + Vector2(0, -18), head + Vector2(6, -30), INK, 3.0)
	draw_circle(head + Vector2(6, -31), 4.0, RED)
