class_name ComicCutscene
extends Control
## The story cutscenes, told as animated comic pages: panels slide in, captions and speech bubbles
## type out, sound-effect words pop, and an ink wipe turns the page.
## Z / Enter / Space / click: show the whole page, then the next page. Esc: skip the scene.

signal finished

const INK := Color("18151d")
const PAPER := Color("fff3d1")
const GOLD := Color("ffd23f")
const FONT_SHOUT := preload("res://assets/fonts/Bangers-Regular.ttf")
const FONT_BODY := preload("res://assets/fonts/ComicNeue-Bold.ttf")
const KINDS := ["opening", "bomb_room", "earth_blast", "ending_sun", "ending_lava", "book", "reveal", "ending_editions"]
const GUTTER := 14.0
const WIPE := 0.45
const CPS := 55.0 ## typing speed of captions and bubbles

var kind := "opening"
var bomb_left := 17 * 60.0
var _pages: Array = []
var _page := 0
var _t := 0.0 ## time on the current page
var _wipe := -1.0 ## >= 0 while the page turns
var _done := false
var _panels: Array[ComicPanel] = []
var _total := 0.0
var _top: Control ## draws captions, bubbles and sound effects above the panels


func _ready() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	_pages = StoryScenes.pages(kind)
	_top = Control.new()
	_top.size = size
	_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top.draw.connect(func() -> void: _draw_overlay(_top))
	add_child(_top)
	_build_page()


## Jumps to a page and a time on it (used by the screenshot tool).
func show_at(page: int, t: float) -> void:
	_page = page
	_build_page()
	_t = t
	_wipe = -1.0
	_animate_panels()
	for p in _panels:
		p.queue_redraw()
	_top.queue_redraw()


## Finishes the cutscene at once (also used by tests).
func skip() -> void:
	if not _done:
		_done = true
		finished.emit()


func _area() -> Rect2:
	return Rect2(Vector2(26, 22), size - Vector2(52, 66))


func _panel_rect(i: int) -> Rect2:
	var a := _area()
	var r: Rect2 = _pages[_page]["panels"][i]["rect"]
	return Rect2(a.position + r.position * a.size + Vector2(GUTTER, GUTTER) * 0.5, r.size * a.size - Vector2(GUTTER, GUTTER))


func _build_page() -> void:
	for p in _panels:
		p.queue_free()
	_panels.clear()
	_t = 0.0
	var page: Dictionary = _pages[_page]
	for i in page["panels"].size():
		var pd: Dictionary = page["panels"][i]
		var p := ComicPanel.new()
		p.key = pd["key"]
		p.params = {"bomb_left": bomb_left, "bomb_secs": 17 * 60.0}
		var r := _panel_rect(i)
		p.position = r.position
		p.size = r.size
		p.pivot_offset = r.size * 0.5
		p.visible = false
		add_child(p)
		_panels.append(p)
	move_child(_top, -1)


## Last moment anything appears on this page, including typing time.
func _page_end() -> float:
	var page: Dictionary = _pages[_page]
	var end := 0.0
	for pd: Dictionary in page["panels"]:
		end = maxf(end, float(pd.get("at", 0.0)) + 0.4)
	for b: Dictionary in page.get("text", []):
		end = maxf(end, float(b["at"]) + String(b["text"]).length() / CPS)
	for s: Dictionary in page.get("sfx", []):
		end = maxf(end, float(s["at"]) + 0.3)
	return end


func _process(delta: float) -> void:
	if _done:
		return
	_total += delta
	if _wipe >= 0.0:
		_wipe += delta
		if _wipe - delta <= 0.0:
			EventBus.sound_requested.emit("page_turn")
		if _wipe >= WIPE * 0.5 and _wipe - delta < WIPE * 0.5:
			_page += 1
			_build_page()
		if _wipe >= WIPE:
			_wipe = -1.0
	else:
		var before := _t
		_t += delta
		for sfx: Dictionary in _pages[_page].get("sfx", []):
			if before < float(sfx["at"]) and _t >= float(sfx["at"]):
				var word := String(sfx["text"])
				EventBus.sound_requested.emit("explosion" if "BOOM" in word else ("key_click" if "CLICK" in word else "comic_pop"))
		var hold := float(_pages[_page].get("hold", 2.2))
		if _t > _page_end() + hold:
			_next()
	_animate_panels()
	queue_redraw()
	_top.queue_redraw()


func _next() -> void:
	if _page >= _pages.size() - 1:
		skip()
	elif _wipe < 0.0:
		_wipe = 0.0


func _animate_panels() -> void:
	var page: Dictionary = _pages[_page]
	for i in _panels.size():
		var pd: Dictionary = page["panels"][i]
		var p := _panels[i]
		var lt := _t - float(pd.get("at", 0.0))
		p.visible = lt >= 0.0
		if lt < 0.0:
			continue
		p.t = lt
		var k := clampf(lt / 0.32, 0.0, 1.0)
		var e := 1.0 - pow(1.0 - k, 3.0)
		var r := _panel_rect(i)
		match String(pd.get("enter", "fade")):
			"left":
				p.position = r.position + Vector2(-80.0 * (1.0 - e), 0)
			"right":
				p.position = r.position + Vector2(80.0 * (1.0 - e), 0)
			"up":
				p.position = r.position + Vector2(0, 60.0 * (1.0 - e))
			"pop":
				var back := 1.0 + 0.12 * sin(k * PI)
				p.scale = Vector2.ONE * lerpf(0.8, 1.0, e) * back
			_:
				pass
		p.modulate.a = e


func _unhandled_input(event: InputEvent) -> void:
	if _done or _total < 0.4:
		return
	var press: bool = (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if not press:
		return
	get_viewport().set_input_as_handled()
	if event is InputEventKey and event.keycode == KEY_ESCAPE:
		skip()
		return
	if event is InputEventKey and not event.keycode in [KEY_Z, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		return
	if _wipe >= 0.0:
		return
	if _t < _page_end():
		_t = _page_end() # show the whole page first
	else:
		_next()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("0d0b10"))
	var a := _area()
	draw_rect(a.grow(8), PAPER)
	ComicArt.halftone(self, size, Color(0.85, 0.75, 0.55, 0.25), 18.0, 4.0, Vector2(0, 0))


## Captions, bubbles, sound effects and the page turn are drawn above the panels.
func _draw_overlay(ci: CanvasItem) -> void:
	if _done:
		return
	var page: Dictionary = _pages[_page]
	for i in _panels.size():
		if _panels[i].visible:
			var r := Rect2(_panels[i].position, _panels[i].size * _panels[i].scale)
			ci.draw_rect(r.grow(2), INK, false, 6.0)
	for s: Dictionary in page.get("sfx", []):
		var lt := _t - float(s["at"])
		if lt < 0.0:
			continue
		var k := clampf(lt / 0.18, 0.0, 1.0)
		var sc := lerpf(2.2, 1.0, k) + 0.04 * sin(lt * 14.0)
		var pr := _panel_rect(int(s.get("panel", 0)))
		var pos: Vector2 = pr.position + Vector2(s["pos"]) * pr.size
		ComicArt.shout(ci, s["text"], pos, int(s.get("size", 64)), Color(s.get("color", GOLD)), 12, float(s.get("rot", -0.08)), sc)
	for b: Dictionary in page.get("text", []):
		var lt := _t - float(b["at"])
		if lt < 0.0:
			continue
		var full := String(b["text"])
		var shown := full.substr(0, int(lt * CPS))
		var pr := _panel_rect(int(b.get("panel", 0)))
		if b["type"] == "caption":
			_caption(ci, pr, b, shown, full)
		else:
			_bubble(ci, pr, b, shown, full)
	var hint := "Z: next   ESC: skip"
	ci.draw_string(FONT_BODY, Vector2(size.x - 230, size.y - 14), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 1, 1, 0.6))
	for k in _pages.size():
		ci.draw_circle(Vector2(40 + k * 22, size.y - 21), 6.0, GOLD if k == _page else Color(1, 1, 1, 0.3))
	if _wipe >= 0.0:
		# an ink wedge sweeps across the page
		var p := _wipe / WIPE
		var x := lerpf(-size.x * 0.6, size.x * 1.6, p)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x - size.x * 0.9, 0), Vector2(x + 160, 0), Vector2(x - 160, size.y), Vector2(x - size.x * 1.2, size.y)]), INK)


func _wrap(text: String, font: Font, fs: int, width: float) -> PackedStringArray:
	var lines := PackedStringArray()
	var line := ""
	for word in text.split(" "):
		var test := word if line == "" else line + " " + word
		if font.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > width and line != "":
			lines.append(line)
			line = word
		else:
			line = test
	if line != "":
		lines.append(line)
	return lines


func _caption(ci: CanvasItem, pr: Rect2, b: Dictionary, shown: String, full: String) -> void:
	var fs := 22
	var w := minf(pr.size.x - 24.0, float(b.get("width", 420.0)))
	var lines := _wrap(full, FONT_BODY, fs, w - 24.0)
	var h := lines.size() * (fs + 4) + 18.0
	var at := String(b.get("at_pos", "tl"))
	var pos := pr.position + Vector2(10, 10)
	if at == "bl":
		pos = Vector2(pr.position.x + 10, pr.end.y - h - 10)
	elif at == "br":
		pos = pr.end - Vector2(w + 10, h + 10)
	elif at == "tr":
		pos = Vector2(pr.end.x - w - 10, pr.position.y + 10)
	var box := Rect2(pos, Vector2(w, h))
	ci.draw_rect(Rect2(box.position + Vector2(4, 4), box.size), Color(0, 0, 0, 0.4))
	ci.draw_rect(box, GOLD)
	ci.draw_rect(box, INK, false, 4.0)
	var left := shown.length()
	var y := box.position.y + 10 + fs
	for ln in lines:
		var part := ln.substr(0, maxi(0, left))
		left -= ln.length() + 1
		ci.draw_string(FONT_BODY, Vector2(box.position.x + 12, y), part, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)
		y += fs + 4


func _bubble(ci: CanvasItem, pr: Rect2, b: Dictionary, shown: String, full: String) -> void:
	var shouty: bool = b.get("shout", false)
	var font: Font = FONT_SHOUT if shouty else FONT_BODY
	var fs := 30 if shouty else 22
	var w := float(b.get("width", 300.0))
	var lines := _wrap(full, font, fs, w - 30.0)
	var h := lines.size() * (fs + 4) + 22.0
	var c: Vector2 = pr.position + Vector2(b["pos"]) * pr.size
	var box := Rect2(c - Vector2(w, h) * 0.5, Vector2(w, h))
	var tail: Vector2 = pr.position + Vector2(b.get("tail", Vector2(0.5, 1.0))) * pr.size
	var side := (tail - c).normalized().orthogonal() * 16.0
	var base := c + (tail - c).normalized() * minf(h * 0.4, 30.0)
	var fill := Color.WHITE if b.get("who", "") != "narrator" else Color("f3e8ff")
	var pts := ComicArt.ellipse_pts(c, w * 0.56, h * 0.62, 30)
	pts.remove_at(pts.size() - 1)
	ci.draw_colored_polygon(pts, INK)
	ci.draw_colored_polygon(PackedVector2Array([base + side * 1.3, tail, base - side * 1.3]), INK)
	var inner := ComicArt.ellipse_pts(c, w * 0.56 - 4, h * 0.62 - 4, 30)
	inner.remove_at(inner.size() - 1)
	ci.draw_colored_polygon(inner, fill)
	ci.draw_colored_polygon(PackedVector2Array([base + side, tail + (c - tail).normalized() * 7.0, base - side]), fill)
	var left := shown.length()
	var y := box.position.y + 10 + fs
	for ln in lines:
		var part := ln.substr(0, maxi(0, left))
		left -= ln.length() + 1
		var lw := font.get_string_size(ln, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		ci.draw_string(font, Vector2(c.x - lw * 0.5, y), part, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("6a040f") if shouty else INK)
		y += fs + 4
