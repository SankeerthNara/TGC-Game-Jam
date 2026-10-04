class_name ComicArt
extends RefCounted
## Code-drawn comic art for the story cutscenes: characters, props and backgrounds with ink outlines.
## Every function draws on the given CanvasItem in its local coordinates.

const INK := Color("18151d")
const PAPER := Color("fff3d1")
const GOLD := Color("ffd23f")
const RED := Color("e63946")
const SKIN := Color("ffd2a6")
const FONT_SHOUT := preload("res://assets/fonts/Bangers-Regular.ttf")
const FONT_BODY := preload("res://assets/fonts/ComicNeue-Bold.ttf")

## The four heroes: pulp superhero, noir detective, manga ninja, pop-art space hero.
const HERO_NAMES := ["THE PULP HERO", "THE NOIR DETECTIVE", "THE NINJA", "THE SPACE HERO"]
const HERO_MAIN := [Color("1d4ed8"), Color("6b6f80"), Color("1f2a44"), Color("ff70a6")]
const HERO_ACCENT := [Color("e63946"), Color("c2a878"), Color("f77f00"), Color("2ec4b6")]


# ---------------------------------------------------------------- basics

static func poly(ci: CanvasItem, pts: PackedVector2Array, fill: Color, w := 4.0) -> void:
	ci.draw_colored_polygon(pts, fill)
	if w > 0.0:
		var closed := pts.duplicate()
		closed.append(pts[0])
		ci.draw_polyline(closed, INK, w, true)


static func disc(ci: CanvasItem, c: Vector2, r: float, fill: Color, w := 4.0) -> void:
	if w > 0.0:
		ci.draw_circle(c, r + w * 0.5, INK)
	ci.draw_circle(c, r - w * 0.5, fill)


static func ellipse_pts(c: Vector2, rx: float, ry: float, n := 28, a0 := 0.0, a1 := TAU) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in n + 1:
		var a := lerpf(a0, a1, float(k) / n)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


static func ellipse(ci: CanvasItem, c: Vector2, rx: float, ry: float, fill: Color, w := 4.0) -> void:
	var pts := ellipse_pts(c, rx, ry)
	pts.remove_at(pts.size() - 1)
	poly(ci, pts, fill, w)


static func shout(ci: CanvasItem, text: String, c: Vector2, size: int, col: Color, outline := 10, rot := 0.0, scale := 1.0) -> void:
	var sz := FONT_SHOUT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	ci.draw_set_transform(c, rot, Vector2(scale, scale))
	var p := Vector2(-sz.x * 0.5, size * 0.33)
	ci.draw_string_outline(FONT_SHOUT, p + Vector2(4, 5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, INK)
	ci.draw_string_outline(FONT_SHOUT, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, INK)
	ci.draw_string(FONT_SHOUT, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ---------------------------------------------------------------- backgrounds

static func fill_bg(ci: CanvasItem, sz: Vector2, top: Color, bottom: Color) -> void:
	var bands := 12
	for i in bands:
		ci.draw_rect(Rect2(0, sz.y * i / bands, sz.x, sz.y / bands + 1), top.lerp(bottom, float(i) / (bands - 1)))


## Comic halftone dots that grow toward `dir` (a corner or side, in 0..1 coordinates).
static func halftone(ci: CanvasItem, sz: Vector2, col: Color, step := 16.0, rmax := 5.0, toward := Vector2(1, 1)) -> void:
	var far := sz.length()
	var target := toward * sz
	var y := 0.0
	var row := 0
	while y < sz.y + step:
		var x := (step * 0.5) if row % 2 == 1 else 0.0
		while x < sz.x + step:
			var k := 1.0 - Vector2(x, y).distance_to(target) / far
			var r := rmax * clampf(k * 1.4 - 0.2, 0.0, 1.0)
			if r > 0.6:
				ci.draw_circle(Vector2(x, y), r, col)
			x += step
		y += step * 0.87
		row += 1


static func burst(ci: CanvasItem, sz: Vector2, c: Vector2, col_a: Color, col_b: Color, rays := 18, rot := 0.0) -> void:
	ci.draw_rect(Rect2(Vector2.ZERO, sz), col_a)
	var r := sz.length() * 1.2
	for k in rays:
		var a := rot + k * TAU / rays
		ci.draw_colored_polygon(PackedVector2Array([c, c + Vector2.from_angle(a) * r, c + Vector2.from_angle(a + TAU / rays * 0.5) * r]), col_b)


static func speed_lines(ci: CanvasItem, sz: Vector2, c: Vector2, t: float, col := Color(0, 0, 0, 0.35), n := 40) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for k in n:
		var a := rng.randf() * TAU
		var r0 := sz.length() * (0.35 + 0.15 * sin(t * 6.0 + k))
		var d := Vector2.from_angle(a)
		ci.draw_line(c + d * r0, c + d * sz.length(), col, rng.randf_range(2.0, 6.0))


static func stars(ci: CanvasItem, sz: Vector2, t: float, seed_value := 3, n := 70) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for k in n:
		var p := Vector2(rng.randf() * sz.x, rng.randf() * sz.y)
		var tw := 0.6 + 0.4 * sin(t * 3.0 + k)
		ci.draw_circle(p, rng.randf_range(0.8, 2.4), Color(1, 1, 1, 0.8 * tw))


# ---------------------------------------------------------------- heroes

## Head and shoulders of hero `kind` (0..3). `c` is the centre of the face, `s` the scale (1 = 100 px head).
## mood: calm | shock | determined | scared
static func hero_bust(ci: CanvasItem, kind: int, c: Vector2, s: float, mood := "calm", t := 0.0) -> void:
	var main: Color = HERO_MAIN[kind]
	var acc: Color = HERO_ACCENT[kind]
	var hr := 50.0 * s
	# shoulders / costume
	if kind == 0:
		poly(ci, PackedVector2Array([c + Vector2(-hr * 2.3, hr * 3.2), c + Vector2(-hr * 2.0, hr * 1.2), c + Vector2(0, hr * 0.9), c + Vector2(hr * 2.0, hr * 1.2), c + Vector2(hr * 2.3, hr * 3.2)]), acc, 4.0 * s) # cape
	var body := PackedVector2Array([c + Vector2(-hr * 1.9, hr * 3.2), c + Vector2(-hr * 1.6, hr * 1.4), c + Vector2(-hr * 0.5, hr * 0.85), c + Vector2(hr * 0.5, hr * 0.85), c + Vector2(hr * 1.6, hr * 1.4), c + Vector2(hr * 1.9, hr * 3.2)])
	poly(ci, body, main, 4.0 * s)
	match kind:
		0: # chest emblem: a lightning bolt in a yellow diamond
			var e := c + Vector2(0, hr * 2.1)
			poly(ci, PackedVector2Array([e + Vector2(0, -hr * 0.6), e + Vector2(hr * 0.6, 0), e + Vector2(0, hr * 0.6), e + Vector2(-hr * 0.6, 0)]), GOLD, 3.0 * s)
			poly(ci, PackedVector2Array([e + Vector2(hr * 0.1, -hr * 0.42), e + Vector2(-hr * 0.22, hr * 0.05), e + Vector2(0, hr * 0.05), e + Vector2(-hr * 0.1, hr * 0.42), e + Vector2(hr * 0.22, -hr * 0.05), e + Vector2(0, -hr * 0.05)]), RED, 2.0 * s)
		1: # trench coat lapels, shirt and tie
			poly(ci, PackedVector2Array([c + Vector2(-hr * 0.5, hr * 0.85), c + Vector2(0, hr * 2.4), c + Vector2(hr * 0.5, hr * 0.85)]), Color("f1f1f1"), 3.0 * s)
			poly(ci, PackedVector2Array([c + Vector2(-hr * 0.12, hr * 1.0), c + Vector2(hr * 0.12, hr * 1.0), c + Vector2(hr * 0.16, hr * 2.0), c + Vector2(0, hr * 2.3), c + Vector2(-hr * 0.16, hr * 2.0)]), RED, 2.0 * s)
			poly(ci, PackedVector2Array([c + Vector2(-hr * 1.6, hr * 1.4), c + Vector2(-hr * 0.5, hr * 0.85), c + Vector2(-hr * 0.15, hr * 2.6), c + Vector2(-hr * 0.9, hr * 3.2)]), acc, 3.0 * s)
			poly(ci, PackedVector2Array([c + Vector2(hr * 1.6, hr * 1.4), c + Vector2(hr * 0.5, hr * 0.85), c + Vector2(hr * 0.15, hr * 2.6), c + Vector2(hr * 0.9, hr * 3.2)]), acc, 3.0 * s)
		2: # ninja sash
			poly(ci, PackedVector2Array([c + Vector2(-hr * 1.7, hr * 1.6), c + Vector2(-hr * 1.3, hr * 1.3), c + Vector2(hr * 1.7, hr * 2.9), c + Vector2(hr * 1.3, hr * 3.2)]), acc, 3.0 * s)
		3: # pop-art suit: teal collar ring and a star
			ellipse(ci, c + Vector2(0, hr * 0.95), hr * 0.85, hr * 0.28, acc, 3.0 * s)
			_star(ci, c + Vector2(hr * 0.9, hr * 2.0), hr * 0.35, GOLD, 2.0 * s)
	# neck and head
	ci.draw_rect(Rect2(c + Vector2(-hr * 0.3, hr * 0.5), Vector2(hr * 0.6, hr * 0.5)), SKIN)
	if kind == 3:
		disc(ci, c, hr * 1.35, Color(0.75, 0.95, 1.0, 0.35), 4.0 * s) # helmet glass behind the head
	disc(ci, c, hr, SKIN, 4.0 * s)
	# hair, hats and masks
	match kind:
		0:
			poly(ci, ellipse_pts(c + Vector2(0, -hr * 0.35), hr * 1.02, hr * 0.75, 20, PI, TAU), INK, 0.0)
			poly(ci, PackedVector2Array([c + Vector2(-hr * 0.1, -hr * 0.9), c + Vector2(hr * 0.35, -hr * 0.55), c + Vector2(0, -hr * 0.6)]), INK, 0.0)
			poly(ci, PackedVector2Array([c + Vector2(-hr * 0.95, -hr * 0.2), c + Vector2(hr * 0.95, -hr * 0.2), c + Vector2(hr * 0.85, hr * 0.12), c + Vector2(-hr * 0.85, hr * 0.12)]), INK, 0.0) # domino mask
		1:
			poly(ci, PackedVector2Array([c + Vector2(-hr * 1.55, -hr * 0.45), c + Vector2(hr * 1.55, -hr * 0.45), c + Vector2(hr * 1.2, -hr * 0.7), c + Vector2(-hr * 1.2, -hr * 0.7)]), Color("3d3f4a"), 3.0 * s)
			poly(ci, PackedVector2Array([c + Vector2(-hr * 0.85, -hr * 0.7), c + Vector2(-hr * 0.7, -hr * 1.55), c + Vector2(0, -hr * 1.35), c + Vector2(hr * 0.7, -hr * 1.55), c + Vector2(hr * 0.85, -hr * 0.7)]), Color("3d3f4a"), 3.0 * s)
			ci.draw_rect(Rect2(c + Vector2(-hr * 0.82, -hr * 0.95), Vector2(hr * 1.64, hr * 0.2)), Color("1b1b22"))
			for k in 6: # stubble
				ci.draw_circle(c + Vector2(-hr * 0.35 + k * hr * 0.14, hr * 0.72 + (k % 2) * hr * 0.06), 1.6 * s, Color(0, 0, 0, 0.45))
		2:
			poly(ci, ellipse_pts(c, hr * 1.04, hr * 1.04, 24, PI * 0.95, PI * 2.05), Color("1f2a44"), 0.0)
			poly(ci, PackedVector2Array([c + Vector2(-hr * 1.0, hr * 0.12), c + Vector2(hr * 1.0, hr * 0.12), c + Vector2(hr * 0.8, hr * 0.75), c + Vector2(0, hr * 1.0), c + Vector2(-hr * 0.8, hr * 0.75)]), Color("1f2a44"), 3.0 * s)
			ci.draw_rect(Rect2(c + Vector2(-hr * 1.02, -hr * 0.55), Vector2(hr * 2.04, hr * 0.26)), acc)
			var wave := sin(t * 8.0) * hr * 0.15
			poly(ci, PackedVector2Array([c + Vector2(hr * 0.95, -hr * 0.5), c + Vector2(hr * 1.9, -hr * 0.75 + wave), c + Vector2(hr * 1.85, -hr * 0.45 + wave), c + Vector2(hr * 0.95, -hr * 0.3)]), acc, 2.5 * s)
			poly(ci, PackedVector2Array([c + Vector2(hr * 0.95, -hr * 0.45), c + Vector2(hr * 1.7, -hr * 0.1 - wave), c + Vector2(hr * 1.6, hr * 0.1 - wave), c + Vector2(hr * 0.95, -hr * 0.3)]), acc, 2.5 * s)
		3:
			poly(ci, ellipse_pts(c + Vector2(0, -hr * 0.3), hr * 1.0, hr * 0.78, 20, PI, TAU), Color("ffb703"), 0.0)
			ci.draw_line(c + Vector2(0, -hr * 1.35), c + Vector2(hr * 0.3, -hr * 1.9), INK, 3.0 * s)
			disc(ci, c + Vector2(hr * 0.3, -hr * 1.95), hr * 0.13, RED, 2.0 * s)
			ci.draw_arc(c + Vector2(-hr * 0.5, -hr * 0.5), hr * 0.9, PI * 1.05, PI * 1.35, 8, Color(1, 1, 1, 0.7), 5.0 * s)
	_face(ci, c, hr, mood, kind)


static func _face(ci: CanvasItem, c: Vector2, hr: float, mood: String, kind: int) -> void:
	var eye_y := -hr * 0.05
	var big := mood == "shock" or mood == "scared"
	for side in [-1.0, 1.0]:
		var e := c + Vector2(side * hr * 0.38, eye_y)
		ci.draw_circle(e, hr * (0.2 if big else 0.16), Color.WHITE)
		ci.draw_circle(e + Vector2(0, hr * 0.02), hr * (0.08 if big else 0.09), INK)
		var brow := -hr * (0.42 if big else 0.32)
		var tilt := 0.0
		if mood == "determined":
			tilt = hr * 0.12 * side
		elif mood == "scared":
			tilt = -hr * 0.1 * side
		if kind != 2 or true:
			ci.draw_line(e + Vector2(-hr * 0.2, brow - tilt), e + Vector2(hr * 0.2, brow + tilt), INK, hr * 0.09)
	if kind == 2:
		return # the ninja's mouth is covered
	var m := c + Vector2(0, hr * 0.5)
	match mood:
		"shock":
			ellipse(ci, m + Vector2(0, hr * 0.05), hr * 0.16, hr * 0.22, Color("6a040f"), hr * 0.06)
		"scared":
			ci.draw_arc(m + Vector2(0, hr * 0.2), hr * 0.25, PI + 0.4, TAU - 0.4, 10, INK, hr * 0.08)
		"determined":
			ci.draw_line(m + Vector2(-hr * 0.25, 0), m + Vector2(hr * 0.25, -hr * 0.05), INK, hr * 0.08)
		_:
			ci.draw_arc(m + Vector2(0, -hr * 0.12), hr * 0.28, 0.35, PI - 0.35, 10, INK, hr * 0.08)


static func _star(ci: CanvasItem, c: Vector2, r: float, fill: Color, w := 3.0) -> void:
	var pts := PackedVector2Array()
	for k in 10:
		var a := -PI * 0.5 + k * TAU / 10.0
		pts.append(c + Vector2.from_angle(a) * (r if k % 2 == 0 else r * 0.45))
	poly(ci, pts, fill, w)


## A small full-body hero for wide shots (flying, running). `dir` is the travel direction.
static func hero_tiny(ci: CanvasItem, kind: int, p: Vector2, s: float, dir := Vector2.RIGHT) -> void:
	var a := dir.angle()
	ci.draw_set_transform(p, a, Vector2(s, s))
	if kind == 0:
		poly(ci, PackedVector2Array([Vector2(-6, -10), Vector2(-46, -18 + sin(Time.get_ticks_msec() / 90.0) * 5.0), Vector2(-40, 14), Vector2(-6, 8)]), HERO_ACCENT[0], 3.0)
	poly(ci, PackedVector2Array([Vector2(-26, -9), Vector2(14, -10), Vector2(16, 10), Vector2(-26, 9)]), HERO_MAIN[kind], 3.0)
	ci.draw_line(Vector2(-6, 0), Vector2(10, 0), HERO_ACCENT[kind], 4.0)
	disc(ci, Vector2(26, 0), 11.0, SKIN, 3.0)
	if kind == 1:
		poly(ci, PackedVector2Array([Vector2(20, -10), Vector2(36, -12), Vector2(36, -6), Vector2(20, -6)]), Color("3d3f4a"), 2.0)
	elif kind == 2:
		ci.draw_rect(Rect2(Vector2(16, -5), Vector2(20, 4)), HERO_ACCENT[2])
	elif kind == 3:
		ci.draw_arc(Vector2(26, 0), 15.0, 0.0, TAU, 18, Color(0.75, 0.95, 1.0, 0.9), 2.5)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ---------------------------------------------------------------- the Narrator / masked villain

## The masked villain. With mask_off = 1 he is the Narrator: top hat, monocle, curled moustache, grin.
static func narrator(ci: CanvasItem, c: Vector2, s: float, mask_off := 1.0, mood := "grin", t := 0.0) -> void:
	var hr := 50.0 * s
	var coat := Color("3c096c")
	# coat with gold trim, shirt and bow tie
	poly(ci, PackedVector2Array([c + Vector2(-hr * 2.4, hr * 3.4), c + Vector2(-hr * 1.8, hr * 1.2), c + Vector2(-hr * 0.4, hr * 0.85), c + Vector2(hr * 0.4, hr * 0.85), c + Vector2(hr * 1.8, hr * 1.2), c + Vector2(hr * 2.4, hr * 3.4)]), coat, 4.0 * s)
	poly(ci, PackedVector2Array([c + Vector2(-hr * 0.45, hr * 0.9), c + Vector2(0, hr * 2.6), c + Vector2(hr * 0.45, hr * 0.9)]), Color("f1f1f1"), 3.0 * s)
	ci.draw_line(c + Vector2(-hr * 0.5, hr * 0.95), c + Vector2(-hr * 0.1, hr * 3.3), GOLD, 4.0 * s)
	ci.draw_line(c + Vector2(hr * 0.5, hr * 0.95), c + Vector2(hr * 0.1, hr * 3.3), GOLD, 4.0 * s)
	poly(ci, PackedVector2Array([c + Vector2(0, hr * 1.1), c + Vector2(-hr * 0.35, hr * 0.9), c + Vector2(-hr * 0.35, hr * 1.3)]), RED, 2.0 * s)
	poly(ci, PackedVector2Array([c + Vector2(0, hr * 1.1), c + Vector2(hr * 0.35, hr * 0.9), c + Vector2(hr * 0.35, hr * 1.3)]), RED, 2.0 * s)
	var hood := clampf(1.0 - mask_off * 1.5, 0.0, 1.0)
	if hood > 0.0:
		poly(ci, ellipse_pts(c + Vector2(0, -hr * 0.1), hr * 1.35, hr * 1.45, 26, PI * 0.8, PI * 2.2), Color(0.09, 0.03, 0.15, hood), 4.0 * s * hood)
	disc(ci, c, hr, Color("f1e3d3"), 4.0 * s)
	if mask_off > 0.0:
		# the Narrator's own face, revealed under the mask
		var hat := Color("18151d")
		poly(ci, PackedVector2Array([c + Vector2(-hr * 1.2, -hr * 0.7), c + Vector2(hr * 1.2, -hr * 0.7), c + Vector2(hr * 1.2, -hr * 0.92), c + Vector2(-hr * 1.2, -hr * 0.92)]), hat, 3.0 * s)
		poly(ci, PackedVector2Array([c + Vector2(-hr * 0.75, -hr * 0.9), c + Vector2(-hr * 0.68, -hr * 2.1), c + Vector2(hr * 0.68, -hr * 2.1), c + Vector2(hr * 0.75, -hr * 0.9)]), hat, 3.0 * s)
		ci.draw_rect(Rect2(c + Vector2(-hr * 0.73, -hr * 1.18), Vector2(hr * 1.46, hr * 0.2)), RED)
		ci.draw_line(c + Vector2(-hr * 0.55, -hr * 0.42), c + Vector2(-hr * 0.15, -hr * 0.3), INK, hr * 0.1)
		ci.draw_line(c + Vector2(hr * 0.55, -hr * 0.45), c + Vector2(hr * 0.15, -hr * 0.3), INK, hr * 0.1)
		ci.draw_circle(c + Vector2(-hr * 0.35, -hr * 0.12), hr * 0.12, INK)
		ci.draw_circle(c + Vector2(-hr * 0.32, -hr * 0.15), hr * 0.04, Color("ff2d2d"))
		disc(ci, c + Vector2(hr * 0.35, -hr * 0.12), hr * 0.2, Color(1, 1, 1, 0.5), 3.0 * s)
		ci.draw_arc(c + Vector2(hr * 0.35, -hr * 0.12), hr * 0.22, 0.0, TAU, 20, GOLD, 3.0 * s)
		ci.draw_circle(c + Vector2(hr * 0.35, -hr * 0.12), hr * 0.08, INK)
		ci.draw_line(c + Vector2(hr * 0.55, -hr * 0.05), c + Vector2(hr * 0.7, hr * 0.7), GOLD, 2.0 * s)
		for side in [-1.0, 1.0]:
			ci.draw_polyline(PackedVector2Array([c + Vector2(0, hr * 0.28), c + Vector2(side * hr * 0.4, hr * 0.3), c + Vector2(side * hr * 0.62, hr * 0.12), c + Vector2(side * hr * 0.55, hr * 0.02)]), INK, hr * 0.08, true)
		if mood == "grin":
			poly(ci, PackedVector2Array([c + Vector2(-hr * 0.5, hr * 0.45), c + Vector2(hr * 0.5, hr * 0.45), c + Vector2(hr * 0.3, hr * 0.72), c + Vector2(-hr * 0.3, hr * 0.72)]), Color("6a040f"), 3.0 * s)
			for k in 5:
				var x := -hr * 0.4 + k * hr * 0.2
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(x, hr * 0.47), c + Vector2(x + hr * 0.18, hr * 0.47), c + Vector2(x + hr * 0.09, hr * 0.6)]), Color.WHITE)
		else:
			ci.draw_arc(c + Vector2(0, hr * 0.3), hr * 0.35, 0.3, PI - 0.3, 12, INK, hr * 0.08)
	if mask_off < 1.0:
		# the white theatre mask flies off to the upper right
		var m := c + Vector2(mask_off * hr * 4.0, -mask_off * mask_off * hr * 3.0)
		ci.draw_set_transform(m, mask_off * 4.0, Vector2.ONE)
		poly(ci, ellipse_pts(Vector2.ZERO, hr * 0.98, hr * 1.02, 26).slice(0, 26), Color("fbfbfb"), 4.0 * s)
		for side in [-1.0, 1.0]:
			poly(ci, PackedVector2Array([Vector2(side * hr * 0.65, -hr * 0.32), Vector2(side * hr * 0.12, -hr * 0.12), Vector2(side * hr * 0.2, hr * 0.05), Vector2(side * hr * 0.62, -hr * 0.12)]), INK, 0.0)
		ci.draw_arc(Vector2(0, hr * 0.75), hr * 0.38, PI + 0.5, TAU - 0.5, 10, INK, hr * 0.07)
		ci.draw_line(Vector2(hr * 0.1, -hr * 0.95), Vector2(-hr * 0.05, -hr * 0.55), INK, 2.0 * s)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A big gloved hand reaching from the right edge (closing 0..1).
static func grab_hand(ci: CanvasItem, p: Vector2, s: float, closing: float) -> void:
	var f := lerpf(1.0, 0.45, closing)
	poly(ci, PackedVector2Array([p + Vector2(60, -40) * s, p + Vector2(400, -60) * s, p + Vector2(400, 60) * s, p + Vector2(60, 40) * s]), Color("3c096c"), 4.0 * s)
	disc(ci, p, 55.0 * s, Color("f1f1f1"), 4.0 * s)
	for k in 4:
		var a := PI + (k - 1.5) * 0.35 * f
		var tip := p + Vector2.from_angle(a) * 95.0 * s * f
		ci.draw_line(p + Vector2.from_angle(a) * 40.0 * s, tip, INK, 26.0 * s)
		ci.draw_line(p + Vector2.from_angle(a) * 40.0 * s, tip, Color("f1f1f1"), 18.0 * s)


# ---------------------------------------------------------------- props

static func earth(ci: CanvasItem, c: Vector2, r: float, dark := 0.0, t := 0.0) -> void:
	ci.draw_circle(c, r * 1.12, Color(0.4, 0.7, 1.0, 0.15 * (1.0 - dark)))
	disc(ci, c, r, Color("3a86ff"), 6.0)
	var lands := [
		[Vector2(-0.55, -0.35), Vector2(-0.1, -0.6), Vector2(0.05, -0.25), Vector2(-0.25, 0.05), Vector2(-0.6, -0.05)],
		[Vector2(0.15, -0.05), Vector2(0.6, -0.2), Vector2(0.7, 0.25), Vector2(0.35, 0.55), Vector2(0.1, 0.3)],
		[Vector2(-0.45, 0.35), Vector2(-0.15, 0.45), Vector2(-0.3, 0.75), Vector2(-0.55, 0.6)],
	]
	for land in lands:
		var pts := PackedVector2Array()
		for v: Vector2 in land:
			pts.append(c + v * r)
		poly(ci, pts, Color("2dc653"), 3.0)
	ci.draw_arc(c + Vector2(-r * 0.2, -r * 0.2), r * 0.62, PI + 0.3, PI * 1.55, 12, Color(1, 1, 1, 0.45), r * 0.06)
	if dark > 0.0:
		# tendrils of darkness crawling over the planet
		for k in 9:
			var a := k * TAU / 9.0 + 0.4
			var reach := r * (0.3 + 1.0 * dark) * (0.8 + 0.2 * sin(t * 2.0 + k))
			var b := c + Vector2.from_angle(a) * r * 1.05
			var tip := b - Vector2.from_angle(a + sin(t + k) * 0.3) * reach
			var side := Vector2.from_angle(a).orthogonal() * r * 0.18
			ci.draw_colored_polygon(PackedVector2Array([b + side, tip, b - side]), Color(0.12, 0.02, 0.2, 0.9))
		ci.draw_circle(c, r, Color(0.07, 0.0, 0.12, dark * 0.75))


static func bomb(ci: CanvasItem, c: Vector2, r: float, secs: float, t: float, flash := false) -> void:
	ci.draw_circle(c + Vector2(r * 0.08, r * 0.1), r, Color(0, 0, 0, 0.35))
	disc(ci, c, r, Color("2b2d42"), 6.0)
	ci.draw_arc(c + Vector2(-r * 0.25, -r * 0.25), r * 0.55, PI + 0.2, PI * 1.6, 12, Color(1, 1, 1, 0.3), r * 0.08)
	poly(ci, PackedVector2Array([c + Vector2(-r * 0.25, -r * 0.9), c + Vector2(r * 0.25, -r * 0.9), c + Vector2(r * 0.25, -r * 1.15), c + Vector2(-r * 0.25, -r * 1.15)]), Color("4a4e69"), 4.0)
	ci.draw_arc(c + Vector2(r * 0.35, -r * 1.15), r * 0.35, PI, PI * 1.7, 10, Color("c9ada7"), 5.0)
	var spark := 0.5 + 0.5 * sin(t * 30.0)
	_star(ci, c + Vector2(r * 0.68, -r * 1.42), r * (0.14 + 0.06 * spark), Color("ffb703"), 2.0)
	var disp := Rect2(c + Vector2(-r * 0.68, -r * 0.22), Vector2(r * 1.36, r * 0.56))
	ci.draw_rect(disp, Color("120808"))
	ci.draw_rect(disp, RED, false, 4.0)
	var s := int(ceil(secs))
	var on := not flash or int(t * 6.0) % 2 == 0
	var txt := "%d:%02d" % [s / 60, s % 60]
	var fs := int(r * 0.46)
	var sz := FONT_SHOUT.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	ci.draw_string(FONT_SHOUT, disp.get_center() + Vector2(-sz.x * 0.5, fs * 0.36), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("ff2d2d") if on else Color("400000"))
	for k in 2:
		ci.draw_line(c + Vector2(-r * 0.95, r * (0.45 + k * 0.15)), c + Vector2(r * 0.95, r * (0.45 + k * 0.15)), Color("d62828") if k == 0 else Color("1d4ed8"), 4.0)


## The steel door of the bomb room with four keyholes. keys: how many keys have turned (0..4). open: 0..1.
static func door(ci: CanvasItem, r: Rect2, keys: float, open: float) -> void:
	ci.draw_rect(r.grow(18), INK)
	ci.draw_rect(r, Color("fff6c9"))
	for k in 10:
		ci.draw_line(r.get_center(), r.get_center() + Vector2.from_angle(k * TAU / 10.0) * r.size.length(), Color(1, 0.9, 0.5, 0.6 * open), 14.0)
	var leaf := Rect2(r.position, Vector2(r.size.x * (1.0 - open * 0.92), r.size.y))
	ci.draw_rect(leaf, Color("5c677d"))
	ci.draw_rect(leaf, INK, false, 6.0)
	for y in 2:
		for x in 4:
			ci.draw_circle(leaf.position + Vector2(18 + x * (leaf.size.x - 36) / 3.0, 18 + y * (leaf.size.y - 36)), 5.0, INK)
	if open > 0.05:
		return
	_hazard(ci, Rect2(r.position + Vector2(0, r.size.y * 0.45), Vector2(r.size.x, r.size.y * 0.1)))
	for i in 4:
		var kh := r.position + Vector2(r.size.x * (0.3 + (i % 2) * 0.4), r.size.y * (0.25 + (i / 2) * 0.52))
		var turned := keys > i
		disc(ci, kh, 22.0, GOLD if turned else Color("33415c"), 4.0)
		if turned:
			ci.draw_line(kh + Vector2(-12, 0), kh + Vector2(12, 0), INK, 6.0)
		else:
			ci.draw_circle(kh + Vector2(0, -3), 6.0, INK)
			ci.draw_rect(Rect2(kh + Vector2(-3, 0), Vector2(6, 12)), INK)


static func _hazard(ci: CanvasItem, r: Rect2) -> void:
	ci.draw_rect(r, GOLD)
	var x := r.position.x - r.size.y
	while x < r.end.x:
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x, r.end.y), Vector2(x + r.size.y, r.position.y), Vector2(x + r.size.y * 1.6, r.position.y), Vector2(x + r.size.y * 0.6, r.end.y)]), INK)
		x += r.size.y * 1.6
	ci.draw_rect(r, INK, false, 3.0)


static func cage(ci: CanvasItem, c: Vector2, s: float) -> void:
	for b in 7:
		var x := c.x - 90.0 * s + b * 30.0 * s
		ci.draw_line(Vector2(x, c.y - 110.0 * s), Vector2(x, c.y + 110.0 * s), INK, 9.0 * s)
		ci.draw_line(Vector2(x, c.y - 110.0 * s), Vector2(x, c.y + 110.0 * s), Color("7b2cbf"), 4.0 * s)
	poly(ci, PackedVector2Array([c + Vector2(-110, -120) * s, c + Vector2(110, -120) * s, c + Vector2(110, -100) * s, c + Vector2(-110, -100) * s]), Color("3c096c"), 4.0 * s)
	poly(ci, PackedVector2Array([c + Vector2(-110, 100) * s, c + Vector2(110, 100) * s, c + Vector2(110, 120) * s, c + Vector2(-110, 120) * s]), Color("3c096c"), 4.0 * s)
