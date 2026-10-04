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
	ci.draw_texture_rect(tex, Rect2(Vector2(-w * 0.5, -h), Vector2(w, h)), false, tint)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return true
