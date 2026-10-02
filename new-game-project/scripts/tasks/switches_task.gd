class_name SwitchesTask
extends TaskBase
## Fuse box: every switch also flips its neighbours. Light all the bulbs.

const COUNT := 6

var _on: Array[bool] = []


func _begin() -> void:
	title = "FIX THE FUSE BOX"
	hint = "Click a switch (or press 1-6). It flips its neighbours too. Light every bulb!"
	_on.clear()
	for i in COUNT:
		_on.append(true)
	var presses := 0
	while presses < 5 or not _on.has(false):
		_press(randi() % COUNT)
		presses += 1


func _press(i: int) -> void:
	for k in [i - 1, i, i + 1]:
		if k >= 0 and k < COUNT:
			_on[k] = not _on[k]


func _rect(i: int) -> Rect2:
	var w := 96.0
	var gap := 20.0
	var total := COUNT * w + (COUNT - 1) * gap
	return Rect2(Vector2(panel.get_center().x - total * 0.5 + i * (w + gap), panel.position.y + 220), Vector2(w, 190))


func _gui_input(event: InputEvent) -> void:
	if _done:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in COUNT:
			if _rect(i).has_point(event.position):
				_toggle(i)


func _unhandled_input(event: InputEvent) -> void:
	if _done or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var i: int = int(event.keycode) - KEY_1
	if i >= 0 and i < COUNT:
		_toggle(i)


func _toggle(i: int) -> void:
	_press(i)
	if not _on.has(false):
		succeed()


func _draw_task() -> void:
	for i in COUNT:
		var r := _rect(i)
		var lit := _on[i]
		var bulb := Vector2(r.get_center().x, r.position.y - 46)
		if lit:
			_glow(bulb, 62.0, Color(1, 0.9, 0.4, 0.8))
		draw_circle(bulb, 24.0, INK)
		draw_circle(bulb, 19.0, GOLD if lit else Color("5a5470"))
		draw_rect(Rect2(r.position + Vector2(5, 6), r.size), Color(0, 0, 0, 0.35))
		draw_rect(r, Color("8d99ae"))
		draw_rect(r, INK, false, 5.0)
		var slot := Rect2(r.position + Vector2(r.size.x * 0.5 - 12, 22), Vector2(24, r.size.y - 44))
		draw_rect(slot, INK)
		var lever_y := slot.position.y + (14.0 if lit else slot.size.y - 14.0)
		draw_line(Vector2(slot.get_center().x, slot.get_center().y), Vector2(slot.get_center().x, lever_y), Color("c1121f"), 14.0)
		draw_circle(Vector2(slot.get_center().x, lever_y), 16.0, INK)
		draw_circle(Vector2(slot.get_center().x, lever_y), 11.0, Color("e63946"))
		_text(str(i + 1), r.position + Vector2(r.size.x * 0.5 - 7, r.size.y + 30), 24, INK, FONT_SHOUT)
