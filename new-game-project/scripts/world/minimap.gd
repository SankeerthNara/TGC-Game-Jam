class_name MiniMap
extends Control
## Full-screen station map (toggle with M or Tab). Shows rooms, task markers and where you are.

const FONT_SHOUT := preload("res://assets/fonts/Bangers-Regular.ttf")
const INK := Color("18151d")

var world: World


func _ready() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	if world == null or world.rows.is_empty():
		return
	var vp := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.78))
	var s := minf((vp.x - 120.0) / world.cols, (vp.y - 200.0) / world.count_rows)
	var origin := Vector2((vp.x - world.cols * s) * 0.5, 135.0)
	draw_rect(Rect2(origin - Vector2(8, 8), Vector2(world.cols, world.count_rows) * s + Vector2(16, 16)), Color("fff3d1"))
	draw_rect(Rect2(origin - Vector2(8, 8), Vector2(world.cols, world.count_rows) * s + Vector2(16, 16)), INK, false, 5.0)
	for y in world.count_rows:
		var row := world.rows[y]
		for x in world.cols:
			var ch := row[x]
			if ch == "#":
				draw_rect(Rect2(origin + Vector2(x, y) * s, Vector2(s + 0.5, s + 0.5)), Color("2e2a45"))
			else:
				var ri := world.room_index_at(x, y)
				var col := Color("d7cdb8") if ri < 0 else world.room_color(ri)
				draw_rect(Rect2(origin + Vector2(x, y) * s, Vector2(s + 0.5, s + 0.5)), col)
	for r: Dictionary in world.rooms:
		var rr := Rect2(origin + Vector2(r["x"], r["y"]) * s, Vector2(r["w"], r["h"]) * s)
		draw_rect(rr, INK, false, 2.0)
		draw_string(FONT_SHOUT, rr.position + Vector2(0, rr.size.y * 0.55), r["name"], HORIZONTAL_ALIGNMENT_CENTER, rr.size.x, int(clampf(s * 1.9, 14, 26)), Color(INK.r, INK.g, INK.b, 0.65))
	for t: Dictionary in world.tasks:
		var p := origin + (Vector2(t["x"], t["y"]) + Vector2(0.5, 0.5)) * s
		if world.tasks_done.has(t["id"]):
			draw_circle(p, s * 0.9, INK)
			draw_circle(p, s * 0.7, Color("2dc653"))
		else:
			var pulse := 1.0 + 0.2 * sin(Time.get_ticks_msec() / 200.0)
			draw_circle(p, s * 1.1 * pulse, INK)
			draw_circle(p, s * 0.85 * pulse, Color("ffd23f"))
			draw_string(FONT_SHOUT, p + Vector2(-s * 0.35, s * 0.55), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, int(s * 1.5), INK)
	var fix: Dictionary = world.active_fix()
	if not fix.is_empty():
		var fp := origin + (Vector2(float(fix["x"]), float(fix["y"])) + Vector2(0.5, 0.5)) * s
		var fpulse := 1.0 + 0.35 * sin(Time.get_ticks_msec() / 120.0)
		draw_circle(fp, s * 1.6 * fpulse, INK)
		draw_circle(fp, s * 1.25 * fpulse, Color("ff3b3b"))
		draw_string(FONT_SHOUT, fp + Vector2(-s * 0.5, s * 0.7), "FIX", HORIZONTAL_ALIGNMENT_LEFT, -1, int(s * 1.7), Color.WHITE)
	var hp := origin + (Vector2(world.tile) + Vector2(0.5, 0.5)) * s
	draw_circle(hp, s * 1.3, INK)
	draw_circle(hp, s * 1.0, Color("e63946"))
	draw_string(FONT_SHOUT, Vector2(origin.x, vp.y - 14), "STATION MAP", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color("ffd23f"))
	draw_string(FONT_SHOUT, Vector2(origin.x + 280, vp.y - 18), "red dot: you     yellow !: task to do     green: done      M / Tab / Esc: close", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("fff3d1"))
