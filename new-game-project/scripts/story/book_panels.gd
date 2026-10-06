class_name BookPanels
extends RefCounted
## The book opening's panels, composed from the painted character art (sprites and portraits) with
## drawn light, ink and backgrounds. Keys: bk_peace, bk_heroes, bk_villain, bk_capture, bk_escape,
## bk_comms, bk_comms_dead.

const A := preload("res://scripts/story/comic_art.gd")
const TEX_GLOW := preload("res://assets/art/radial_glow.png")
const PORTRAITS := "res://assets/editions/portraits/"
## Light trail colours of the four heroes: pulp, noir detective, ninja, space hero.
const TRAIL := [Color("ffd23f"), Color("e9d3a4"), Color("ff8c1a"), Color("ff70a6")]

static var _tex := {}


static func has(key: String) -> bool:
	return key in ["bk_peace", "bk_heroes", "bk_villain", "bk_capture", "bk_escape", "bk_comms", "bk_comms_dead", "bk_sunlit", "bk_flare", "bk_melt"]


static func draw(ci: CanvasItem, key: String, sz: Vector2, t: float) -> void:
	match key:
		"bk_peace":
			_peace(ci, sz, t)
		"bk_heroes":
			_heroes(ci, sz, t)
		"bk_villain":
			_villain(ci, sz, t)
		"bk_capture":
			_capture(ci, sz, t)
		"bk_escape":
			_escape(ci, sz, t)
		"bk_comms":
			_comms(ci, sz, t, false)
		"bk_comms_dead":
			_comms(ci, sz, t, true)
		"bk_sunlit":
			_sunlit(ci, sz, t)
		"bk_flare":
			_flare(ci, sz, t)
		"bk_melt":
			_melt(ci, sz, t)


static func _portrait(key: String) -> Texture2D:
	if not _tex.has(key):
		var p := PORTRAITS + key + ".png"
		_tex[key] = load(p) if ResourceLoader.exists(p) else null
	return _tex[key]


static func _glow(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_texture_rect(TEX_GLOW, Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), false, col)


## A wobbly blob (continents, clouds, ink).
static func _blob(c: Vector2, r: Vector2, seed_value: float, n := 16) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in n:
		var a := k * TAU / n
		var w := 0.78 + 0.14 * sin(a * 3.0 + seed_value) + 0.08 * sin(a * 5.0 + seed_value * 2.3)
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y) * w)
	return pts


static func _fill_clipped(ci: CanvasItem, poly: PackedVector2Array, clip: PackedVector2Array, col: Color) -> void:
	for p in Geometry2D.intersect_polygons(poly, clip):
		_safe_fill(ci, p, col)


## Fills a polygon only if it can be drawn: clipping can leave slivers, repeated points or holes,
## which the renderer refuses ("triangulation failed"). Those are cleaned or skipped.
static func _safe_fill(ci: CanvasItem, poly: PackedVector2Array, col: Color) -> void:
	var clean := PackedVector2Array()
	for q in poly:
		if clean.is_empty() or clean[clean.size() - 1].distance_squared_to(q) > 0.25:
			clean.append(q)
	if clean.size() >= 2 and clean[0].distance_squared_to(clean[clean.size() - 1]) <= 0.25:
		clean.remove_at(clean.size() - 1)
	if clean.size() < 3 or absf(_area(clean)) < 2.0 or Geometry2D.triangulate_polygon(clean).is_empty():
		return
	ci.draw_colored_polygon(clean, col)


static func _area(p: PackedVector2Array) -> float:
	var a := 0.0
	for i in p.size():
		var j := (i + 1) % p.size()
		a += p[i].x * p[j].y - p[j].x * p[i].y
	return a * 0.5


# --- once, the Earth shone with light ----------------------------------------------------------

static func _peace(ci: CanvasItem, sz: Vector2, t: float) -> void:
	A.fill_bg(ci, sz, Color("060a1c"), Color("16245c"))
	A.stars(ci, sz, t)
	_glow(ci, Vector2(sz.x * 0.08, sz.y * 0.1), sz.y * 0.8, Color(1, 0.85, 0.55, 0.35))
	var c := Vector2(sz.x * 0.56, sz.y * 0.6)
	var r := minf(sz.x, sz.y) * 0.33
	_orbits(ci, c, r, t, false)
	_glow(ci, c, r * 1.7, Color(0.3, 0.6, 1.0, 0.5))
	planet(ci, c, r, t, 0.0)
	_orbits(ci, c, r, t, true)
	A.halftone(ci, sz, Color(1, 1, 1, 0.05), 18.0, 5.0, Vector2(1, 0))


## A painted-looking Earth: oceans, drifting continents and clouds, a night side and a bright rim.
## grey (0..1) drains its colour (the villain drinking the light).
static func planet(ci: CanvasItem, c: Vector2, r: float, t: float, grey: float) -> void:
	var disc := A.ellipse_pts(c, r, r, 72)
	disc.remove_at(disc.size() - 1)
	var ocean := Color("1d6fd6").lerp(Color("5a5f6e"), grey)
	ci.draw_colored_polygon(disc, ocean)
	var land_col := Color("3faa58").lerp(Color("6c6f66"), grey)
	var drift := fposmod(t * 0.04, 1.0) * r * 2.6
	var lands := [[Vector2(-0.45, -0.35), Vector2(0.42, 0.3), 1.0], [Vector2(0.35, 0.0), Vector2(0.34, 0.42), 2.7], [Vector2(-0.25, 0.5), Vector2(0.3, 0.2), 4.1], [Vector2(0.9, -0.5), Vector2(0.3, 0.22), 5.3]]
	for l: Array in lands:
		for wrap in [0.0, -r * 2.6]:
			var lc: Vector2 = c + (l[0] as Vector2) * r + Vector2(drift + wrap, 0)
			_fill_clipped(ci, _blob(lc, (l[1] as Vector2) * r, l[2]), disc, land_col)
	var cloud := Color(1, 1, 1, 0.55 * (1.0 - 0.5 * grey))
	var cdrift := fposmod(t * 0.07, 1.0) * r * 2.6
	for k in 5:
		for wrap in [0.0, -r * 2.6]:
			var cc := c + Vector2(-r + k * r * 0.55 + cdrift + wrap, -r * 0.6 + fmod(k * 0.53, 1.0) * r * 1.2)
			_fill_clipped(ci, _blob(cc, Vector2(r * 0.32, r * 0.08), k * 1.7, 12), disc, cloud)
	# the night side
	var lit := A.ellipse_pts(c + Vector2(-r * 0.35, -r * 0.3), r * 1.08, r * 1.08, 72)
	lit.remove_at(lit.size() - 1)
	for p in Geometry2D.clip_polygons(disc, lit):
		_safe_fill(ci, p, Color(0.02, 0.03, 0.12, 0.55))
	_glow(ci, c + Vector2(-r * 0.4, -r * 0.4), r * 0.75, Color(1, 1, 1, 0.22 * (1.0 - grey)))
	ci.draw_arc(c, r, 0.0, TAU, 72, Color(0.6, 0.85, 1.0, 0.85 * (1.0 - grey)), 3.0)
	ci.draw_arc(c, r + 3.0, 0.0, TAU, 72, A.INK, 4.0)


## The four heroes circling the Earth as trails of light. front: the half in front of the planet.
static func _orbits(ci: CanvasItem, c: Vector2, r: float, t: float, front: bool) -> void:
	var rx := r * 1.5
	var ry := r * 0.42
	var tilt := -0.28
	for i in 4:
		var head := t * 0.55 + i * TAU / 4.0
		var prev := Vector2.ZERO
		for k in 28:
			var a := head - k * 0.055
			var p := c + Vector2(cos(a) * rx, sin(a) * ry).rotated(tilt)
			if k > 0 and (sin(a) > 0.0) == front:
				var f := 1.0 - k / 28.0
				ci.draw_line(prev, p, Color(TRAIL[i].r, TRAIL[i].g, TRAIL[i].b, 0.75 * f), 1.5 + 6.0 * f)
			prev = p
		if (sin(head) > 0.0) == front:
			var hp := c + Vector2(cos(head) * rx, sin(head) * ry).rotated(tilt)
			_glow(ci, hp, 26.0, Color(TRAIL[i].r, TRAIL[i].g, TRAIL[i].b, 0.9))
			ci.draw_circle(hp, 4.5, Color.WHITE)


## The ending: the hero's blade gathers the freed heroes' light into a solar flare.
static func _flare(ci: CanvasItem, sz: Vector2, t: float) -> void:
	var c := Vector2(sz.x * 0.52, sz.y * 0.42)
	A.burst(ci, sz, c, Color("fff3c4"), Color("ffd66b"), 22, t * 0.25)
	_glow(ci, c, sz.y * 0.8, Color(1, 1, 0.92, 0.9))
	# the three freed heroes' light pours in from above
	for i in 3:
		var from := Vector2(sz.x * (0.1 + 0.4 * i), -10.0)
		var col: Color = TRAIL[i + 1]
		ci.draw_line(from, c, Color(col.r, col.g, col.b, 0.55), 26.0)
		ci.draw_line(from, c, Color(1, 1, 0.95, 0.9), 7.0)
	for k in 14:
		var q := fposmod(t * 0.7 + k / 14.0, 1.0)
		var a := k * 2.4
		ci.draw_circle(c + Vector2.from_angle(a) * q * sz.y * 0.6, 4.0 * (1.0 - q) + 1.0, Color(1, 1, 0.9, 1.0 - q))
	if not Sprites.draw(ci, "hero_attack", Vector2(sz.x * 0.46, sz.y * 1.03), sz.y * 0.86, 1.0):
		A.hero_bust(ci, 0, Vector2(sz.x * 0.5, sz.y * 0.6), sz.y / 420.0, "determined", t)
	A.halftone(ci, sz, Color(1, 0.6, 0.1, 0.12), 14.0, 5.0, Vector2(0.5, 0.4))


## The ending: the Narrator comes apart in the sunlight, from the feet up, ink rising off him.
static func _melt(ci: CanvasItem, sz: Vector2, t: float) -> void:
	A.fill_bg(ci, sz, Color("fff6d8"), Color("ffd98a"))
	for k in 7:
		var x := sz.x * (k / 6.0) - sz.x * 0.2 + fposmod(t * 20.0, sz.x * 0.17)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 40, 0), Vector2(x - 60, sz.y), Vector2(x - 100, sz.y)]), Color(1, 1, 1, 0.35))
	var fade := clampf(1.0 - t / 3.5, 0.3, 1.0)
	var feet := Vector2(sz.x * 0.5, sz.y * 1.02)
	if not Sprites.draw(ci, "narrator_boss", feet, sz.y * 0.92, -1.0, Color(0.85, 0.78, 1.0, fade)):
		A.narrator(ci, Vector2(sz.x * 0.5, sz.y * 0.5), sz.y / 300.0, 1.0, "grin", t)
	# the light eats him from below
	var top := sz.y * (0.95 - 0.5 * clampf(t / 3.5, 0.0, 1.0))
	var bg_lo := Color("ffd98a")
	ci.draw_polygon(PackedVector2Array([Vector2(0, top - sz.y * 0.2), Vector2(sz.x, top - sz.y * 0.2), Vector2(sz.x, sz.y), Vector2(0, sz.y)]),
		PackedColorArray([Color(bg_lo.r, bg_lo.g, bg_lo.b, 0.0), Color(bg_lo.r, bg_lo.g, bg_lo.b, 0.0), bg_lo, bg_lo]))
	for k in 26:
		var q := fposmod(t * 0.45 + k / 26.0, 1.0)
		var x := sz.x * (0.3 + 0.4 * fposmod(k * 0.618, 1.0)) + sin(t + k) * 14.0
		var y := top - q * sz.y * 0.7
		ci.draw_circle(Vector2(x, y), 6.0 * (1.0 - q) + 1.5, Color(0.2, 0.08, 0.3, 0.8 * (1.0 - q)))


## The ending: the sun rises over the Earth again, the four heroes' light circling it.
static func _sunlit(ci: CanvasItem, sz: Vector2, t: float) -> void:
	A.fill_bg(ci, sz, Color("0d1a4a"), Color("f6a35c"))
	A.stars(ci, sz, t, 7, 30)
	var sun := Vector2(sz.x * 0.82, sz.y * 0.2)
	_glow(ci, sun, sz.y * 0.75, Color(1, 0.85, 0.5, 0.8))
	ci.draw_circle(sun, sz.y * 0.07, Color("fff1c1"))
	var c := Vector2(sz.x * 0.46, sz.y * 0.64)
	var r := minf(sz.x, sz.y) * 0.3
	_orbits(ci, c, r, t, false)
	_glow(ci, c, r * 1.8, Color(1, 0.8, 0.5, 0.55))
	planet(ci, c, r, t, 0.0)
	_orbits(ci, c, r, t, true)
	A.halftone(ci, sz, Color(1, 0.9, 0.6, 0.08), 16.0, 5.0, Vector2(0.8, 0.2))


# --- guarded by four heroes ----------------------------------------------------------------------

static func _heroes(ci: CanvasItem, sz: Vector2, t: float) -> void:
	A.fill_bg(ci, sz, Color("ffcf70"), Color("5a1a4a"))
	A.burst(ci, sz, Vector2(sz.x * 0.5, sz.y * 0.45), Color(1, 0.86, 0.5, 0.0), Color(1, 0.95, 0.75, 0.35), 18, t * 0.1)
	_glow(ci, Vector2(sz.x * 0.5, sz.y * 0.5), sz.y * 0.55, Color(1, 0.95, 0.8, 0.7))
	A.halftone(ci, sz, Color(0.5, 0.1, 0.3, 0.12), 14.0, 5.0, Vector2(0.5, 1.0))
	var h := sz.y
	# the pulp hero up front
	if not Sprites.draw(ci, "hero_idle", Vector2(sz.x * 0.5, h * 1.04), h * 0.72, 1.0):
		A.hero_bust(ci, 0, Vector2(sz.x * 0.5, h * 0.62), h / 420.0, "determined", t)
	ci.draw_rect(Rect2(0, h * 0.97, sz.x, h * 0.05), Color("2a0f24"))
	# his team, in round insets above him: the noir detective, the ninja, the space hero
	var r := minf(sz.x * 0.15, h * 0.11)
	for i in 3:
		var c := Vector2(sz.x * (0.2 + 0.3 * i), h * 0.17 + (12.0 if i == 1 else 0.0) + sin(t * 2.0 + i) * 3.0)
		ci.draw_circle(c + Vector2(5, 6), r + 6.0, Color(0, 0, 0, 0.35))
		ci.draw_circle(c, r + 6.0, A.INK)
		ci.draw_circle(c, r + 2.0, TRAIL[i + 1])
		ci.draw_circle(c, r - 2.0, Color("fff3d1"))
		A.hero_bust(ci, i + 1, c + Vector2(0, r * 0.05), r / 125.0, "determined", t)
		ci.draw_arc(c, r - 2.0, 0.0, TAU, 32, A.INK, 3.0)


# --- the villain drinks the light ----------------------------------------------------------------

static func _villain(ci: CanvasItem, sz: Vector2, t: float) -> void:
	var drain := clampf(t / 3.0, 0.0, 1.0)
	A.fill_bg(ci, sz, Color("7fb7ff").lerp(Color("4a4658"), drain), Color("ffe0a3").lerp(Color("2a2433"), drain))
	_glow(ci, Vector2(sz.x * 0.18, sz.y * 0.3), sz.y * 0.5, Color(1, 0.95, 0.7, 0.8 * (1.0 - drain)))
	# the city below loses its detail: its windows melt into ever bigger pixel blocks
	var block := lerpf(6.0, 22.0, drain)
	for k in 9:
		var bx := k * sz.x * 0.12 - 10.0
		var bh := sz.y * (0.16 + fmod(k * 0.37, 0.18))
		var top := sz.y - bh
		ci.draw_rect(Rect2(bx, top, sz.x * 0.11, bh), Color("2b2a3a").lerp(Color("3a3a40"), drain))
		var y := top + block
		while y < sz.y - block:
			var x := bx + block * 0.6
			while x < bx + sz.x * 0.11 - block:
				if int(x / block + y / block + k) % 3 != 0:
					ci.draw_rect(Rect2(x, y, block * 0.6, block * 0.6), Color(1, 0.85, 0.4, 0.75 * (1.0 - drain * 0.8)))
				x += block
			y += block
	# the masked villain, quill raised; light streams out of the sky into it
	var feet := Vector2(sz.x * 0.7, sz.y * 1.06)
	var hgt := sz.y * 1.0
	var s := hgt / 768.0
	var nib := feet + Vector2(-(630.0 - 384.0) * s, -(768.0 - 300.0) * s)
	for k in 7:
		var from := Vector2(sz.x * (0.02 + k * 0.11), -20.0) if k < 5 else Vector2(-20.0, sz.y * (0.2 + (k - 5) * 0.2))
		var mid := from.lerp(nib, 0.5) + Vector2(sin(t * 1.3 + k) * 30.0, -60.0 + k * 10.0)
		var prev := from
		for j in range(1, 21):
			var q := j / 20.0
			var p := from.lerp(mid, q).lerp(mid.lerp(nib, q), q)
			var w := 2.0 + 9.0 * (1.0 - q)
			ci.draw_line(prev, p, Color(1, 0.92, 0.55, 0.22 + 0.5 * q), w)
			prev = p
		# motes of light flowing along the stream
		for m in 3:
			var q := fposmod(t * 0.6 + m / 3.0 + k * 0.13, 1.0)
			var p := from.lerp(mid, q).lerp(mid.lerp(nib, q), q)
			ci.draw_circle(p, 3.0 + 2.0 * q, Color(1, 1, 0.85, 0.9))
	_glow(ci, nib, 60.0, Color(1, 0.9, 0.5, 0.9))
	if not Sprites.draw(ci, "masked_villain", feet, hgt, -1.0):
		A.narrator(ci, Vector2(sz.x * 0.6, sz.y * 0.5), sz.y / 330.0, 0.0, "grin", t)
	A.halftone(ci, sz, Color(0.2, 0.1, 0.3, 0.12 + 0.1 * drain), 14.0, 5.0, Vector2(1.0, 1.0))


# --- three heroes in ink cages ---------------------------------------------------------------------

static func _capture(ci: CanvasItem, sz: Vector2, t: float) -> void:
	A.fill_bg(ci, sz, Color("0d0618"), Color("2a0e45"))
	A.halftone(ci, sz, Color(0.7, 0.4, 1.0, 0.14), 14.0, 5.0, Vector2(0.5, 1.0))
	cages(ci, sz, t)
	# a pool of ink below
	for k in 7:
		ci.draw_circle(Vector2(sz.x * (k / 6.0), sz.y * 1.02 + sin(t + k) * 4.0), sz.y * 0.09, Color("12051f"))


## The three captured heroes in their hanging ink cages (no background).
static func cages(ci: CanvasItem, sz: Vector2, t: float) -> void:
	var n := 3
	var gap := minf(sz.x / 3.2, sz.y * 0.42)
	var s := gap / 300.0
	for i in n:
		var cx := sz.x * 0.5 + (i - 1) * gap * 1.05
		var cy := sz.y * (0.46 + 0.06 * (i % 2)) + sin(t * 1.6 + i * 1.3) * 6.0
		# a cold spotlight from above
		ci.draw_colored_polygon(PackedVector2Array([Vector2(cx - gap * 0.12, 0), Vector2(cx + gap * 0.12, 0), Vector2(cx + gap * 0.5, sz.y), Vector2(cx - gap * 0.5, sz.y)]), Color(0.75, 0.6, 1.0, 0.08))
		ci.draw_line(Vector2(cx, 0), Vector2(cx, cy - 125.0 * s), A.INK, 6.0)
		A.hero_bust(ci, i + 1, Vector2(cx, cy - 6.0 * s), s * 0.9, "scared", t)
		A.cage(ci, Vector2(cx, cy), s)
		# ink dripping off the cage floor
		for d in 3:
			var dt := fposmod(t * 0.8 + d * 0.33 + i * 0.21, 1.0)
			var dx := cx + (d - 1) * 50.0 * s
			ci.draw_circle(Vector2(dx, cy + 125.0 * s + dt * sz.y * 0.4), (6.0 - 3.0 * dt) * maxf(s, 0.5), Color(0.1, 0.02, 0.18, 1.0 - dt))


# --- one hero escaped -------------------------------------------------------------------------------

static func _escape(ci: CanvasItem, sz: Vector2, t: float) -> void:
	A.fill_bg(ci, sz, Color("07040d"), Color("1a0b2e"))
	# a crack of light splits the dark page
	var crack := PackedVector2Array()
	var crack2 := PackedVector2Array()
	for k in 9:
		var q := k / 8.0
		var p := Vector2(sz.x * (0.92 - 0.86 * q) + (18.0 if k % 2 == 0 else -18.0), sz.y * q)
		var w := 10.0 + 34.0 * sin(q * PI)
		crack.append(p + Vector2(w, 0))
		crack2.insert(0, p - Vector2(w, 0))
	crack.append_array(crack2)
	for k in 6:
		var a := -2.2 + k * 0.25
		ci.draw_colored_polygon(PackedVector2Array([Vector2(sz.x * 0.5, sz.y * 0.5), Vector2(sz.x * 0.5, sz.y * 0.5) + Vector2.from_angle(a - 0.05) * sz.x, Vector2(sz.x * 0.5, sz.y * 0.5) + Vector2.from_angle(a + 0.05) * sz.x]), Color(1, 0.9, 0.6, 0.12))
	_glow(ci, Vector2(sz.x * 0.5, sz.y * 0.5), sz.y * 0.7, Color(1, 0.85, 0.5, 0.55))
	_safe_fill(ci, crack, Color(1, 0.96, 0.82))
	ci.draw_polyline(crack, Color(1, 0.8, 0.35), 3.0)
	# ink grabbing at him from below
	for k in 5:
		var bx := sz.x * (0.05 + k * 0.22)
		var reach := sz.y * (0.3 + 0.12 * sin(t * 2.0 + k))
		var tip := Vector2(bx + sin(t * 1.5 + k) * 40.0, sz.y - reach)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(bx - 34, sz.y + 4), tip, Vector2(bx + 34, sz.y + 4)]), Color("140621"))
		ci.draw_circle(tip, 9.0, Color("140621"))
	A.speed_lines(ci, sz, Vector2(sz.x * 0.5, sz.y * 0.48), t, Color(1, 1, 1, 0.1))
	# the whole hero inside the panel: a rising leap, head well below the top edge
	var key := "hero_jump_3" if Sprites.has("hero_jump_3") else "hero_jump"
	if not Sprites.draw(ci, key, Vector2(sz.x * 0.5, sz.y * 0.9 - sin(t * 3.0) * 6.0), sz.y * 0.7, 1.0, Color.WHITE, 1.0, -0.14):
		A.hero_bust(ci, 0, Vector2(sz.x * 0.48, sz.y * 0.42), sz.y / 330.0, "determined", t)


# --- the comms machine ---------------------------------------------------------------------------------

static func _comms(ci: CanvasItem, sz: Vector2, t: float, dead: bool) -> void:
	A.fill_bg(ci, sz, Color("071016"), Color("142630"))
	A.halftone(ci, sz, Color(0.4, 1.0, 0.8, 0.06), 14.0, 5.0, Vector2(0.6, 0.5))
	var dev := Rect2(Vector2(sz.x * 0.42, sz.y * 0.4), Vector2(sz.x * 0.46, sz.y * 0.44))
	if not dead:
		_glow(ci, dev.get_center(), sz.y * 0.55, Color(0.3, 1.0, 0.75, 0.35 + 0.08 * sin(t * 5.0)))
	# the hero listening in the dark (his portrait, turned toward the device)
	var hero := _portrait("hero")
	if hero != null:
		var hs := sz.y * 0.62
		ci.draw_set_transform(Vector2(sz.x * 0.02 + hs * 0.5, sz.y - hs * 0.5), 0.0, Vector2(-1, 1))
		ci.draw_texture_rect(hero, Rect2(Vector2(-hs * 0.5, -hs * 0.5), Vector2(hs, hs)), false, Color(0.75, 0.9, 0.85) if not dead else Color(0.55, 0.6, 0.65))
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# the device: antenna, body, screen, speaker
	var ant := Vector2(dev.end.x - dev.size.x * 0.18, dev.position.y)
	ci.draw_line(ant, ant + Vector2(dev.size.x * 0.06, -sz.y * 0.16), A.INK, 7.0)
	ci.draw_line(ant, ant + Vector2(dev.size.x * 0.06, -sz.y * 0.16), Color("5c6470"), 3.0)
	var tip := ant + Vector2(dev.size.x * 0.06, -sz.y * 0.16)
	var blink := not dead and fposmod(t, 1.0) < 0.5
	ci.draw_circle(tip, 7.0, Color("ff3b3b") if blink else Color("4a1a1a"))
	if blink:
		_glow(ci, tip, 22.0, Color(1, 0.3, 0.3, 0.8))
	ci.draw_rect(Rect2(dev.position + Vector2(8, 10), dev.size), Color(0, 0, 0, 0.45))
	ci.draw_rect(dev, Color("2b313c"))
	ci.draw_rect(Rect2(dev.position, Vector2(dev.size.x, dev.size.y * 0.08)), Color("3b4350"))
	ci.draw_rect(dev, A.INK, false, 5.0)
	var scr := Rect2(dev.position + dev.size * Vector2(0.08, 0.12), dev.size * Vector2(0.84, 0.58))
	ci.draw_rect(scr, Color("06140f"))
	if dead:
		# static and NO SIGNAL
		for k in 40:
			var rx := fposmod(sin(k * 12.9898 + floorf(t * 20.0)) * 43758.5, 1.0)
			var ry := fposmod(sin(k * 78.233 + floorf(t * 20.0)) * 12345.6, 1.0)
			ci.draw_rect(Rect2(scr.position + Vector2(rx, ry) * (scr.size - Vector2(30, 6)), Vector2(30, 6)), Color(1, 1, 1, 0.35))
		var msg := "NO SIGNAL"
		var fs := int(scr.size.y * 0.16)
		var w := A.FONT_SHOUT.get_string_size(msg, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		ci.draw_string(A.FONT_SHOUT, Vector2(scr.get_center().x - w * 0.5, scr.get_center().y + fs * 0.35), msg, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("ff5a5a"))
	else:
		var nar := _portrait("narrator_friendly")
		if nar != null:
			var side := minf(scr.size.x, scr.size.y) * 1.05
			ci.draw_texture_rect(nar, Rect2(scr.get_center() - Vector2(side * 0.5, side * 0.46), Vector2(side, side)), false, Color(0.7, 1.0, 0.85))
		for k in int(scr.size.y / 4.0):
			ci.draw_line(Vector2(scr.position.x, scr.position.y + k * 4.0), Vector2(scr.end.x, scr.position.y + k * 4.0), Color(0, 0, 0, 0.25), 1.0)
		# his voice on the wave line
		var prev := Vector2.ZERO
		for k in 41:
			var q := k / 40.0
			var p := Vector2(scr.position.x + q * scr.size.x, scr.end.y - scr.size.y * 0.12 + sin(q * 30.0 + t * 12.0) * scr.size.y * 0.06 * sin(q * PI))
			if k > 0:
				ci.draw_line(prev, p, Color(0.4, 1.0, 0.7), 3.0)
			prev = p
	ci.draw_rect(scr, A.INK, false, 4.0)
	for k in 12:
		ci.draw_circle(dev.position + dev.size * Vector2(0.14 + (k % 6) * 0.14, 0.8 + (k / 6) * 0.09), 4.0, Color("151920"))
