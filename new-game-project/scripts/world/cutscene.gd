class_name CutScene
extends Control
## Short Among Us style cutscenes for the vampire moments, plus the story beats of the bomb.
## Everything is drawn in code.
## kind: detected | friend_revealed | villain_revealed | friend_killed | villain_killed
##       | opening | bomb_room | earth_blast

signal finished

const FONT_SHOUT := preload("res://assets/fonts/Bangers-Regular.ttf")
const FONT_BODY := preload("res://assets/fonts/ComicNeue-Bold.ttf")
const INK := Color("18151d")
const GOLD := Color("ffd23f")

const DURATIONS := {"detected": 2.2, "friend_revealed": 3.4, "villain_revealed": 3.6, "friend_killed": 4.4, "villain_killed": 4.4,
	"opening": 11.0, "bomb_room": 10.0, "earth_blast": 7.0}
const HERO_COLORS := [Color("e63946"), Color("8d99ae"), Color("f77f00"), Color("ff70a6")] ## pulp, noir, ninja, pop-art

var kind := "detected"
var bomb_left := 17 * 60.0 ## shown on the bomb in the bomb room
var _t := 0.0
var _done := false
var _stars: Array[Vector2] = []


func _ready() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	mouse_filter = Control.MOUSE_FILTER_STOP
	for i in 90:
		_stars.append(Vector2(randf() * 1400.0, randf() * 720.0))


## Finishes the cutscene at once (also used by tests).
func skip() -> void:
	if not _done:
		_done = true
		finished.emit()


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
		"opening":
			_draw_opening(vp, c)
		"bomb_room":
			_draw_bomb_room(vp, c)
		"earth_blast":
			_draw_blast(vp, c)
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


## The masked villain. Unmasked, he is the Narrator: top hat, monocle and a wide grin.
func _villain(o: Vector2, r: float, masked: bool, mask_fly := 0.0) -> void:
	draw_colored_polygon(PackedVector2Array([o + Vector2(-r * 1.6, r * 2.2), o + Vector2(-r * 0.8, r * 0.4), o + Vector2(r * 0.8, r * 0.4), o + Vector2(r * 1.6, r * 2.2)]), Color("3c096c"))
	draw_colored_polygon(PackedVector2Array([o + Vector2(-r * 0.5, r * 2.2), o + Vector2(0, r * 0.6), o + Vector2(r * 0.5, r * 2.2)]), Color("ffd23f"))
	draw_circle(o, r, INK)
	draw_circle(o, r * 0.92, Color("f1e3d3"))
	if not masked:
		# the Narrator's face
		draw_rect(Rect2(o + Vector2(-r * 0.75, -r * 1.05), Vector2(r * 1.5, r * 0.18)), INK)
		draw_rect(Rect2(o + Vector2(-r * 0.5, -r * 1.9), Vector2(r * 1.0, r * 0.9)), INK)
		draw_rect(Rect2(o + Vector2(-r * 0.5, -r * 1.25), Vector2(r * 1.0, r * 0.14)), Color("e63946"))
		draw_circle(o + Vector2(-r * 0.35, -r * 0.2), r * 0.13, INK)
		draw_circle(o + Vector2(r * 0.35, -r * 0.2), r * 0.22, Color("ffd23f"))
		draw_circle(o + Vector2(r * 0.35, -r * 0.2), r * 0.17, Color("f1e3d3"))
		draw_circle(o + Vector2(r * 0.35, -r * 0.2), r * 0.11, INK)
		draw_line(o + Vector2(r * 0.55, -r * 0.1), o + Vector2(r * 0.65, r * 0.5), Color("ffd23f"), 2.0)
		draw_arc(o + Vector2(0, r * 0.15), r * 0.5, 0.25, PI - 0.25, 18, INK, r * 0.09)
		draw_colored_polygon(PackedVector2Array([o + Vector2(-r * 0.4, r * 0.35), o + Vector2(r * 0.4, r * 0.35), o + Vector2(0, r * 0.62)]), Color("fff"))
	if masked or mask_fly > 0.0:
		var m := o + Vector2(mask_fly * r * 3.0, -mask_fly * r * 2.5)
		draw_set_transform(m, mask_fly * 3.0, Vector2.ONE)
		draw_circle(Vector2.ZERO, r * 0.95, Color("fbfbfb"))
		draw_arc(Vector2.ZERO, r * 0.95, 0.0, TAU, 32, INK, 3.0)
		draw_colored_polygon(PackedVector2Array([Vector2(-r * 0.6, -r * 0.35), Vector2(-r * 0.12, -r * 0.15), Vector2(-r * 0.2, r * 0.02), Vector2(-r * 0.62, -r * 0.18)]), INK)
		draw_colored_polygon(PackedVector2Array([Vector2(r * 0.6, -r * 0.35), Vector2(r * 0.12, -r * 0.15), Vector2(r * 0.2, r * 0.02), Vector2(r * 0.62, -r * 0.18)]), INK)
		draw_line(Vector2(-r * 0.3, r * 0.5), Vector2(r * 0.3, r * 0.5), INK, 3.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _earth(o: Vector2, r: float, dark: float) -> void:
	draw_circle(o, r + 6.0, INK)
	draw_circle(o, r, Color("3a86ff"))
	for blob in [Vector3(-0.35, -0.3, 0.38), Vector3(0.3, 0.1, 0.32), Vector3(-0.1, 0.45, 0.25), Vector3(0.45, -0.45, 0.18)]:
		draw_circle(o + Vector2(blob.x, blob.y) * r, blob.z * r, Color("2dc653"))
	draw_arc(o + Vector2(-r * 0.25, -r * 0.25), r * 0.55, PI + 0.4, PI * 1.5, 12, Color(1, 1, 1, 0.35), 6.0)
	if dark > 0.0:
		draw_circle(o, r + 7.0, Color(0.05, 0.0, 0.1, dark * 0.85))


func _bomb(o: Vector2, r: float, secs: float, flash := false) -> void:
	draw_circle(o + Vector2(5, 6), r, Color(0, 0, 0, 0.4))
	draw_circle(o, r, INK)
	draw_circle(o, r * 0.92, Color("2b2d42"))
	draw_circle(o + Vector2(-r * 0.35, -r * 0.35), r * 0.18, Color(1, 1, 1, 0.3))
	draw_rect(Rect2(o + Vector2(-r * 0.25, -r * 1.15), Vector2(r * 0.5, r * 0.3)), INK)
	draw_arc(o + Vector2(r * 0.3, -r * 1.2), r * 0.35, PI, PI * 1.6, 10, Color("c9ada7"), 4.0)
	var spark := 0.5 + 0.5 * sin(_t * 30.0)
	draw_circle(o + Vector2(r * 0.6, -r * 1.45), 6.0 + 5.0 * spark, Color("ffb703"))
	draw_circle(o + Vector2(r * 0.6, -r * 1.45), 3.0 + 2.0 * spark, Color("fff3d1"))
	var disp := Rect2(o + Vector2(-r * 0.7, -r * 0.2), Vector2(r * 1.4, r * 0.55))
	draw_rect(disp, Color("120808"))
	draw_rect(disp, Color("e63946"), false, 3.0)
	var s := int(ceil(secs))
	var col := Color("ff2d2d") if not flash or int(_t * 6.0) % 2 == 0 else Color("400000")
	var txt := "%d:%02d" % [s / 60, s % 60]
	var fs := int(r * 0.45)
	var sz := FONT_SHOUT.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	draw_string(FONT_SHOUT, disp.get_center() + Vector2(-sz.x * 0.5, fs * 0.36), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


func _caption_line(text: String, y: float, fs := 54, col := GOLD) -> void:
	_text(text, Vector2(size.x * 0.5, y), fs, col, 10)


func _draw_opening(vp: Vector2, c: Vector2) -> void:
	var dark := clampf((_t - 3.6) / 1.6, 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, vp), Color("0b1d3a").lerp(Color("07030c"), dark))
	for st in _stars:
		draw_circle(st, 1.2 + (int(st.x) % 3) * 0.6, Color(1, 1, 1, 0.7 * (1.0 - dark * 0.6)))
	var eo := c + Vector2(0, 30)
	_earth(eo, 150.0, dark)
	# the four heroes circle the planet until the darkness swallows them
	for i in 4:
		var a := _t * 0.9 + i * TAU / 4.0
		var hp := eo + Vector2(cos(a) * 230.0, sin(a) * 90.0)
		var fade := 1.0 - dark
		draw_circle(hp, 20.0, Color(INK.r, INK.g, INK.b, fade))
		draw_circle(hp, 16.0, Color(HERO_COLORS[i].r, HERO_COLORS[i].g, HERO_COLORS[i].b, fade))
		draw_circle(hp + Vector2(0, -2), 6.0, Color(1, 0.85, 0.7, fade))
	if _t < 3.6:
		_caption_line("THE EARTH LIVED IN PEACE...", 130)
		_text("...guarded by four superheroes.", Vector2(c.x, vp.y - 130), 34, Color("fff3d1"), 6, FONT_BODY)
	elif _t < 7.0:
		var rise := clampf((_t - 3.6) / 1.0, 0.0, 1.0)
		_villain(Vector2(c.x + 330, vp.y + 60 - 300 * rise), 70.0, true)
		_caption_line("UNTIL A MASKED VILLAIN CAME", 130, 54, Color("e63946"))
		_text("...and covered it in darkness.", Vector2(c.x, vp.y - 130), 34, Color("fff3d1"), 6, FONT_BODY)
		if _t > 4.8:
			_text("HA HA HA!", c + Vector2(330, -150) + Vector2(sin(_t * 30.0) * 3.0, 0), 44, Color("c77dff"), 8)
	else:
		_villain(Vector2(c.x + 420, vp.y - 250), 70.0, true)
		var drop := clampf((_t - 7.0) / 0.6, 0.0, 1.0)
		_bomb(eo + Vector2(0, -420 + 420 * drop), 95.0, 17 * 60.0)
		_caption_line("...AND HID A BOMB: 17 MINUTES!", 130, 54, Color("ff4d4d"))
		if _t > 8.0:
			_text("Clear each hero's comic to earn a key. 4 keys open the bomb room.", Vector2(c.x, vp.y - 130), 28, Color("fff3d1"), 6, FONT_BODY)


func _draw_bomb_room(vp: Vector2, c: Vector2) -> void:
	if _t < 2.6:
		# the door with four keyholes; the keys turn one by one
		draw_rect(Rect2(Vector2.ZERO, vp), Color("1b1b2f"))
		var open := clampf((_t - 2.1) / 0.5, 0.0, 1.0)
		var door := Rect2(c + Vector2(-170, -200), Vector2(340, 400))
		draw_rect(door.grow(14), INK)
		draw_rect(door, Color("ffe9a8"))
		var leaf := Rect2(door.position, Vector2(door.size.x * (1.0 - open), door.size.y))
		draw_rect(leaf, Color("6d597a"))
		draw_rect(leaf, INK, false, 6.0)
		for i in 4:
			var kh := door.position + Vector2(70 + (i % 2) * 200, 120 + (i / 2) * 150)
			if open > 0.0:
				break
			var turned := _t > 0.3 + i * 0.4
			draw_circle(kh, 26.0, INK)
			draw_circle(kh, 20.0, GOLD if turned else Color("3d3d4d"))
			draw_rect(Rect2(kh + Vector2(-5, 0), Vector2(10, 18)), INK)
		_caption_line("4 KEYS! THE BOMB ROOM OPENS", 120)
		return
	draw_rect(Rect2(Vector2.ZERO, vp), Color("12061f"))
	var glow := 0.5 + 0.5 * sin(_t * 5.0)
	draw_circle(c + Vector2(-180, 60), 230.0, Color(1, 0.1, 0.1, 0.10 + 0.06 * glow))
	_bomb(c + Vector2(-180, 80), 110.0, bomb_left)
	var unmask := clampf((_t - 3.8) / 0.7, 0.0, 1.0)
	_villain(c + Vector2(230, -10), 75.0, _t < 3.8, unmask if _t < 4.5 else 0.0)
	if _t < 3.8:
		_caption_line("THE MASKED VILLAIN...", 110, 58, Color("e63946"))
	elif _t < 6.2:
		var k := clampf((_t - 3.9) / 0.3, 0.0, 1.0)
		draw_set_transform(c + Vector2(0, -250), -0.04, Vector2(k, k))
		_text("...IS THE NARRATOR!", Vector2.ZERO, 76, GOLD, 12)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		_text("Yes. It was me all along.", c + Vector2(230, 190), 30, Color("fff3d1"), 6, FONT_BODY)
	else:
		# he snatches the level 1 hero and locks him in a cage of ink
		var lift := clampf((_t - 6.2) / 0.8, 0.0, 1.0)
		var cage := c + Vector2(420, 120 - 200 * lift)
		_hero_head(cage, 42.0, true)
		for b in 6:
			draw_line(cage + Vector2(-55 + b * 22, -60), cage + Vector2(-55 + b * 22, 60), INK, 5.0)
		draw_rect(Rect2(cage + Vector2(-62, -66), Vector2(124, 10)), INK)
		draw_rect(Rect2(cage + Vector2(-62, 56), Vector2(124, 10)), INK)
		draw_line(cage + Vector2(0, -66), c + Vector2(280, -60), INK, 4.0)
		_caption_line("HE CAPTURED THE FIRST HERO!", 110, 58, Color("e63946"))
		if _t > 7.2:
			_text("Defeat the Narrator before the bomb blows!", Vector2(c.x, vp.y - 120), 34, Color("fff3d1"), 6, FONT_BODY)


func _draw_blast(vp: Vector2, c: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, vp), Color("07030c"))
	for st in _stars:
		draw_circle(st, 1.2, Color(1, 1, 1, 0.5))
	if _t < 1.6:
		_earth(c + Vector2(0, 40), 150.0, 0.6)
		_bomb(c + Vector2(0, 40), 90.0, 0.0, true)
		_caption_line("0:00", 120, 90, Color("ff2d2d"))
		return
	var p := _t - 1.6
	var white := clampf(1.0 - p / 0.6, 0.0, 1.0)
	for k in 4:
		var r := p * (380.0 + k * 140.0)
		draw_circle(c + Vector2(0, 40), r, Color(1, 0.55 - k * 0.1, 0.1, maxf(0.0, 0.5 - p * 0.12)))
	# chunks of the planet fly apart
	for i in 18:
		var a := i * TAU / 18.0 + 0.3
		var d := p * (160.0 + (i % 5) * 60.0)
		var o := c + Vector2(0, 40) + Vector2.from_angle(a) * d
		draw_set_transform(o, p * (1.0 + i % 3), Vector2.ONE)
		draw_colored_polygon(PackedVector2Array([Vector2(-18, -12), Vector2(16, -16), Vector2(20, 10), Vector2(-10, 18)]), Color("2dc653") if i % 3 == 0 else Color("3a86ff"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if white > 0.0:
		draw_rect(Rect2(Vector2.ZERO, vp), Color(1, 1, 1, white))
	if p > 0.4:
		var k := clampf((p - 0.4) / 0.3, 0.0, 1.0)
		draw_set_transform(c + Vector2(0, -150), -0.05, Vector2(k * 1.2, k * 1.2))
		_text("BOOM!", Vector2.ZERO, 130, Color("ffb703"), 16)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if p > 2.0:
		_caption_line("THE EARTH IS GONE.", vp.y - 170, 60, Color("fff3d1"))
		_text("The heroes did not open the bomb room in time.", Vector2(c.x, vp.y - 115), 30, Color("8d99ae"), 6, FONT_BODY)
