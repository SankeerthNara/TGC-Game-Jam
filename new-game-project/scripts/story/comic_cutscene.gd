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
const DIVE := 1.5 ## the cover page: the camera pushes in, the cover swings open, pages flick, light

var kind := "opening"
## Lines spoken inside another line's clip: [the clip's line id, seconds into it]. When voiced, the
## line appears when the speaker reaches it.
const COVERED := {"book/1/1": ["book/1/0", 2.2], "book/2/1": ["book/2/0", 7.6], "reveal/1/2": ["reveal/1/1", 5.2], "ending_editions/1/1": ["ending_editions/1/0", 2.6]}
var bomb_left := 17 * 60.0
var _pages: Array = []
var _page := 0
var _t := 0.0 ## time on the current page
var _wipe := -1.0 ## >= 0 while the page turns
var _done := false
var _panels: Array[ComicPanel] = []
var _total := 0.0
var _top: Control ## draws captions, bubbles and sound effects above the panels
var _dive := -1.0 ## >= 0 while diving into the book
var _shake := 0.0
var _flash := 0.0
var _punch: Array[float] = [] ## a quick zoom punch per panel, for the big hits


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
	var vo := VoPlayer.get_vo(get_tree()) if is_inside_tree() else null
	if vo != null:
		vo.stop()
	if not _done:
		_done = true
		finished.emit()


func _area() -> Rect2:
	return Rect2(Vector2(26, 22), size - Vector2(52, 66))


func _panel_rect(i: int) -> Rect2:
	var a := _area()
	var r: Rect2 = _pages[_page]["panels"][i]["rect"]
	return Rect2(a.position + r.position * a.size + Vector2(GUTTER, GUTTER) * 0.5, r.size * a.size - Vector2(GUTTER, GUTTER))


## The Narrator's long laugh at the unmasking shakes the panel and glitches the picture.
func _laugh_fx(_delta: float) -> void:
	var vo := VoPlayer.get_vo(get_tree())
	if vo == null or vo.current_file() != "vo_reveal_4.mp3" or vo.position() < 8.0:
		return
	_shake = maxf(_shake, 3.0 + 2.5 * absf(sin(_total * 9.0)))
	var d: Node = get_tree().get_first_node_in_group("editions_director")
	if d != null and d.fx != null and fposmod(_total, 1.1) < 0.02:
		d.fx.glitch(0.5, 0.25)
		EventBus.sound_requested.emit("glitch")


func _sync_covered() -> void:
	var vo := VoPlayer.get_vo(get_tree()) if is_inside_tree() else null
	if vo == null:
		return
	var texts: Array = _pages[_page].get("text", [])
	for i in texts.size():
		var id := "%s/%d/%d" % [kind, _page, i]
		if COVERED.has(id):
			var parent: Array = COVERED[id]
			var pi := int(String(parent[0]).get_slice("/", 2))
			if pi < texts.size() and vo.has_clip("", String(parent[0])):
				texts[i]["at"] = float(texts[pi]["at"]) + float(parent[1])


func _build_page() -> void:
	_sync_covered()
	for p in _panels:
		p.queue_free()
	_panels.clear()
	_punch.clear()
	_t = 0.0
	var page: Dictionary = _pages[_page]
	for i in page["panels"].size():
		_punch.append(0.0)
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
		end = maxf(end, float(b["at"]) + String(b["text"]).length() / float(b.get("cps", CPS)))
	for s: Dictionary in page.get("sfx", []):
		end = maxf(end, float(s["at"]) + 0.3)
	return end


func _process(delta: float) -> void:
	if _done:
		return
	_total += delta
	_shake = maxf(0.0, _shake - delta * 36.0)
	_flash = maxf(0.0, _flash - delta * 1.5)
	for i in _punch.size():
		_punch[i] = maxf(0.0, _punch[i] - delta * 3.5)
	if _dive >= 0.0:
		_dive += delta
		for at: float in [0.36, 0.78, 0.9]:
			if _dive - delta < at and _dive >= at:
				EventBus.sound_requested.emit("page_turn")
		if _dive >= DIVE:
			_dive = -1.0
			_page += 1
			_build_page()
			_flash = 1.0
	elif _wipe >= 0.0:
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
				EventBus.sound_requested.emit(String(sfx.get("sound", "explosion" if "BOOM" in word else ("key_click" if "CLICK" in word else "comic_pop"))))
		# camera moments: shake, flash, a zoom punch on a panel, a sound
		for f: Dictionary in _pages[_page].get("fx", []):
			var at := float(f["at"])
			if (before < at or (before == 0.0 and at <= 0.0)) and _t >= at:
				_shake = maxf(_shake, float(f.get("shake", 0.0)))
				_flash = maxf(_flash, float(f.get("flash", 0.0)))
				if f.has("punch") and int(f["punch"]) < _punch.size():
					_punch[int(f["punch"])] = 1.0
				if f.has("sound"):
					EventBus.sound_requested.emit(String(f["sound"]))
		# voice-over: each caption or bubble speaks as it appears (queued, never cut off)
		var texts: Array = _pages[_page].get("text", [])
		var vo0 := VoPlayer.get_vo(get_tree())
		if vo0 != null and vo0.busy():
			# a voiced line waits for the voice before it: the page follows the speech
			for i in texts.size():
				var at3 := float(texts[i]["at"])
				if before < at3 and _t >= at3 and vo0.has_clip(String(texts[i]["text"]), "%s/%d/%d" % [kind, _page, i]):
					_t = at3 - 0.001
					break
		_laugh_fx(delta)
		for i in texts.size():
			var at2 := float(texts[i]["at"])
			if (before < at2 or (before == 0.0 and at2 <= 0.0)) and _t >= at2:
				var vo := VoPlayer.get_vo(get_tree())
				if vo != null:
					vo.queue(String(texts[i]["text"]), "%s/%d/%d" % [kind, _page, i])
		var hold := float(_pages[_page].get("hold", 2.2))
		var vo2 := VoPlayer.get_vo(get_tree())
		if _t > _page_end() + hold and (vo2 == null or not vo2.busy()):
			_next() # the page waits for its voice to finish
	_animate_panels()
	position = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake)) if _shake > 0.0 else Vector2.ZERO
	queue_redraw()
	_top.queue_redraw()


func _next() -> void:
	if _page >= _pages.size() - 1:
		skip()
	elif _wipe < 0.0 and _dive < 0.0:
		if String(_pages[_page].get("turn", "")) == "dive":
			_dive = 0.0
		else:
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
			"settle":
				# the camera settles on the scene
				var ks := 1.0 - pow(1.0 - clampf(lt / 0.9, 0.0, 1.0), 3.0)
				p.scale = Vector2.ONE * lerpf(1.12, 1.0, ks)
			"pullback":
				# the camera pulls back out of the story, onto the closed book
				var kp := 1.0 - pow(1.0 - clampf(lt / 1.6, 0.0, 1.0), 3.0)
				p.scale = Vector2.ONE * lerpf(2.6, 1.0, kp)
				e = 1.0
			_:
				pass
		if i < _punch.size() and _punch[i] > 0.0:
			p.scale = (p.scale if String(pd.get("enter", "fade")) in ["pop", "settle", "pullback"] else Vector2.ONE) * (1.0 + 0.07 * _punch[i])
		elif not String(pd.get("enter", "fade")) in ["pop", "settle", "pullback"]:
			p.scale = Vector2.ONE
		if _dive >= 0.0 and i == 0:
			# push in until the cover fills the screen, then keep drifting closer
			p.pivot_offset = p.size * Vector2(0.5, 0.48)
			p.scale = Vector2.ONE * (1.0 + 1.2 * smoothstep(0.0, 0.4, _dive) + 0.3 * clampf((_dive - 0.4) / 1.1, 0.0, 1.0))
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
	if _wipe >= 0.0 or _dive >= 0.0:
		return
	if _t < _page_end():
		_t = _page_end() # show the whole page first
	elif VoPlayer.get_vo(get_tree()) != null and VoPlayer.get_vo(get_tree()).busy():
		VoPlayer.get_vo(get_tree()).stop() # Z again: cut the voice, then turn the page
		_next()
	else:
		_next()


func _draw() -> void:
	draw_rect(Rect2(Vector2(-40, -40), size + Vector2(80, 80)), Color("0d0b10"))
	var a := _area()
	draw_rect(a.grow(8), PAPER)
	ComicArt.halftone(self, size, Color(0.85, 0.75, 0.55, 0.25), 18.0, 4.0, Vector2(0, 0))


## Captions, bubbles, sound effects and the page turn are drawn above the panels.
func _draw_overlay(ci: CanvasItem) -> void:
	if _done:
		return
	var page: Dictionary = _pages[_page]
	for i in _panels.size():
		var pn := _panels[i]
		if pn.visible:
			var r := Rect2(pn.position + pn.pivot_offset * (Vector2.ONE - pn.scale), pn.size * pn.scale)
			ci.draw_rect(r.grow(2), INK, false, 6.0)
	for s: Dictionary in page.get("sfx", []) if _dive < 0.0 else []: # the camera leaves the page's words behind
		var lt := _t - float(s["at"])
		if lt < 0.0:
			continue
		var k := clampf(lt / 0.18, 0.0, 1.0)
		var sc := lerpf(2.2, 1.0, k) + 0.04 * sin(lt * 14.0)
		var pr := _panel_rect(int(s.get("panel", 0)))
		var pos: Vector2 = pr.position + Vector2(s["pos"]) * pr.size
		ComicArt.shout(ci, s["text"], pos, int(s.get("size", 64)), Color(s.get("color", GOLD)), 12, float(s.get("rot", -0.08)), sc)
	for b: Dictionary in page.get("text", []) if _dive < 0.0 else []:
		var lt := _t - float(b["at"])
		if lt < 0.0:
			continue
		var full := String(b["text"])
		var shown := full.substr(0, int(lt * float(b.get("cps", CPS))))
		var pr := _panel_rect(int(b.get("panel", 0)))
		if b["type"] == "caption":
			_caption(ci, pr, b, shown, full)
		else:
			_bubble(ci, pr, b, shown, full)
	var hint := "Z: next   ESC: skip"
	ci.draw_string(FONT_BODY, Vector2(size.x - 230, size.y - 14), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 1, 1, 0.6))
	for k in _pages.size():
		ci.draw_circle(Vector2(40 + k * 22, size.y - 21), 6.0, GOLD if k == _page else Color(1, 1, 1, 0.3))
	if _dive >= 0.0:
		_draw_dive(ci)
	if _flash > 0.0:
		ci.draw_rect(Rect2(Vector2(-40, -40), size + Vector2(80, 80)), Color(1, 0.98, 0.9, minf(1.0, _flash)))
	if _wipe >= 0.0:
		# an ink wedge sweeps across the page
		var p := _wipe / WIPE
		var x := lerpf(-size.x * 0.6, size.x * 1.6, p)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x - size.x * 0.9, 0), Vector2(x + 160, 0), Vector2(x - 160, size.y), Vector2(x - size.x * 1.2, size.y)]), INK)


## The comic opens: its cover swings open on the spine, two pages flick past, the page fills with light.
func _draw_dive(ci: CanvasItem) -> void:
	var quad := PackedVector2Array()
	if not _panels.is_empty() and _panels[0].key == "book_cover":
		quad = _panels[0].cover_quad_in_parent()
	if quad.size() == 4 and _dive > 0.34:
		# the first page, under the cover, with the gutter shadow by the spine
		ci.draw_colored_polygon(quad, PAPER)
		var gut := PackedVector2Array([quad[0], quad[0].lerp(quad[1], 0.08), quad[3].lerp(quad[2], 0.08), quad[3]])
		ci.draw_polygon(gut, PackedColorArray([Color(0, 0, 0, 0.35), Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0.35)]))
		for j in 2:
			var pk := clampf((_dive - 0.78 - j * 0.12) / 0.3, 0.0, 1.0)
			if pk > 0.0 and pk < 1.0:
				_swing(ci, quad, pk, null)
		var sw := clampf((_dive - 0.34) / 0.5, 0.0, 1.0)
		if sw < 1.0:
			_swing(ci, quad, sw * sw, _panels[0].texture())
	var w := clampf((_dive - 1.0) / 0.5, 0.0, 1.0)
	ci.draw_rect(Rect2(Vector2(-40, -40), size + Vector2(80, 80)), Color(1, 0.98, 0.9, w * w))


## Draws the cover (tex) or a page (no tex) of the book swung open by k (0 shut .. 1 flat open)
## around the spine: the left edge of the cover quad.
func _swing(ci: CanvasItem, quad: PackedVector2Array, k: float, tex: Texture2D) -> void:
	var th := k * PI
	var c := cos(th)
	var lift := sin(th) * 80.0 # the free edge swings toward us
	var tr := quad[0] + (quad[1] - quad[0]) * c + Vector2(0, -lift)
	var br := quad[3] + (quad[2] - quad[3]) * c + Vector2(0, lift)
	if absf(tr.x - quad[0].x) < 4.0:
		return
	var pts := PackedVector2Array([quad[0], tr, br, quad[3]])
	var shade := 1.0 - 0.5 * sin(th)
	if tex != null and c > 0.0:
		var uvs := PackedVector2Array()
		for v: Vector2 in ComicPanel.COVER_QUAD:
			uvs.append(v)
		var col := Color(shade, shade, shade)
		ci.draw_polygon(pts, PackedColorArray([col, col, col, col]), uvs, tex)
	else:
		var inside := Color("1d2a4a") if tex != null else PAPER
		ci.draw_colored_polygon(pts, Color(inside.r * shade, inside.g * shade, inside.b * shade))
	pts.append(pts[0])
	ci.draw_polyline(pts, INK, 3.0)


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
