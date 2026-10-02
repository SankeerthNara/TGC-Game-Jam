class_name InventoryHUD
extends Control
## Bottom-left strip in the town: collected items and keys in your pocket.

const FONT_SHOUT := preload("res://assets/fonts/Bangers-Regular.ttf")
const INK := Color("18151d")
const GOLD := Color("ffd23f")

var inv := {"ink": 0, "gear": 0, "shard": 0}
var keys: Array = []
var _pulse := {}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func update_state(new_inv: Dictionary, new_keys: Array) -> void:
	for t: String in new_inv:
		if int(new_inv[t]) > int(inv.get(t, 0)):
			_pulse[t] = 0.6
	inv = new_inv.duplicate()
	keys = new_keys.duplicate()
	queue_redraw()


func _process(delta: float) -> void:
	if not visible:
		return
	for t: String in _pulse.keys():
		_pulse[t] -= delta
		if _pulse[t] <= 0.0:
			_pulse.erase(t)
	queue_redraw()


func _draw() -> void:
	var w := 330.0 + 46.0 * keys.size()
	var r := Rect2(Vector2(24, 640), Vector2(w, 56))
	draw_rect(Rect2(r.position + Vector2(4, 4), r.size), Color(0, 0, 0, 0.4))
	draw_rect(r, Color("fff9e6"))
	draw_rect(r, INK, false, 4.0)
	var x := r.position.x + 20.0
	for type: String in ["ink", "gear", "shard"]:
		var bump := 1.0 + float(_pulse.get(type, 0.0)) * 0.7
		KeySymbols.draw_item(self, type, Vector2(x + 12, r.position.y + 28), 13.0 * bump, INK)
		draw_string(FONT_SHOUT, Vector2(x + 32, r.position.y + 37), "x%d" % int(inv.get(type, 0)), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, INK)
		x += 90.0
	x += 4.0
	draw_line(Vector2(x - 10, r.position.y + 8), Vector2(x - 10, r.end.y - 8), INK, 2.0)
	for id: String in keys:
		draw_circle(Vector2(x + 16, r.position.y + 28), 19.0, INK)
		KeySymbols.draw_key(self, id, Vector2(x + 16, r.position.y + 28), 13.0, GOLD, INK)
		x += 44.0
	if keys.is_empty():
		draw_string(FONT_SHOUT, Vector2(x, r.position.y + 36), "NO KEYS", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("8d99ae"))
