extends Node
## Plays each villain chase with a simple bot to check it can be won, and saves screenshots
## (not part of the game). A bot is not a real player: this only proves the courses are possible.

const SHOT_DIR := "user://"
var TEST_CLASSES := [BallChase, RunChase, WebChase]
var TRACE := false
var SHOTS_ONLY := DisplayServer.get_name() != "headless"

var _keys := {}


func press(k: Key, on: bool) -> void:
	if _keys.get(k, false) == on:
		return
	_keys[k] = on
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.physical_keycode = k
	ev.pressed = on
	Input.parse_input_event(ev)


func tap(k: Key) -> void:
	press(k, true)
	await get_tree().process_frame
	press(k, false)


func release_all() -> void:
	for k in _keys.keys():
		press(k, false)


func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var results := []
	for cls in TEST_CLASSES:
		for diff in ([2] if SHOTS_ONLY else [1, 3]):
			var wins := 0
			var runs := 1 if SHOTS_ONLY else 2
			for r in runs:
				var g: ChaseBase = cls.new()
				g.difficulty = diff
				g.course_seed = 5 if TRACE else -1
				layer.add_child(g)
				var result := [null]
				g.finished.connect(func(ok: bool) -> void: result[0] = ok)
				Engine.time_scale = 3.0
				var frames := 0
				while result[0] == null and frames < 20000:
					await get_tree().process_frame
					frames += 1
					_drive(g)
					if TRACE and g is BallChase and frames % 3 == 0 and g._pos.x > 2250.0 and g._pos.x < 2700.0 and g.deaths.size() < 2:
						print("  f%d pos %s vel %s ground %.2f" % [frames, g._pos.round(), g._vel.round(), g._ground_t])
					if r == 0 and diff == 2 and frames == 420 and DisplayServer.get_name() != "headless":
						get_viewport().get_texture().get_image().save_png(SHOT_DIR + "chase_%s.png" % g.get_script().get_global_name())
				release_all()
				Engine.time_scale = 1.0
				if result[0] == true:
					wins += 1
				var left := g.time_left()
				print("%s diff %d run %d: %s (%.1f s left, progress %.2f, msg %s)" % [g.get_script().get_global_name(), diff, r, "WIN" if result[0] else "LOSE", left, g.progress(), g._msg])
				if g is BallChase:
					print("   deaths: ", g.deaths.slice(0, 12), " goal ", int(g._goal.x))
				g.queue_free()
				await get_tree().process_frame
			results.append("%s diff %d: %d/%d" % [cls.get_global_name(), diff, wins, runs])
	for line in results:
		print(line)
	get_tree().quit()


func _drive(g: ChaseBase) -> void:
	if g is BallChase:
		_drive_ball(g)
	elif g is RunChase:
		_drive_run(g)
	elif g is WebChase:
		_drive_web(g)


func _ground_under(g: BallChase, x: float, y: float) -> bool:
	for seg in g._segs:
		var a: Vector2 = seg[0]
		var b: Vector2 = seg[1]
		if x >= minf(a.x, b.x) and x <= maxf(a.x, b.x) and maxf(a.y, b.y) > y - 60.0:
			return true
	for m: Dictionary in g._movers:
		var r: Rect2 = m["rect"]
		if x >= r.position.x and x <= r.end.x:
			return true
	return false


func _drive_ball(g: BallChase) -> void:
	press(KEY_RIGHT, true)
	var p := g._pos
	var jump := false
	if not _ground_under(g, p.x + 110.0, p.y):
		# wait for a moving platform to come close before jumping onto it
		var mover_near := false
		for m: Dictionary in g._movers:
			var r: Rect2 = m["rect"]
			if r.position.x > p.x - 40.0 and r.position.x < p.x + 400.0:
				mover_near = true
				if r.position.x - p.x > 140.0:
					press(KEY_RIGHT, false)
					g._vel.x *= 0.9
					return
		jump = true
	for sp in g._spikes:
		if sp.position.x - p.x > 0.0 and sp.position.x - p.x < 120.0:
			jump = true
	for seg in g._segs:
		if absf(seg[0].x - seg[1].x) < 1.0 and seg[0].x - p.x > 0.0 and seg[0].x - p.x < 120.0 and minf(seg[0].y, seg[1].y) < p.y:
			jump = true
	if jump and g._ground_t > 0.0 and not _keys.get(KEY_SPACE, false):
		tap(KEY_SPACE)


func _drive_run(g: RunChase) -> void:
	var jump := false
	var slide := false
	var roof := g._roof_at(g._x + 70.0)
	if roof.size.x <= 0.0 or roof.position.y < g._y - 10.0:
		jump = true
	for k in g._crates.size():
		var c := g._crates[k]
		if c.position.x - g._x > 0.0 and c.position.x - g._x < 85.0:
			jump = true
	for b in g._bars:
		if b.position.x - g._x > 0.0 and b.position.x - g._x < 70.0:
			slide = true
	if jump and g._ground:
		tap(KEY_SPACE)
	elif slide and g._slide <= 0.0:
		tap(KEY_DOWN)


func _drive_web(g: WebChase) -> void:
	press(KEY_RIGHT, true)
	var hold := false
	if g._hook >= 0:
		var h := g._hooks[g._hook]
		# keep swinging until past the hook and rising, then let go
		hold = not (g._pos.x > h.x + 70.0 and g._vel.y < 0.0)
	elif g._ground:
		hold = g._nearest_hook() >= 0
	else:
		hold = g._vel.y > 50.0 and g._nearest_hook() >= 0
	press(KEY_SPACE, hold)
	for e: Dictionary in g._enemies:
		var d: Vector2 = (e["pos"] as Vector2) - g._pos
		if not e["webbed"] and d.x > 0.0 and d.length() < 520.0 and g._shot_cd <= 0.0:
			tap(KEY_X)
			break
