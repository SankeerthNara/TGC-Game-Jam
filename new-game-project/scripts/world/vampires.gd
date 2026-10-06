class_name Vampires
extends RefCounted
## The two vampires of a level: the hero's friend and the comic's villain. They look and behave
## exactly the same (they patrol, run from torchlight, freeze when held in the light), so which one
## is which is pure chance. The villain also starts the sabotage himself by walking to a spot.
## After a Reveal a friend becomes an ally who ignores light and helps more with every level.

const PATROL_SPEED := 3.0 ## tiles per second
const FLEE_SPEED := 5.0
const ALLY_SPEED := 5.8
const LIGHT_R := 3.7 ## tiles: how far the torch scares them
const FREEZE_AFTER := 1.0 ## seconds in the light before they freeze

var world: World
var list: Array[Dictionary] = []
var ally_index := -1
var villain_gone := false
var ally_task_t := 0.0
var autofix_t := -1.0
var _sources: Array = []


func setup(w: World, data: Array) -> void:
	world = w
	_sources = data.duplicate(true)
	reset()


func reset() -> void:
	list.clear()
	ally_index = -1
	villain_gone = false
	ally_task_t = 0.0
	autofix_t = -1.0
	for d: Dictionary in _sources:
		list.append({
			"role": d["role"], "pos": world.center_of(Vector2i(int(d["x"]), int(d["y"]))), "path": [], "state": "patrol",
			"mode": "patrol", "goal": Vector2i.ZERO, "light": 0.0, "thaw": 0.0, "alive": true, "revealed": false, "repath": randf() * 2.0, "seed": randf() * 6.0,
		})


func role_of(i: int) -> String:
	return String(list[i]["role"])


func villain_index() -> int:
	for i in list.size():
		if list[i]["role"] == "villain" and list[i]["alive"]:
			return i
	return -1


## True when the OTHER vampire's role is already known (revealed, dead or defeated), so there is no real choice left.
func other_resolved(i: int) -> bool:
	for k in list.size():
		if k != i and (list[k]["revealed"] or not list[k]["alive"] or k == ally_index):
			return true
	return false


# --- outcomes chosen by the player ------------------------------------------------

func reveal_friend(i: int) -> void:
	var v: Dictionary = list[i]
	v["revealed"] = true
	v["state"] = "ally"
	v["mode"] = "ally"
	v["path"] = []
	ally_index = i
	ally_task_t = 0.0


func reveal_villain(i: int) -> void:
	list[i]["revealed"] = true


## Teleports the villain far away from the hero and returns him to active patrol.
func teleport_far(i: int) -> void:
	var v: Dictionary = list[i]
	v["revealed"] = true
	v["state"] = "patrol"
	v["mode"] = "patrol"
	v["light"] = 0.0
	v["thaw"] = 0.0
	v["path"] = []
	v["repath"] = 0.0
	var hero_tile := world.tile
	var candidates: Array[Vector2i] = []
	for r: Dictionary in world.rooms:
		var center := Vector2i(int(r["x"]) + int(r["w"]) / 2, int(r["y"]) + int(r["h"]) / 2)
		var tile := world.find_free_tile(center)
		candidates.append(tile)
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.distance_to(hero_tile) > b.distance_to(hero_tile))
	var pick_tile: Vector2i = candidates[0] if not candidates.is_empty() else hero_tile
	if candidates.size() >= 3:
		pick_tile = candidates[randi() % mini(3, candidates.size())]
	v["pos"] = world.center_of(pick_tile)



func kill(i: int) -> void:
	list[i]["alive"] = false
	if list[i]["role"] == "villain":
		villain_gone = true
	if ally_index == i:
		ally_index = -1


func defeat_villain(i: int) -> void:
	list[i]["alive"] = false
	villain_gone = true


## The villain got away after a lost parkour: he runs and goes back to patrolling.
func release(i: int) -> void:
	var v: Dictionary = list[i]
	v["state"] = "patrol"
	v["mode"] = "patrol"
	v["light"] = 0.0
	v["thaw"] = 0.0
	v["path"] = []
	v["repath"] = 0.0


# --- per-frame behaviour -----------------------------------------------------------

func update(delta: float) -> void:
	var hero_tile := world.tile
	for i in list.size():
		var v: Dictionary = list[i]
		if not v["alive"]:
			continue
		if v["state"] == "ally":
			_update_ally(v, delta)
			continue
		var d: float = (v["pos"] as Vector2).distance_to(world._foot) / World.TILE
		var lit := d < LIGHT_R
		if v["state"] == "frozen":
			if lit:
				v["thaw"] = 0.0
			else:
				v["thaw"] += delta
				if v["thaw"] > 1.4:
					v["state"] = "patrol"
					v["light"] = 0.0
			continue
		if lit:
			v["light"] = minf(float(v["light"]) + delta, FREEZE_AFTER + 0.2)
			if float(v["light"]) >= FREEZE_AFTER:
				v["state"] = "frozen"
				v["path"] = []
				v["thaw"] = 0.0
				world.vampire_caught.emit(i)
				continue
			_flee(v, delta, hero_tile)
		else:
			v["light"] = maxf(0.0, float(v["light"]) - delta * 0.8)
			_normal_behaviour(i, v, delta)


func _tile_of(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / World.TILE), floori(p.y / World.TILE))


func _flee(v: Dictionary, delta: float, hero_tile: Vector2i) -> void:
	v["state"] = "flee"
	v["repath"] = float(v["repath"]) - delta
	if (v["path"] as Array).is_empty() or float(v["repath"]) <= 0.0:
		v["repath"] = 0.9
		var here := _tile_of(v["pos"])
		var best := here
		var best_d := -1.0
		for k in 6:
			var r: Dictionary = world.rooms[randi() % world.rooms.size()]
			var c := world.find_free_tile(Vector2i(int(r["x"]) + int(r["w"]) / 2, int(r["y"]) + int(r["h"]) / 2))
			var dd := float(hero_tile.distance_to(c))
			if dd > best_d:
				best_d = dd
				best = c
		v["path"] = _bfs(here, best)
	_follow(v, FLEE_SPEED, delta)
	if (v["path"] as Array).is_empty():
		v["state"] = "patrol"


func _normal_behaviour(i: int, v: Dictionary, delta: float) -> void:
	if v["state"] == "flee":
		v["state"] = "patrol"
	var here := _tile_of(v["pos"])
	if v["role"] == "villain" and not villain_gone:
		_villain_schedule(v, here)
	if (v["path"] as Array).is_empty():
		if v["mode"] == "goto_sab":
			world.fire_next_sabotage()
			v["mode"] = "patrol"
		elif v["mode"] == "goto_disrupt":
			world.villain_disrupt()
			v["mode"] = "patrol"
		var r: Dictionary = world.rooms[randi() % world.rooms.size()]
		var c := world.find_free_tile(Vector2i(int(r["x"]) + randi() % int(r["w"]), int(r["y"]) + randi() % int(r["h"])))
		v["path"] = _bfs(here, c)
	_follow(v, PATROL_SPEED, delta)


## The villain decides when to start a sabotage or tamper with a finished task.
func _villain_schedule(v: Dictionary, here: Vector2i) -> void:
	if v["mode"] != "patrol" or not world.sabotage.is_empty():
		return
	var next: Dictionary = world.next_sabotage_due()
	if not next.is_empty():
		var pt: Array = next["point"]
		v["mode"] = "goto_sab"
		v["path"] = _bfs(here, Vector2i(int(pt[0]), int(pt[1])))
		return
	var stand := world.disrupt_target_due()
	if stand.x >= 0:
		v["mode"] = "goto_disrupt"
		v["path"] = _bfs(here, stand)


func _follow(v: Dictionary, speed_tiles: float, delta: float) -> void:
	var path: Array = v["path"]
	if path.is_empty():
		return
	var target := world.center_of(path[0])
	var pos: Vector2 = v["pos"]
	var step := speed_tiles * World.TILE * delta
	if pos.distance_to(target) <= step:
		v["pos"] = target
		path.pop_front()
	else:
		v["pos"] = pos.move_toward(target, step)


## Seconds the friend needs for one task: slower than you, faster every level.
const ALLY_WORK := [30.0, 30.0, 24.0, 18.0]


func _update_ally(v: Dictionary, delta: float) -> void:
	var pos: Vector2 = v["pos"]
	# drop tasks the hero already finished himself
	while not world.assigned.is_empty() and world.tasks_done.has(world.assigned[0]):
		world.assigned.pop_front()
		v["work"] = 0.0
	if not world.assigned.is_empty():
		_work_on_task(v, delta)
		_ally_help(delta)
		return
	v["work"] = 0.0
	v["job"] = ""
	var gap := pos.distance_to(world._foot) / World.TILE
	if gap > 14.0:
		v["pos"] = world._foot + Vector2(world.TILE, 0)
		v["path"] = []
		return
	v["repath"] = float(v["repath"]) - delta
	if gap > 2.2 and ((v["path"] as Array).is_empty() or float(v["repath"]) <= 0.0):
		v["repath"] = 0.45
		v["path"] = _bfs(_tile_of(pos), world.tile)
	elif gap <= 1.6:
		v["path"] = []
	_follow(v, ALLY_SPEED, delta)
	_ally_help(delta)


## Walks to the first task in the queue and works on it until it is done.
func _work_on_task(v: Dictionary, delta: float) -> void:
	var id: String = world.assigned[0]
	if String(v.get("job", "")) != id:
		v["job"] = id
		v["work"] = 0.0
		v["path"] = []
		v["goal"] = world.task_stand_tile(id)
	var goal: Vector2i = v["goal"]
	var pos: Vector2 = v["pos"]
	if pos.distance_to(world.center_of(goal)) > World.TILE * 0.35:
		v["repath"] = float(v.get("repath", 0.0)) - delta
		if (v["path"] as Array).is_empty() or float(v["repath"]) <= 0.0:
			v["repath"] = 1.0
			v["path"] = _bfs(_tile_of(pos), goal)
			if (v["path"] as Array).is_empty():
				v["pos"] = world.center_of(goal) # no path (should not happen): just get there
		_follow(v, ALLY_SPEED, delta)
		return
	v["path"] = []
	v["work"] = float(v["work"]) + delta
	if float(v["work"]) >= work_time():
		v["work"] = 0.0
		v["job"] = ""
		world.ally_complete(id)


func work_time() -> float:
	return ALLY_WORK[clampi(world.level_index, 0, 3)]


## 0..1 progress on the current task, or -1 when the friend is not working.
func work_progress() -> float:
	if ally_index < 0 or world.assigned.is_empty():
		return -1.0
	var v: Dictionary = list[ally_index]
	if String(v.get("job", "")) == "" or not (v["path"] as Array).is_empty():
		return -1.0
	return clampf(float(v.get("work", 0.0)) / work_time(), 0.0, 1.0)


## What the friend does for you. It grows with every level.
func _ally_help(delta: float) -> void:
	if autofix_t > 0.0:
		autofix_t -= delta
		if autofix_t <= 0.0:
			world.ally_fix_sabotage()


# --- pathfinding -------------------------------------------------------------------

func _bfs(from: Vector2i, to: Vector2i) -> Array:
	if from == to:
		return []
	var parent := {from: from}
	var queue: Array[Vector2i] = [from]
	var head := 0
	var found := false
	while head < queue.size() and queue.size() < 14000:
		var p := queue[head]
		head += 1
		if p == to:
			found = true
			break
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = p + d
			if parent.has(n) or world.is_solid(n):
				continue
			parent[n] = p
			queue.append(n)
	if not found:
		return []
	var path: Array = []
	var cur := to
	while cur != from:
		path.push_front(cur)
		cur = parent[cur]
	return path


# --- drawing -----------------------------------------------------------------------

func draw_one(c: CanvasItem, i: int, time: float, ink: Color) -> void:
	var v: Dictionary = list[i]
	if not v["alive"]:
		return
	var s := World.TILE * 1.15
	var f: Vector2 = v["pos"]
	var state: String = v["state"]
	var shiver := Vector2(sin(time * 55.0) * 2.0, 0.0) if state == "frozen" else Vector2.ZERO
	var moving := not (v["path"] as Array).is_empty()
	var bob := absf(sin(time * 10.0 + float(v["seed"]))) * s * 0.05 if moving else 0.0
	var o := f + Vector2(0, -s * 0.3 - bob) + shiver
	var lean := 0.12 * s if state == "flee" else 0.0
	# shadow
	c.draw_set_transform(f + Vector2(0, 2), 0.0, Vector2(1.0, 0.3))
	c.draw_circle(Vector2.ZERO, s * 0.26, Color(0, 0, 0, 0.35))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if state == "frozen":
		c.draw_circle(o + Vector2(0, -s * 0.1), s * 0.55, Color(0.6, 0.3, 1.0, 0.28 + 0.1 * sin(time * 8.0)))
	# cape
	var sway := sin(time * 5.0 + float(v["seed"])) * s * 0.04
	var cape := PackedVector2Array([o + Vector2(-0.16 * s + lean, -0.02 * s), o + Vector2(0.16 * s + lean, -0.02 * s), o + Vector2(0.34 * s + sway, 0.34 * s), o + Vector2(-0.34 * s + sway, 0.34 * s)])
	c.draw_colored_polygon(cape, Color("1a1423"))
	c.draw_colored_polygon(PackedVector2Array([o + Vector2(-0.07 * s + lean, 0.0), o + Vector2(0.07 * s + lean, 0.0), o + Vector2(0.14 * s + sway, 0.32 * s), o + Vector2(-0.14 * s + sway, 0.32 * s)]), Color("a4161a"))
	c.draw_polyline(PackedVector2Array([cape[0], cape[3], cape[2], cape[1]]), ink, s * 0.03)
	# collar and head
	c.draw_colored_polygon(PackedVector2Array([o + Vector2(-0.2 * s + lean, -0.1 * s), o + Vector2(-0.08 * s + lean, 0.02 * s), o + Vector2(-0.14 * s + lean, -0.26 * s)]), Color("1a1423"))
	c.draw_colored_polygon(PackedVector2Array([o + Vector2(0.2 * s + lean, -0.1 * s), o + Vector2(0.08 * s + lean, 0.02 * s), o + Vector2(0.14 * s + lean, -0.26 * s)]), Color("1a1423"))
	var h := o + Vector2(lean, -0.2 * s)
	c.draw_circle(h, s * 0.2, ink)
	c.draw_circle(h, s * 0.175, Color("e9e1f2"))
	c.draw_colored_polygon(PackedVector2Array([h + Vector2(-0.18 * s, -0.04 * s), h + Vector2(0, -0.12 * s), h + Vector2(0.18 * s, -0.04 * s), h + Vector2(0.15 * s, -0.19 * s), h + Vector2(-0.15 * s, -0.19 * s)]), Color("120d1a"))
	for side in [-1.0, 1.0]:
		c.draw_circle(h + Vector2(side * 0.07 * s, -0.02 * s), s * 0.035, Color("ff2d2d"))
	c.draw_colored_polygon(PackedVector2Array([h + Vector2(-0.05 * s, 0.07 * s), h + Vector2(-0.02 * s, 0.07 * s), h + Vector2(-0.035 * s, 0.13 * s)]), Color.WHITE)
	c.draw_colored_polygon(PackedVector2Array([h + Vector2(0.05 * s, 0.07 * s), h + Vector2(0.02 * s, 0.07 * s), h + Vector2(0.035 * s, 0.13 * s)]), Color.WHITE)
	if state == "ally":
		c.draw_rect(Rect2(h + Vector2(-0.19 * s, 0.14 * s), Vector2(0.38 * s, 0.08 * s)), Color("4cc9f0"))
		var hp := h + Vector2(0, -0.34 * s - sin(time * 3.0) * s * 0.02)
		c.draw_circle(hp + Vector2(-0.04 * s, 0), s * 0.05, Color("e63946"))
		c.draw_circle(hp + Vector2(0.04 * s, 0), s * 0.05, Color("e63946"))
		c.draw_colored_polygon(PackedVector2Array([hp + Vector2(-0.085 * s, 0.015 * s), hp + Vector2(0.085 * s, 0.015 * s), hp + Vector2(0, 0.1 * s)]), Color("e63946"))
		var prog := work_progress()
		if prog >= 0.0 and i == ally_index:
			# progress ring above the friend while he works on a task you gave him
			var rc := h + Vector2(0, -0.62 * s)
			c.draw_circle(rc, s * 0.2, Color(0.1, 0.08, 0.15, 0.85))
			c.draw_arc(rc, s * 0.16, -PI * 0.5, -PI * 0.5 + TAU * prog, 32, Color("4cc9f0"), s * 0.07)
			var wrench := rc + Vector2(0, -0.01 * s)
			c.draw_line(wrench + Vector2(-0.06, 0.06) * s, wrench + Vector2(0.06, -0.06) * s, Color.WHITE, s * 0.035)
	elif state == "frozen":
		c.draw_string(ThemeDB.fallback_font, h + Vector2(-6, -s * 0.3), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("ffe066"))
