class_name ChaseBase
extends Control
## Shared frame of the three villain chases (one per level with vampires, each harder):
## a short "get ready" card, the clock, the progress bar, messages, the villain and the end.
## Subclasses fill in _build, _step, _draw_world, progress, title, controls and limit.

signal finished(success: bool)

const FONT_SHOUT := preload("res://assets/fonts/Bangers-Regular.ttf")
const FONT_BODY := preload("res://assets/fonts/ComicNeue-Bold.ttf")
const INK := Color("18151d")
const PAPER := Color("fff3d1")
const GOLD := Color("ffd23f")
const RED := Color("e63946")
const READY := 2.2 ## seconds of the intro card before the clock starts

var difficulty := 0
var course_seed := -1 ## >= 0: build the same course every time (tests)
var _left := 60.0
var _t := 0.0
var _won := false
var _lost := false
var _end_t := 0.0
var _msg := ""
var _msg_t := 0.0
var _msg_col := GOLD
var _shake := 0.0


func _ready() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	grab_focus()
	_build()
	_left = limit()


# --- to override ------------------------------------------------------------------

func title() -> String:
	return "CATCH THE VILLAIN!"


func controls() -> String:
	return ""


func limit() -> float:
	return 60.0


func progress() -> float:
	return 0.0


func _build() -> void:
	pass


func _step(_delta: float) -> void:
	pass


func _draw_world() -> void:
	pass


## How many seconds are left (some chases compute it from the course instead of a clock).
func time_left() -> float:
	return _left


# --- shared -------------------------------------------------------------------------

func playing() -> bool:
	return _t >= READY and not _won and not _lost


func win(text := "GOTCHA!") -> void:
	if not _won and not _lost:
		_won = true
		flash(text, 3.0)


func lose(text := "HE GOT AWAY!") -> void:
	if not _won and not _lost:
		_lost = true
		flash(text, 5.0, RED)


func flash(text: String, secs := 1.1, col := GOLD) -> void:
	_msg = text
	_msg_t = secs
	_msg_col = col


func penalty(secs: float, text := "") -> void:
	_left -= secs
	_shake = 10.0
	if text != "":
		flash(text, 1.0, RED)


func _process(delta: float) -> void:
	_t += delta
	_msg_t = maxf(0.0, _msg_t - delta)
	_shake = maxf(0.0, _shake - delta * 40.0)
	if _won or _lost:
		_end_t += delta
		if _end_t > 1.8:
			finished.emit(_won)
			set_process(false)
		queue_redraw()
		return
	if _t >= READY:
		_left -= delta
		_step(delta)
		if time_left() <= 0.0:
			lose("TOO SLOW! HE GOT AWAY!")
	queue_redraw()


func _draw() -> void:
	var off := Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake)) if _shake > 0.0 else Vector2.ZERO
	draw_set_transform(off)
	_draw_world()
	draw_set_transform(Vector2.ZERO)
	_draw_hud()


func shout(text: String, c: Vector2, fs: int, col: Color, outline := 10, rot := 0.0) -> void:
	var sz := FONT_SHOUT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	draw_set_transform(c, rot, Vector2.ONE)
	var p := Vector2(-sz.x * 0.5, fs * 0.33)
	draw_string_outline(FONT_SHOUT, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, outline, INK)
	draw_string(FONT_SHOUT, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
	draw_set_transform(Vector2.ZERO)


func _draw_hud() -> void:
	var vp := size
	draw_rect(Rect2(0, 0, vp.x, 74), Color(0, 0, 0, 0.6))
	draw_string(FONT_SHOUT, Vector2(30, 52), title(), HORIZONTAL_ALIGNMENT_LEFT, -1, 42, GOLD)
	var bar := Rect2(Vector2(vp.x - 440, 22), Vector2(400, 30))
	draw_rect(bar, INK)
	var left := maxf(0.0, time_left())
	var frac := clampf(left / limit(), 0.0, 1.0)
	draw_rect(Rect2(bar.position + Vector2(3, 3), Vector2((bar.size.x - 6) * frac, bar.size.y - 6)), RED if left < 10.0 else Color("2dc653"))
	draw_string(FONT_SHOUT, bar.position + Vector2(-110, 26), "%d s" % int(ceil(left)), HORIZONTAL_ALIGNMENT_LEFT, -1, 30, PAPER)
	var prog := clampf(progress(), 0.0, 1.0)
	draw_rect(Rect2(30, 84, vp.x - 60, 8), Color(0, 0, 0, 0.45))
	draw_circle(Vector2(vp.x - 30, 88), 9.0, RED)
	draw_circle(Vector2(30 + (vp.x - 60) * prog, 88), 9.0, GOLD)
	draw_rect(Rect2(0, vp.y - 40, vp.x, 40), Color(0, 0, 0, 0.55))
	draw_string(FONT_BODY, Vector2(30, vp.y - 13), controls(), HORIZONTAL_ALIGNMENT_LEFT, -1, 21, PAPER)
	if _t < READY:
		# the intro card: title, controls, countdown
		var k := clampf(_t / 0.25, 0.0, 1.0)
		draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.45 * k))
		shout(title(), Vector2(vp.x * 0.5, vp.y * 0.36), 86, GOLD, 14, -0.04)
		var lines := controls().split("     ")
		for i in lines.size():
			var w := FONT_BODY.get_string_size(lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
			draw_string(FONT_BODY, Vector2((vp.x - w) * 0.5, vp.y * 0.5 + i * 36), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 28, PAPER)
		var n := int(ceil(READY - _t))
		shout(str(n) if n > 0 else "GO!", Vector2(vp.x * 0.5, vp.y * 0.78), 70, RED, 12)
	if _msg_t > 0.0:
		var a := minf(_msg_t / 0.3, 1.0)
		var col := Color(_msg_col.r, _msg_col.g, _msg_col.b, a)
		shout(_msg, Vector2(vp.x * 0.5, 190), 66, col, 12, -0.03)


## The vampire villain, side view. `run` animates his legs; `s` scales him (1 = about 90 px tall).
func draw_villain(p: Vector2, s := 1.0, run := false) -> void:
	var o := p + Vector2(0, -34.0 * s)
	draw_circle(p + Vector2(0, 2), 22.0 * s, Color(0, 0, 0, 0.3))
	var sway := sin(_t * 9.0) * 6.0 * s if run else 0.0
	draw_colored_polygon(PackedVector2Array([o + Vector2(-14, -4) * s, o + Vector2(14, -4) * s, o + Vector2(36 + sway, 34) * s, o + Vector2(-36 + sway, 34) * s]), Color("1a1423"))
	draw_colored_polygon(PackedVector2Array([o + Vector2(-6, -2) * s, o + Vector2(6, -2) * s, o + Vector2(14, 32) * s, o + Vector2(-14, 32) * s]), Color("a4161a"))
	draw_circle(o + Vector2(0, -22) * s, 20.0 * s, INK)
	draw_circle(o + Vector2(0, -22) * s, 17.5 * s, Color("e9e1f2"))
	draw_colored_polygon(PackedVector2Array([o + Vector2(-17, -26) * s, o + Vector2(0, -34) * s, o + Vector2(17, -26) * s, o + Vector2(14, -42) * s, o + Vector2(-14, -42) * s]), Color("120d1a"))
	draw_circle(o + Vector2(-7, -22) * s, 3.5 * s, Color("ff2d2d"))
	draw_circle(o + Vector2(7, -22) * s, 3.5 * s, Color("ff2d2d"))


## A comic night sky with halftone dots and a moon, shared by the chases.
func draw_sky(top: Color, bottom: Color, cam_x: float) -> void:
	var vp := size
	for k in 12:
		draw_rect(Rect2(0, vp.y * k / 12.0, vp.x, vp.y / 12.0 + 1.0), top.lerp(bottom, k / 11.0))
	var step := 22.0
	var y := 90.0
	var row := 0
	while y < vp.y * 0.7:
		var x := fposmod(-cam_x * 0.05 + (step * 0.5 if row % 2 == 1 else 0.0), step) - step
		while x < vp.x + step:
			draw_circle(Vector2(x, y), 2.2 * (1.0 - y / (vp.y * 0.7)) + 0.4, Color(1, 1, 1, 0.08))
			x += step
		y += step * 0.87
		row += 1
	draw_circle(Vector2(vp.x * 0.78 - cam_x * 0.03, 150.0), 60.0, Color("f6ecd2"))
	draw_circle(Vector2(vp.x * 0.78 - cam_x * 0.03 + 20.0, 138.0), 52.0, top.lerp(bottom, 0.15))


## Parallax city blocks in two layers.
func draw_city(cam_x: float, far_col: Color, near_col: Color, base_y := 470.0) -> void:
	var vp := size
	for layer in 2:
		var par := 0.15 if layer == 0 else 0.35
		var col := far_col if layer == 0 else near_col
		for k in 16:
			var w := 110.0 + (k * 37 % 70)
			var bx := fposmod(k * 170.0 - cam_x * par, vp.x + 340.0) - 170.0
			var h := 120.0 + ((k * 53 + layer * 29) % 160)
			var top := base_y - h + layer * 60.0
			draw_rect(Rect2(bx, top, w, vp.y - top), col)
			for wy in range(int(top) + 16, int(vp.y) - 40, 34):
				for wx in range(int(bx) + 12, int(bx + w) - 14, 26):
					if (wx * 7 + wy * 3 + k) % 5 == 0:
						draw_rect(Rect2(wx, wy, 10, 14), Color(1, 0.85, 0.4, 0.35 - layer * 0.1))
