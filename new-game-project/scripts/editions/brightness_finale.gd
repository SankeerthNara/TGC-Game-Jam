class_name BrightnessFinale
extends CanvasLayer
## The last blow belongs to the player: the three freed heroes pour their light into the pulp hero,
## and a real "Brightness" slider appears. Drag it (or hold RIGHT) to 100% to flood the stage with
## sunlight. The beaten Narrator, kneeling in ink, comes apart as the light rises. Emits finished.

signal finished

const FONT_UI := preload("res://assets/fonts/ComicNeue-Bold.ttf")
const FONT_SHOUT := preload("res://assets/fonts/Bangers-Regular.ttf")
const BEGS := [[0.45, "No... put that down, reader."], [0.7, "STOP! This is not how my story ends!"], [0.9, "Please... just one more page..."]]
const FLARE := 2.4 ## seconds of solar flare before the ending pages

var hero := Vector2(640, 520) ## the hero on screen (the director sets it from the fight)
var _value := 0.2
var _t := 0.0
var _done := false
var _drag := false
var _said := 0 ## the Narrator begs as the light rises
var _node: Control
var _ink: Array[Dictionary] = [] ## drops of the Narrator's ink, drifting up into the light
var _spawn := 0.0


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_node = Control.new()
	_node.size = Vector2(1280, 720)
	_node.mouse_filter = Control.MOUSE_FILTER_STOP
	_node.draw.connect(_draw_ui)
	_node.gui_input.connect(_on_gui)
	add_child(_node)


func _track() -> Rect2:
	return Rect2(Vector2(440, 600), Vector2(400, 10))


## Where the beaten Narrator kneels: across the stage from the hero.
func _narrator_feet() -> Vector2:
	var side := 1.0 if hero.x < 640.0 else -1.0
	return Vector2(clampf(hero.x + 330.0 * side, 180.0, 1100.0), 600.0)


func _on_gui(event: InputEvent) -> void:
	if _done or _t < 1.5:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_drag = event.pressed and _track().grow(24.0).has_point(event.position)
		if _drag:
			_set_from_x(event.position.x)
	elif event is InputEventMouseMotion and _drag:
		_set_from_x(event.position.x)


func _set_from_x(x: float) -> void:
	var tr := _track()
	_value = maxf(_value, clampf((x - tr.position.x) / tr.size.x, 0.0, 1.0))


func _process(delta: float) -> void:
	_t += delta
	if not _done and _t > 1.5 and Input.is_action_pressed("move_right"):
		_value = minf(1.0, _value + delta * 0.35)
	var c: Node = get_tree().get_first_node_in_group("comms")
	if not _done and _said < BEGS.size() and _value >= float(BEGS[_said][0]):
		if c != null:
			c.dead = false # his own voice breaks through the dead comms
			c.clear() # a newer plea cuts off the last one
			c.say(String(BEGS[_said][1]), "narrator_evil", 1.0)
		_said += 1
	if not _done and _value >= 0.999:
		_done = true
		_t = 0.0
		if c != null:
			c.clear() # the ending pages speak for him now
		EventBus.sound_requested.emit("power_solar")
		EventBus.sound_requested.emit("light_swell")
		EventBus.sound_requested.emit("shockwave")
		_burst()
	_update_ink(delta)
	# the flare shakes the stage
	var s := 16.0 * (1.0 - clampf(_t / 1.2, 0.0, 1.0)) if _done else 0.0
	offset = Vector2(randf_range(-s, s), randf_range(-s, s)) if s > 0.0 else Vector2.ZERO
	if _done and _t > FLARE:
		set_process(false)
		finished.emit()
		queue_free()
	_node.queue_redraw()


func _update_ink(delta: float) -> void:
	var light := _value if not _done else 1.0
	if not _done:
		_spawn += delta * (4.0 + 34.0 * light * light)
		var feet := _narrator_feet()
		while _spawn >= 1.0:
			_spawn -= 1.0
			_ink.append({"pos": feet + Vector2(randf_range(-70, 70), -randf_range(20, 260)), "vel": Vector2(randf_range(-30, 30), -randf_range(50, 150)), "t": 0.0, "life": randf_range(0.9, 1.8), "r": randf_range(3, 8)})
	for d in _ink:
		d["t"] = float(d["t"]) + delta
		d["vel"] = (d["vel"] as Vector2) * (1.0 - 0.6 * delta)
		d["pos"] = (d["pos"] as Vector2) + (d["vel"] as Vector2) * delta
	_ink = _ink.filter(func(d: Dictionary) -> bool: return float(d["t"]) < float(d["life"]))


## The Narrator bursts into ink in the flare.
func _burst() -> void:
	var feet := _narrator_feet()
	for i in 70:
		var ang := randf() * TAU
		_ink.append({"pos": feet + Vector2(randf_range(-60, 60), -randf_range(20, 260)), "vel": Vector2.from_angle(ang) * randf_range(200, 700), "t": 0.0, "life": randf_range(0.6, 1.4), "r": randf_range(4, 11)})


func _draw_ui() -> void:
	var ci := _node
	var full := Rect2(Vector2(-40, -40), Vector2(1360, 800))
	var light := _value if not _done else 1.0
	# the stage brightens with the slider
	ci.draw_rect(full, Color(1.0, 0.95, 0.75, 0.15 + 0.6 * light * light))
	# the beaten Narrator, kneeling, his ink coming apart in the light
	var feet := _narrator_feet()
	var fade := 1.0 - 0.55 * light if not _done else maxf(0.0, 0.45 - _t * 1.2)
	if fade > 0.0:
		var face := 1.0 if hero.x > feet.x else -1.0
		var tint := Color(0.62, 0.5, 0.85, fade)
		if not Sprites.draw(ci, "narrator_boss", feet + Vector2(0, 6), 290.0, face, tint, 0.86, -0.08 * face):
			ci.draw_colored_polygon(PackedVector2Array([feet + Vector2(-60, 0), feet + Vector2(-30, -220), feet + Vector2(30, -220), feet + Vector2(60, 0)]), Color(0.2, 0.1, 0.3, fade))
	for d in _ink:
		var k := float(d["t"]) / float(d["life"])
		ci.draw_circle(d["pos"], float(d["r"]) * (1.0 - 0.5 * k), Color(0.16, 0.08, 0.24, 0.85 * (1.0 - k)))
	# three beams of light converge on the hero
	for i in 3:
		var from := Vector2([430.0, 640.0, 850.0][i], 230.0 - (40.0 if i == 1 else 0.0))
		var w := 6.0 + 30.0 * light
		ci.draw_line(from, hero, Color(1, 0.95, 0.6, 0.25 + 0.5 * light), w)
		ci.draw_line(from, hero, Color(1, 1, 0.9, 0.6), w * 0.35)
	ci.draw_circle(hero, 40.0 + 120.0 * light, Color(1, 1, 0.85, 0.35))
	if _done:
		_draw_flare(ci, full)
		return
	if _t < 1.5:
		ComicArt.shout(ci, "READER! TURN UP THE LIGHT!", Vector2(640, 300), 60, Color("ffd23f"), 12, -0.03)
		return
	# a plain system slider: the real world reaching into the comic
	var panel := Rect2(Vector2(400, 540), Vector2(480, 110))
	ci.draw_rect(Rect2(panel.position + Vector2(0, 8), panel.size), Color(0, 0, 0, 0.3))
	ci.draw_rect(panel, Color(0.96, 0.96, 0.97))
	ci.draw_string(FONT_UI, panel.position + Vector2(40, 38), "Brightness", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.1, 0.1, 0.15))
	ci.draw_string(FONT_UI, panel.position + Vector2(400, 38), "%d%%" % int(_value * 100.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.1, 0.1, 0.15))
	var tr := _track()
	ci.draw_rect(tr, Color(0.82, 0.83, 0.87))
	ci.draw_rect(Rect2(tr.position, Vector2(tr.size.x * _value, tr.size.y)), Color(0.27, 0.52, 0.96))
	var knob := Vector2(tr.position.x + tr.size.x * _value, tr.get_center().y)
	ci.draw_circle(knob, 13.0, Color.WHITE)
	ci.draw_arc(knob, 13.0, 0.0, TAU, 24, Color(0.6, 0.6, 0.65), 2.0)
	ci.draw_string(FONT_UI, Vector2(450, 690), "Drag the slider to 100%  (or hold RIGHT / D)", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.15, 0.15, 0.2))


## The solar flare: sun rays burst out of the hero, a shock ring rolls out, the page burns white.
func _draw_flare(ci: CanvasItem, full: Rect2) -> void:
	var k := clampf(_t / 1.3, 0.0, 1.0)
	var e := 1.0 - pow(1.0 - k, 3.0)
	for i in 18:
		var ang := i * TAU / 18.0 + _t * 0.5
		var reach := 160.0 + 1500.0 * e
		var w := 0.05 + 0.04 * float(i % 2)
		ci.draw_colored_polygon(PackedVector2Array([hero, hero + Vector2.from_angle(ang - w) * reach, hero + Vector2.from_angle(ang + w) * reach]), Color(1, 0.93, 0.55, 0.5))
	ci.draw_arc(hero, 50.0 + 1000.0 * e, 0.0, TAU, 72, Color(1, 1, 0.92, 1.0 - k), 4.0 + 26.0 * (1.0 - k))
	ci.draw_circle(hero, 70.0 + 360.0 * e, Color(1, 1, 0.9, 0.55))
	if _t < 1.8:
		var pop := lerpf(2.2, 1.0, clampf(_t / 0.18, 0.0, 1.0))
		ComicArt.shout(ci, "SOLAR FLARE!", Vector2(640, 250), 104, Color("ffd23f"), 14, -0.04, pop)
	ci.draw_rect(full, Color(1, 0.99, 0.94, clampf((_t - 0.7) / 1.1, 0.0, 1.0)))
