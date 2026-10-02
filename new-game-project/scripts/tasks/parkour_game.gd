class_name ParkourGame
extends Control
## The villain was revealed: he bolts and the hero is teleported into a short parkour run
## (about 30 to 60 seconds). Reach the villain before the clock runs out. Falling or touching a
## spike sends you back to the last flag.

signal finished(success: bool)

const FONT_SHOUT := preload("res://assets/fonts/Bangers-Regular.ttf")
const FONT_BODY := preload("res://assets/fonts/ComicNeue-Bold.ttf")
const TEX_GLOW := preload("res://assets/art/radial_glow.png")
const INK := Color("18151d")
const PAPER := Color("fff3d1")
const GOLD := Color("ffd23f")

const GRAVITY := 2100.0
const RUN := 340.0
const JUMP := -760.0
const HERO_W := 34.0
const HERO_H := 58.0
const LIMIT := 80.0

var difficulty := 0

var _platforms: Array[Rect2] = []
var _spikes: Array[Rect2] = []
var _flags: Array[Vector2] = [] ## respawn feet positions
var _flag_hit := 0
var _villain := Vector2.ZERO
var _pos := Vector2.ZERO ## feet
var _vel := Vector2.ZERO
var _ground := false
var _coyote := 0.0
var _jump_buffer := 0.0
var _left := 60.0
var _t := 0.0
var _won := false
var _lost := false
var _end_t := 0.0
var _msg := ""
var _msg_t := 0.0
var _hero := HeroActor.new()
var _stars: Array[Vector2] = []
var _falls := 0


func _ready() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	grab_focus()
	_hero.glow = TEX_GLOW
	_hero.bubble = false
	_build()
	for i in 60:
		_stars.append(Vector2(randf() * 2400.0, randf() * 420.0))
	_pos = _flags[0]
	_left = LIMIT - 4.0 * difficulty


func _build() -> void:
	var y := 520.0
	var right := 620.0
	_platforms.append(Rect2(-300, y, 920, 500))
	_flags.append(Vector2(120, y))
	var count := 22 + difficulty * 3
	for i in count:
		var dy := randf_range(-70.0, 70.0)
		var ny := clampf(y + dy, 360.0, 580.0)
		if ny < y - 80.0:
			ny = y - 80.0
		var gap := randf_range(90.0, 150.0 + 22.0 * difficulty)
		if ny < y - 20.0:
			gap = minf(gap, 150.0)
		var w := randf_range(220.0, 380.0 - 22.0 * difficulty)
		var x := right + gap
		_platforms.append(Rect2(x, ny, w, 500))
		if difficulty >= 1 and w > 260.0 and randf() < 0.4:
			_spikes.append(Rect2(x + w * 0.5 - 20.0, ny - 22.0, 40.0, 22.0))
		if i % 4 == 3:
			_flags.append(Vector2(x + 40.0, ny))
		y = ny
		right = x + w
	var fx := right + 120.0
	_platforms.append(Rect2(fx, y, 560, 500))
	_villain = Vector2(fx + 420.0, y)


func _rect(feet: Vector2) -> Rect2:
	return Rect2(feet + Vector2(-HERO_W * 0.5, -HERO_H), Vector2(HERO_W, HERO_H))


func _process(delta: float) -> void:
	_t += delta
	_msg_t = maxf(0.0, _msg_t - delta)
	if _won or _lost:
		_end_t += delta
		if _end_t > 1.6:
			finished.emit(_won)
			set_process(false)
		queue_redraw()
		return
	_left -= delta
	if _left <= 0.0:
		_lost = true
		_msg = "TOO SLOW! HE GOT AWAY"
		_msg_t = 5.0
		queue_redraw()
		return
	var dir := 0.0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		dir -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		dir += 1.0
	_vel.x = dir * RUN
	_jump_buffer = maxf(0.0, _jump_buffer - delta)
	_coyote = maxf(0.0, _coyote - delta)
	if _ground:
		_coyote = 0.1
	if _jump_buffer > 0.0 and _coyote > 0.0:
		_vel.y = JUMP
		_ground = false
		_coyote = 0.0
		_jump_buffer = 0.0
	_vel.y += GRAVITY * delta
	# horizontal move and wall resolve
	_pos.x += _vel.x * delta
	var hr := _rect(_pos)
	for p in _platforms:
		if hr.intersects(p) and _pos.y > p.position.y + 8.0:
			if _vel.x > 0.0:
				_pos.x = p.position.x - HERO_W * 0.5
			elif _vel.x < 0.0:
				_pos.x = p.end.x + HERO_W * 0.5
			hr = _rect(_pos)
	# vertical move and landing
	var prev_feet := _pos.y
	_pos.y += _vel.y * delta
	_ground = false
	hr = _rect(_pos)
	for p in _platforms:
		if hr.intersects(p):
			if _vel.y >= 0.0 and prev_feet <= p.position.y + 10.0:
				_pos.y = p.position.y
				_vel.y = 0.0
				_ground = true
			elif _vel.y < 0.0 and hr.position.y < p.end.y:
				_vel.y = maxf(_vel.y, 0.0)
			hr = _rect(_pos)
	# hazards
	var hurt := _pos.y > 940.0
	for sp in _spikes:
		if _rect(_pos).grow(-6.0).intersects(sp):
			hurt = true
	if hurt:
		_respawn()
	for k in _flags.size():
		if k > _flag_hit and _pos.x >= _flags[k].x:
			_flag_hit = k
			_msg = "CHECKPOINT!"
			_msg_t = 1.0
	if _pos.x >= _villain.x - 40.0:
		_won = true
		_msg = "GOTCHA!"
		_msg_t = 3.0
	_hero.drive(_screen(_pos) + Vector2(0, -HERO_H * 0.5 + 6.0), absf(_vel.x) > 1.0 and _ground, _vel.x, _screen(_pos) + Vector2(200, -30), delta)
	queue_redraw()


func _respawn() -> void:
	_falls += 1
	_pos = _flags[_flag_hit]
	_vel = Vector2.ZERO
	_msg = "OOPS! BACK TO THE FLAG"
	_msg_t = 1.2


func _cam() -> float:
	return clampf(_pos.x - 420.0, -200.0, _villain.x + 300.0 - size.x)


func _screen(p: Vector2) -> Vector2:
	return Vector2(p.x - _cam(), p.y)


func _unhandled_input(event: InputEvent) -> void:
	if _won or _lost or not (event is InputEventKey):
		return
	if event.pressed and not event.echo and event.keycode in [KEY_SPACE, KEY_UP, KEY_W]:
		_jump_buffer = 0.12
	elif not event.pressed and event.keycode in [KEY_SPACE, KEY_UP, KEY_W] and _vel.y < -240.0:
		_vel.y *= 0.5


func _draw() -> void:
	var vp := size
	# sky
	for k in 12:
		var c := Color("1b1035").lerp(Color("5a2a6b"), k / 11.0)
		draw_rect(Rect2(0, vp.y * k / 12.0, vp.x, vp.y / 12.0 + 1.0), c)
	var cam := _cam()
	for st in _stars:
		var sx := fposmod(st.x - cam * 0.2, vp.x + 200.0) - 100.0
		draw_circle(Vector2(sx, st.y), 1.8, Color(1, 1, 1, 0.5 + 0.4 * sin(_t * 2.0 + st.x)))
	draw_circle(Vector2(980.0 - cam * 0.05, 130.0), 62.0, Color("f6ecd2"))
	draw_circle(Vector2(1000.0 - cam * 0.05, 118.0), 54.0, Color("1b1035"))
	for k in 14:
		var bx := fposmod(k * 190.0 - cam * 0.4, vp.x + 300.0) - 150.0
		draw_rect(Rect2(bx, 430.0 - (k % 4) * 40.0, 120.0, 400.0), Color("2a1646"))
	# platforms
	for p in _platforms:
		var r := Rect2(p.position - Vector2(cam, 0.0), p.size)
		if r.end.x < -20.0 or r.position.x > vp.x + 20.0:
			continue
		draw_rect(r, Color("2b2d42"))
		draw_rect(Rect2(r.position, Vector2(r.size.x, 22.0)), PAPER)
		draw_rect(Rect2(r.position + Vector2(0, 22.0), Vector2(r.size.x, 4.0)), INK)
		draw_rect(Rect2(r.position, Vector2(r.size.x, 500.0)), INK, false, 5.0)
		for k in range(0, int(r.size.x), 28):
			draw_line(r.position + Vector2(k, 34.0), r.position + Vector2(k + 14.0, 120.0), Color(1, 1, 1, 0.08), 2.0)
	for sp in _spikes:
		var r := Rect2(sp.position - Vector2(cam, 0.0), sp.size)
		for k in 3:
			var x0 := r.position.x + k * r.size.x / 3.0
			draw_colored_polygon(PackedVector2Array([Vector2(x0, r.end.y), Vector2(x0 + r.size.x / 6.0, r.position.y), Vector2(x0 + r.size.x / 3.0, r.end.y)]), Color("e63946"))
			draw_polyline(PackedVector2Array([Vector2(x0, r.end.y), Vector2(x0 + r.size.x / 6.0, r.position.y), Vector2(x0 + r.size.x / 3.0, r.end.y)]), INK, 3.0)
	for k in _flags.size():
		var f := _screen(_flags[k])
		draw_line(f, f + Vector2(0, -70), INK, 6.0)
		draw_colored_polygon(PackedVector2Array([f + Vector2(0, -70), f + Vector2(46, -56), f + Vector2(0, -42)]), Color("2dc653") if k <= _flag_hit else Color("8d99ae"))
	# the villain waits at the end
	var vp0 := _screen(_villain)
	var run_away := _won
	var o := vp0 + Vector2(0, -34.0)
	draw_circle(vp0 + Vector2(0, 2), 22.0, Color(0, 0, 0, 0.3))
	draw_colored_polygon(PackedVector2Array([o + Vector2(-14, -4), o + Vector2(14, -4), o + Vector2(36, 34), o + Vector2(-36, 34)]), Color("1a1423"))
	draw_colored_polygon(PackedVector2Array([o + Vector2(-6, -2), o + Vector2(6, -2), o + Vector2(14, 32), o + Vector2(-14, 32)]), Color("a4161a"))
	draw_circle(o + Vector2(0, -22), 20.0, INK)
	draw_circle(o + Vector2(0, -22), 17.5, Color("e9e1f2"))
	draw_colored_polygon(PackedVector2Array([o + Vector2(-17, -26), o + Vector2(0, -34), o + Vector2(17, -26), o + Vector2(14, -42), o + Vector2(-14, -42)]), Color("120d1a"))
	draw_circle(o + Vector2(-7, -22), 3.5, Color("ff2d2d"))
	draw_circle(o + Vector2(7, -22), 3.5, Color("ff2d2d"))
	if not run_away:
		draw_string(FONT_SHOUT, vp0 + Vector2(-90, -120), "CATCH ME IF YOU CAN!", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("ffe066"))
	# the hero
	_hero.draw(self, 76.0, INK, PAPER, FONT_SHOUT, Vector2.ZERO)
	# HUD
	draw_rect(Rect2(0, 0, vp.x, 74), Color(0, 0, 0, 0.55))
	draw_string(FONT_SHOUT, Vector2(30, 52), "CATCH THE VILLAIN!", HORIZONTAL_ALIGNMENT_LEFT, -1, 44, GOLD)
	var bar := Rect2(Vector2(vp.x - 440, 22), Vector2(400, 30))
	draw_rect(bar, INK)
	var frac := clampf(_left / (LIMIT - 4.0 * difficulty), 0.0, 1.0)
	draw_rect(Rect2(bar.position + Vector2(3, 3), Vector2((bar.size.x - 6) * frac, bar.size.y - 6)), Color("e63946") if _left < 12.0 else Color("2dc653"))
	draw_string(FONT_SHOUT, bar.position + Vector2(-110, 26), "%d s" % int(ceil(_left)), HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("fff3d1"))
	var prog := clampf((_pos.x) / (_villain.x), 0.0, 1.0)
	draw_rect(Rect2(30, 84, vp.x - 60, 8), Color(0, 0, 0, 0.45))
	draw_circle(Vector2(30 + (vp.x - 60) * prog, 88), 9.0, GOLD)
	draw_string(FONT_BODY, Vector2(30, vp.y - 16), "LEFT / RIGHT run     SPACE jump (hold for higher)     a fall sends you back to the last flag", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("fff3d1"))
	if _msg_t > 0.0:
		var a := minf(_msg_t / 0.3, 1.0)
		var ms := FONT_SHOUT.get_string_size(_msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 70)
		draw_string_outline(FONT_SHOUT, Vector2((vp.x - ms.x) * 0.5, 200), _msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 70, 12, Color(INK.r, INK.g, INK.b, a))
		draw_string(FONT_SHOUT, Vector2((vp.x - ms.x) * 0.5, 200), _msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 70, Color(GOLD.r, GOLD.g, GOLD.b, a))
