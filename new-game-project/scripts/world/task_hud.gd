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
	position = Vector2.ZERO
	size = get_viewport_rect().size
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
	_draw_health_and_sabotage()
	var total := world.tasks.size()
	var done := world.tasks_done.size()
	_draw_timers()
	var box := Rect2(Vector2(900, 112), Vector2(350, 76))
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
	_draw_ally_arrow()
	if not list_open:
		return
	var n := world.tasks.size()
	var lh := 21.0
	var lbox := Rect2(Vector2(900, 200), Vector2(350, 30 + n * lh))
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
		draw_string(FONT_BODY, Vector2(lbox.position.x + 34, y), "%s: %s" % [t["room"], t["name"]], HORIZONTAL_ALIGNMENT_LEFT, 310, 15, c)
		y += lh


func _heart(c: Vector2, r: float, filled: bool) -> void:
	var pts := PackedVector2Array()
	for k in 28:
		var t := k / 28.0 * TAU
		var x := 16.0 * pow(sin(t), 3.0)
		var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		pts.append(c + Vector2(x, y) * r / 16.0)
	if filled:
		draw_colored_polygon(pts, Color("e63946"))
	else:
		draw_colored_polygon(pts, Color(0.2, 0.2, 0.25, 0.7))
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, INK, 3.0)


func _draw_health_and_sabotage() -> void:
	for i in world.max_health:
		_heart(Vector2(52 + i * 52, 142), 20.0, i < world.hp)
	if world.sabotage.is_empty():
		return
	var def: Dictionary = world.sabotage["def"]
	var left: float = world.sabotage["left"]
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 130.0)
	var vp := get_viewport_rect().size
	var a := 0.12 + 0.22 * pulse * (1.0 if left < 15.0 else 0.6)
	draw_rect(Rect2(0, 0, vp.x, 14), Color(1, 0.1, 0.1, a * 2.0))
	draw_rect(Rect2(0, vp.y - 14, vp.x, 14), Color(1, 0.1, 0.1, a * 2.0))
	draw_rect(Rect2(0, 0, 14, vp.y), Color(1, 0.1, 0.1, a * 2.0))
	draw_rect(Rect2(vp.x - 14, 0, 14, vp.y), Color(1, 0.1, 0.1, a * 2.0))
	var fix: Dictionary = world.active_fix()
	var box := Rect2(Vector2(30, 176), Vector2(560, 74))
	draw_rect(Rect2(box.position + Vector2(4, 4), box.size), Color(0, 0, 0, 0.4))
	draw_rect(box, Color(0.55 + 0.35 * pulse, 0.05, 0.08))
	draw_rect(box, INK, false, 4.0)
	var tp := box.position + Vector2(34, 36)
	draw_colored_polygon(PackedVector2Array([tp + Vector2(0, -22), tp + Vector2(-24, 20), tp + Vector2(24, 20)]), Color("ffd23f"))
	draw_polyline(PackedVector2Array([tp + Vector2(0, -22), tp + Vector2(-24, 20), tp + Vector2(24, 20), tp + Vector2(0, -22)]), INK, 3.0)
	draw_line(tp + Vector2(0, -8), tp + Vector2(0, 6), INK, 4.0)
	draw_circle(tp + Vector2(0, 13), 2.5, INK)
	draw_string(FONT_SHOUT, box.position + Vector2(76, 32), "%s%s!" % ["BIG SABOTAGE: " if def.get("big", false) else "", def["name"]], HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("fff3d1"))
	draw_string(FONT_BODY, box.position + Vector2(76, 60), "Fix: %s (%s)" % [fix.get("name", "?"), fix.get("room", "?")], HORIZONTAL_ALIGNMENT_LEFT, 360, 18, Color("fff3d1"))
	var secs := int(ceil(left))
	draw_string(FONT_SHOUT, box.position + Vector2(box.size.x - 120, 52), "%d:%02d" % [secs / 60, secs % 60], HORIZONTAL_ALIGNMENT_LEFT, -1, 48, Color("fff3d1") if left > 10.0 else Color("ffe066"))
	# arrow around the hero pointing to the fix console
	if fix.is_empty():
		return
	var to := Vector2(float(fix["x"]) + 0.5, float(fix["y"]) + 0.5) * World.TILE - world._foot
	var dir := to.normalized()
	var c := Vector2(640, 345) + dir * 130.0
	var side := dir.orthogonal()
	draw_colored_polygon(PackedVector2Array([c + dir * 26, c - dir * 14 + side * 18, c - dir * 14 - side * 18]), Color("ff4d4d"))
	draw_polyline(PackedVector2Array([c + dir * 26, c - dir * 14 + side * 18, c - dir * 14 - side * 18, c + dir * 26]), INK, 3.0)


func _fmt(t: float) -> String:
	var secs := int(t)
	return "%02d:%02d" % [secs / 60, secs % 60]


func _draw_timers() -> void:
	var box := Rect2(Vector2(900, 20), Vector2(350, 84))
	draw_rect(Rect2(box.position + Vector2(4, 4), box.size), Color(0, 0, 0, 0.4))
	draw_rect(box, Color("18151d"))
	draw_rect(box, Color("ffd23f"), false, 3.0)
	draw_string(FONT_SHOUT, box.position + Vector2(12, 24), "LEVEL %d/%d" % [world.level_index + 1, world.level_count], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("ffd23f"))
	var over := world.level_par > 0 and world.level_time > world.level_par
	draw_string(FONT_SHOUT, box.position + Vector2(12, 45), "THIS LEVEL  %s / PAR %s" % [_fmt(world.level_time), _fmt(world.level_par)], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("ff8b8b") if over else Color("fff3d1"))
	draw_string(FONT_SHOUT, box.position + Vector2(box.size.x - 12 - 120, 45), "TOTAL %s" % _fmt(world.total_time), HORIZONTAL_ALIGNMENT_RIGHT, 120, 20, Color("fff3d1"))
	draw_string(FONT_BODY, box.position + Vector2(box.size.x - 12 - 190, 22), world.level_title, HORIZONTAL_ALIGNMENT_RIGHT, 190, 15, Color("ffffff"))
	draw_string(FONT_SHOUT, box.position + Vector2(12, 76), "SCORE  %d" % world.score_total, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("ffd23f"))


## Once a friend has been revealed he points to the nearest unfinished task.
func _draw_ally_arrow() -> void:
	if world.vampires.ally_index < 0:
		return
	var best := Vector2.ZERO
	var best_d := 1e9
	for t: Dictionary in world.tasks:
		if world.tasks_done.has(t["id"]):
			continue
		var p := Vector2(float(t["x"]) + 0.5, float(t["y"]) + 0.5) * World.TILE
		var d := p.distance_to(world._foot)
		if d < best_d:
			best_d = d
			best = p
	if best_d > 1e8:
		return
	var dir := (best - world._foot).normalized()
	var c := Vector2(640, 345) + dir * 108.0
	var side := dir.orthogonal()
	draw_colored_polygon(PackedVector2Array([c + dir * 20, c - dir * 11 + side * 14, c - dir * 11 - side * 14]), Color("4cc9f0"))
	draw_polyline(PackedVector2Array([c + dir * 20, c - dir * 11 + side * 14, c - dir * 11 - side * 14, c + dir * 20]), INK, 3.0)
