class_name GlintLayer
extends CanvasLayer
## Draws things that must glow in the dark (item glints, fireflies) above the town's darkness.

var world: World
var _drawer: Node2D
var _flies: Array[Dictionary] = []


func _ready() -> void:
	layer = 2
	_drawer = Node2D.new()
	_drawer.draw.connect(_draw_glints)
	add_child(_drawer)
	for i in 70:
		_flies.append({"x": randf() * 44.0 * World.TILE, "y": randf() * 30.0 * World.TILE, "p": randf() * TAU, "s": 0.5 + randf()})


func _process(_delta: float) -> void:
	visible = world != null and world.active
	if visible:
		_drawer.queue_redraw()


func _draw_glints() -> void:
	if world == null or not world.active:
		return
	var vp := get_viewport().get_visible_rect().size
	var cam := get_viewport().get_camera_2d()
	var cc := cam.get_screen_center_position() if cam != null else world.hero.pos
	var origin := cc - vp * 0.5
	var t := world._time
	for it: Dictionary in world.items:
		if it["taken"]:
			continue
		var wp := world._center(Vector2i(it["x"], it["y"]))
		var sp := wp - origin
		if sp.x < -60 or sp.y < -60 or sp.x > vp.x + 60 or sp.y > vp.y + 60:
			continue
		var near := clampf(1.0 - wp.distance_to(world.hero.pos) / (World.TILE * 7.0), 0.0, 1.0)
		var col: Color = KeySymbols.ITEM_COLORS.get(it["type"], Color.WHITE).lerp(Color.WHITE, 0.5)
		var tw := 0.5 + 0.5 * sin(t * 4.0 + float(it["x"]) * 1.7)
		var rad := 7.0 + 8.0 * tw + near * 10.0
		_drawer.draw_circle(sp, rad * 0.55, Color(col.r, col.g, col.b, 0.22 + 0.25 * tw))
		_drawer.draw_line(sp + Vector2(-rad, 0), sp + Vector2(rad, 0), Color(col.r, col.g, col.b, 0.9), 2.0)
		_drawer.draw_line(sp + Vector2(0, -rad), sp + Vector2(0, rad), Color(col.r, col.g, col.b, 0.9), 2.0)
	for f in _flies:
		var wp2 := Vector2(f["x"] + sin(t * f["s"] + f["p"]) * 30.0, f["y"] + cos(t * 0.7 * f["s"] + f["p"]) * 24.0)
		var tile := Vector2i(int(wp2.x / World.TILE), int(wp2.y / World.TILE))
		if not world._zone_open(tile) or world._at(tile) in "T,#":
			continue
		var sp2 := wp2 - origin
		if sp2.x < -20 or sp2.y < -20 or sp2.x > vp.x + 20 or sp2.y > vp.y + 20:
			continue
		var blink := 0.5 + 0.5 * sin(t * 3.0 * f["s"] + f["p"] * 3.0)
		_drawer.draw_circle(sp2, 6.0 * blink + 3.0, Color(1.0, 0.95, 0.5, 0.18 * blink))
		_drawer.draw_circle(sp2, 2.0, Color(1.0, 0.98, 0.7, 0.35 + 0.5 * blink))
