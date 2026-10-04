class_name TaskBase
extends Control
## Base class of every interactive task mini-game (wires, fuses, lanterns, ...).
## A task is a full-screen overlay with a comic panel in the middle. It emits `finished`
## when the player completes it (true) or backs out with Esc (false).

signal finished(success: bool)

const FONT_SHOUT := preload("res://assets/fonts/Bangers-Regular.ttf")
const FONT_BODY := preload("res://assets/fonts/ComicNeue-Bold.ttf")
const TEX_GLOW := preload("res://assets/art/radial_glow.png")
const INK := Color("18151d")
const PAPER := Color("fff3d1")
const GOLD := Color("ffd23f")
const RED := Color("e63946")
const GREEN := Color("2d6a4f")

var difficulty := 0 ## 0..3: set by the game before the task opens; higher is harder
var panel := Rect2(Vector2(240, 105), Vector2(800, 520))
var title := "TASK"
var hint := ""

var _t := 0.0
var _done := false
var _finished_emitted := false
var _done_t := 0.0
var _msg := ""
var _msg_t := 0.0
var _shake := 0.0


func _fit() -> void:
	# The parent is a CanvasLayer, so anchors do nothing: size the overlay by hand.
	# Without a real size the control never receives mouse clicks.
	position = Vector2.ZERO
	size = get_viewport_rect().size


func _ready() -> void:
	_fit()
	get_viewport().size_changed.connect(_fit)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	grab_focus()
	_begin()


## Override: set title/hint and initial state.
func _begin() -> void:
	pass


## Override: advance the game.
func _update(_delta: float) -> void:
	pass


## Override: draw the mini-game inside `panel`.
func _draw_task() -> void:
	pass


func succeed() -> void:
	if not _done:
		EventBus.sound_requested.emit("task_success")
		_done = true
		_done_t = 0.0


func _finish(success: bool) -> void:
	if _finished_emitted:
		return
	_finished_emitted = true
	finished.emit(success)
	set_process(false)


func flash(text: String, shake := 0.0) -> void:
	EventBus.sound_requested.emit("task_mistake")
	_msg = text
	_msg_t = 1.1
	_shake = maxf(_shake, shake)


func _process(delta: float) -> void:
	_t += delta
	_msg_t = maxf(0.0, _msg_t - delta)
	_shake = maxf(0.0, _shake - delta * 30.0)
	if _done:
		_done_t += delta
		if _done_t > 1.15:
			_finish(true)
		queue_redraw()
		return
	_update(delta)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE or event.keycode == KEY_X:
		_finish(_done)
		get_viewport().set_input_as_handled()


func _text(s: String, pos: Vector2, size: int, col: Color, font: Font = FONT_BODY, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	draw_string(font, pos, s, align, width, size, col)


func _centered(s: String, y: float, size: int, col: Color, font: Font = FONT_BODY) -> void:
	_text(s, Vector2(panel.position.x, y), size, col, font, HORIZONTAL_ALIGNMENT_CENTER, panel.size.x)


func _draw() -> void:
	var vp := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.72))
	var off := Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake)) if _shake > 0.0 else Vector2.ZERO
	draw_set_transform(off)
	draw_rect(Rect2(panel.position + Vector2(8, 8), panel.size), Color(0, 0, 0, 0.5))
	draw_rect(panel, PAPER)
	draw_rect(panel, INK, false, 6.0)
	draw_rect(Rect2(panel.position, Vector2(panel.size.x, 62)), GOLD)
	draw_rect(Rect2(panel.position, Vector2(panel.size.x, 62)), INK, false, 6.0)
	var title_size := 44
	while title_size > 24 and FONT_SHOUT.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x > panel.size.x - 205.0:
		title_size -= 1
	_text(title, panel.position + Vector2(24, 47), title_size, INK, FONT_SHOUT)
	_text("ESC: leave", Vector2(panel.end.x - 150, panel.position.y + 40), 20, INK)
	if hint != "":
		var hint_size := 20
		while hint_size > 12 and FONT_BODY.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, hint_size).x > panel.size.x - 48.0:
			hint_size -= 1
		_centered(hint, panel.end.y - 18, hint_size, Color("5c5470"))
	_draw_task()
	draw_set_transform(Vector2.ZERO)
	if _msg_t > 0.0:
		var a := minf(_msg_t / 0.3, 1.0)
		_centered(_msg, panel.position.y + 100, 34, Color(RED.r, RED.g, RED.b, a), FONT_SHOUT)
	if _done:
		var k := minf(_done_t / 0.18, 1.0)
		var c := panel.get_center()
		draw_rect(panel, Color(1, 1, 1, 0.55 * k))
		draw_set_transform(c, -0.07, Vector2(k, k) * 1.0)
		draw_rect(Rect2(-250, -52, 500, 104), GOLD)
		draw_rect(Rect2(-250, -52, 500, 104), INK, false, 7.0)
		var sz := FONT_SHOUT.get_string_size("TASK COMPLETE!", HORIZONTAL_ALIGNMENT_LEFT, -1, 62)
		draw_string(FONT_SHOUT, Vector2(-sz.x * 0.5, 22), "TASK COMPLETE!", HORIZONTAL_ALIGNMENT_LEFT, -1, 62, INK)
		draw_set_transform(Vector2.ZERO)


func _glow(pos: Vector2, radius: float, col: Color) -> void:
	draw_texture_rect(TEX_GLOW, Rect2(pos - Vector2(radius, radius), Vector2(radius, radius) * 2.0), false, col)
