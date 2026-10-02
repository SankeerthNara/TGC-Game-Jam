class_name PageView
extends Node2D
## Draws the page and turns mouse input into swap/toggle requests.
## Placeholder visuals: Antigravity restyles via ui/ and assets/ without touching logic.

signal swap_requested(a: int, b: int)
signal toggle_requested(cell: Vector2i)
signal locked_panel_clicked(panel: int)

const GUTTER := 16.0
const PAPER := Color("f6ecd2")
const INK := Color("1b1b24")
const BEAM := Color("ffd23f")
const BEAM_CORE := Color("fffbe6")
const GOOD := Color("ffb703")
const BAD := Color("c1121f")
const MIRROR_COLOR := Color("3a86ff")
const FIXED_COLOR := Color("6c757d")

var model: PageModel
var trace: Dictionary = {"paths": [], "lit": {}}
var input_enabled := true
var cell_size := 64.0
var origin := Vector2.ZERO

var _drag_panel := -1
var _drag_start := Vector2.ZERO
var _drag_pos := Vector2.ZERO
var _dragging := false
var _shake := 0.0


func _ready() -> void:
	get_viewport().size_changed.connect(func() -> void:
		_layout()
		queue_redraw())


func set_model(m: PageModel) -> void:
	model = m
	_layout()
	queue_redraw()


func set_trace(t: Dictionary) -> void:
	trace = t
	queue_redraw()


func shake(amount := 10.0) -> void:
	_shake = amount


func _layout() -> void:
	if model == null:
		return
	var area := get_viewport_rect().size - Vector2(120, 260)
	var gut := Vector2(GUTTER * (model.cols - 1), GUTTER * (model.rows - 1))
	cell_size = floorf(minf((area.x - gut.x) / model.width, (area.y - gut.y) / model.height))
	cell_size = clampf(cell_size, 24.0, 96.0)
	var size := Vector2(model.width, model.height) * cell_size + gut
	origin = Vector2((get_viewport_rect().size.x - size.x) * 0.5, 150.0 + (area.y - size.y) * 0.5)


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


func _process(delta: float) -> void:
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 40.0)
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if model == null or not input_enabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag_panel = panel_at(event.position)
			_drag_start = event.position
			_drag_pos = event.position
			_dragging = false
		elif _drag_panel >= 0:
			_finish_drag(event.position)
	elif event is InputEventMouseMotion and _drag_panel >= 0:
		_drag_pos = event.position
		if not _dragging and _drag_pos.distance_to(_drag_start) > 8.0 and not model.locked.has(_drag_panel):
			_dragging = true
		queue_redraw()


func _finish_drag(pos: Vector2) -> void:
	var from := _drag_panel
	var was_dragging := _dragging
	_drag_panel = -1
	_dragging = false
	queue_redraw()
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


func _draw() -> void:
	if model == null:
		return
	var off := Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake)) if _shake > 0.0 else Vector2.ZERO
	draw_set_transform(off)
	for i in model.panel_count():
		if i != _drag_panel or not _dragging:
			_draw_panel(i, Vector2.ZERO)
	_draw_beams()
	if _dragging:
		_draw_panel(_drag_panel, _drag_pos - _drag_start)
	draw_set_transform(Vector2.ZERO)


func _draw_panel(panel: int, shift: Vector2) -> void:
	var r := panel_rect(panel)
	r.position += shift
	draw_rect(Rect2(r.position + Vector2(6, 6), r.size), Color(0, 0, 0, 0.25)) # drop shadow
	draw_rect(r, PAPER)
	var o := model.panel_origin(panel)
	for ly in model.ph:
		for lx in model.pw:
			var i := model.index_of(o + Vector2i(lx, ly))
			var cr := Rect2(r.position + Vector2(lx, ly) * cell_size, Vector2(cell_size, cell_size))
			_draw_cell(i, cr)
	var border := INK if not model.locked.has(panel) else Color("8d0801")
	draw_rect(r, border, false, 4.0)
	if model.locked.has(panel):
		draw_string(ThemeDB.fallback_font, r.position + Vector2(8, 22), "LOCKED", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, border)


func _draw_cell(i: int, cr: Rect2) -> void:
	var c := cr.get_center()
	var s := cell_size
	match model.kind[i]:
		PageModel.Kind.WALL:
			draw_rect(cr.grow(-3), INK)
			for k in range(1, 4):
				draw_line(cr.position + Vector2(0, s * k / 4.0), cr.position + Vector2(s * k / 4.0, 0), PAPER, 1.5)
		PageModel.Kind.MIRROR_SLASH, PageModel.Kind.FIXED_SLASH:
			_draw_mirror(c, s, true, model.kind[i] == PageModel.Kind.FIXED_SLASH)
		PageModel.Kind.MIRROR_BACK, PageModel.Kind.FIXED_BACK:
			_draw_mirror(c, s, false, model.kind[i] == PageModel.Kind.FIXED_BACK)
		PageModel.Kind.EMITTER:
			draw_circle(c, s * 0.32, INK)
			draw_circle(c, s * 0.24, BEAM)
			var d := Vector2(PageModel.DIRS[model.dir[i]])
			draw_line(c, c + d * s * 0.42, INK, 5.0)
		PageModel.Kind.TARGET_GOOD, PageModel.Kind.TARGET_BAD:
			_draw_target(i, c, s)


func _draw_mirror(c: Vector2, s: float, slash: bool, fixed: bool) -> void:
	var h := s * 0.38
	var a := c + (Vector2(-h, h) if slash else Vector2(-h, -h))
	var b := c + (Vector2(h, -h) if slash else Vector2(h, h))
	draw_line(a, b, INK, 9.0)
	draw_line(a, b, FIXED_COLOR if fixed else MIRROR_COLOR, 5.0)


func _draw_target(i: int, c: Vector2, s: float) -> void:
	var good := model.target_is_good(i)
	var lit: bool = trace["lit"].has(i)
	var col := GOOD if good else BAD
	draw_circle(c, s * 0.34, INK)
	draw_circle(c, s * 0.27, col if lit else PAPER)
	if good:
		draw_arc(c, s * 0.27, 0, TAU, 24, col, 3.0)
		if lit:
			draw_circle(c, s * 0.12, BEAM_CORE)
	else:
		var d := s * 0.15
		draw_line(c + Vector2(-d, -d), c + Vector2(d, d), INK if not lit else PAPER, 4.0)
		draw_line(c + Vector2(-d, d), c + Vector2(d, -d), INK if not lit else PAPER, 4.0)


func _draw_beams() -> void:
	for path: PackedVector2Array in trace["paths"]:
		var pts := PackedVector2Array()
		for p in path:
			pts.append(to_px(p))
		if pts.size() < 2:
			continue
		draw_polyline(pts, Color(BEAM.r, BEAM.g, BEAM.b, 0.28), 16.0, true)
		draw_polyline(pts, BEAM, 7.0, true)
		draw_polyline(pts, BEAM_CORE, 3.0, true)
