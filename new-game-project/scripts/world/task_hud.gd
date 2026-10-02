class_name TaskHUD
extends Control
## Top-right: the task progress bar and the task checklist (Among Us style).

const FONT_SHOUT := preload("res://assets/fonts/Bangers-Regular.ttf")
const FONT_BODY := preload("res://assets/fonts/ComicNeue-Bold.ttf")
const INK := Color("18151d")
const GOLD := Color("ffd23f")

var world: World
var _shown := 0.0 ## animated fill so the bar glides
var _pulse := 0.0
var _last_done := 0
var list_open := true


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if world == null or not visible:
		return
	var total := maxi(world.tasks.size(), 1)
	var target := float(world.tasks_done.size()) / total
	_shown = move_toward(_shown, target, delta * 0.45)
	var d := world.tasks_done.size()
	if d > _last_done:
		_pulse = 1.0
	_last_done = d
	_pulse = maxf(0.0, _pulse - delta * 1.6)
	queue_redraw()


func _draw() -> void:
	if world == null or not world.station_mode:
		return
	var total := world.tasks.size()
	var done := world.tasks_done.size()
	var box := Rect2(Vector2(900, 20), Vector2(350, 76))
	draw_rect(Rect2(box.position + Vector2(4, 4), box.size), Color(0, 0, 0, 0.4))
	draw_rect(box, Color("fff9e6"))
	draw_rect(box, INK, false, 4.0)
	draw_string(FONT_SHOUT, box.position + Vector2(14, 28), "TOTAL TASKS COMPLETED", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, INK)
	draw_string(FONT_SHOUT, box.position + Vector2(box.size.x - 74, 28), "%d/%d" % [done, total], HORIZONTAL_ALIGNMENT_RIGHT, 60, 22, INK)
	var bar := Rect2(box.position + Vector2(14, 40), Vector2(box.size.x - 28, 24))
	draw_rect(bar, INK)
	var inner := bar.grow(-4)
	var w := inner.size.x * clampf(_shown, 0.0, 1.0)
	var col := Color("2dc653").lerp(Color("95d5b2"), _pulse)
	draw_rect(Rect2(inner.position, Vector2(w, inner.size.y)), col)
	draw_rect(Rect2(inner.position, Vector2(w, inner.size.y * 0.35)), Color(1, 1, 1, 0.25))
	for k in range(1, total):
		var x := inner.position.x + inner.size.x * k / total
		draw_line(Vector2(x, inner.position.y), Vector2(x, inner.end.y), Color(0, 0, 0, 0.35), 1.5)
	if not list_open:
		return
	var n := world.tasks.size()
	var lh := 21.0
	var lbox := Rect2(Vector2(900, 108), Vector2(350, 30 + n * lh))
	draw_rect(Rect2(lbox.position + Vector2(4, 4), lbox.size), Color(0, 0, 0, 0.3))
	draw_rect(lbox, Color(1, 0.98, 0.9, 0.9))
	draw_rect(lbox, INK, false, 3.0)
	draw_string(FONT_SHOUT, lbox.position + Vector2(12, 22), "TASKS  (M: map)", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, INK)
	var y := lbox.position.y + 44.0
	for t: Dictionary in world.tasks:
		var is_done := world.tasks_done.has(t["id"])
		var c := Color("6c757d") if is_done else INK
		draw_rect(Rect2(Vector2(lbox.position.x + 12, y - 13), Vector2(14, 14)), Color(1, 1, 1, 0.8))
		draw_rect(Rect2(Vector2(lbox.position.x + 12, y - 13), Vector2(14, 14)), INK, false, 2.0)
		if is_done:
			draw_line(Vector2(lbox.position.x + 14, y - 6), Vector2(lbox.position.x + 18, y - 1), Color("2dc653"), 3.0)
			draw_line(Vector2(lbox.position.x + 18, y - 1), Vector2(lbox.position.x + 26, y - 14), Color("2dc653"), 3.0)
		draw_string(FONT_BODY, Vector2(lbox.position.x + 34, y), "%s: %s" % [t["room"], t["name"]], HORIZONTAL_ALIGNMENT_LEFT, 300, 15, c)
		y += lh
