class_name CutScene
extends Control
## Short Among Us style cutscenes for the vampire moments. Everything is drawn in code.
## kind: detected | friend_revealed | villain_revealed | friend_killed | villain_killed

signal finished

const FONT_SHOUT := preload("res://assets/fonts/Bangers-Regular.ttf")
const FONT_BODY := preload("res://assets/fonts/ComicNeue-Bold.ttf")
const INK := Color("18151d")
const GOLD := Color("ffd23f")

const DURATIONS := {"detected": 2.2, "friend_revealed": 3.4, "villain_revealed": 3.6, "friend_killed": 4.4, "villain_killed": 4.4}

var kind := "detected"
var _t := 0.0
var _done := false
var _stars: Array[Vector2] = []


func _ready() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	mouse_filter = Control.MOUSE_FILTER_STOP
	for i in 90:
		_stars.append(Vector2(randf() * 1400.0, randf() * 720.0))


func _process(delta: float) -> void:
	_t += delta
	if _t >= float(DURATIONS.get(kind, 3.0)) and not _done:
		_done = true
		finished.emit()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _t > 1.0 and not _done and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_Z, KEY_ENTER, KEY_SPACE]:
		_done = true
		finished.emit()
		get_viewport().set_input_as_handled()


func _text(text: String, c: Vector2, fs: int, col: Color, outline := 10, font: Font = FONT_SHOUT) -> void:
	var sz := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var p := c + Vector2(-sz.x * 0.5, fs * 0.33)
	draw_string_outline(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, outline, INK)
	draw_string(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


## A vampire head. mood: "evil", "kind", "sad"
func _face(o: Vector2, r: float, mood: String, tilt := 0.0) -> void:
	draw_set_transform(o, tilt, Vector2.ONE)
	var eye := Color("ff2d2d") if mood == "evil" else (Color("4cc9f0") if mood == "kind" else Color("8d99ae"))
	draw_colored_polygon(PackedVector2Array([Vector2(-r * 1.5, r * 1.3), Vector2(-r * 0.7, -r * 0.3), Vector2(r * 0.7, -r * 0.3), Vector2(r * 1.5, r * 1.3)]), Color("1a1423"))
	draw_colored_polygon(PackedVector2Array([Vector2(-r * 0.5, r * 1.3), Vector2(0, -r * 0.1), Vector2(r * 0.5, r * 1.3)]), Color("a4161a"))
	draw_circle(Vector2(0, -r * 0.7), r * 1.0, INK)
	draw_circle(Vector2(0, -r * 0.7), r * 0.92, Color("e9e1f2"))
	draw_colored_polygon(PackedVector2Array([Vector2(-r * 0.92, -r * 0.85), Vector2(0, -r * 1.25), Vector2(r * 0.92, -r * 0.85), Vector2(r * 0.7, -r * 1.55), Vector2(-r * 0.7, -r * 1.55)]), Color("120d1a"))
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(side * r * 0.38, -r * 0.62), r * 0.2, Color("fff"))
		draw_circle(Vector2(side * r * 0.38, -r * 0.62), r * 0.15, eye)
	if mood == "evil":
		draw_colored_polygon(PackedVector2Array([Vector2(-r * 0.3, -r * 0.2), Vector2(-r * 0.1, -r * 0.2), Vector2(-r * 0.2, r * 0.2)]), Color.WHITE)
		draw_colored_polygon(PackedVector2Array([Vector2(r * 0.3, -r * 0.2), Vector2(r * 0.1, -r * 0.2), Vector2(r * 0.2, r * 0.2)]), Color.WHITE)
		draw_arc(Vector2(0, -r * 0.18), r * 0.4, 0.2, PI - 0.2, 14, INK, r * 0.06)
	elif mood == "kind":
		draw_arc(Vector2(0, -r * 0.3), r * 0.35, 0.3, PI - 0.3, 14, INK, r * 0.07)
	else:
		draw_arc(Vector2(0, r * 0.05), r * 0.3, PI + 0.4, TAU - 0.4, 14, INK, r * 0.07)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _hero_head(o: Vector2, r: float, worried := false) -> void:
	draw_circle(o, r, INK)
	draw_circle(o, r * 0.9, Color("ffd9b3"))
	draw_rect(Rect2(o + Vector2(-r * 0.9, -r * 0.35), Vector2(r * 1.8, r * 0.45)), INK)
	for side in [-1.0, 1.0]:
		draw_circle(o + Vector2(side * r * 0.35, -r * 0.12), r * 0.2, Color.WHITE)
		draw_circle(o + Vector2(side * r * 0.35, -r * 0.12), r * 0.09, INK)
	if worried:
		draw_arc(o + Vector2(0, r * 0.65), r * 0.25, PI + 0.3, TAU - 0.3, 10, INK, r * 0.07)
	else:
		draw_arc(o + Vector2(0, r * 0.35), r * 0.3, 0.3, PI - 0.3, 10, INK, r * 0.07)


func _bars() -> void:
	var vp := size
	draw_rect(Rect2(0, 0, vp.x, 80), INK)
	draw_rect(Rect2(0, vp.y - 80, vp.x, 80), INK)
	if _t > 1.0 and int(_t * 2.0) % 2 == 0:
		draw_string(FONT_BODY, Vector2(vp.x - 190, vp.y - 30), "Z: skip", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("fff3d1"))


func _draw() -> void:
	var vp := size
	var c := vp * 0.5
	match kind:
		"detected":
			_draw_detected(vp, c)
		"friend_revealed":
			_draw_friend(vp, c)
		"villain_revealed":
			_draw_villain(vp, c)
		"friend_killed":
			_draw_eject(vp, c, true)
		"villain_killed":
			_draw_eject(vp, c, false)
	_bars()


func _draw_detected(vp: Vector2, c: Vector2) -> void:
	var flash := 0.5 + 0.5 * sin(_t * 18.0)
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.25 + 0.25 * flash, 0.0, 0.05, 1.0))
	for k in 14:
		var a := k * TAU / 14.0 + _t * 1.5
		draw_colored_polygon(PackedVector2Array([c, c + Vector2.from_angle(a) * 900.0, c + Vector2.from_angle(a + 0.12) * 900.0]), Color(1, 0.2, 0.2, 0.12))
	var slide := clampf(_t / 0.35, 0.0, 1.0)
	_face(c + Vector2(0, 40) + Vector2(sin(_t * 40.0) * 3.0, 0), 90.0 * slide, "evil")
	var k := clampf(_t / 0.25, 0.0, 1.0)
	var sc := 1.0 + (1.0 - k) * 2.0
	draw_set_transform(c + Vector2(0, -200), -0.04, Vector2(sc, sc))
	_text("VAMPIRE DETECTED!", Vector2.ZERO, 92, GOLD, 14)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_text("Hold him in your light!", c + Vector2(0, 215), 34, Color("fff3d1"), 8, FONT_BODY)


func _draw_friend(vp: Vector2, c: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, vp), Color("2a1a4a") if _t < 1.3 else Color("ffe9a8"))
	if _t >= 1.3:
		for k in 16:
			var a := k * TAU / 16.0 + _t * 0.4
			draw_colored_polygon(PackedVector2Array([c, c + Vector2.from_angle(a) * 1000.0, c + Vector2.from_angle(a + 0.1) * 1000.0]), Color(1, 0.85, 0.3, 0.35))
	var shake := 6.0 if _t < 1.3 else 0.0
	var mood := "evil" if _t < 1.3 else "kind"
	_face(c + Vector2(110, 60) + Vector2(sin(_t * 50.0) * shake, 0), 100.0, mood)
	_hero_head(c + Vector2(-190, 90), 62.0, _t < 1.3)
	if _t < 1.3:
		_text("...?", c + Vector2(0, -180), 80, Color("e63946"))
	else:
		var k := clampf((_t - 1.3) / 0.25, 0.0, 1.0)
		draw_set_transform(c + Vector2(0, -190), -0.03, Vector2(k, k))
		_text("HE'S YOUR FRIEND!", Vector2.ZERO, 92, Color("2dc653"), 14)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for i in 6:
			var hp := c + Vector2(-200 + i * 80, 180 - fposmod((_t - 1.3) * 90.0 + i * 40.0, 220.0))
			draw_circle(hp + Vector2(-6, 0), 9.0, Color("e63946"))
			draw_circle(hp + Vector2(6, 0), 9.0, Color("e63946"))
			draw_colored_polygon(PackedVector2Array([hp + Vector2(-15, 3), hp + Vector2(15, 3), hp + Vector2(0, 22)]), Color("e63946"))
		_text("He is not afraid of light anymore.", c + Vector2(0, 225), 32, INK, 0, FONT_BODY)


func _draw_villain(vp: Vector2, c: Vector2) -> void:
	var lightning := fposmod(_t, 0.6) < 0.08
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.9, 0.9, 1.0) if lightning else Color("1a0b2e"))
	var grow := clampf(_t / 0.6, 0.0, 1.0)
	_face(c + Vector2(0, 90), 60.0 + 80.0 * grow, "evil", sin(_t * 12.0) * 0.03)
	if _t > 0.8:
		var k := clampf((_t - 0.8) / 0.25, 0.0, 1.0)
		draw_set_transform(c + Vector2(0, -230), 0.03, Vector2(k, k))
		_text("IT'S THE VILLAIN!", Vector2.ZERO, 92, Color("e63946"), 14)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _t > 2.2:
		# a spiral teleports the hero into the chase
		var p := (_t - 2.2) / 1.4
		for k in 30:
			var a := k * 0.5 + _t * 6.0
			var r := p * 40.0 * k * 0.5
			draw_circle(c + Vector2.from_angle(a) * r, 6.0 + k * 0.3, Color(0.7, 0.4, 1.0, 0.7))
		_text("TELEPORTING!", c + Vector2(0, 250), 56, GOLD, 10)


func _draw_eject(vp: Vector2, c: Vector2, friend: bool) -> void:
	draw_rect(Rect2(Vector2.ZERO, vp), Color("050510"))
	for st in _stars:
		var x := fposmod(st.x - _t * 220.0 * (0.4 + st.y / 720.0), vp.x + 100.0) - 50.0
		draw_circle(Vector2(x, st.y), 1.5 + (int(st.x) % 3), Color(1, 1, 1, 0.8))
	var p := clampf(_t / 3.2, 0.0, 1.0)
	var pos := Vector2(lerpf(-100.0, vp.x + 100.0, p), c.y + sin(_t * 1.6) * 40.0)
	var scale := lerpf(1.0, 0.25, p)
	draw_set_transform(pos, _t * 2.4, Vector2(scale, scale))
	_face(Vector2.ZERO, 80.0, "sad" if friend else "evil")
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var chars := int(clampf((_t - 0.5) / 2.2, 0.0, 1.0) * 40.0)
	var line1 := "The vampire was your FRIEND." if friend else "The vampire was the VILLAIN."
	_text(line1.substr(0, chars), c + Vector2(0, -190), 56, Color("8d99ae") if friend else Color("ffd23f"), 8)
	if _t > 2.9:
		var line2 := "You will never forget him." if friend else "No villains remain."
		_text(line2, c + Vector2(0, 215), 36, Color("fff3d1"), 6, FONT_BODY)
	if not friend and _t > 3.2:
		for k in 12:
			var a := k * TAU / 12.0
			draw_circle(Vector2(vp.x - 130, c.y) + Vector2.from_angle(a) * (_t - 3.2) * 90.0, 6.0, Color(1, 0.8, 0.2, 0.8))
