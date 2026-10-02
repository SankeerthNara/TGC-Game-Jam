class_name LevelOverlay
extends Control
## Between levels: the score breakdown, rank and times. At the very end: every level's time, score and rank.

signal continue_pressed

const FONT_SHOUT := preload("res://assets/fonts/Bangers-Regular.ttf")
const FONT_BODY := preload("res://assets/fonts/ComicNeue-Bold.ttf")
const INK := Color("18151d")
const GOLD := Color("ffd23f")
const RANK_COLORS := {"S": Color("ffb703"), "A": Color("2dc653"), "B": Color("3a86ff"), "C": Color("8d99ae")}

var final := false
var title := ""
var level_time := 0.0
var total_time := 0.0
var splits: Array = []
var next_title := ""
var par := 0
var lines: Array = [] ## [[label, points]]
var score := 0
var rank := "C"
var total_score := 0
var level_scores: Array = []
var level_ranks: Array = []
var overall_rank := "C"
var easier_next := false
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


func _rank_badge(c: Vector2, r: float, letter: String) -> void:
	draw_circle(c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
	draw_circle(c, r, INK)
	draw_circle(c, r - 5, RANK_COLORS.get(letter, Color.WHITE))
	var fs := int(r * 1.5)
	var sz := FONT_SHOUT.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	draw_string(FONT_SHOUT, c + Vector2(-sz.x * 0.5, fs * 0.33), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)


func _draw() -> void:
	var vp := get_viewport_rect().size
	var k := minf(_t / 0.4, 1.0)
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.8 * k))
	var rows := splits.size() if final else lines.size()
	var h := 330.0 + rows * 30.0
	var panel := Rect2(Vector2(vp.x * 0.5 - 360, vp.y * 0.5 - h * 0.5), Vector2(720, h))
	draw_rect(Rect2(panel.position + Vector2(8, 8), panel.size), Color(0, 0, 0, 0.5))
	draw_rect(panel, Color("fff3d1"))
	draw_rect(panel, INK, false, 6.0)
	draw_rect(Rect2(panel.position, Vector2(panel.size.x, 72)), Color("2dc653") if not final else GOLD)
	draw_rect(Rect2(panel.position, Vector2(panel.size.x, 72)), INK, false, 6.0)
	var head := "LEVEL COMPLETE!" if not final else "YOU SAVED THE STUDIO!"
	var hs := FONT_SHOUT.get_string_size(head, HORIZONTAL_ALIGNMENT_LEFT, -1, 50)
	draw_string(FONT_SHOUT, panel.position + Vector2((panel.size.x - hs.x) * 0.5, 54), head, HORIZONTAL_ALIGNMENT_LEFT, -1, 50, INK)
	var y := panel.position.y + 108.0
	var left := panel.position.x + 40.0
	var right := panel.end.x - 40.0
	draw_string(FONT_SHOUT, Vector2(left, y), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, INK)
	y += 34.0
	if final:
		for i in splits.size():
			draw_string(FONT_BODY, Vector2(left + 10, y), "Level %d" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, INK)
			draw_string(FONT_BODY, Vector2(left + 190, y), _fmt(splits[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, INK)
			draw_string(FONT_SHOUT, Vector2(right - 190, y), "%d" % level_scores[i], HORIZONTAL_ALIGNMENT_RIGHT, 120, 26, INK)
			_rank_badge(Vector2(right - 14, y - 9), 15.0, level_ranks[i])
			y += 30.0
		draw_line(Vector2(left, y - 10), Vector2(right, y - 10), INK, 3.0)
		draw_string(FONT_SHOUT, Vector2(left + 10, y + 22), "TOTAL SCORE", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("c1121f"))
		draw_string(FONT_SHOUT, Vector2(right - 200, y + 22), "%d" % total_score, HORIZONTAL_ALIGNMENT_RIGHT, 140, 40, Color("c1121f"))
		_rank_badge(Vector2(right - 20, y + 10), 26.0, overall_rank)
		draw_string(FONT_BODY, Vector2(left + 10, y + 56), "Total time %s" % _fmt(total_time), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, INK)
	else:
		for ln in lines:
			var pts: int = ln[1]
			draw_string(FONT_BODY, Vector2(left + 10, y), String(ln[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, INK)
			draw_string(FONT_SHOUT, Vector2(right - 210, y), "%s%d" % ["+" if pts >= 0 else "", pts], HORIZONTAL_ALIGNMENT_RIGHT, 150, 24, Color("2d6a4f") if pts >= 0 else Color("c1121f"))
			y += 30.0
		draw_line(Vector2(left, y - 10), Vector2(right, y - 10), INK, 3.0)
		draw_string(FONT_SHOUT, Vector2(left + 10, y + 22), "LEVEL SCORE", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, INK)
		draw_string(FONT_SHOUT, Vector2(right - 210, y + 22), "%d" % score, HORIZONTAL_ALIGNMENT_RIGHT, 150, 36, INK)
		_rank_badge(Vector2(right - 20, y + 8), 26.0, rank)
		var under := par > 0 and level_time <= par
		draw_string(FONT_BODY, Vector2(left + 10, y + 54), "Time %s   Par %s   %s    Total score %d" % [_fmt(level_time), _fmt(par), "under par" if under else "over par", total_score], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("2d6a4f") if under else Color("5c5470"))
		var note := "Checkpoint saved! If you run out of hearts, you restart %s." % next_title
		if easier_next:
			note += " The Narrator took pity: it will be a little easier."
		draw_string(FONT_BODY, Vector2(left + 10, y + 82), note, HORIZONTAL_ALIGNMENT_LEFT, 640, 18, Color("2d6a4f"))
	if _t > 0.7 and int(_t * 2.0) % 2 == 0:
		var t := "PRESS Z TO CONTINUE" if not final else "PRESS Z FOR THE MENU"
		var ts := FONT_SHOUT.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 30)
		draw_string(FONT_SHOUT, Vector2(panel.position.x + (panel.size.x - ts.x) * 0.5, panel.end.y - 16), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("e63946"))
