class_name ComicPanel
extends Control
## One comic panel of a story page. Draws its art clipped to the panel. If a picture named
## `res://assets/story/<key>.png` exists it is shown (slowly zooming) instead of the drawn art.

const ART_DIR := "res://assets/story/"
## Corners of the comic's cover inside book_cover.png (fractions of the picture).
const COVER_QUAD := [Vector2(0.301, 0.213), Vector2(0.709, 0.192), Vector2(0.723, 0.809), Vector2(0.289, 0.830)]

var key := ""
var params := {}
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
	if _tex != null:
		# cover the panel, with a slow push-in
		var ts := _tex.get_size()
		var k := maxf(size.x / ts.x, size.y / ts.y) * (1.0 + 0.03 * t)
		var ds := ts * k
		var at := (size - ds) * 0.5
		draw_texture_rect(_tex, Rect2(at, ds), false)
		if key == "book_cover":
			_cover_fx(at, ds)
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
