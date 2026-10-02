class_name LevelOverlay
extends Control
## Between levels: shows this level's time, the total, and the checkpoint. At the very end it shows every level's time.

signal continue_pressed

const FONT_SHOUT := preload("res://assets/fonts/Bangers-Regular.ttf")
const FONT_BODY := preload("res://assets/fonts/ComicNeue-Bold.ttf")
const INK := Color("18151d")
const GOLD := Color("ffd23f")

var final := false
var title := ""
var level_time := 0.0
var total_time := 0.0
var splits: Array = []
var next_title := ""
var _t := 0.0


func _ready() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	mouse_filter = Control.MOUSE_FILTER_STOP


func _fmt(t: float) -> String:
	var secs := int(t)
	return "%02d:%02d" % [secs / 60, secs % 60]


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _t > 0.7 and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_Z, KEY_ENTER, KEY_SPACE]:
		continue_pressed.emit()
		get_viewport().set_input_as_handled()


func _draw() -> void:
	var vp := get_viewport_rect().size
	var k := minf(_t / 0.4, 1.0)
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.78 * k))
	var h := 300.0 + (splits.size() * 34.0 if final else 0.0)
	var panel := Rect2(Vector2(vp.x * 0.5 - 340, vp.y * 0.5 - h * 0.5), Vector2(680, h))
	draw_rect(Rect2(panel.position + Vector2(8, 8), panel.size), Color(0, 0, 0, 0.5))
	draw_rect(panel, Color("fff3d1"))
	draw_rect(panel, INK, false, 6.0)
	draw_rect(Rect2(panel.position, Vector2(panel.size.x, 78)), Color("2dc653") if not final else GOLD)
	draw_rect(Rect2(panel.position, Vector2(panel.size.x, 78)), INK, false, 6.0)
	var head := "LEVEL COMPLETE!" if not final else "YOU SAVED THE STUDIO!"
	var hs := FONT_SHOUT.get_string_size(head, HORIZONTAL_ALIGNMENT_LEFT, -1, 54)
	draw_string(FONT_SHOUT, panel.position + Vector2((panel.size.x - hs.x) * 0.5, 58), head, HORIZONTAL_ALIGNMENT_LEFT, -1, 54, INK)
	var y := panel.position.y + 120.0
	draw_string(FONT_SHOUT, Vector2(panel.position.x + 40, y), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, INK)
	y += 44.0
	if final:
		for i in splits.size():
			draw_string(FONT_BODY, Vector2(panel.position.x + 60, y), "Level %d" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 26, INK)
			draw_string(FONT_SHOUT, Vector2(panel.end.x - 200, y), _fmt(splits[i]), HORIZONTAL_ALIGNMENT_RIGHT, 150, 28, INK)
			y += 34.0
		draw_line(Vector2(panel.position.x + 50, y - 16), Vector2(panel.end.x - 50, y - 16), INK, 3.0)
		draw_string(FONT_SHOUT, Vector2(panel.position.x + 60, y + 14), "TOTAL TIME", HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color("c1121f"))
		draw_string(FONT_SHOUT, Vector2(panel.end.x - 240, y + 14), _fmt(total_time), HORIZONTAL_ALIGNMENT_RIGHT, 190, 40, Color("c1121f"))
	else:
		draw_string(FONT_BODY, Vector2(panel.position.x + 40, y), "Level time", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, INK)
		draw_string(FONT_SHOUT, Vector2(panel.end.x - 240, y), _fmt(level_time), HORIZONTAL_ALIGNMENT_RIGHT, 190, 34, INK)
		y += 42.0
		draw_string(FONT_BODY, Vector2(panel.position.x + 40, y), "Total time", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, INK)
		draw_string(FONT_SHOUT, Vector2(panel.end.x - 240, y), _fmt(total_time), HORIZONTAL_ALIGNMENT_RIGHT, 190, 34, INK)
		y += 46.0
		draw_string(FONT_BODY, Vector2(panel.position.x + 40, y), "Checkpoint saved! If you run out of hearts, you restart %s." % next_title, HORIZONTAL_ALIGNMENT_LEFT, 600, 20, Color("2d6a4f"))
	if _t > 0.7 and int(_t * 2.0) % 2 == 0:
		var t := "PRESS Z TO CONTINUE" if not final else "PRESS Z FOR THE MENU"
		var ts := FONT_SHOUT.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 32)
		draw_string(FONT_SHOUT, Vector2(panel.position.x + (panel.size.x - ts.x) * 0.5, panel.end.y - 22), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color("e63946"))
