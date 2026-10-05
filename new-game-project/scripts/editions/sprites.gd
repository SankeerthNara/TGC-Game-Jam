class_name Sprites
extends RefCounted
## Painted / pixel character sprites from res://assets/editions/sprites/. When a sprite exists it is
## drawn instead of the code-drawn figure (so art can arrive at any time without code changes).
## Sprites face RIGHT with their feet on the bottom edge of the image.

const DIR := "res://assets/editions/sprites/"
static var _cache := {}


static func get_tex(key: String) -> Texture2D:
	if not _cache.has(key):
		var p := DIR + key + ".png"
		_cache[key] = load(p) if ResourceLoader.exists(p) else null
	return _cache[key]


static func has(key: String) -> bool:
	return get_tex(key) != null


## Draws sprite `key` with its feet at `feet`, `height` pixels tall on screen (the whole image),
## facing `dir` (1 right, -1 left). squash > 1 makes it taller and thinner (breathing, landing).
static func draw(ci: CanvasItem, key: String, feet: Vector2, height: float, dir := 1.0, tint := Color.WHITE, squash := 1.0, rot := 0.0) -> bool:
	var tex := get_tex(key)
	if tex == null:
		return false
	var sc := height / tex.get_height()
	var w := tex.get_width() * sc / squash
	var h := tex.get_height() * sc * squash
	ci.draw_set_transform(feet, rot, Vector2(dir, 1.0))
	# half a texel in from the edges: on a canvas item with texture repeat on (the halftone turns it on),
	# filtering would otherwise wrap the feet row around to a faint line above the head
	ci.draw_texture_rect_region(tex, Rect2(Vector2(-w * 0.5, -h), Vector2(w, h)), Rect2(Vector2(0.5, 0.5), tex.get_size() - Vector2.ONE), tint)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return true


## A light rim around a sprite so it reads against a busy background: the silhouette drawn solid
## (an overbright modulate clamps to one colour) in 8 directions, `width` px out, before the sprite.
static func draw_rim(ci: CanvasItem, key: String, feet: Vector2, height: float, dir := 1.0, col := Color(1, 0.93, 0.8, 0.55), squash := 1.0, rot := 0.0, width := 3.0) -> void:
	var tex := get_tex(key)
	if tex == null:
		return
	var solid := Color(col.r * 8.0, col.g * 8.0, col.b * 8.0, col.a)
	for i in 8:
		draw(ci, key, feet + Vector2.from_angle(i * TAU / 8.0) * width, height, dir, solid, squash, rot)
