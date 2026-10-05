class_name SettingsTwist
extends CanvasLayer
## The fourth wall: a "video settings" window appears over the game.
##   mode "player": the player clicks 720p themselves (mouse, or Up/Down + Enter).
##   mode "hijack": the cursor moves by itself and picks 2K (the Narrator is in control).
## Emits finished(choice) once the new resolution is "applied".

signal finished(choice: String)

const FONT_UI := preload("res://assets/fonts/ComicNeue-Bold.ttf")
const OPTIONS := ["240p", "360p", "720p", "1080p", "2K"]

var mode := "player"
var _t := 0.0
var _phase := "in" ## in | choose | apply | out
var _sel := 0
var _choice := ""
var _hover := -1
var _cursor := Vector2(900, 600)
var _shake := 0.0
var _msg := ""
var _apply_t := 0.0
var _node: Control
var _path: Array[Vector2] = []


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_node = Control.new()
	_node.size = Vector2(1280, 720)
	_node.mouse_filter = Control.MOUSE_FILTER_STOP
	_node.draw.connect(_draw_ui)
	_node.gui_input.connect(_on_gui)
	add_child(_node)
	_sel = 0
	if mode == "hijack":
		_cursor = Vector2(1180, 680)
		_path = [Vector2(760, 330), _opt_rect(4).get_center() + Vector2(-40, 0)]
	EventBus.sound_requested.emit("glitch")
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _panel() -> Rect2:
	return Rect2(Vector2(390, 170), Vector2(500, 380))


func _opt_rect(i: int) -> Rect2:
	var p := _panel()
	return Rect2(p.position + Vector2(40, 150 + i * 40), Vector2(420, 34))


func _on_gui(event: InputEvent) -> void:
	if mode != "player" or _phase != "choose":
		return
	if event is InputEventMouseMotion:
		_cursor = event.position
		_hover = -1
		for i in OPTIONS.size():
			if _opt_rect(i).has_point(event.position):
				_hover = i
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in OPTIONS.size():
			if _opt_rect(i).has_point(event.position):
				_pick(i)


func _unhandled_input(event: InputEvent) -> void:
	if mode != "player" or _phase != "choose" or not (event is InputEventKey) or not event.pressed:
		return
	if event.keycode in [KEY_UP, KEY_W]:
		_hover = (maxi(_hover, 0) + OPTIONS.size() - 1) % OPTIONS.size()
	elif event.keycode in [KEY_DOWN, KEY_S]:
		_hover = (_hover + 1) % OPTIONS.size()
	elif event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_Z, KEY_SPACE] and _hover >= 0:
		_pick(_hover)
	get_viewport().set_input_as_handled()


func _pick(i: int) -> void:
	EventBus.sound_requested.emit("cursor_click")
	if mode == "player" and OPTIONS[i] != "720p":
		_shake = 0.4
		_msg = "Not unlocked yet." if i > 2 else "That's even worse!"
		return
	_choice = OPTIONS[i]
	_sel = i
	_phase = "apply"
	_apply_t = 0.0


func _process(delta: float) -> void:
	_t += delta
	_shake = maxf(0.0, _shake - delta)
	match _phase:
		"in":
			if _t > 0.5:
				_phase = "choose"
				_t = 0.0
				if mode == "player":
					_hover = 2
		"choose":
			if mode == "hijack":
				# the cursor moves on its own; nobody is touching the mouse
				if not _path.is_empty():
					_cursor = _cursor.move_toward(_path[0], 520.0 * delta)
					if _cursor.distance_to(_path[0]) < 2.0:
						_path.pop_front()
						if _path.is_empty():
							_hover = 4
				elif _t > 3.2:
					_pick(4)
				for i in OPTIONS.size():
					if _opt_rect(i).has_point(_cursor):
						_hover = i
		"apply":
			_apply_t += delta
			if _apply_t > 1.4:
				_phase = "out"
				_t = 0.0
				EventBus.sound_requested.emit("resolution_change")
		"out":
			if _t > 0.25:
				set_process(false)
				finished.emit(_choice)
				queue_free()
	_node.queue_redraw()


func _draw_ui() -> void:
	var ci := _node
	var k := clampf(_t / 0.3, 0.0, 1.0) if _phase == "in" else (1.0 - clampf(_t / 0.25, 0.0, 1.0) if _phase == "out" else 1.0)
	ci.draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color(0, 0, 0, 0.45 * k))
	var p := _panel()
	var off := Vector2(sin(_t * 80.0) * 8.0 * _shake, 0)
	p.position += off
	p.position.y += (1.0 - k) * 30.0
	# a plain, modern "system" window: deliberately NOT comic style, it belongs to the real world
	ci.draw_rect(Rect2(p.position + Vector2(0, 10), p.size), Color(0, 0, 0, 0.35 * k))
	ci.draw_rect(p, Color(0.96, 0.96, 0.97, k))
	ci.draw_rect(Rect2(p.position, Vector2(p.size.x, 44)), Color(0.88, 0.89, 0.92, k))
	ci.draw_string(FONT_UI, p.position + Vector2(18, 29), "Video Settings", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.15, 0.15, 0.2, k))
	ci.draw_string(FONT_UI, p.end + Vector2(-38, -p.size.y + 29), "x", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.4, 0.4, 0.45, k))
	ci.draw_string(FONT_UI, p.position + Vector2(40, 90), "Display", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.4, 0.4, 0.45, k))
	ci.draw_string(FONT_UI, p.position + Vector2(40, 128), "Resolution", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.1, 0.1, 0.15, k))
	for i in OPTIONS.size():
		var r := _opt_rect(i)
		r.position += off
		var current := (i == 0 and mode == "player") or (i == 2 and mode == "hijack")
		var bg := Color(0.92, 0.93, 0.95, k)
		if i == _hover:
			bg = Color(0.27, 0.52, 0.96, k)
		if _phase == "apply" and i == _sel:
			bg = Color(0.18, 0.7, 0.4, k)
		ci.draw_rect(r, bg)
		var col := Color.WHITE if i == _hover or (_phase == "apply" and i == _sel) else Color(0.15, 0.15, 0.2, k)
		ci.draw_string(FONT_UI, r.position + Vector2(14, 24), OPTIONS[i] + ("   (current)" if current else ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 19, col)
	if _msg != "" and _phase == "choose":
		ci.draw_string(FONT_UI, p.position + Vector2(40, p.size.y - 14), _msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.8, 0.2, 0.2, k))
	if _phase == "apply":
		var bar := Rect2(p.position + Vector2(40, p.size.y - 30), Vector2(420, 10))
		ci.draw_rect(bar, Color(0.85, 0.86, 0.9))
		ci.draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(_apply_t / 1.3, 0.0, 1.0), bar.size.y)), Color(0.27, 0.52, 0.96))
		ci.draw_string(FONT_UI, p.position + Vector2(40, p.size.y - 40), "Applying %s..." % _choice, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.2, 0.2, 0.25))
	# the mouse cursor (the real one is hidden while the window is up)
	var c := _cursor
	var head := PackedVector2Array([c, c + Vector2(0, 26), c + Vector2(20, 17)])
	var tail := PackedVector2Array([c + Vector2(7, 19), c + Vector2(12, 30), c + Vector2(16, 28), c + Vector2(11, 17)])
	ci.draw_colored_polygon(tail, Color.WHITE)
	ci.draw_colored_polygon(head, Color.WHITE)
	var outline := PackedVector2Array([c, c + Vector2(0, 26), c + Vector2(7, 19), c + Vector2(12, 30), c + Vector2(16, 28), c + Vector2(11, 17), c + Vector2(20, 17), c])
	ci.draw_polyline(outline, Color.BLACK, 1.5)
