class_name PageView
extends Node2D
## Draws the comic page and turns mouse input into swap/toggle requests.
## Pure presentation: all rules live in PageModel / BeamSolver.

signal swap_requested(a: int, b: int)
signal toggle_requested(cell: Vector2i)
signal locked_panel_clicked(panel: int)

const TEX_PAPER := preload("res://assets/art/paper_texture.png")
const TEX_HALFTONE := preload("res://assets/art/halftone_dot.png")
const TEX_GLOW := preload("res://assets/art/radial_glow.png")
const FONT_SHOUT := preload("res://assets/fonts/Bangers-Regular.ttf")

## Page skins: the narrator sometimes drops you into some other comic entirely.
const SKINS := {
	"": {"paper": Color("fff3d1"), "ink": Color("18151d"), "bg": Color("2a2740")},
	"romance": {"paper": Color("ffd9e4"), "ink": Color("4a0d2b"), "bg": Color("3d1730")},
	"cooking": {"paper": Color("ffe9c9"), "ink": Color("4a2308"), "bg": Color("3a2412")},
}

const GUTTER := 18.0
const TOP_MARGIN := 138.0
const BOTTOM_MARGIN := 92.0

const PAPER_NORMAL := Color("fff3d1")
const PAPER_TWIST := Color("5a3aa8") ## negative-print inversion after the narrator's twist
const INK_NORMAL := Color("18151d")
const INK_TWIST := Color("f1e9ff")
const BG_NORMAL := Color("2a2740")
const BG_TWIST := Color("120a2e")
const BEAM := Color("ffd23f")
const BEAM_CORE := Color("fffbe6")
const GOOD := Color("ffb703")
const BAD := Color("e63946")
const GLASS := Color("4cc9f0")
const GLASS_FIXED := Color("adb5bd")
const TAPE := Color("ffd23f")

var model: PageModel
var trace: Dictionary = {"paths": [], "lit": {}}
var input_enabled := true
var cell_size := 64.0
var origin := Vector2.ZERO

var _paper := PAPER_NORMAL
var _ink := INK_NORMAL
var _drag_panel := -1
var _drag_start := Vector2.ZERO
var _drag_pos := Vector2.ZERO
var _dragging := false
var _hover := Vector2i(-1, -1)
var _shake := 0.0
var _time := 0.0
var _slide := {} ## panel index -> pixel offset easing back to zero after a swap
var _pops: Array[Dictionary] = [] ## floating comic words
var _last_lit := 0
var _was_flipped := false
var _hero := HeroActor.new()
var _status := {}
var _confused := false


func _ready() -> void:
	get_viewport().size_changed.connect(func() -> void:
		_layout()
		queue_redraw())
	EventBus.panel_swapped.connect(_on_swapped)
	EventBus.mirror_toggled.connect(_on_mirror)
	EventBus.panel_rejected.connect(_on_rejected)
	EventBus.twist_triggered.connect(func(kind: String) -> void:
		if kind == "wrong_page":
			_confused = true
			_pop("WRONG PAGE!", Vector2(640, 118), BAD, 64)
		else:
			_pop("PLOT TWIST!", Vector2(640, 110), BAD, 64))


func set_model(m: PageModel) -> void:
	model = m
	_slide.clear()
	_pops.clear()
	_last_lit = 0
	_was_flipped = false
	_confused = false
	_hero.reset()
	RenderingServer.set_default_clear_color(SKINS.get(m.skin, SKINS[""])["bg"])
	_layout()
	queue_redraw()


func set_trace(t: Dictionary) -> void:
	var lit_now: int = (t["lit"] as Dictionary).size()
	if model != null and lit_now > _last_lit:
		_pop("ZAP!", _lit_pos(t), GOOD, 46)
	_last_lit = lit_now
	trace = t
	if model != null:
		_status = model.status(t)
		_aim_hero(t)
	queue_redraw()


func shake(amount := 10.0) -> void:
	_shake = amount


func _layout() -> void:
	if model == null:
		return
	var vp := get_viewport_rect().size
	var area := Vector2(vp.x - 90.0, vp.y - TOP_MARGIN - BOTTOM_MARGIN)
	var gut := Vector2(GUTTER * (model.cols - 1), GUTTER * (model.rows - 1))
	cell_size = floorf(minf((area.x - gut.x) / model.width, (area.y - gut.y) / model.height))
	cell_size = clampf(cell_size, 24.0, 104.0)
	var size := Vector2(model.width, model.height) * cell_size + gut
	origin = Vector2((vp.x - size.x) * 0.5, TOP_MARGIN + (area.y - size.y) * 0.5)


## Pixel position of a point given in (fractional) cell units.
func to_px(c: Vector2) -> Vector2:
	var pc := clampi(floori(c.x / model.pw), 0, model.cols - 1)
	var pr := clampi(floori(c.y / model.ph), 0, model.rows - 1)
	return origin + c * cell_size + Vector2(pc, pr) * GUTTER


func panel_rect(panel: int) -> Rect2:
	var o := model.panel_origin(panel)
	return Rect2(to_px(Vector2(o)), Vector2(model.pw, model.ph) * cell_size)


func panel_at(p: Vector2) -> int:
	for i in model.panel_count():
		if panel_rect(i).has_point(p):
			return i
	return -1


func cell_at(p: Vector2) -> Vector2i:
	var pan := panel_at(p)
	if pan < 0:
		return Vector2i(-1, -1)
	var local := (p - panel_rect(pan).position) / cell_size
	return model.panel_origin(pan) + Vector2i(floori(local.x), floori(local.y))


@warning_ignore("integer_division")
func _lit_pos(t: Dictionary) -> Vector2:
	for i: int in t["lit"]:
		return to_px(Vector2(i % model.width, i / model.width) + Vector2(0.5, -0.2))
	return Vector2(640, 300)


# --- hero --------------------------------------------------------------------

## Sends the hero to stand just before wherever the beam ends, looking at it.
func _aim_hero(t: Dictionary) -> void:
	var paths: Array = t["paths"]
	if paths.is_empty():
		_hero.set_target(Vector2(640, 360), Vector2(640, 360))
		return
	var path: PackedVector2Array = paths[0]
	var end := to_px(path[path.size() - 1])
	var prev := to_px(path[maxi(path.size() - 2, 0)])
	var dir := (end - prev).normalized() if end.distance_to(prev) > 1.0 else Vector2.RIGHT
	_hero.set_target(end - dir * cell_size * 0.65, end)
	if _confused:
		_hero.mood = HeroActor.Mood.CONFUSED
	elif _status.get("good_lit", 0) > 0:
		_hero.mood = HeroActor.Mood.HAPPY
	elif _status.get("bad_lit", 0) > 0:
		_hero.mood = HeroActor.Mood.SCARED
	else:
		_hero.mood = HeroActor.Mood.THINK


# --- juice -------------------------------------------------------------------

func _pop(text: String, pos: Vector2, color: Color, size := 40) -> void:
	_pops.append({"text": text, "pos": pos, "t": 0.0, "rot": randf_range(-0.22, 0.22), "color": color, "size": size})


func _on_swapped(a: int, b: int) -> void:
	if model == null:
		return
	var ra := panel_rect(a)
	var rb := panel_rect(b)
	_slide[a] = rb.position - ra.position # content now at a, glide in from where it was
	_slide[b] = ra.position - rb.position
	_pop(["WHOOSH!", "SHUFFLE!", "SWAP!"][randi() % 3], ra.get_center().lerp(rb.get_center(), 0.5) + Vector2(0, -cell_size), Color("ffffff"), 38)


func _on_mirror(cell: Vector2i) -> void:
	if model == null:
		return
	var pan := model.panel_index(cell)
	var local := Vector2(cell - model.panel_origin(pan)) + Vector2(0.5, -0.1)
	_pop("CLINK!", panel_rect(pan).position + local * cell_size, GLASS, 32)


func _on_rejected(panel: int) -> void:
	if model != null:
		_pop("STUCK!", panel_rect(panel).get_center(), BAD, 44)


func _process(delta: float) -> void:
	_time += delta
	_shake = maxf(0.0, _shake - delta * 40.0)
	for k: int in _slide.keys():
		_slide[k] = (_slide[k] as Vector2).lerp(Vector2.ZERO, 1.0 - exp(-delta * 12.0))
		if (_slide[k] as Vector2).length() < 0.6:
			_slide.erase(k)
	if model != null:
		_hero.villain = model.flipped
		if _confused:
			_hero.mood = HeroActor.Mood.CONFUSED
		_hero.update(delta, cell_size)
	for p in _pops:
		p["t"] += delta
	_pops = _pops.filter(func(p: Dictionary) -> bool: return p["t"] < 1.0)
	if model != null:
		if model.flipped != _was_flipped:
			_was_flipped = model.flipped
			RenderingServer.set_default_clear_color(BG_TWIST if _was_flipped else BG_NORMAL)
		queue_redraw()


# --- input -------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if model == null:
		return
	if event is InputEventMouseMotion:
		_hover = cell_at(event.position)
		if _drag_panel >= 0 and input_enabled:
			_drag_pos = event.position
			if not _dragging and _drag_pos.distance_to(_drag_start) > 8.0 and not model.locked.has(_drag_panel):
				_dragging = true
		return
	if not input_enabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag_panel = panel_at(event.position)
			_drag_start = event.position
			_drag_pos = event.position
			_dragging = false
		elif _drag_panel >= 0:
			_finish_drag(event.position)


func _finish_drag(pos: Vector2) -> void:
	var from := _drag_panel
	var was_dragging := _dragging
	_drag_panel = -1
	_dragging = false
	if was_dragging:
		var to := panel_at(pos)
		if to >= 0 and to != from:
			if model.locked.has(to):
				locked_panel_clicked.emit(to)
			else:
				swap_requested.emit(from, to)
	else:
		var cell := cell_at(pos)
		if cell.x >= 0 and model.is_rotatable(model.index_of(cell)):
			toggle_requested.emit(cell)
		elif model.locked.has(from):
			locked_panel_clicked.emit(from)


# --- drawing -----------------------------------------------------------------

func _draw() -> void:
	if model == null:
		return
	var skin: Dictionary = SKINS.get(model.skin, SKINS[""])
	_paper = PAPER_TWIST if model.flipped else skin["paper"]
	_ink = INK_TWIST if model.flipped else skin["ink"]
	var vp := get_viewport_rect().size
	draw_texture_rect(TEX_HALFTONE, Rect2(Vector2.ZERO, vp), true, Color(1, 1, 1, 0.07))
	var off := Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake)) if _shake > 0.0 else Vector2.ZERO
	draw_set_transform(off)
	for i in model.panel_count():
		if i != _drag_panel or not _dragging:
			_draw_panel(i, _slide.get(i, Vector2.ZERO))
	_draw_beams()
	_hero.draw(self, cell_size * 1.3, _ink, _paper, FONT_SHOUT, off)
	if _dragging:
		_draw_panel(_drag_panel, _drag_pos - _drag_start, true)
	draw_set_transform(Vector2.ZERO)
	_draw_pops()


func _draw_panel(panel: int, shift: Vector2, lifted := false) -> void:
	var r := panel_rect(panel)
	r.position += shift
	var shadow := Vector2(12, 12) if lifted else Vector2(6, 7)
	draw_rect(Rect2(r.position + shadow, r.size), Color(0, 0, 0, 0.4 if lifted else 0.32))
	draw_texture_rect(TEX_PAPER, r, false, _paper)
	var o := model.panel_origin(panel)
	# cell dots, so the grid reads without clutter
	var dot := Color(_ink.r, _ink.g, _ink.b, 0.16)
	for ly in model.ph:
		for lx in model.pw:
			draw_circle(r.position + (Vector2(lx, ly) + Vector2(0.5, 0.5)) * cell_size, 2.2, dot)
	for ly in model.ph:
		for lx in model.pw:
			var i := model.index_of(o + Vector2i(lx, ly))
			var cr := Rect2(r.position + Vector2(lx, ly) * cell_size, Vector2(cell_size, cell_size))
			_draw_cell(i, cr, o + Vector2i(lx, ly))
	draw_rect(r, _ink, false, 5.0)
	if model.locked.has(panel):
		_draw_tape(r)


func _draw_tape(r: Rect2) -> void:
	var c := r.get_center()
	var w := r.size.x * 0.98
	for ang in [0.55, -0.55]:
		draw_set_transform(c, ang)
		var band := Rect2(Vector2(-w * 0.5, -13), Vector2(w, 26))
		draw_rect(band, Color(TAPE.r, TAPE.g, TAPE.b, 0.9))
		var half := int((w * 0.5 - 18.0) / 34.0)
		for k in range(-half, half + 1):
			draw_line(Vector2(k * 34, -13), Vector2(k * 34 + 14, 13), _ink, 5.0)
		draw_rect(band, _ink, false, 2.5)
	draw_set_transform(Vector2.ZERO)
	var label := "LOCKED"
	var fs := 30
	var sz := FONT_SHOUT.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var p := c + Vector2(-sz.x * 0.5, 11)
	draw_rect(Rect2(p + Vector2(-8, -fs + 3), Vector2(sz.x + 16, fs + 4)), TAPE)
	draw_rect(Rect2(p + Vector2(-8, -fs + 3), Vector2(sz.x + 16, fs + 4)), _ink, false, 3.0)
	draw_string(FONT_SHOUT, p, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, _ink)


func _draw_cell(i: int, cr: Rect2, cell: Vector2i) -> void:
	var c := cr.get_center()
	var s := cell_size
	match model.kind[i]:
		PageModel.Kind.WALL:
			_draw_wall(cr)
		PageModel.Kind.MIRROR_SLASH, PageModel.Kind.FIXED_SLASH:
			_draw_mirror(c, s, true, model.kind[i] == PageModel.Kind.FIXED_SLASH, cell == _hover)
		PageModel.Kind.MIRROR_BACK, PageModel.Kind.FIXED_BACK:
			_draw_mirror(c, s, false, model.kind[i] == PageModel.Kind.FIXED_BACK, cell == _hover)
		PageModel.Kind.EMITTER:
			_draw_emitter(c, s, model.dir[i])
		PageModel.Kind.TARGET_GOOD, PageModel.Kind.TARGET_BAD:
			_draw_target(i, c, s)


func _draw_wall(cr: Rect2) -> void:
	var r := cr.grow(-cell_size * 0.06)
	draw_rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.3))
	var sb := StyleBoxFlat.new()
	sb.bg_color = _ink
	sb.set_corner_radius_all(int(cell_size * 0.12))
	draw_style_box(sb, r)
	var hatch := Color(_paper.r, _paper.g, _paper.b, 0.55)
	var n := 5
	for k in range(1, n):
		var t := float(k) / n
		draw_line(r.position + Vector2(r.size.x * t, r.size.y * 0.12), r.position + Vector2(r.size.x * 0.12, r.size.y * t), hatch, 1.6)


func _draw_mirror(c: Vector2, s: float, slash: bool, fixed: bool, hover: bool) -> void:
	var h := s * 0.4
	var a := c + (Vector2(-h, h) if slash else Vector2(-h, -h))
	var b := c + (Vector2(h, -h) if slash else Vector2(h, h))
	if hover and not fixed:
		draw_circle(c, s * 0.5, Color(GLASS.r, GLASS.g, GLASS.b, 0.28))
	var col := GLASS_FIXED if fixed else GLASS
	draw_line(a + Vector2(2, 3), b + Vector2(2, 3), Color(0, 0, 0, 0.3), s * 0.2)
	draw_line(a, b, _ink, s * 0.2)
	draw_line(a, b, col, s * 0.13)
	var n := (b - a).normalized().orthogonal()
	draw_line(a + n * s * 0.03, b + n * s * 0.03, Color(1, 1, 1, 0.8), s * 0.03)
	draw_circle(a, s * 0.06, _ink)
	draw_circle(b, s * 0.06, _ink)
	if not fixed:
		draw_circle(c, s * 0.06, _ink) # bolt: this one turns


func _draw_emitter(c: Vector2, s: float, d_idx: int) -> void:
	var d := Vector2(PageModel.DIRS[d_idx])
	var pulse := 1.0 + sin(_time * 5.0) * 0.06
	draw_texture_rect(TEX_GLOW, Rect2(c - Vector2(s, s) * 0.8, Vector2(s, s) * 1.6), false, Color(BEAM.r, BEAM.g, BEAM.b, 0.55))
	draw_circle(c + Vector2(2, 3), s * 0.33, Color(0, 0, 0, 0.3))
	draw_circle(c, s * 0.34, _ink)
	draw_circle(c, s * 0.26 * pulse, BEAM)
	draw_circle(c, s * 0.13, BEAM_CORE)
	# nozzle pointing along the beam direction
	var tip := c + d * s * 0.5
	var side := d.orthogonal() * s * 0.16
	draw_colored_polygon(PackedVector2Array([c + d * s * 0.28 + side, tip, c + d * s * 0.28 - side]), _ink)
	draw_colored_polygon(PackedVector2Array([c + d * s * 0.32 + side * 0.5, c + d * s * 0.45, c + d * s * 0.32 - side * 0.5]), BEAM)


func _star(c: Vector2, r_out: float, r_in: float, rot := -PI / 2.0, points := 5) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in points * 2:
		var r := r_out if k % 2 == 0 else r_in
		var a := rot + k * PI / points
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


func _draw_target(i: int, c: Vector2, s: float) -> void:
	var good := model.target_is_good(i)
	var lit: bool = trace["lit"].has(i)
	var col := GOOD if good else BAD
	var wob := sin(_time * 4.0 + c.x) * 0.04 if lit else 0.0
	if lit:
		draw_texture_rect(TEX_GLOW, Rect2(c - Vector2(s, s) * 0.95, Vector2(s, s) * 1.9), false, Color(col.r, col.g, col.b, 0.8))
	if good:
		var pts := _star(c, s * 0.42 * (1.0 + wob), s * 0.19)
		draw_colored_polygon(_offset(pts, Vector2(2, 3)), Color(0, 0, 0, 0.3))
		draw_colored_polygon(pts, col if lit else _paper)
		var closed := pts.duplicate()
		closed.append(pts[0])
		draw_polyline(closed, _ink, 3.5, true)
		if lit:
			draw_circle(c, s * 0.09, BEAM_CORE)
	else:
		var pts := _star(c, s * 0.42 * (1.0 + wob), s * 0.28, 0.0, 8)
		draw_colored_polygon(_offset(pts, Vector2(2, 3)), Color(0, 0, 0, 0.3))
		draw_colored_polygon(pts, col if lit else Color(_ink.r, _ink.g, _ink.b, 0.9))
		var closed := pts.duplicate()
		closed.append(pts[0])
		draw_polyline(closed, _ink if lit else col, 3.0, true)
		var d := s * 0.13
		var xc := _paper if not lit else Color.WHITE
		draw_line(c + Vector2(-d, -d), c + Vector2(d, d), xc, 4.5)
		draw_line(c + Vector2(-d, d), c + Vector2(d, -d), xc, 4.5)


func _offset(pts: PackedVector2Array, by: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(p + by)
	return out


func _draw_beams() -> void:
	var w := 1.0 + sin(_time * 9.0) * 0.06
	for path: PackedVector2Array in trace["paths"]:
		var pts := PackedVector2Array()
		for p in path:
			pts.append(to_px(p))
		if pts.size() < 2:
			continue
		draw_polyline(pts, Color(BEAM.r, BEAM.g, BEAM.b, 0.18), 30.0 * w, true)
		draw_polyline(pts, Color(BEAM.r, BEAM.g, BEAM.b, 0.35), 18.0 * w, true)
		draw_polyline(pts, BEAM, 8.0, true)
		draw_polyline(pts, BEAM_CORE, 3.5, true)
		for k in range(1, pts.size() - 1): # glow at every bounce
			draw_texture_rect(TEX_GLOW, Rect2(pts[k] - Vector2(22, 22), Vector2(44, 44)), false, Color(1, 0.95, 0.6, 0.8))
		draw_circle(pts[pts.size() - 1], 6.0, BEAM_CORE)


func _draw_pops() -> void:
	for p in _pops:
		var t: float = p["t"]
		var a := clampf(1.0 - maxf(0.0, t - 0.55) / 0.45, 0.0, 1.0)
		var pop := minf(t / 0.12, 1.0)
		var sc := 0.5 + 0.7 * pop - 0.2 * t
		var pos: Vector2 = (p["pos"] as Vector2) + Vector2(0, -50.0 * t)
		draw_set_transform(pos, p["rot"], Vector2(sc, sc))
		var fs: int = p["size"]
		var text: String = p["text"]
		var sz := FONT_SHOUT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		var tp := Vector2(-sz.x * 0.5, fs * 0.35)
		draw_string_outline(FONT_SHOUT, tp, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 10, Color(INK_NORMAL.r, INK_NORMAL.g, INK_NORMAL.b, a))
		var c: Color = p["color"]
		draw_string(FONT_SHOUT, tp, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(c.r, c.g, c.b, a))
	draw_set_transform(Vector2.ZERO)
