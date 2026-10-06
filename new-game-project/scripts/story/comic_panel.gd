class_name ComicPanel
extends Control
## One comic panel of a story page. Draws its art clipped to the panel. If a picture named
## `res://assets/story/<key>.png` exists it is shown (slowly zooming) instead of the drawn art.

const ART_DIR := "res://assets/story/"
## Corners of the comic's cover inside book_cover.png (fractions of the picture).
const COVER_QUAD := [Vector2(0.301, 0.213), Vector2(0.709, 0.192), Vector2(0.723, 0.809), Vector2(0.289, 0.830)]

var key := ""
var params := {}
var art := {} ## a cinematic panel from the painted art (see _draw_art)
var t := 0.0
var _tex: Texture2D


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for path in [ART_DIR + key + ".png", "res://assets/editions/book/" + key + ".png"]:
		if ResourceLoader.exists(path):
			_tex = load(path)
			break


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if not art.is_empty():
		_draw_art()
		return
	if _tex != null:
		# cover the panel, with a slow push-in
		var ts := _tex.get_size()
		var k := maxf(size.x / ts.x, size.y / ts.y) * (1.0 + 0.03 * t)
		var ds := ts * k
		var at := (size - ds) * 0.5
		draw_texture_rect(_tex, Rect2(at, ds), false)
		if key == "book_cover":
			_cover_fx(at, ds)
			if params.get("quill", false):
				_draw_broken_quill(at, ds)
		return
	StoryPanels.draw(self, key, size, t, params)


## The cover's corners in the parent's coordinates (the cutscene swings the cover open with them).
func cover_quad_in_parent() -> PackedVector2Array:
	var out := PackedVector2Array()
	if _tex == null:
		return out
	var ts := _tex.get_size()
	var k := maxf(size.x / ts.x, size.y / ts.y) * (1.0 + 0.03 * t)
	var ds := ts * k
	var at := (size - ds) * 0.5
	for c: Vector2 in COVER_QUAD:
		out.append(position + pivot_offset + (at + c * ds - pivot_offset) * scale)
	return out


func texture() -> Texture2D:
	return _tex


## The closed comic on the desk: a gleam slides over its cover now and then, dust drifts in the lamp light.
func _cover_fx(at: Vector2, ds: Vector2) -> void:
	var quad := PackedVector2Array()
	for c: Vector2 in COVER_QUAD:
		quad.append(at + c * ds)
	var g := fposmod(t - 0.7, 4.5) / 0.9
	if g < 1.0:
		var x := lerpf(quad[0].x - 260.0, quad[1].x + 120.0, g)
		var band := PackedVector2Array([Vector2(x, 0), Vector2(x + 70.0, 0), Vector2(x - 130.0, size.y), Vector2(x - 200.0, size.y)])
		for poly in Geometry2D.intersect_polygons(band, quad):
			if poly.size() >= 3 and not Geometry2D.triangulate_polygon(poly).is_empty():
				draw_colored_polygon(poly, Color(1, 0.97, 0.85, 0.22 * sin(g * PI)))
	for i in 22:
		var rx := fposmod(i * 0.618034, 1.0)
		var ry := fposmod(i * 0.414214 + t * (0.025 + 0.012 * (i % 3)), 1.0)
		var p := Vector2(rx * size.x + sin(t * 0.8 + i) * 14.0, (1.0 - ry) * size.y)
		draw_circle(p, 1.4 + (i % 3) * 0.8, Color(1, 0.88, 0.62, 0.28 * sin(ry * PI)))


# --- cinematic art panels ---------------------------------------------------------------------------
# A panel built from the painted art (backgrounds, sprites, portraits) with a slow camera move and an
# effect. `art` keys: bg / bg2 (cover the panel), bg_col, crop [path, centre (fraction of the picture),
# height (fraction of the picture)], figs [[path, feet (fraction of the panel), height, flip, tint]],
# cam / cam2 [focus (fraction of the panel), zoom] over dur seconds, fx (+ fx_at, fx_t, fx_size).

const TEX_GLOW := preload("res://assets/art/radial_glow.png")
const QUILL_SRC := "res://assets/editions/sprites/masked_villain.png"
const QUILL_REGION := Rect2(0.6, 0.165, 0.19, 0.157) ## the quill's feather in masked_villain.png (fractions)

var _art_tex := {}
var _cam_xf := Transform2D.IDENTITY


func _art_texture(path: String) -> Texture2D:
	if not _art_tex.has(path):
		_art_tex[path] = load(path) if ResourceLoader.exists(path) else null
	return _art_tex[path]


func _smooth(k: float) -> float:
	k = clampf(k, 0.0, 1.0)
	return k * k * (3.0 - 2.0 * k)


## The part of a picture that covers the panel (centre crop).
func _cover_region(tex: Texture2D) -> Rect2:
	var ts := tex.get_size()
	var k := maxf(size.x / ts.x, size.y / ts.y)
	var rs := size / k
	return Rect2((ts - rs) * 0.5, rs)


func _draw_art() -> void:
	var k := _smooth(t / float(art.get("dur", 3.0)))
	var c0: Array = art.get("cam", [Vector2(0.5, 0.5), 1.0])
	var c1: Array = art.get("cam2", c0)
	var z := lerpf(float(c0[1]), float(c1[1]), k)
	var f: Vector2 = (c0[0] as Vector2).lerp(c1[0] as Vector2, k)
	var half := Vector2(0.5, 0.5) / z
	f = Vector2(clampf(f.x, half.x, 1.0 - half.x), clampf(f.y, half.y, 1.0 - half.y))
	_cam_xf = Transform2D(0.0, Vector2(z, z), 0.0, size * 0.5 - f * size * z)
	draw_rect(Rect2(Vector2.ZERO, size), Color(art.get("bg_col", Color("0d0b10"))))
	draw_set_transform_matrix(_cam_xf)
	var fx := String(art.get("fx", ""))
	var ft := t - float(art.get("fx_t", 0.0))
	if art.has("bg"):
		var tex := _art_texture(art["bg"])
		if tex != null:
			draw_texture_rect_region(tex, Rect2(Vector2.ZERO, size), _cover_region(tex))
	if art.has("crop"):
		var cr: Array = art["crop"]
		var tex := _art_texture(cr[0])
		if tex != null:
			var ts := tex.get_size()
			var rh := float(cr[2]) * ts.y
			var rs := Vector2(rh * size.x / size.y, rh)
			draw_texture_rect_region(tex, Rect2(Vector2.ZERO, size), Rect2((cr[1] as Vector2) * ts - rs * 0.5, rs))
	match fx:
		"sweep":
			_fx_sweep(ft)
		"drain":
			_fx_drain(ft)
	for fg: Array in art.get("figs", []):
		var tex := _art_texture(fg[0])
		if tex == null:
			continue
		var dh := float(fg[2]) * size.y
		var dw := dh * tex.get_width() / tex.get_height()
		var feet: Vector2 = (fg[1] as Vector2) * size
		if bool(fg[3]): # mirrored about the feet
			draw_set_transform_matrix(_cam_xf * Transform2D(0.0, Vector2(-1, 1), 0.0, Vector2(feet.x * 2.0, 0)))
		draw_texture_rect(tex, Rect2(feet - Vector2(dw * 0.5, dh), Vector2(dw, dh)), false, Color(fg[4]) if fg.size() > 4 else Color.WHITE)
		draw_set_transform_matrix(_cam_xf)
	match fx:
		"crack":
			_fx_crack(ft)
		"mask_fall":
			_fx_mask_fall(ft)
		"drips":
			_fx_drips()
		"eyes":
			for e: Vector2 in art.get("eyes", []):
				var r := size.y * (0.22 + 0.04 * sin(t * 5.0))
				draw_texture_rect(TEX_GLOW, Rect2(e * size - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(0.75, 1.0, 1.0, 0.75))
	draw_set_transform(Vector2.ZERO)
	if fx == "cages":
		# the cages stay framed while the opera drifts behind them
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.0, 0.1, 0.35))
		BookPanels.cages(self, size, t)


## Sunlight sweeps across the dark opera: the lit painting is revealed behind a bright edge.
func _fx_sweep(ft: float) -> void:
	var tex := _art_texture(String(art.get("bg2", "")))
	if tex == null:
		return
	var k := _smooth(ft / float(art.get("fx_dur", 1.6)))
	var sx := lerpf(-0.25, 1.25, k) * size.x
	var reg := _cover_region(tex)
	if sx > 0.0:
		var w := minf(sx, size.x)
		draw_texture_rect_region(tex, Rect2(Vector2.ZERO, Vector2(w, size.y)), Rect2(reg.position, Vector2(reg.size.x * w / size.x, reg.size.y)))
	if k < 1.0:
		var lean := size.y * 0.35
		draw_colored_polygon(PackedVector2Array([Vector2(sx - 40.0 + lean, 0), Vector2(sx + 40.0 + lean, 0), Vector2(sx + 40.0, size.y), Vector2(sx - 40.0, size.y)]), Color(1, 0.95, 0.7, 0.55))
		draw_texture_rect(TEX_GLOW, Rect2(Vector2(sx - 260.0, -120.0), Vector2(520.0, size.y + 240.0)), false, Color(1, 0.85, 0.45, 0.7))
	for i in 5:
		var a := 0.25 * k * (1.0 - 0.6 * k)
		var x0 := size.x * (0.1 + i * 0.2)
		draw_colored_polygon(PackedVector2Array([Vector2(x0 - 10.0 + size.x * 0.3, 0), Vector2(x0 + 30.0 + size.x * 0.3, 0), Vector2(x0 + 90.0, size.y), Vector2(x0 - 50.0, size.y)]), Color(1, 0.9, 0.55, a))


## The light is drained: the scene darkens and motes of light stream into the quill.
func _fx_drain(ft: float) -> void:
	var k := _smooth(ft / 1.8)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.0, 0.08, 0.72 * k))
	var at: Vector2 = (art.get("fx_at", Vector2(0.5, 0.5)) as Vector2) * size
	for i in 40:
		var start := Vector2(fposmod(i * 0.618034, 1.0) * size.x, fposmod(i * 0.414214 + 0.2, 1.0) * size.y)
		var p := fposmod(ft * 0.7 + i * 0.137, 1.0)
		if ft < 0.0:
			continue
		var pos := start.lerp(at, p * p)
		draw_circle(pos, 3.0 + 2.0 * (1.0 - p), Color(1, 0.86, 0.45, 0.9 * (1.0 - p * p)))
	draw_texture_rect(TEX_GLOW, Rect2(at - Vector2(90, 90), Vector2(180, 180)), false, Color(1, 0.8, 0.4, 0.5 + 0.3 * k))


## Cracks race across the mask.
func _fx_crack(ft: float) -> void:
	if ft < 0.0:
		return
	var at: Vector2 = (art.get("fx_at", Vector2(0.5, 0.5)) as Vector2) * size
	var reach := size.y * float(art.get("fx_size", 0.22)) * _smooth(ft / 0.45)
	for b in 7:
		var ang := b * TAU / 7.0 + 0.4
		var pts := PackedVector2Array([at])
		var p := at
		for s in 5:
			var a := ang + sin(b * 3.1 + s * 1.7) * 0.6
			p += Vector2.from_angle(a) * reach / 5.0
			pts.append(p)
		draw_polyline(pts, Color("18151d"), 4.0)
		draw_polyline(pts, Color(0.85, 0.7, 1.0, 0.8), 1.5)
	if ft < 0.25:
		draw_texture_rect(TEX_GLOW, Rect2(at - Vector2(120, 120), Vector2(240, 240)), false, Color(0.8, 0.6, 1.0, 1.0 - ft / 0.25))


## The cracked mask splits in two and falls away from the face beneath.
func _fx_mask_fall(ft: float) -> void:
	var at: Vector2 = (art.get("fx_at", Vector2(0.5, 0.5)) as Vector2) * size
	var s := size.y * float(art.get("fx_size", 0.5))
	var crack := [Vector2(0.0, -0.62), Vector2(-0.04, -0.4), Vector2(0.05, -0.18), Vector2(-0.05, 0.06), Vector2(0.04, 0.32), Vector2(0.0, 0.6)]
	var outer := [Vector2(-0.3, -0.55), Vector2(-0.42, -0.35), Vector2(-0.44, 0.05), Vector2(-0.3, 0.38)]
	var dt := maxf(0.0, ft)
	for side in [-1.0, 1.0]: # the half on this side of the crack
		var poly := PackedVector2Array()
		for c: Vector2 in crack:
			poly.append(c)
		for i in range(outer.size() - 1, -1, -1):
			poly.append(Vector2(outer[i].x * -side, outer[i].y))
		var off := Vector2(side * size.x * 0.12 * dt, 0.5 * size.y * 2.6 * dt * dt)
		var xf := Transform2D(-side * 1.2 * dt, Vector2(s, s), 0.0, at + off)
		draw_set_transform_matrix(_cam_xf * xf)
		draw_colored_polygon(poly, Color("ece6f0"))
		# porcelain shading: a cool shadow down the outer cheek, a highlight on the brow
		draw_colored_polygon(PackedVector2Array([Vector2(side * 0.3, -0.5), Vector2(side * 0.42, -0.35), Vector2(side * 0.44, 0.05), Vector2(side * 0.3, 0.38), Vector2(side * 0.2, 0.3), Vector2(side * 0.3, 0.0), Vector2(side * 0.28, -0.35)]), Color("b9aecb"))
		draw_colored_polygon(PackedVector2Array([Vector2(side * 0.05, -0.55), Vector2(side * 0.22, -0.5), Vector2(side * 0.2, -0.42), Vector2(side * 0.05, -0.45)]), Color(1, 1, 1, 0.8))
		draw_colored_polygon(PackedVector2Array([Vector2(side * 0.08, -0.16), Vector2(side * 0.32, -0.2), Vector2(side * 0.28, -0.08), Vector2(side * 0.1, -0.06)]), Color("1a0d2a"))
		var closed := poly.duplicate()
		closed.append(poly[0])
		draw_polyline(closed, Color("18151d"), 3.0 / s)
		if dt < 0.3:
			draw_texture_rect(TEX_GLOW, Rect2(Vector2(side * 0.2, -0.13) - Vector2(0.12, 0.12), Vector2(0.24, 0.24)), false, Color(0.8, 0.4, 1.0, 1.0 - dt / 0.3))
	draw_set_transform_matrix(_cam_xf)


## Ink drips off the quill's nib.
func _fx_drips() -> void:
	var at: Vector2 = (art.get("fx_at", Vector2(0.5, 0.8)) as Vector2) * size
	for d in 4:
		var k := fposmod(t * 0.9 + d * 0.25, 1.0)
		draw_circle(at + Vector2(sin(d * 2.0) * 4.0, k * size.y * 0.45), 5.0 * (1.0 - 0.5 * k), Color(0.08, 0.02, 0.14, 1.0 - k))


## The villain's quill, snapped in two, lying on the closed book.
func _draw_broken_quill(at: Vector2, ds: Vector2) -> void:
	var tex := _art_texture(QUILL_SRC)
	if tex == null:
		return
	var ts := tex.get_size()
	var reg := Rect2(QUILL_REGION.position * ts, QUILL_REGION.size * ts)
	var len := ds.x * 0.13
	var sc := len / reg.size.x
	var base := at + Vector2(0.6, 0.76) * ds
	# a pool of spilled ink under it
	draw_set_transform(base + Vector2(0, len * 0.3), 0.0, Vector2(1.0, 0.3))
	for i in 6:
		draw_circle(Vector2(cos(i * 1.3) * len * 0.35, sin(i * 2.1) * len * 0.15), len * (0.14 + 0.04 * (i % 3)), Color(0.05, 0.02, 0.09, 0.92))
	var halves := [[Rect2(reg.position, Vector2(reg.size.x * 0.5, reg.size.y)), Vector2(-len * 0.32, -len * 0.05), -0.3],
		[Rect2(reg.position + Vector2(reg.size.x * 0.5, 0), Vector2(reg.size.x * 0.5, reg.size.y)), Vector2(len * 0.3, len * 0.08), 0.35]]
	for h: Array in halves:
		var r: Rect2 = h[0]
		draw_set_transform(base + (h[1] as Vector2), float(h[2]), Vector2(sc, sc))
		draw_texture_rect_region(tex, Rect2(-r.size * 0.5, r.size), r)
	draw_set_transform(Vector2.ZERO)
