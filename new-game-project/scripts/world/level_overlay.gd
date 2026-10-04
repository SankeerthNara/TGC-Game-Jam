class_name LevelOverlay
extends Control
## Comic-styled score card between levels: score breakdown, animated rank badge, key icons.

signal continue_pressed

const FONT_SHOUT := preload("res://assets/fonts/Bangers-Regular.ttf")
const FONT_BODY := preload("res://assets/fonts/ComicNeue-Bold.ttf")
const INK := Color("18151d")
const PAPER := Color("fff3d1")
const GOLD := Color("ffd23f")
const RED := Color("e63946")

const RANK_COLORS := {
	"S": Color("ffb703"),
	"A": Color("2dc653"),
	"B": Color("3a86ff"),
	"C": Color("8d99ae")
}

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
var to_bomb_room := false ## the last level: Z opens the bomb room
var keys_found := 0
var key_total := 4
var bomb_left := 0.0
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
	if _t > 0.6 and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_Z, KEY_ENTER, KEY_SPACE]:
		continue_pressed.emit()
		get_viewport().set_input_as_handled()


func _rank_badge(c: Vector2, base_r: float, letter: String) -> void:
	var rank_anim_t := clampf((_t - 0.35) / 0.3, 0.0, 1.0)
	var s := 1.0
	if rank_anim_t < 0.7:
		s = lerpf(0.1, 1.25, rank_anim_t / 0.7)
	else:
		s = lerpf(1.25, 1.0, (rank_anim_t - 0.7) / 0.3)

	var r := base_r * s
	if r <= 1.0:
		return

	# Comic starburst behind S and A ranks
	if letter in ["S", "A"] and rank_anim_t >= 0.7:
		var burst_pts := PackedVector2Array()
		for k in 12:
			var a := k / 12.0 * TAU + _t * 1.5
			var br := (r * 1.5) if k % 2 == 0 else (r * 1.1)
			burst_pts.append(c + Vector2(cos(a), sin(a)) * br)
		burst_pts.append(burst_pts[0])
		draw_colored_polygon(burst_pts, GOLD if letter == "S" else Color("52b788"))
		draw_polyline(burst_pts, INK, 2.0)

	draw_circle(c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
	draw_circle(c, r, INK)
	draw_circle(c, r - 4, RANK_COLORS.get(letter, Color.WHITE))
	var fs := int(r * 1.45)
	var sz := FONT_SHOUT.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	draw_string(FONT_SHOUT, c + Vector2(-sz.x * 0.5, fs * 0.34), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)


func _draw_key(c: Vector2, s: float, unlocked: bool) -> void:
	var col := GOLD if unlocked else Color(0.35, 0.35, 0.42)
	# Key head ring
	draw_circle(c + Vector2(-s * 5, 0), s * 6.5, col)
	draw_circle(c + Vector2(-s * 5, 0), s * 2.5, INK)
	draw_circle(c + Vector2(-s * 5, 0), s * 6.5, INK, false, 2.0)
	# Stem
	draw_line(c + Vector2(-s * 1, 0), c + Vector2(s * 15, 0), col, s * 4.0)
	draw_line(c + Vector2(-s * 1, 0), c + Vector2(s * 15, 0), INK, s * 1.0)
	# Teeth
	draw_line(c + Vector2(s * 7, 0), c + Vector2(s * 7, s * 6), col, s * 3.0)
	draw_line(c + Vector2(s * 13, 0), c + Vector2(s * 13, s * 8), col, s * 3.0)
	if unlocked:
		# Spark glint
		var spark_a := _t * 3.0
		draw_circle(c + Vector2(-s * 5, 0) + Vector2(cos(spark_a), sin(spark_a)) * (s * 4.5), s * 1.8, Color.WHITE)


func _draw() -> void:
	var vp := get_viewport_rect().size
	var k := minf(_t / 0.35, 1.0)
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.08, 0.05, 0.12, 0.85 * k))

	# Subtle comic halftone on backdrop
	ComicArt.halftone(self, vp, Color(0, 0, 0, 0.25), 24.0, 4.0, Vector2(1, 1))

	var rows := splits.size() if final else lines.size()
	var h := 370.0 + rows * 30.0
	var panel := Rect2(Vector2(vp.x * 0.5 - 380, vp.y * 0.5 - h * 0.5), Vector2(760, h))

	# Drop shadow
	draw_rect(Rect2(panel.position + Vector2(8, 8), panel.size), Color(0, 0, 0, 0.5))
	# Comic card paper
	draw_rect(panel, PAPER)
	draw_rect(panel, INK, false, 6.0)

	# Header ribbon
	var ribbon_h := 74.0
	var ribbon_col := Color("2dc653") if not final else GOLD
	draw_rect(Rect2(panel.position, Vector2(panel.size.x, ribbon_h)), ribbon_col)
	draw_rect(Rect2(panel.position, Vector2(panel.size.x, ribbon_h)), INK, false, 5.0)

	var head := "✦ LEVEL COMPLETE! ✦" if not final else "✦ THE BOMB ROOM IS OPEN! ✦"
	var hs := FONT_SHOUT.get_string_size(head, HORIZONTAL_ALIGNMENT_LEFT, -1, 46)
	draw_string(FONT_SHOUT, panel.position + Vector2((panel.size.x - hs.x) * 0.5, 52), head, HORIZONTAL_ALIGNMENT_LEFT, -1, 46, INK)

	var y := panel.position.y + 110.0
	var left := panel.position.x + 36.0
	var right := panel.end.x - 36.0

	# Title & Keys Row
	draw_string(FONT_SHOUT, Vector2(left, y), title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 460, 28, INK)

	# 4 Bomb Room Keys Display on top right
	var keys_x := right - 130.0
	for i in key_total:
		var kc := Vector2(keys_x + i * 30.0, y - 8.0)
		_draw_key(kc, 1.0, i < keys_found)

	y += 36.0

	if final:
		for i in splits.size():
			draw_string(FONT_BODY, Vector2(left + 10, y), "Level %d" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, INK)
			draw_string(FONT_BODY, Vector2(left + 200, y), _fmt(splits[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, INK)
			draw_string(FONT_SHOUT, Vector2(right - 180, y), "%d PTS" % level_scores[i], HORIZONTAL_ALIGNMENT_RIGHT, 140, 24, INK)
			_rank_badge(Vector2(right - 20, y - 8), 16.0, level_ranks[i])
			y += 30.0
		draw_line(Vector2(left, y - 8), Vector2(right, y - 8), INK, 3.0)
		y += 24.0
		draw_string(FONT_SHOUT, Vector2(left + 10, y), "FINAL SCORE", HORIZONTAL_ALIGNMENT_LEFT, -1, 36, RED)
		draw_string(FONT_SHOUT, Vector2(right - 200, y), "%d PTS" % total_score, HORIZONTAL_ALIGNMENT_RIGHT, 160, 42, RED)
		_rank_badge(Vector2(right - 20, y - 10), 28.0, overall_rank)
		y += 34.0
		draw_string(FONT_BODY, Vector2(left + 10, y), "Total Run Time: %s    Bomb Clock Remaining: %s" % [_fmt(total_time), _fmt(bomb_left)], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, INK)
		y += 26.0
		draw_string(FONT_BODY, Vector2(left + 10, y), "The four heroes confront the Narrator in the bomb room!", HORIZONTAL_ALIGNMENT_LEFT, 680, 18, Color("5c5470"))
	else:
		for ln in lines:
			var pts: int = ln[1]
			draw_string(FONT_BODY, Vector2(left + 10, y), String(ln[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, INK)
			var col_pts := Color("2d6a4f") if pts >= 0 else RED
			draw_string(FONT_SHOUT, Vector2(right - 190, y), "%s%d PTS" % ["+" if pts >= 0 else "", pts], HORIZONTAL_ALIGNMENT_RIGHT, 160, 24, col_pts)
			y += 30.0
		draw_line(Vector2(left, y - 8), Vector2(right, y - 8), INK, 3.0)
		y += 24.0
		draw_string(FONT_SHOUT, Vector2(left + 10, y), "LEVEL SCORE", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, INK)
		draw_string(FONT_SHOUT, Vector2(right - 190, y), "%d PTS" % score, HORIZONTAL_ALIGNMENT_RIGHT, 160, 36, INK)
		_rank_badge(Vector2(right - 20, y - 10), 28.0, rank)
		y += 32.0
		var under := par > 0 and level_time <= par
		var par_note := "Time: %s   Par: %s   [%s]    Total: %d pts" % [_fmt(level_time), _fmt(par), "UNDER PAR" if under else "OVER PAR", total_score]
		draw_string(FONT_BODY, Vector2(left + 10, y), par_note, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("2d6a4f") if under else Color("5c5470"))
		y += 26.0
		var note := "🗝 Bomb Key %d of %d secured! Checkpoint saved." % [keys_found, key_total]
		if to_bomb_room:
			note = "🗝 ALL 4 KEYS COLLECTED! The Bomb Room awaits with %s on the clock!" % _fmt(bomb_left)
		elif easier_next:
			note += " (Narrator pity bonus active for next level.)"
		draw_string(FONT_BODY, Vector2(left + 10, y), note, HORIZONTAL_ALIGNMENT_LEFT, 680, 18, Color("2d6a4f"))

	# Blinking continue prompt
	if _t > 0.6 and int(_t * 2.5) % 2 == 0:
		var prompt_t := "PRESS [Z] OR [SPACE] FOR MAIN MENU" if final else ("PRESS [Z] TO ENTER BOMB ROOM!" if to_bomb_room else "PRESS [Z] OR [SPACE] TO CONTINUE")
		var ts := FONT_SHOUT.get_string_size(prompt_t, HORIZONTAL_ALIGNMENT_LEFT, -1, 30)
		draw_string(FONT_SHOUT, Vector2(panel.position.x + (panel.size.x - ts.x) * 0.5, panel.end.y - 18), prompt_t, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, RED)
