class_name StoryPanels
extends RefCounted
## What each named comic panel shows. If `res://assets/story/<key>.png` exists it is shown instead
## (so drawn, CC0 or generated art can be swapped in without touching code).

const A := preload("res://scripts/story/comic_art.gd")


static func draw(ci: CanvasItem, key: String, sz: Vector2, t: float, params: Dictionary) -> void:
	var c := sz * 0.5
	match key:
		"earth_peace":
			A.fill_bg(ci, sz, Color("0b2a5b"), Color("1b4f9c"))
			A.stars(ci, sz, t)
			A.halftone(ci, sz, Color(1, 1, 1, 0.07), 18.0, 6.0, Vector2(1, 0))
			var eo := Vector2(sz.x * 0.62, sz.y * 0.58)
			A.earth(ci, eo, sz.y * 0.36, 0.0, t)
			for i in 4:
				var a := t * 0.7 + i * TAU / 4.0
				var p := eo + Vector2(cos(a) * sz.y * 0.62, sin(a) * sz.y * 0.22)
				var v := Vector2(-sin(a) * sz.y * 0.62, cos(a) * sz.y * 0.22)
				if sin(a) > -0.2 or true:
					A.hero_tiny(ci, i, p, 1.1, v.normalized())
		"hero_portrait_0", "hero_portrait_1", "hero_portrait_2", "hero_portrait_3":
			var k := int(key.right(1))
			A.burst(ci, sz, Vector2(sz.x * 0.5, sz.y * 0.45), A.HERO_ACCENT[k].lightened(0.35), A.HERO_ACCENT[k].lightened(0.15), 16, t * 0.2)
			A.halftone(ci, sz, Color(0, 0, 0, 0.12), 12.0, 4.0, Vector2(0, 1))
			A.hero_bust(ci, k, Vector2(sz.x * 0.5, sz.y * 0.42 + sin(t * 2.0 + k) * 3.0), sz.y / 330.0, "determined", t)
		"villain_rise":
			var flash := fposmod(t, 1.7) < 0.08
			A.fill_bg(ci, sz, Color("10002b") if not flash else Color("c8b6ff"), Color("3c096c"))
			A.halftone(ci, sz, Color(0.8, 0.5, 1.0, 0.18), 16.0, 6.0, Vector2(0.5, 1))
			if flash:
				ci.draw_polyline(PackedVector2Array([Vector2(sz.x * 0.2, 0), Vector2(sz.x * 0.28, sz.y * 0.2), Vector2(sz.x * 0.22, sz.y * 0.25), Vector2(sz.x * 0.32, sz.y * 0.5)]), Color.WHITE, 6.0)
			var rise := clampf(t / 1.2, 0.0, 1.0)
			var ease := 1.0 - pow(1.0 - rise, 3.0)
			A.narrator(ci, Vector2(sz.x * 0.5, sz.y * (1.1 - 0.72 * ease)), sz.y / 330.0, 0.0, "grin", t)
		"earth_darkening":
			A.fill_bg(ci, sz, Color("0b1d3a"), Color("07030c"))
			A.stars(ci, sz, t, 5, 40)
			A.earth(ci, c, sz.y * 0.36, clampf(t / 2.5, 0.0, 1.0), t)
		"heroes_shock":
			A.fill_bg(ci, sz, Color("fff3d1"), Color("ffe08a"))
			A.speed_lines(ci, sz, c, t, Color(0, 0, 0, 0.18))
			for i in 4:
				A.hero_bust(ci, i, Vector2(sz.x * (0.14 + i * 0.24), sz.y * 0.5 + (i % 2) * 12.0), sz.y / 420.0, "shock", t)
		"bomb_closeup":
			var shake := Vector2(sin(t * 50.0), cos(t * 43.0)) * 2.0
			A.burst(ci, sz, c, Color("3a0008"), Color("6a040f"), 22, t * 0.3)
			A.halftone(ci, sz, Color(1, 0.3, 0.3, 0.15), 14.0, 5.0, Vector2(0.5, 0.5))
			A.bomb(ci, c + Vector2(0, sz.y * 0.08) + shake, sz.y * 0.32, float(params.get("bomb_secs", 1020.0)), t)
		"door_locked":
			A.fill_bg(ci, sz, Color("1b1b2f"), Color("3a3a55"))
			A.halftone(ci, sz, Color(1, 1, 1, 0.06), 14.0, 5.0, Vector2(0.5, 0))
			var dr := Rect2(Vector2(sz.x * 0.3, sz.y * 0.12), Vector2(sz.x * 0.4, sz.y * 0.8))
			A.door(ci, dr, 0.0, 0.0)
		"hero_ready":
			A.fill_bg(ci, sz, Color("1a1423"), Color("3d2c1e"))
			ci.draw_circle(Vector2(sz.x * 0.72, sz.y * 0.3), sz.y * 0.5, Color(1, 0.75, 0.3, 0.18))
			ci.draw_circle(Vector2(sz.x * 0.72, sz.y * 0.3), sz.y * 0.28, Color(1, 0.8, 0.4, 0.2))
			A.hero_bust(ci, 0, Vector2(sz.x * 0.42, sz.y * 0.4), sz.y / 320.0, "determined", t)
			var torch := Vector2(sz.x * 0.72, sz.y * 0.3)
			ci.draw_line(torch + Vector2(-10, 120), torch + Vector2(0, 20), Color("6b4226"), 12.0)
			A._star(ci, torch + Vector2(0, 5), 26.0 + sin(t * 12.0) * 4.0, Color("ffb703"), 3.0)
		"door_unlock":
			A.fill_bg(ci, sz, Color("1b1b2f"), Color("3a3a55"))
			var dr2 := Rect2(Vector2(sz.x * 0.36, sz.y * 0.1), Vector2(sz.x * 0.28, sz.y * 0.82))
			A.door(ci, dr2, t / 0.45, clampf((t - 2.1) / 0.6, 0.0, 1.0))
		"bomb_room_bomb":
			A.fill_bg(ci, sz, Color("12061f"), Color("3a0008"))
			var glow := 0.5 + 0.5 * sin(t * 5.0)
			ci.draw_circle(c, sz.y * 0.48, Color(1, 0.1, 0.1, 0.12 + 0.08 * glow))
			A.halftone(ci, sz, Color(1, 0.2, 0.2, 0.14), 14.0, 5.0, Vector2(0.5, 1))
			A.bomb(ci, c + Vector2(0, sz.y * 0.08), minf(sz.x, sz.y) * 0.3, float(params.get("bomb_left", 180.0)), t)
		"masked_closeup":
			A.fill_bg(ci, sz, Color("240046"), Color("10002b"))
			A.halftone(ci, sz, Color(0.8, 0.5, 1.0, 0.2), 12.0, 5.0, Vector2(1, 1))
			A.narrator(ci, Vector2(sz.x * 0.5, sz.y * 0.4), sz.y / 300.0, 0.0, "grin", t)
		"unmask":
			A.burst(ci, sz, Vector2(sz.x * 0.5, sz.y * 0.4), Color("ffd23f"), Color("ffb703"), 18, t * 0.4)
			var off := clampf((t - 0.7) / 0.7, 0.0, 1.0)
			A.narrator(ci, Vector2(sz.x * 0.5, sz.y * 0.42), sz.y / 300.0, off, "grin", t)
		"narrator_reveal":
			A.burst(ci, sz, Vector2(sz.x * 0.5, sz.y * 0.5), Color("5a189a"), Color("7b2cbf"), 22, -t * 0.3)
			A.halftone(ci, sz, Color(1, 0.85, 0.3, 0.2), 14.0, 6.0, Vector2(0.5, 0.5))
			var zoom := 1.0 + 0.05 * t
			A.narrator(ci, Vector2(sz.x * 0.5, sz.y * 0.48), sz.y / 280.0 * zoom, 1.0, "grin", t)
		"grab":
			A.fill_bg(ci, sz, Color("fff3d1"), Color("ffd6a5"))
			A.speed_lines(ci, sz, Vector2(sz.x * 0.35, sz.y * 0.45), t, Color(0, 0, 0, 0.25))
			var close := clampf((t - 0.5) / 0.4, 0.0, 1.0)
			A.hero_bust(ci, 0, Vector2(sz.x * 0.33, sz.y * 0.42 - close * 20.0), sz.y / 380.0, "scared", t)
			A.grab_hand(ci, Vector2(lerpf(sz.x * 1.1, sz.x * 0.5, minf(t / 0.5, 1.0)), sz.y * 0.55), sz.y / 380.0, close)
		"caged":
			A.fill_bg(ci, sz, Color("10002b"), Color("3c096c"))
			A.halftone(ci, sz, Color(0.8, 0.5, 1.0, 0.18), 12.0, 5.0, Vector2(0, 1))
			var sway := sin(t * 2.0) * 0.04
			ci.draw_line(Vector2(sz.x * 0.5, 0), Vector2(sz.x * 0.5, sz.y * 0.12), A.INK, 6.0)
			ci.draw_set_transform(Vector2(sz.x * 0.5, 0), sway, Vector2.ONE)
			A.hero_bust(ci, 0, Vector2(0, sz.y * 0.45), sz.y / 520.0, "scared", t)
			A.cage(ci, Vector2(0, sz.y * 0.55), sz.y / 300.0)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"bomb_zero":
			var red := int(t * 6.0) % 2 == 0
			A.burst(ci, sz, c, Color("6a040f") if red else Color("1a0003"), Color("9d0208") if red else Color("370617"), 20, 0.0)
			A.bomb(ci, c + Vector2(0, sz.y * 0.08), sz.y * 0.32, 0.0, t, true)
		"heroes_too_late":
			A.fill_bg(ci, sz, Color("1b1b2f"), Color("3a3a55"))
			var dr3 := Rect2(Vector2(sz.x * 0.82, sz.y * 0.15), Vector2(sz.x * 0.12, sz.y * 0.75))
			A.door(ci, dr3, 0.0, 0.0)
			A.speed_lines(ci, sz, Vector2(sz.x * 0.9, sz.y * 0.5), t, Color(1, 1, 1, 0.1))
			for i in 4:
				A.hero_tiny(ci, i, Vector2(sz.x * (0.12 + i * 0.13) + t * 40.0, sz.y * (0.4 + (i % 2) * 0.22)), 1.6, Vector2.RIGHT)
		"boom":
			A.fill_bg(ci, sz, Color("07030c"), Color("1a0b2e"))
			A.stars(ci, sz, t)
			var p := t
			for k in 5:
				var rr := p * (sz.y * 0.9 + k * sz.y * 0.3)
				ci.draw_circle(c, rr, Color(1, 0.65 - k * 0.1, 0.1, maxf(0.0, 0.55 - p * 0.12)))
			for i in 20:
				var a := i * TAU / 20.0 + 0.3
				var d := p * sz.y * (0.35 + (i % 5) * 0.12)
				var o := c + Vector2.from_angle(a) * d
				ci.draw_set_transform(o, p * (1.0 + i % 3), Vector2.ONE)
				A.poly(ci, PackedVector2Array([Vector2(-20, -14), Vector2(18, -18), Vector2(22, 12), Vector2(-12, 20)]), Color("2dc653") if i % 3 == 0 else Color("3a86ff"), 3.0)
				ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			var white := clampf(1.0 - p / 0.5, 0.0, 1.0)
			if white > 0.0:
				ci.draw_rect(Rect2(Vector2.ZERO, sz), Color(1, 1, 1, white))
		"solar_flare":
			A.burst(ci, sz, Vector2(sz.x * 0.75, sz.y * 0.3), Color("ffd23f"), Color("fff3b0"), 24, t * 0.5)
			var glow := clampf(t / 1.2, 0.0, 1.0)
			ci.draw_circle(Vector2(sz.x * 0.75, sz.y * 0.3), sz.y * (0.15 + 0.5 * glow), Color(1, 1, 0.85, 0.6))
			A.hero_bust(ci, 3, Vector2(sz.x * 0.35, sz.y * 0.45), sz.y / 330.0, "determined", t)
			for k in 3:
				var d := Vector2.from_angle(-0.5 + (k - 1) * 0.12)
				ci.draw_line(Vector2(sz.x * 0.45, sz.y * 0.5), Vector2(sz.x * 0.45, sz.y * 0.5) + d * sz.x, Color(1, 1, 0.9, 0.8), 14.0 - k * 3.0)
		"narrator_melt":
			A.fill_bg(ci, sz, Color("fff3b0"), Color("ffd23f"))
			A.halftone(ci, sz, Color(1, 0.6, 0.0, 0.25), 14.0, 5.0, Vector2(0.5, 1))
			var melt := clampf((t - 0.6) / 2.4, 0.0, 1.0)
			var col := Color(1, 1, 1, 1.0 - melt)
			ci.draw_set_transform(Vector2(sz.x * 0.5, sz.y * (0.42 + 0.25 * melt)), 0.0, Vector2(1.0 + melt * 0.3, 1.0 - melt * 0.7))
			A.narrator(ci, Vector2.ZERO, sz.y / 330.0, 1.0, "shock", t)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			ci.draw_rect(Rect2(Vector2.ZERO, sz), Color(1, 0.95, 0.7, melt * 0.8))
			for k in 24:
				var px := sz.x * (0.25 + 0.5 * fposmod(k * 0.37, 1.0))
				var py := sz.y * (0.75 - fposmod(t * 0.25 + k * 0.13, 0.7))
				ci.draw_circle(Vector2(px, py), 4.0 + (k % 3) * 2.0, Color(0.48, 0.17, 0.75, 0.6 * (1.0 - melt * 0.5)))
		"hero_freed":
			A.burst(ci, sz, Vector2(sz.x * 0.5, sz.y * 0.45), Color("8ecae6"), Color("bde0fe"), 18, t * 0.3)
			A.hero_bust(ci, 0, Vector2(sz.x * 0.5, sz.y * 0.42), sz.y / 340.0, "calm", t)
			# the broken cage lies open
			for b in 4:
				ci.draw_line(Vector2(sz.x * (0.1 + b * 0.06), sz.y * 0.95), Vector2(sz.x * (0.05 + b * 0.07), sz.y * 0.7), A.INK, 7.0)
		"earth_sunlit":
			A.fill_bg(ci, sz, Color("4cc9f0"), Color("1b4f9c"))
			ci.draw_circle(Vector2(sz.x * 0.85, sz.y * 0.18), sz.y * 0.12, Color("ffd23f"))
			for k in 12:
				var a := k * TAU / 12.0 + t * 0.2
				ci.draw_line(Vector2(sz.x * 0.85, sz.y * 0.18) + Vector2.from_angle(a) * sz.y * 0.15, Vector2(sz.x * 0.85, sz.y * 0.18) + Vector2.from_angle(a) * sz.y * 0.24, Color("ffd23f"), 6.0)
			var eo := Vector2(sz.x * 0.45, sz.y * 0.58)
			A.earth(ci, eo, sz.y * 0.28, 0.0, t)
			for i in 4:
				var a2 := t * 0.6 + i * TAU / 4.0
				A.hero_tiny(ci, i, eo + Vector2(cos(a2) * sz.y * 0.48, sin(a2) * sz.y * 0.16), 1.0, Vector2(-sin(a2), cos(a2) * 0.35).normalized())
		"lava_drop":
			A.fill_bg(ci, sz, Color("3a0008"), Color("ff5400"))
			var drop := clampf((t - 0.6) / 1.6, 0.0, 1.0)
			for k in 8:
				var x := sz.x * (k / 7.0)
				ci.draw_circle(Vector2(x, sz.y * 0.95 + sin(t * 3.0 + k) * 8.0), sz.y * 0.16, Color("ff7b00"))
			ci.draw_rect(Rect2(0, sz.y * 0.88, sz.x, sz.y * 0.2), Color("ff9e00"))
			var cage_c := Vector2(sz.x * 0.62, sz.y * (0.3 + 0.55 * drop * drop))
			ci.draw_line(Vector2(sz.x * 0.62, 0), cage_c + Vector2(0, -sz.y * 0.2), A.INK, 5.0 if drop < 0.3 else 0.0)
			A.hero_bust(ci, 0, cage_c + Vector2(0, -10), sz.y / 700.0, "scared", t)
			A.cage(ci, cage_c, sz.y / 600.0)
			A.narrator(ci, Vector2(sz.x * 0.2, sz.y * 0.35), sz.y / 520.0, 1.0, "grin", t)
		"earth_dark":
			A.fill_bg(ci, sz, Color("07030c"), Color("1a0b2e"))
			A.stars(ci, sz, t, 9, 40)
			A.earth(ci, Vector2(sz.x * 0.5, sz.y * 0.52), sz.y * 0.3, 1.0, t)
		"book_cover":
			A.fill_bg(ci, sz, Color("1a120c"), Color("0a0705"))
			ci.draw_circle(Vector2(sz.x * 0.75, sz.y * 0.1), sz.y * 0.6, Color(1, 0.75, 0.4, 0.12))
			var bk := Rect2(sz * Vector2(0.28, 0.12), sz * Vector2(0.44, 0.78))
			ci.draw_rect(Rect2(bk.position + Vector2(14, 14), bk.size), Color(0, 0, 0, 0.5))
			A.poly(ci, PackedVector2Array([bk.position, Vector2(bk.end.x, bk.position.y), bk.end, Vector2(bk.position.x, bk.end.y)]), Color("6a1b1b"), 6.0)
			ci.draw_rect(Rect2(bk.position + Vector2(18, 18), bk.size - Vector2(36, 36)), Color("ffd23f"), false, 3.0)
			A.halftone(ci, sz, Color(1, 0.8, 0.5, 0.06), 16.0, 4.0, Vector2(0.75, 0.1))
		"op_peace":
			draw(ci, "earth_peace", sz, t, params)
		"op_heroes":
			A.burst(ci, sz, Vector2(sz.x * 0.5, sz.y * 0.5), Color("ffd23f"), Color("ffe58f"), 18, t * 0.2)
			for i in 4:
				var order: int = [1, 0, 2, 3][i]
				var big := order == 0
				A.hero_bust(ci, order, Vector2(sz.x * (0.14 + i * 0.24), sz.y * (0.42 if big else 0.5)), sz.y / (330.0 if big else 450.0), "determined", t)
		"op_villain":
			draw(ci, "villain_rise", sz, t, params)
		"op_capture":
			A.fill_bg(ci, sz, Color("10002b"), Color("3c096c"))
			for i in 3:
				var cc := Vector2(sz.x * (0.2 + i * 0.3), sz.y * (0.45 + (i % 2) * 0.1) + sin(t * 2.0 + i) * 6.0)
				ci.draw_line(Vector2(cc.x, 0), cc + Vector2(0, -sz.y * 0.22), A.INK, 5.0)
				A.hero_bust(ci, i + 1, cc + Vector2(0, -6), sz.y / 760.0, "scared", t)
				A.cage(ci, cc, sz.y / 640.0)
		"op_escape":
			A.burst(ci, sz, Vector2(sz.x * 0.7, sz.y * 0.3), Color("0d1b2a"), Color("1b263b"), 16, t * 0.3)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(sz.x * 0.62, 0), Vector2(sz.x * 0.78, 0), Vector2(sz.x * 0.55, sz.y), Vector2(sz.x * 0.4, sz.y)]), Color(1, 0.95, 0.75, 0.5))
			A.speed_lines(ci, sz, Vector2(sz.x * 0.5, sz.y * 0.5), t, Color(1, 1, 1, 0.12))
			A.hero_bust(ci, 0, Vector2(sz.x * 0.48, sz.y * 0.42), sz.y / 330.0, "determined", t)
		"op_comms":
			A.fill_bg(ci, sz, Color("0b0f14"), Color("1b2a33"))
			A.hero_bust(ci, 0, Vector2(sz.x * 0.4, sz.y * 0.5), sz.y / 360.0, "determined", t)
			var dev := Rect2(Vector2(sz.x * 0.6, sz.y * 0.62), Vector2(sz.x * 0.18, sz.y * 0.24))
			ci.draw_rect(dev, Color("2b2d42"))
			ci.draw_rect(dev, A.INK, false, 4.0)
			ci.draw_rect(dev.grow(-10.0), Color(0.3, 0.9, 1.0, 0.35 + 0.2 * sin(t * 6.0)))
			for k in 3:
				ci.draw_arc(dev.get_center(), 30.0 + k * 22.0 + fposmod(t * 40.0, 22.0), -0.8, 0.8, 10, Color(0.3, 0.9, 1.0, 0.5 - k * 0.12), 3.0)
		_:
			ci.draw_rect(Rect2(Vector2.ZERO, sz), Color("ff00ff"))
