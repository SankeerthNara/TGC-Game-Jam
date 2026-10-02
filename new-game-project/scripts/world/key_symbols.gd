class_name KeySymbols
extends RefCounted
## Small vector icons for keys (door keyholes) and the three collectible item types.
## Everything is drawn with CanvasItem primitives, so there are no image assets to credit.

const ITEM_COLORS := {"ink": Color("3a86ff"), "gear": Color("adb5bd"), "shard": Color("ffd23f")}
const ITEM_NAMES := {"ink": "INK DROP", "gear": "GEAR", "shard": "STAR SHARD"}


static func _poly(c: CanvasItem, pts: Array, center: Vector2, r: float, col: Color) -> void:
	var out := PackedVector2Array()
	for p: Vector2 in pts:
		out.append(center + p * r)
	c.draw_colored_polygon(out, col)


## Draws the key symbol `id` centred at `center`, `r` is its radius in pixels.
static func draw_key(c: CanvasItem, id: String, center: Vector2, r: float, fg: Color, bg: Color) -> void:
	match id:
		"star":
			var pts := PackedVector2Array()
			for k in 10:
				var rad := r if k % 2 == 0 else r * 0.42
				var a := -PI / 2.0 + k * PI / 5.0
				pts.append(center + Vector2(cos(a), sin(a)) * rad)
			c.draw_colored_polygon(pts, fg)
		"moon":
			c.draw_circle(center, r, fg)
			c.draw_circle(center + Vector2(r * 0.5, -r * 0.2), r * 0.82, bg)
		"bolt":
			_poly(c, [Vector2(0.2, -1.0), Vector2(-0.55, 0.15), Vector2(-0.1, 0.15), Vector2(-0.3, 1.0), Vector2(0.55, -0.25), Vector2(0.05, -0.25)], center, r, fg)
		"zigzag":
			_poly(c, [Vector2(0.2, -1.0), Vector2(-0.5, -0.1), Vector2(-0.05, -0.1), Vector2(-0.4, 0.5), Vector2(0.0, 0.5), Vector2(-0.3, 1.0), Vector2(0.5, 0.1), Vector2(0.1, 0.1), Vector2(0.45, -0.45), Vector2(0.05, -0.45)], center, r, fg)
		"sun":
			c.draw_circle(center, r * 0.5, fg)
			for k in 8:
				var d := Vector2.from_angle(k * TAU / 8.0)
				c.draw_line(center + d * r * 0.68, center + d * r, fg, maxf(2.0, r * 0.16))
		"flower":
			for k in 6:
				c.draw_circle(center + Vector2.from_angle(k * TAU / 6.0) * r * 0.58, r * 0.36, fg)
			c.draw_circle(center, r * 0.26, bg)
		"gear":
			for k in 8:
				var d := Vector2.from_angle(k * TAU / 8.0)
				c.draw_line(center + d * r * 0.55, center + d * r, fg, maxf(3.0, r * 0.3))
			c.draw_circle(center, r * 0.72, fg)
			c.draw_circle(center, r * 0.28, bg)
		"crown":
			_poly(c, [Vector2(-1, 0.55), Vector2(-1, -0.55), Vector2(-0.5, -0.05), Vector2(0, -0.85), Vector2(0.5, -0.05), Vector2(1, -0.55), Vector2(1, 0.55)], center, r, fg)
			c.draw_rect(Rect2(center + Vector2(-1.0, 0.4) * r, Vector2(2.0, 0.3) * r), bg)
		_:
			c.draw_circle(center, r, fg)


## Draws a collectible item icon.
static func draw_item(c: CanvasItem, type: String, center: Vector2, r: float, outline: Color) -> void:
	var col: Color = ITEM_COLORS.get(type, Color.WHITE)
	match type:
		"ink":
			c.draw_circle(center + Vector2(0, r * 0.25), r * 0.72, outline)
			_poly(c, [Vector2(0, -1.15), Vector2(0.62, 0.0), Vector2(-0.62, 0.0)], center, r * 1.05, outline)
			c.draw_circle(center + Vector2(0, r * 0.25), r * 0.6, col)
			_poly(c, [Vector2(0, -0.95), Vector2(0.5, 0.0), Vector2(-0.5, 0.0)], center, r * 1.0, col)
			c.draw_circle(center + Vector2(-r * 0.2, r * 0.1), r * 0.14, Color(1, 1, 1, 0.8))
		"gear":
			draw_key(c, "gear", center, r * 1.05, outline, outline)
			draw_key(c, "gear", center, r * 0.9, col, Color("5a5f66"))
		"shard":
			_poly(c, [Vector2(0, -1.1), Vector2(0.75, 0.0), Vector2(0, 1.1), Vector2(-0.75, 0.0)], center, r * 1.05, outline)
			_poly(c, [Vector2(0, -0.95), Vector2(0.62, 0.0), Vector2(0, 0.95), Vector2(-0.62, 0.0)], center, r, col)
			c.draw_line(center + Vector2(0, -r * 0.95), center + Vector2(0, r * 0.95), Color(1, 1, 1, 0.5), 1.5)
			c.draw_line(center + Vector2(-r * 0.62, 0), center + Vector2(r * 0.62, 0), Color(1, 1, 1, 0.5), 1.5)
		_:
			c.draw_circle(center, r, col)
