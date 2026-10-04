class_name BrightnessFinale
extends CanvasLayer
## The last blow belongs to the player: the three freed heroes pour their light into the pulp hero,
## and a real "Brightness" slider appears. Drag it (or hold RIGHT) to 100% to flood the stage with
## sunlight. Emits finished.

signal finished

const FONT_UI := preload("res://assets/fonts/ComicNeue-Bold.ttf")
const FONT_SHOUT := preload("res://assets/fonts/Bangers-Regular.ttf")

var _value := 0.2
var _t := 0.0
var _done := false
var _drag := false
var _node: Control


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_node = Control.new()
	_node.size = Vector2(1280, 720)
	_node.mouse_filter = Control.MOUSE_FILTER_STOP
	_node.draw.connect(_draw_ui)
	_node.gui_input.connect(_on_gui)
	add_child(_node)


func _track() -> Rect2:
	return Rect2(Vector2(440, 600), Vector2(400, 10))


func _on_gui(event: InputEvent) -> void:
	if _done or _t < 1.5:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_drag = event.pressed and _track().grow(24.0).has_point(event.position)
		if _drag:
			_set_from_x(event.position.x)
	elif event is InputEventMouseMotion and _drag:
		_set_from_x(event.position.x)


func _set_from_x(x: float) -> void:
	var tr := _track()
	_value = maxf(_value, clampf((x - tr.position.x) / tr.size.x, 0.0, 1.0))


func _process(delta: float) -> void:
	_t += delta
	if not _done and _t > 1.5 and (Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)):
		_value = minf(1.0, _value + delta * 0.35)
	if not _done and _value >= 0.999:
		_done = true
		_t = 0.0
		EventBus.sound_requested.emit("light_swell")
	if _done and _t > 2.2:
		set_process(false)
		finished.emit()
		queue_free()
	_node.queue_redraw()


func _draw_ui() -> void:
	var ci := _node
	var light := _value if not _done else 1.0
	# the stage brightens with the slider
	ci.draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color(1.0, 0.95, 0.75, 0.15 + 0.6 * light * light))
	# three beams of light converge on the hero
	var hero := Vector2(640, 520)
	for i in 3:
		var from := Vector2([260.0, 640.0, 1020.0][i], 170.0)
		var w := 6.0 + 30.0 * light
		ci.draw_line(from, hero, Color(1, 0.95, 0.6, 0.25 + 0.5 * light), w)
		ci.draw_line(from, hero, Color(1, 1, 0.9, 0.6), w * 0.35)
	ci.draw_circle(hero, 40.0 + 120.0 * light, Color(1, 1, 0.85, 0.35))
	if _done:
		ci.draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color(1, 1, 1, clampf(_t / 0.6, 0.0, 1.0)))
		return
	if _t < 1.5:
		ComicArt.shout(ci, "READER! TURN UP THE LIGHT!", Vector2(640, 300), 60, Color("ffd23f"), 12, -0.03)
		return
	# a plain system slider: the real world reaching into the comic
	var panel := Rect2(Vector2(400, 540), Vector2(480, 110))
	ci.draw_rect(Rect2(panel.position + Vector2(0, 8), panel.size), Color(0, 0, 0, 0.3))
	ci.draw_rect(panel, Color(0.96, 0.96, 0.97))
	ci.draw_string(FONT_UI, panel.position + Vector2(40, 38), "Brightness", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.1, 0.1, 0.15))
	ci.draw_string(FONT_UI, panel.position + Vector2(400, 38), "%d%%" % int(_value * 100.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.1, 0.1, 0.15))
	var tr := _track()
	ci.draw_rect(tr, Color(0.82, 0.83, 0.87))
	ci.draw_rect(Rect2(tr.position, Vector2(tr.size.x * _value, tr.size.y)), Color(0.27, 0.52, 0.96))
	var knob := Vector2(tr.position.x + tr.size.x * _value, tr.get_center().y)
	ci.draw_circle(knob, 13.0, Color.WHITE)
	ci.draw_arc(knob, 13.0, 0.0, TAU, 24, Color(0.6, 0.6, 0.65), 2.0)
	ci.draw_string(FONT_UI, Vector2(450, 690), "Drag the slider to 100%  (or hold RIGHT)", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.15, 0.15, 0.2))
