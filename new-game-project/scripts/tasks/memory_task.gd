class_name MemoryTask
extends TaskBase
## Comic task: flip the sticker cards and find every matching pair.

const ICONS := ["star", "moon", "bolt", "sun", "flower", "crown"]

var _cards: Array[String] = []
var _open: Array[int] = []
var _matched: Array[bool] = []
var _wait := 0.0


func _begin() -> void:
	title = "MATCH THE COMIC STICKERS"
	hint = "Flip two cards at a time. Find all six pairs!"
	for id in ICONS:
		_cards.append(id)
		_cards.append(id)
	_cards.shuffle()
	for i in _cards.size():
		_matched.append(false)


func _rect(i: int) -> Rect2:
	var w := 120.0
	var h := 120.0
	var gap := 22.0
	var cols := 4
	var total_w := cols * w + (cols - 1) * gap
	return Rect2(Vector2(panel.get_center().x - total_w * 0.5 + (i % cols) * (w + gap), panel.position.y + 100 + (i / cols) * (h + 14.0)), Vector2(w, h))


func _update(delta: float) -> void:
	if _wait > 0.0:
		_wait -= delta
		if _wait <= 0.0:
			_open.clear()


func _gui_input(event: InputEvent) -> void:
	if _done or _wait > 0.0:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in _cards.size():
			if _rect(i).has_point(event.position) and not _matched[i] and not _open.has(i):
				_open.append(i)
				if _open.size() == 2:
					if _cards[_open[0]] == _cards[_open[1]]:
						_matched[_open[0]] = true
						_matched[_open[1]] = true
						_open.clear()
						if not _matched.has(false):
							succeed()
					else:
						_wait = maxf(0.4, 0.9 - 0.15 * difficulty)
				return


func _draw_task() -> void:
	for i in _cards.size():
		var r := _rect(i)
		var shown := _matched[i] or _open.has(i)
		draw_rect(Rect2(r.position + Vector2(4, 5), r.size), Color(0, 0, 0, 0.3))
		draw_rect(r, Color("fffdf2") if shown else Color("e63946"))
		draw_rect(r, INK, false, 4.0)
		if shown:
			KeySymbols.draw_key(self, _cards[i], r.get_center(), 36.0, GOLD if not _matched[i] else Color("2dc653"), Color("fffdf2"))
		else:
			_text("?", r.get_center() + Vector2(-14, 18), 56, Color("fff3d1"), FONT_SHOUT)
