class_name ComicPanel
extends Control
## One comic panel of a story page. Draws its art clipped to the panel. If a picture named
## `res://assets/story/<key>.png` exists it is shown (slowly zooming) instead of the drawn art.

const ART_DIR := "res://assets/story/"

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
		draw_texture_rect(_tex, Rect2((size - ds) * 0.5, ds), false)
		return
	StoryPanels.draw(self, key, size, t, params)
