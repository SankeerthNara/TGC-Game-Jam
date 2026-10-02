class_name BlotsTask
extends TaskBase
## Ink spills pop up: click them before they spread. Wipe ten, miss four and you start over.

const NEED := 10
const MAX_MISS := 4

var _blots: Array[Dictionary] = []
var _wiped := 0
var _missed := 0
var _spawn := 0.4


func _begin() -> void:
	title = "WIPE THE INK SPILLS"
	hint = "Click the ink blots before they spread! Wipe 10. Miss 4 and it starts over."


func _area() -> Rect2:
	return Rect2(panel.position + Vector2(40, 100), panel.size - Vector2(80, 170))


func _update(delta: float) -> void:
	_spawn -= delta
	if _spawn <= 0.0 and _wiped + _blots.size() < NEED + 2:
		var a := _area()
		_blots.append({"p": Vector2(randf_range(a.position.x + 50, a.end.x - 50), randf_range(a.position.y + 50, a.end.y - 50)), "age": 0.0, "pop": -1.0, "seed": randf() * 6.0})
		_spawn = 0.75
	for b in _blots:
		if b["pop"] < 0.0:
			b["age"] += delta
		else:
			b["pop"] += delta
	for b in _blots.duplicate():
		if b["pop"] < 0.0 and b["age"] > 2.3:
			_blots.erase(b)
			_missed += 1
			flash("SPLAT! MISSED", 6.0)
			if _missed >= MAX_MISS:
				_missed = 0
				_wiped = 0
				_blots.clear()
				flash("TOO MESSY! AGAIN", 12.0)
				break
		elif b["pop"] > 0.25:
			_blots.erase(b)


func _gui_input(event: InputEvent) -> void:
	if _done:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in range(_blots.size() - 1, -1, -1):
			var b := _blots[i]
			if b["pop"] < 0.0 and event.position.distance_to(b["p"]) < 18.0 + minf(b["age"] * 14.0, 30.0):
				b["pop"] = 0.0
				_wiped += 1
				if _wiped >= NEED:
					succeed()
				return


func _draw_task() -> void:
	var a := _area()
	draw_rect(a, Color("fff9e6"))
	draw_rect(a, INK, false, 3.0)
	for b in _blots:
		var p: Vector2 = b["p"]
		if b["pop"] >= 0.0:
			var k: float = b["pop"] / 0.25
			for n in 8:
				var d := Vector2.from_angle(n * TAU / 8.0 + b["seed"]) * (14.0 + 40.0 * k)
				draw_circle(p + d, 6.0 * (1.0 - k), INK)
			_text("POP!", p + Vector2(-20, -30 - 20 * k), 26, GOLD, FONT_SHOUT)
			continue
		var r: float = 14.0 + minf(b["age"] * 14.0, 30.0)
		var wob := sin(_t * 8.0 + b["seed"]) * 2.0
		draw_circle(p, r + wob, INK)
		for n in 5:
			draw_circle(p + Vector2.from_angle(n * 1.3 + b["seed"]) * r * 0.8, r * 0.45, INK)
		draw_circle(p + Vector2(-r * 0.3, -r * 0.3), r * 0.18, Color(1, 1, 1, 0.5))
		if b["age"] > 1.6:
			draw_arc(p, r + 12.0, 0.0, TAU, 24, RED, 4.0)
	_text("WIPED %d/%d" % [_wiped, NEED], panel.position + Vector2(30, 90), 26, INK, FONT_SHOUT)
	_text("MISSED %d/%d" % [_missed, MAX_MISS], Vector2(panel.end.x - 210, panel.position.y + 90), 26, RED if _missed >= 2 else INK, FONT_SHOUT)
