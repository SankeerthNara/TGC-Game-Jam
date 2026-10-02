class_name DeathOverlay
extends Control
## Shown when the hero runs out of hearts. Z / Enter / Space starts a new run.

signal restart

const FONT_SHOUT := preload("res://assets/fonts/Bangers-Regular.ttf")
const FONT_BODY := preload("res://assets/fonts/ComicNeue-Bold.ttf")

var _t := 0.0
var message := "The station won this round. Back to the checkpoint!"


func _ready() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _t > 0.8 and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_Z, KEY_ENTER, KEY_SPACE]:
		restart.emit()
		get_viewport().set_input_as_handled()


func _draw() -> void:
	var vp := get_viewport_rect().size
	var k := minf(_t / 0.6, 1.0)
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.35, 0.0, 0.05, 0.82 * k))
	var c := vp * 0.5
	draw_set_transform(c, -0.05, Vector2(k, k))
	draw_rect(Rect2(-330, -110, 660, 220), Color("fff3d1"))
	draw_rect(Rect2(-330, -110, 660, 220), Color("18151d"), false, 8.0)
	draw_rect(Rect2(-330, -110, 660, 78), Color("e63946"))
	draw_rect(Rect2(-330, -110, 660, 78), Color("18151d"), false, 8.0)
	var s1 := FONT_SHOUT.get_string_size("YOU DIED!", HORIZONTAL_ALIGNMENT_LEFT, -1, 72)
	draw_string(FONT_SHOUT, Vector2(-s1.x * 0.5, -42), "YOU DIED!", HORIZONTAL_ALIGNMENT_LEFT, -1, 72, Color("fff3d1"))
	var msg := message
	var s2 := FONT_BODY.get_string_size(msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 26)
	draw_string(FONT_BODY, Vector2(-s2.x * 0.5, 14), msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("18151d"))
	if _t > 0.8 and int(_t * 2.0) % 2 == 0:
		var s3 := FONT_SHOUT.get_string_size("PRESS Z TO RESPAWN", HORIZONTAL_ALIGNMENT_LEFT, -1, 36)
		draw_string(FONT_SHOUT, Vector2(-s3.x * 0.5, 72), "PRESS Z TO RESPAWN", HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color("e63946"))
	draw_set_transform(Vector2.ZERO)
