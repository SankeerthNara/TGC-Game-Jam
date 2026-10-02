class_name PanelsTask
extends TaskBase
## Comic task: four panels of a little story are shuffled. Click two to swap them until time flows left to right.

const SEQUENCES := ["candle", "flower", "tower", "battery"]

var _kind := "candle"
var _order: Array[int] = [0, 1, 2, 3] ## stage shown in each slot
var _sel := -1


func _begin() -> void:
	title = "ORDER THE COMIC PANELS"
	hint = "Click two panels to swap them. Put the story in order, first panel on the left."
	_kind = SEQUENCES[randi() % SEQUENCES.size()]
	while _order == [0, 1, 2, 3]:
		_order.shuffle()


func _slot(i: int) -> Rect2:
	var w := 150.0
	var gap := 28.0
	var total := 4 * w + 3 * gap
	return Rect2(Vector2(panel.get_center().x - total * 0.5 + i * (w + gap), panel.position.y + 150), Vector2(w, 220))


func _gui_input(event: InputEvent) -> void:
	if _done:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in 4:
			if _slot(i).has_point(event.position):
				if _sel < 0:
					_sel = i
				elif _sel == i:
					_sel = -1
				else:
					var tmp := _order[_sel]
					_order[_sel] = _order[i]
					_order[i] = tmp
					_sel = -1
					if _order == [0, 1, 2, 3]:
						succeed()


func _draw_task() -> void:
	_centered("What happens first? What happens last?", panel.position.y + 112, 26, INK, FONT_SHOUT)
	for i in 4:
		var r := _slot(i)
		draw_rect(Rect2(r.position + Vector2(6, 7), r.size), Color(0, 0, 0, 0.3))
		draw_rect(r, Color("fffdf2") if _sel != i else Color("ffe9a8"))
		draw_rect(r, INK, false, 5.0 if _sel == i else 4.0)
		_picture(_kind, _order[i], r)
		if i < 3:
			var a := r.get_center() + Vector2(r.size.x * 0.5 + 14, 0)
			draw_colored_polygon(PackedVector2Array([a + Vector2(-8, -12), a + Vector2(10, 0), a + Vector2(-8, 12)]), Color("8d99ae"))
	_centered("TIME  ->", panel.position.y + 420, 30, Color("8d99ae"), FONT_SHOUT)


func _picture(kind: String, stage: int, r: Rect2) -> void:
	var c := r.get_center()
	var ground := r.end.y - 30.0
	draw_rect(Rect2(Vector2(r.position.x + 8, ground), Vector2(r.size.x - 16, 4)), INK)
	match kind:
		"candle":
			var h: float = [110.0, 78.0, 46.0, 14.0][stage]
			draw_rect(Rect2(Vector2(c.x - 18, ground - h), Vector2(36, h)), Color("f1e9d2"))
			draw_rect(Rect2(Vector2(c.x - 18, ground - h), Vector2(36, h)), INK, false, 3.0)
			if stage < 3:
				var fl := sin(_t * 12.0) * 2.0
				draw_colored_polygon(PackedVector2Array([Vector2(c.x - 9, ground - h - 2), Vector2(c.x + fl, ground - h - 34), Vector2(c.x + 9, ground - h - 2)]), Color("ff8c1a"))
				draw_colored_polygon(PackedVector2Array([Vector2(c.x - 4, ground - h - 2), Vector2(c.x, ground - h - 20), Vector2(c.x + 4, ground - h - 2)]), Color("ffe066"))
			else:
				draw_line(Vector2(c.x, ground - h - 2), Vector2(c.x + 6, ground - h - 40), Color(0.5, 0.5, 0.5, 0.6), 4.0)
		"flower":
			match stage:
				0:
					draw_circle(Vector2(c.x, ground - 6), 9.0, Color("8b5a2b"))
				1:
					draw_line(Vector2(c.x, ground), Vector2(c.x, ground - 40), Color("2dc653"), 5.0)
					draw_circle(Vector2(c.x - 10, ground - 40), 9.0, Color("2dc653"))
					draw_circle(Vector2(c.x + 10, ground - 44), 9.0, Color("2dc653"))
				2:
					draw_line(Vector2(c.x, ground), Vector2(c.x, ground - 85), Color("2dc653"), 6.0)
					draw_circle(Vector2(c.x, ground - 95), 14.0, Color("ff7bd5"))
				3:
					draw_line(Vector2(c.x, ground), Vector2(c.x, ground - 85), Color("2dc653"), 6.0)
					for k in 6:
						draw_circle(Vector2(c.x, ground - 98) + Vector2.from_angle(k * TAU / 6.0) * 20.0, 13.0, Color("ff7bd5"))
					draw_circle(Vector2(c.x, ground - 98), 11.0, GOLD)
		"tower":
			var n := stage + 1
			for k in n:
				var w := 100.0 - k * 14.0
				draw_rect(Rect2(Vector2(c.x - w * 0.5, ground - (k + 1) * 36), Vector2(w, 34)), [Color("e63946"), Color("ffd23f"), Color("3a86ff"), Color("2dc653")][k])
				draw_rect(Rect2(Vector2(c.x - w * 0.5, ground - (k + 1) * 36), Vector2(w, 34)), INK, false, 3.0)
		"battery":
			draw_rect(Rect2(Vector2(c.x - 34, ground - 120), Vector2(68, 120)), INK)
			draw_rect(Rect2(Vector2(c.x - 14, ground - 134), Vector2(28, 14)), INK)
			var fill := (stage) * 0.33
			draw_rect(Rect2(Vector2(c.x - 28, ground - 114 + (1.0 - maxf(fill, 0.04)) * 108.0), Vector2(56, maxf(fill, 0.04) * 108.0)), Color("2dc653") if stage > 0 else RED)
