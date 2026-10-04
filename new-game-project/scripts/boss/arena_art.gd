class_name ArenaArt
extends RefCounted
## Drawing for the final battle: the Narrator's opera stage (curtains, balconies of ink spectators,
## the glowing mask, the giant inkwell podium, spike gates) and the side-view fighters.
## Everything is drawn in code in the comic style: ink outlines, halftone, flat colours, warm light.

const INK := Color("18151d")
const PAPER := Color("fff3d1")
const GOLD := Color("ffd23f")
const GLOW := Color("ffb46b")
const FLOOR_Y := 600.0
const PODIUM := Rect2(520, 505, 240, 18) ## the rim of the giant inkwell: a platform
const TEX_GLOW := preload("res://assets/art/radial_glow.png")
const HERO_SCALE := 1.35
static var land_squash := 0.0 ## 0..1, set by the fight for the frame after a landing

const HERO_MAIN := [Color("1d4ed8"), Color("c2a878"), Color("1f2a44"), Color("ff70a6")]
const HERO_ACCENT := [Color("e63946"), Color("3d3f4a"), Color("f77f00"), Color("2ec4b6")]


static func poly(ci: CanvasItem, pts: PackedVector2Array, fill: Color, w := 3.0) -> void:
	ci.draw_colored_polygon(pts, fill)
	if w > 0.0:
		var closed := pts.duplicate()
		closed.append(pts[0])
		ci.draw_polyline(closed, INK, w, true)


# --- the stage --------------------------------------------------------------------------

static func _glow(ci: CanvasItem, c: Vector2, sz: Vector2, col: Color) -> void:
	ci.draw_texture_rect(TEX_GLOW, Rect2(c - sz * 0.5, sz), false, col)


static func _h(i: int) -> float:
	return fposmod(sin(i * 12.9898) * 43758.5453, 1.0)


static func stage_back(ci: CanvasItem, sz: Vector2, t: float, glow: float) -> void:
	# deep blue-green opera hall
	for k in 14:
		ci.draw_rect(Rect2(0, sz.y * k / 14.0, sz.x, sz.y / 14.0 + 1.0), Color("1f2d31").lerp(Color("0b1012"), k / 13.0))
	var c := Vector2(sz.x * 0.5, 260.0)
	# big soft warm light behind the stage, and a hot core
	_glow(ci, c, Vector2(1500, 900), Color(1.0, 0.68, 0.38, 0.55 * glow))
	_glow(ci, c + Vector2(0, -30), Vector2(760, 520), Color(1.0, 0.8, 0.55, 0.55 * glow))
	_glow(ci, c + Vector2(0, -50), Vector2(340, 240), Color(1.0, 0.92, 0.75, 0.5 * glow))
	# the Narrator's giant mask carved in the back wall, lit from behind
	var m := c + Vector2(0, -60)
	var mc := Color(0.35, 0.2, 0.12, 0.55)
	for side in [-1.0, 1.0]:
		ci.draw_colored_polygon(PackedVector2Array([m + Vector2(side * 30, -6), m + Vector2(side * 170, -50), m + Vector2(side * 160, 6), m + Vector2(side * 50, 24)]), mc)
		ci.draw_circle(m + Vector2(side * 100, -16), 22.0, Color(1, 0.95, 0.8, 0.5 * glow))
	ci.draw_colored_polygon(PackedVector2Array([m + Vector2(-70, 70), m + Vector2(70, 70), m + Vector2(0, 130)]), mc)
	ci.draw_rect(Rect2(m + Vector2(-80, -170), Vector2(160, 90)), Color(0.3, 0.17, 0.1, 0.5))
	ci.draw_rect(Rect2(m + Vector2(-110, -90), Vector2(220, 14)), Color(0.3, 0.17, 0.1, 0.5))
	# tall pillars for depth
	for x in [150.0, 1130.0]:
		ci.draw_rect(Rect2(x - 46, 60, 92, FLOOR_Y - 60), Color("121a1c"))
		ci.draw_rect(Rect2(x - 46, 60, 10, FLOOR_Y - 60), Color(1, 0.75, 0.45, 0.10 * glow))
		for k in 6:
			ci.draw_rect(Rect2(x - 54, 110 + k * 80, 108, 10), Color("0d1314"))
	# balconies of ink spectators: curved balcony fronts and rows of heads, lit near the centre
	for row in 3:
		var y := 330.0 + row * 62.0
		for k in 34:
			var x := k * 40.0 + (_h(k + row * 50) - 0.5) * 18.0 + row * 13.0
			var lit := clampf(1.0 - absf(x - c.x) / 560.0, 0.0, 1.0)
			var hy := y + (_h(k * 7 + row) - 0.5) * 8.0 + sin(t * 1.6 + k * 0.7 + row) * 1.5
			ci.draw_circle(Vector2(x, hy), 11.0, Color(0.05, 0.06, 0.07, 0.85))
			ci.draw_arc(Vector2(x, hy), 11.0, PI * 1.1, PI * 1.9, 8, Color(1, 0.8, 0.55, 0.15 + 0.5 * lit * glow), 2.0)
			ci.draw_rect(Rect2(x - 13, hy + 9, 26, 22), Color(0.05, 0.06, 0.07, 0.85))
		var front := PackedVector2Array()
		for k in 33:
			var fx := k * 40.0
			front.append(Vector2(fx, y + 28 + sin(fx / 1280.0 * PI) * -14.0))
		front.append(Vector2(1280, y + 52))
		front.append(Vector2(0, y + 52))
		ci.draw_colored_polygon(front, Color("141b1d"))
		var rim := front.slice(0, 33)
		ci.draw_polyline(rim, Color(0.85, 0.62, 0.35, 0.45 * glow), 3.0)
	# halftone haze
	ComicArt.halftone(ci, sz, Color(1.0, 0.8, 0.5, 0.05), 16.0, 4.0, Vector2(0.5, 0.35))
	# the giant inkwell podium (its rim is a platform)
	var pc := Vector2(PODIUM.get_center().x, PODIUM.position.y)
	poly(ci, PackedVector2Array([pc + Vector2(-150, 0), pc + Vector2(150, 0), pc + Vector2(110, 70), pc + Vector2(40, 85), pc + Vector2(30, 95), pc + Vector2(-30, 95), pc + Vector2(-40, 85), pc + Vector2(-110, 70)]), Color("1b2226"), 4.0)
	ci.draw_set_transform(pc, 0.0, Vector2(1.0, 0.22))
	ci.draw_circle(Vector2.ZERO, 150.0, INK)
	ci.draw_circle(Vector2.ZERO, 138.0, Color("0a0d10"))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	ci.draw_line(pc + Vector2(-150, 0), pc + Vector2(150, 0), Color("c79a55"), 6.0)
	ci.draw_arc(pc + Vector2(0, 40), 120.0, PI * 1.15, PI * 1.85, 16, Color(1, 0.8, 0.5, 0.25 * glow), 4.0)
	ci.draw_rect(Rect2(pc + Vector2(-120, 95), Vector2(240, FLOOR_Y - pc.y - 95)), Color("161c1f"))
	# quill stands
	for x in [380.0, 900.0]:
		ci.draw_line(Vector2(x, FLOOR_Y), Vector2(x, 440), Color("2a3236"), 6.0)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x, 380), Vector2(x + 14, 430), Vector2(x, 445), Vector2(x - 6, 425)]), Color("d8cbb0"))
	# spotlight cone
	ci.draw_colored_polygon(PackedVector2Array([Vector2(c.x - 60, 0), Vector2(c.x + 60, 0), Vector2(c.x + 320, FLOOR_Y), Vector2(c.x - 320, FLOOR_Y)]), Color(1, 0.85, 0.6, 0.06 * glow))


static func curtains(ci: CanvasItem, sz: Vector2, t: float) -> void:
	# top valance and side drapes
	var top := PackedVector2Array([Vector2(0, 0), Vector2(sz.x, 0), Vector2(sz.x, 40)])
	for k in 20:
		var x := sz.x - k * sz.x / 19.0
		top.append(Vector2(x, 40 + (30.0 if k % 2 == 0 else 8.0) + sin(t * 0.8 + k) * 2.0))
	top.append(Vector2(0, 40))
	poly(ci, top, Color("2d1420"), 4.0)
	for k in 19:
		var x := (k + 0.5) * sz.x / 19.0
		ci.draw_line(Vector2(x, 0), Vector2(x, 60), Color(0, 0, 0, 0.25), 3.0)
	ci.draw_line(Vector2(0, 8), Vector2(sz.x, 8), GOLD, 3.0)
	for side in [0.0, 1.0]:
		var x0 := 0.0 if side == 0.0 else sz.x
		var dir := 1.0 if side == 0.0 else -1.0
		var pts := PackedVector2Array([Vector2(x0, 0)])
		for k in 12:
			var y := k * sz.y / 11.0
			pts.append(Vector2(x0 + dir * (70.0 + 18.0 * sin(y * 0.03 + t * 0.6) + (30.0 if k > 8 else 0.0)), y))
		pts.append(Vector2(x0, sz.y))
		poly(ci, pts, Color("21101a"), 4.0)
		for k in 3:
			ci.draw_line(Vector2(x0 + dir * (18 + k * 18), 0), Vector2(x0 + dir * (24 + k * 20), sz.y), Color(0, 0, 0, 0.3), 3.0)


static func stage_floor(ci: CanvasItem, sz: Vector2) -> void:
	ci.draw_rect(Rect2(0, FLOOR_Y, sz.x, sz.y - FLOOR_Y), Color("15100e"))
	ci.draw_rect(Rect2(0, FLOOR_Y, sz.x, 14), Color("3a2a22"))
	for k in 24:
		var x := k * sz.x / 23.0
		ci.draw_line(Vector2(x, FLOOR_Y + 2), Vector2(x - 6, FLOOR_Y + 14), Color(0, 0, 0, 0.5), 2.0)
	ci.draw_line(Vector2(0, FLOOR_Y), Vector2(sz.x, FLOOR_Y), Color("8a6a4a"), 3.0)
	# ornate stage lip
	for k in 12:
		var cx := 60.0 + k * 106.0
		ci.draw_arc(Vector2(cx, FLOOR_Y + 60), 40.0, PI, TAU, 16, Color("3b2c25"), 6.0)
		ci.draw_circle(Vector2(cx, FLOOR_Y + 40), 6.0, Color("6b5040"))


## Ink spike gates that rise from the floor when the arena locks (0 = down, 1 = up).
static func gate(ci: CanvasItem, x: float, up: float, t: float) -> void:
	if up <= 0.01:
		return
	for k in 4:
		var bx := x + (k - 1.5) * 18.0
		var h := maxf(24.0, (150.0 + (k % 2) * 30.0) * up)
		var pts := PackedVector2Array([Vector2(bx - 6, FLOOR_Y), Vector2(bx - 4, FLOOR_Y - h + 20), Vector2(bx, FLOOR_Y - h), Vector2(bx + 4, FLOOR_Y - h + 20), Vector2(bx + 6, FLOOR_Y)])
		ci.draw_colored_polygon(pts, Color("0b0b10"))
		ci.draw_arc(Vector2(bx + 12, FLOOR_Y - 30), 14.0, PI * 0.5, PI * 1.6, 10, Color("0b0b10"), 5.0)
	if up < 1.0:
		for k in 8:
			var a := k * TAU / 8.0 + t * 4.0
			ci.draw_line(Vector2(x, FLOOR_Y - 10) + Vector2.from_angle(a) * 30.0, Vector2(x, FLOOR_Y - 10) + Vector2.from_angle(a) * 46.0, Color(1, 0.9, 0.6, 0.6 * (1.0 - up)), 3.0)


static func foreground(ci: CanvasItem, sz: Vector2) -> void:
	# dark vignette like a spotlight on a stage
	for k in 6:
		var a := 0.06 + k * 0.03
		ci.draw_rect(Rect2(0, 0, 40 + k * 20, sz.y), Color(0, 0, 0, a))
		ci.draw_rect(Rect2(sz.x - 40 - k * 20, 0, 40 + k * 20, sz.y), Color(0, 0, 0, a))
	ci.draw_rect(Rect2(0, sz.y - 50, sz.x, 50), Color(0, 0, 0, 0.35))


# --- the heroes, side view ----------------------------------------------------------------

## A hero (kind: ComicArt hero index 1 noir, 2 ninja, 3 space) at feet position `f`, facing `dir` (1 or -1).
## pose: idle | run | jump | fall | dash | attack | attack_up | attack_down | hurt | heal
static func hero(ci: CanvasItem, kind: int, f: Vector2, dir: float, pose: String, t: float, flash := 0.0, sc := 1.0) -> void:
	if kind == 0 and _hero_sprite(ci, f, dir, pose, t, flash, sc):
		return
	var main: Color = HERO_MAIN[kind]
	var acc: Color = HERO_ACCENT[kind]
	if flash > 0.0:
		main = main.lerp(Color.WHITE, flash)
		acc = acc.lerp(Color.WHITE, flash)
	ci.draw_set_transform(f + Vector2(0, 2), 0.0, Vector2(sc, 0.25 * sc))
	ci.draw_circle(Vector2.ZERO, 22.0, Color(0, 0, 0, 0.35))
	ci.draw_set_transform(f, 0.0, Vector2(dir * sc, sc))
	var lean := 0.0
	var crouch := 0.0
	match pose:
		"run":
			lean = 0.18
		"dash":
			lean = 0.5
			crouch = 6.0
		"hurt":
			lean = -0.3
		"heal":
			crouch = 8.0
	var hip := Vector2(0, -30 + crouch)
	var neck := hip + Vector2(sin(lean) * 30.0, -cos(lean) * 30.0)
	# legs
	var ph := t * 14.0
	var legs := [Vector2(-7, 0), Vector2(7, 0)]
	if pose == "run":
		legs = [Vector2(sin(ph) * 15.0, -absf(cos(ph)) * 4.0), Vector2(-sin(ph) * 15.0, -absf(sin(ph)) * 4.0)]
	elif pose in ["jump", "attack_up"]:
		legs = [Vector2(-8, -10), Vector2(9, -4)]
	elif pose in ["fall", "attack_down"]:
		legs = [Vector2(-6, 4), Vector2(10, -2)]
	elif pose == "dash":
		legs = [Vector2(-22, -6), Vector2(-10, -2)]
	for k in 2:
		var foot: Vector2 = legs[k]
		ci.draw_line(hip, foot, INK, 11.0)
		ci.draw_line(hip, foot, main.darkened(0.25), 6.5)
	# coat / cape / scarf behind the body
	var flow := sin(t * 9.0) * 4.0 - (10.0 if pose in ["run", "dash"] else 0.0)
	match kind:
		0: # the pulp hero's long torn crimson cape, whipping behind him
			var whip := sin(t * 7.0) * 6.0 + (-16.0 if pose in ["run", "dash"] else 0.0) + (10.0 if pose in ["jump", "fall"] else 0.0)
			var c0 := neck + Vector2(-5, -2)
			var c1 := neck + Vector2(5, 0)
			var c2 := hip + Vector2(-26 + whip, 28)
			var c3 := hip + Vector2(-44 + whip * 1.3, 22)
			poly(ci, PackedVector2Array([c0, c1, c2, c3]), acc, 3.0)
			# torn ends
			ci.draw_colored_polygon(PackedVector2Array([c2, c2.lerp(c3, 0.5) + Vector2(-2, 10), c2.lerp(c3, 0.5)]), acc)
			ci.draw_colored_polygon(PackedVector2Array([c2.lerp(c3, 0.5), c3 + Vector2(-4, 12), c3]), acc)
			ci.draw_line(neck + Vector2(-4, 2), hip + Vector2(-20 + whip, 14), acc.darkened(0.35), 3.0)
		1: # trench coat tails
			poly(ci, PackedVector2Array([neck + Vector2(-6, 4), neck + Vector2(8, 4), hip + Vector2(10, 8), hip + Vector2(-16 + flow, 12)]), main, 3.0)
		2: # long scarf
			ci.draw_polyline(PackedVector2Array([neck + Vector2(-2, 2), neck + Vector2(-20 + flow, 4), neck + Vector2(-36 + flow * 1.5, 10 + sin(t * 12.0) * 3.0)]), acc, 6.0)
		3: # small cape
			poly(ci, PackedVector2Array([neck + Vector2(-4, 2), neck + Vector2(6, 2), hip + Vector2(0, 6), hip + Vector2(-18 + flow, 8)]), acc, 3.0)
	# body
	ci.draw_line(hip, neck, INK, 21.0)
	ci.draw_line(hip, neck, main, 15.0)
	if kind == 2:
		ci.draw_line(hip + Vector2(-5, -6), neck + Vector2(6, 6), acc, 4.0)
	elif kind == 0:
		# gold lightning emblem and a high collar
		var em := (hip + neck) * 0.5 + Vector2(2, -2)
		ci.draw_colored_polygon(PackedVector2Array([em + Vector2(0, -6), em + Vector2(5, 0), em + Vector2(0, 6), em + Vector2(-5, 0)]), GOLD)
		ci.draw_polyline(PackedVector2Array([em + Vector2(1, -4), em + Vector2(-2, 1), em + Vector2(2, 1), em + Vector2(-1, 5)]), Color("e63946"), 1.5)
		poly(ci, PackedVector2Array([neck + Vector2(-9, 4), neck + Vector2(-11, -12), neck + Vector2(-2, -4)]), acc, 2.0)
	# arms: the weapon arm depends on the pose
	var hand := neck + Vector2(10, 14)
	match pose:
		"attack":
			hand = neck + Vector2(22, 2)
		"attack_up":
			hand = neck + Vector2(4, -22)
		"attack_down":
			hand = neck + Vector2(8, 24)
		"heal":
			hand = neck + Vector2(4, 4)
		"dash":
			hand = neck + Vector2(18, 8)
	ci.draw_line(neck + Vector2(0, 3), hand, INK, 9.0)
	ci.draw_line(neck + Vector2(0, 3), hand, main, 5.0)
	_weapon(ci, kind, hand, pose)
	# head
	var head := neck + Vector2(3, -13)
	match kind:
		0: # the pulp hero: swept black hair, domino mask, glowing white eyes
			ci.draw_circle(head, 12.5, INK)
			ci.draw_circle(head, 10.5, Color("e8b48a") if flash <= 0.0 else Color.WHITE)
			ci.draw_colored_polygon(PackedVector2Array([head + Vector2(-12, -2), head + Vector2(-10, -12), head + Vector2(2, -15), head + Vector2(13, -9), head + Vector2(10, -6), head + Vector2(-4, -8)]), INK)
			ci.draw_colored_polygon(PackedVector2Array([head + Vector2(-9, -10), head + Vector2(-21, -17), head + Vector2(-5, -14)]), INK)
			ci.draw_rect(Rect2(head + Vector2(-6, -5), Vector2(18, 6)), INK)
			ci.draw_circle(head + Vector2(7, -2), 4.0, Color(1, 1, 1, 0.35))
			ci.draw_circle(head + Vector2(7, -2), 2.2, Color.WHITE)
			ci.draw_line(head + Vector2(4, 5), head + Vector2(10, 4), INK, 2.0)
		1: # noir detective: skin, fedora
			ci.draw_circle(head, 12.0, INK)
			ci.draw_circle(head, 10.0, Color("ffd2a6") if flash <= 0.0 else Color.WHITE)
			poly(ci, PackedVector2Array([head + Vector2(-17, -5), head + Vector2(17, -5), head + Vector2(14, -9), head + Vector2(-14, -9)]), acc, 2.0)
			poly(ci, PackedVector2Array([head + Vector2(-9, -8), head + Vector2(-8, -20), head + Vector2(0, -16), head + Vector2(8, -20), head + Vector2(9, -8)]), acc, 2.0)
			ci.draw_circle(head + Vector2(5, 0), 2.0, INK)
		2: # ninja: hooded mask, eye slit, headband
			ci.draw_circle(head, 12.0, INK)
			ci.draw_circle(head, 10.0, main)
			ci.draw_rect(Rect2(head + Vector2(-1, -4), Vector2(11, 5)), Color("ffd2a6"))
			ci.draw_circle(head + Vector2(6, -2), 1.8, INK)
			ci.draw_line(head + Vector2(-11, -8), head + Vector2(10, -8), acc, 4.0)
			ci.draw_line(head + Vector2(-10, -8), head + Vector2(-26 + flow, -12 + sin(t * 14.0) * 3.0), acc, 3.0)
		3: # space hero: big white helmet like a mask, visor, antenna
			ci.draw_circle(head, 14.0, INK)
			ci.draw_circle(head, 12.0, Color("f8f9fa"))
			ci.draw_rect(Rect2(head + Vector2(0, -5), Vector2(11, 8)), Color("2ec4b6"))
			ci.draw_line(head + Vector2(-4, -12), head + Vector2(-10, -26), INK, 2.5)
			ci.draw_circle(head + Vector2(-10, -27), 3.5, Color("e63946"))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The painted pulp hero (Antigravity's sprite frames), if they exist.
static func _hero_sprite(ci: CanvasItem, f: Vector2, dir: float, pose: String, t: float, flash: float, sc: float) -> bool:
	var key := "hero_idle"
	var squash := 1.0 + sin(t * 3.0) * 0.015
	var rot := 0.0
	var bob := 0.0
	match pose:
		"run":
			key = "hero_run1" if int(t * 9.0) % 2 == 0 else "hero_run2"
			squash = 1.0 + absf(sin(t * 28.0)) * 0.03
			bob = -absf(sin(t * 28.0)) * 4.0 * sc
			rot = 0.07 * dir
		"jump", "fall", "attack_down":
			key = "hero_jump"
		"attack", "attack_up":
			key = "hero_attack"
			rot = -0.2 * dir if pose == "attack_up" else 0.1 * dir
			squash = 0.95
		"dash":
			key = "hero_dash"
		"hurt":
			key = "hero_hurt"
	if not Sprites.has(key):
		key = "hero_idle"
	if land_squash > 0.0:
		squash *= 1.0 - 0.18 * land_squash
	var tint := Color(1, 1, 1, 0.55) if flash > 0.0 else Color.WHITE
	return Sprites.draw(ci, key, f + Vector2(0, 4 + bob), 128.0 * sc, dir, tint, squash, rot)


static func _weapon(ci: CanvasItem, kind: int, hand: Vector2, pose: String) -> void:
	var tip := hand + Vector2(30, -6)
	if pose == "attack_up":
		tip = hand + Vector2(4, -32)
	elif pose == "attack_down":
		tip = hand + Vector2(6, 32)
	elif pose in ["idle", "run", "jump", "fall", "hurt", "heal"]:
		tip = hand + Vector2(18, 20)
	match kind:
		0: # blade of light
			var tip2 := hand + (tip - hand) * 1.5
			ci.draw_line(hand, tip2, Color(1, 0.95, 0.7, 0.35), 9.0)
			ci.draw_line(hand, tip2, Color("fff6d5"), 3.5)
			ci.draw_line(hand - (tip - hand).normalized() * 8.0, hand, INK, 5.0)
			ci.draw_circle(hand, 3.5, GOLD)
		1: # torch-baton
			ci.draw_line(hand, tip, INK, 7.0)
			ci.draw_line(hand, tip, Color("6b6f80"), 4.0)
			ci.draw_circle(tip, 5.0, Color("fff3b0"))
		2: # katana of light
			ci.draw_line(hand, tip + (tip - hand) * 0.3, INK, 5.0)
			ci.draw_line(hand, tip + (tip - hand) * 0.3, Color("e0fbfc"), 2.5)
		3: # prism blade
			ci.draw_line(hand, tip, INK, 6.0)
			ci.draw_line(hand, tip, Color("2ec4b6"), 3.0)
			ci.draw_circle(hand, 4.0, Color("ff70a6"))


## The white crescent of a slash (the arc follows the attack direction).
static func slash(ci: CanvasItem, c: Vector2, dir: Vector2, k: float, big := false) -> void:
	var a := dir.angle()
	var r := 62.0 if not big else 90.0
	var span := 1.6
	var pts := PackedVector2Array()
	var n := 14
	for i in n + 1:
		var u := float(i) / n
		pts.append(c + Vector2.from_angle(a - span * 0.5 + span * u) * r)
	for i in n + 1:
		var u := 1.0 - float(i) / n
		var thick := maxf(1.5, sin(u * PI) * (16.0 if not big else 26.0))
		pts.append(c + Vector2.from_angle(a - span * 0.5 + span * u) * (r - thick))
	var alpha := clampf(1.0 - k, 0.0, 1.0)
	ci.draw_colored_polygon(pts, Color(1, 1, 1, 0.95 * alpha))
	ci.draw_arc(c, r + 4.0, a - span * 0.5, a + span * 0.5, 16, Color(1, 0.9, 0.6, 0.5 * alpha), 3.0)


## A white starburst where a hit lands.
static func hit_spark(ci: CanvasItem, c: Vector2, k: float, size := 1.0) -> void:
	var alpha := clampf(1.0 - k, 0.0, 1.0)
	for i in 10:
		var a := i * TAU / 10.0 + 0.3
		var len := (24.0 + (i % 3) * 18.0) * size * (0.6 + k)
		ci.draw_line(c + Vector2.from_angle(a) * 8.0 * size, c + Vector2.from_angle(a) * len, Color(1, 1, 1, alpha), 4.0 * size * alpha + 1.0)
	ci.draw_circle(c, 14.0 * size * alpha, Color(1, 1, 0.9, alpha))
