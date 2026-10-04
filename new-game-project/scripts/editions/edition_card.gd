class_name EditionCard
extends Control
## A simple full-screen title card (edition title + a few lines). Z / Enter / Space continues.

signal done

const FONT_SHOUT := preload("res://assets/fonts/Bangers-Regular.ttf")
const FONT_BODY := preload("res://assets/fonts/ComicNeue-Bold.ttf")

var title := ""
var lines: Array = []
var _t := 0.0


func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _t > 0.6 and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_Z, KEY_ENTER, KEY_SPACE]:
		get_viewport().set_input_as_handled()
		done.emit()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("0d0b10"))
	ComicArt.shout(self, title, Vector2(640, 300), 96, Color("ffd23f"), 14, -0.03)
	for i in lines.size():
		var s := String(lines[i])
		var w := FONT_BODY.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
		draw_string(FONT_BODY, Vector2(640 - w * 0.5, 420 + i * 36), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("fff3d1"))
