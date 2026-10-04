class_name LevelGenerator
extends RefCounted
## Builds one level of the station at run time: 8 rooms in a random layout joined by corridors,
## with tasks, risky tasks (sabotage triggers) and fix consoles. Higher levels are bigger, have
## more tasks and more sabotage, and give less time to react.

const ROOM_COUNT := 8
const WALK_TILES_PER_SEC := 6.2

const ROOM_POOL := [
	["Observatory", "d9d2ff"], ["Library", "ffe0b2"], ["Archive", "e8dcc4"], ["Greenhouse", "d4f1c5"],
	["Workshop", "ffd6a5"], ["Laboratory", "cdeffd"], ["Kitchen", "ffe5ec"], ["Cafeteria", "fff3d1"],
	["Medbay", "e0f7fa"], ["Boiler Room", "ffcdb2"], ["Security", "d8e2dc"], ["Electrical", "fff1a8"],
	["Navigation", "d0e6ff"], ["Cellar", "d9cfc1"], ["Reactor", "ffc9c9"], ["Attic", "ecd9ff"],
	["Vault", "f0e6b8"], ["Gallery", "ffd9f0"], ["Dock", "c8e7ef"], ["Storage", "e6e0d4"],
	["Print Shop", "e0e7ff"], ["Studio", "ffe8d6"], ["Lecture Hall", "e2ece9"], ["Dorm", "f1e4f3"],
]

## par = the target time in seconds (about 2, 3, 4 and 5 minutes). risky = how many hidden sabotage
## triggers. disrupt = a hidden task that undoes one of your finished tasks. big = long, harsh sabotage.
const LEVELS := [
	{"title": "THE STUDIO", "par": 120, "risky": 0, "disrupt": 0, "big": false, "vampires": false,
	 "intro": "Level 1: THE STUDIO. The bomb is ticking! Finish every task to earn the first key to the bomb room. Arrow keys move (hold two for diagonals), Z interacts, M opens the map.",
	 "tasks": ["mirror:0", "wires", "bubbles", "dial"]},
	{"title": "THE ARCHIVE WING", "par": 180, "risky": 1, "disrupt": 0, "big": false, "vampires": true,
	 "intro": "Level 2: THE ARCHIVE WING. You are not alone: two vampires lurk in the dark, a friend and the villain who cut the lights. Hold your torch on one to catch him!",
	 "tasks": ["mirror:1", "sort", "switches", "blots", "swipe", "panels"]},
	{"title": "THE MACHINE FLOOR", "par": 240, "risky": 2, "disrupt": 0, "big": true, "vampires": true,
	 "intro": "Level 3: THE MACHINE FLOOR. The sabotage is bigger now and the timers are shorter. Catch a vampire in your light!",
	 "tasks": ["mirror:3", "logic", "simon", "sfx", "charge", "debug", "wires", "dial"]},
	{"title": "THE FINAL PAGE", "par": 300, "risky": 2, "disrupt": 1, "big": true, "vampires": true,
	 "intro": "Level 4: THE FINAL PAGE. Everything at once. Big sabotage, and something may undo your finished work. The end is near...",
	 "tasks": ["mirror:4", "mirror:6", "mirror:7", "debug", "logic", "panels", "sort", "charge", "simon", "sfx"]},
]

const TASK_NAMES := {
	"mirror": ["Light the Page", "Steer the Light Beam", "Bounce the Beam"],
	"wires": ["Rewire the Panel", "Reboot the Breakers", "Reconnect the Cameras"],
	"bubbles": ["Fill the Speech Bubbles", "Letter the Dialogue"],
	"blots": ["Wipe the Ink Spills", "Clean the Print Floor"],
	"dial": ["Align the Telescope", "Steer the Beam"],
	"sort": ["Shelve the Library Books", "Sort the Reading List"],
	"switches": ["Fix the Fuse Box", "Reset the Fuses"],
	"panels": ["Order the Comic Panels", "Storyboard the Strip"],
	"swipe": ["Swipe the Pantry Card", "Swipe the Staff Pass"],
	"debug": ["Debug the Door Lock", "Debug the Assignment"],
	"logic": ["Wire the Logic Gates", "Fix the Circuit Lab"],
	"simon": ["Repeat the Lantern Code", "Match the Light Show"],
	"sfx": ["Letter the Sound Effects", "Type the Sound Effects"],
	"charge": ["Charge the Printing Press", "Charge the Reactor", "Charge the Torch Bank"],
}

const TASK_NAMES_NEW := {
	"dots": ["Connect the Dots", "Trace the Hero Outline"],
	"whack": ["Whack the Lanterns", "Snuff the Flares"],
	"memory": ["Match the Comic Stickers", "Pair the Trading Cards"],
	"unscramble": ["Unscramble the Word", "Fix the Torn Caption"],
	"math": ["Pop Quiz", "Balance the Budget"],
	"inkmix": ["Mix the Ink", "Match the Paint Swatch"],
	"rain": ["Catch the Ink Drops", "Empty the Leaky Pipe"],
	"needle": ["Calibrate the Gauge", "Tune the Oscilloscope"],
	"proofread": ["Proofread the Paragraph", "Check the Essay"],
	"lightsout": ["Lights Out", "Relight the Panel"],
	"pipes": ["Connect the Ink Pipes", "Fix the Plumbing"],
	"slide": ["Slide the Comic Panels", "Rebuild the Torn Page"],
	"safe": ["Crack the Safe", "Open the Locker"],
}

## Task tiers: easy ones come first, hard ones last. Every non-mirror task is used at most once per run.
const TIERS := {
	"easy": ["dots", "whack", "memory", "unscramble", "math", "inkmix", "rain", "bubbles", "wires", "swipe"],
	"medium": ["blots", "dial", "switches", "sort", "panels", "needle", "proofread", "lightsout", "simon", "sfx"],
	"hard": ["logic", "debug", "safe", "pipes", "slide", "charge"],
}
const MIRRORS := [["mirror:0"], ["mirror:1"], ["mirror:3"], ["mirror:4", "mirror:6", "mirror:7"]]


## The task list of every level for this run: no task type appears twice.
static func run_plan(run_seed: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = run_seed * 31 + 7
	var easy: Array = TIERS["easy"].duplicate()
	var medium: Array = TIERS["medium"].duplicate()
	var hard: Array = TIERS["hard"].duplicate()
	_shuffle(easy, rng)
	_shuffle(medium, rng)
	_shuffle(hard, rng)
	var l1: Array = easy.slice(0, 3)
	var l2: Array = easy.slice(3, 5) + medium.slice(0, 3)
	var l3: Array = medium.slice(3, 7) + hard.slice(0, 3)
	var rest: Array = easy.slice(5) + medium.slice(7)
	_shuffle(rest, rng)
	var l4: Array = hard.slice(3, 6) + rest.slice(0, 4)
	var out: Array = []
	var lists := [l1, l2, l3, l4]
	for i in 4:
		var specs: Array = []
		for t in lists[i]:
			specs.append(t)
		for m in MIRRORS[i]:
			specs.append(m)
		_shuffle(specs, rng)
		out.append(specs)
	return out


const SABOTAGES := [
	{"name": "POWER SURGE", "line": "Sparks everywhere!", "fix_name": "Vent the Boiler", "fix_type": "charge"},
	{"name": "REACTOR OVERLOAD", "line": "The core is overheating!", "fix_name": "Cool the Reactor Core", "fix_type": "switches"},
	{"name": "INK FLOOD", "line": "The press burst and ink is flooding the floor!", "fix_name": "Mop Up the Ink Flood", "fix_type": "blots"},
	{"name": "FIRE ALARM", "line": "Something is on fire!", "fix_name": "Silence the Fire Alarm", "fix_type": "wires"},
	{"name": "WRONG COURSE", "line": "The compass spun wildly!", "fix_name": "Re-sort the Star Charts", "fix_type": "sort"},
	{"name": "CHEMICAL SPILL", "line": "A beaker smashed!", "fix_name": "Neutralise the Spill", "fix_type": "dial"},
]


static var last_fail := ""


static func _fail(reason: String) -> Dictionary:
	last_fail = reason
	return {}


static func level_count() -> int:
	return LEVELS.size()


static func level_title(level: int) -> String:
	return LEVELS[clampi(level, 0, LEVELS.size() - 1)]["title"]


## Always returns a valid, fully reachable level (retries with a new sub-seed if needed).
## ease (0 to 2): the player ran over par on the last level, so this one has fewer tasks and kinder timers.
static func generate(level: int, run_seed: int, ease := 0) -> Dictionary:
	var specs: Array = run_plan(run_seed)[clampi(level, 0, 3)]
	for attempt in 12:
		var data := _try_generate(level, run_seed * 7919 + attempt * 104729, ease, specs)
		if not data.is_empty():
			return data
	push_error("LevelGenerator failed to build a level")
	return {}


static func _try_generate(level: int, seed_value: int, ease := 0, specs: Array = []) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + level * 31
	var def: Dictionary = LEVELS[clampi(level, 0, LEVELS.size() - 1)]
	var width := 82 + level * 8
	var height := 58 + level * 6
	# --- rooms in a random layout ---
	var rooms: Array[Dictionary] = []
	var tries := 0
	var names: Array = ROOM_POOL.duplicate()
	_shuffle(names, rng)
	while rooms.size() < ROOM_COUNT and tries < 6000:
		tries += 1
		var w := rng.randi_range(10, 16)
		var h := rng.randi_range(8, 12)
		var x := rng.randi_range(3, width - w - 4)
		var y := rng.randi_range(3, height - h - 4)
		var rect := Rect2i(x, y, w, h)
		var ok := true
		for r in rooms:
			if rect.grow(5).intersects(r["rect"]):
				ok = false
				break
		if ok:
			var nm: Array = names[rooms.size()]
			rooms.append({"rect": rect, "name": nm[0], "color": nm[1]})
	if rooms.size() < ROOM_COUNT:
		return _fail("rooms")
	# --- the floor grid ---
	var g: Array = []
	for y in height:
		var row: Array = []
		row.resize(width)
		row.fill("#")
		g.append(row)
	for r in rooms:
		var rr: Rect2i = r["rect"]
		for y in range(rr.position.y, rr.end.y):
			for x in range(rr.position.x, rr.end.x):
				g[y][x] = "."
	# --- corridors: minimum spanning tree plus two extra loops ---
	var connected: Array[int] = [0]
	var edges: Array = []
	while connected.size() < rooms.size():
		var best_d := 1e9
		var best_a := -1
		var best_b := -1
		for a in connected:
			for b in rooms.size():
				if connected.has(b):
					continue
				var d := _center(rooms[a]["rect"]).distance_to(_center(rooms[b]["rect"]))
				if d < best_d:
					best_d = d
					best_a = a
					best_b = b
		edges.append([best_a, best_b])
		connected.append(best_b)
	for k in 2:
		var a := rng.randi_range(0, rooms.size() - 1)
		var b := rng.randi_range(0, rooms.size() - 1)
		if a != b and not edges.has([a, b]) and not edges.has([b, a]):
			edges.append([a, b])
	for e in edges:
		_carve(g, _center(rooms[e[0]]["rect"]), _center(rooms[e[1]]["rect"]), rng.randf() < 0.5)
	# corridor tiles = floor outside every room
	var is_corridor := {}
	for y in height:
		for x in width:
			if g[y][x] == "." and _room_at(rooms, x, y) < 0:
				is_corridor[Vector2i(x, y)] = true
	# --- task and fix consoles against the top wall of rooms ---
	var plan := _plan_tasks(specs if not specs.is_empty() else def["tasks"], rng, ease)
	var tasks: Array = []
	var fixes: Array = []
	var used: Array[Vector2i] = []
	var order: Array = range(rooms.size())
	_shuffle(order, rng)
	for i in plan["tasks"].size():
		var placed := false
		for k in rooms.size():
			var room_i: int = order[(i + k) % order.size()]
			var spot := _console_spot(g, rooms[room_i], is_corridor, used, rng)
			if spot.x < 0:
				continue
			used.append(spot)
			g[spot.y][spot.x] = "K"
			var t: Dictionary = plan["tasks"][i]
			t["id"] = "t%02d" % (i + 1)
			t["x"] = spot.x
			t["y"] = spot.y
			t["room"] = rooms[room_i]["name"]
			t["room_index"] = room_i
			tasks.append(t)
			placed = true
			break
		if not placed:
			return _fail("task_spot")
	# --- sabotage plan: the villain starts these himself; each fix console is far from where it starts ---
	var sabotages: Array = []
	var sab_pool: Array = SABOTAGES.duplicate()
	_shuffle(sab_pool, rng)
	var point_rooms: Array = range(1, rooms.size())
	_shuffle(point_rooms, rng)
	for i in int(def["risky"]):
		var sab: Dictionary = sab_pool[i % sab_pool.size()]
		var point_room: int = point_rooms[i % point_rooms.size()]
		var far: Array = range(rooms.size())
		far.erase(point_room)
		far.sort_custom(func(a: int, b: int) -> bool:
			return _center(rooms[a]["rect"]).distance_to(_center(rooms[point_room]["rect"])) > _center(rooms[b]["rect"]).distance_to(_center(rooms[point_room]["rect"])))
		var spot := Vector2i(-1, -1)
		var fix_room := -1
		var start := rng.randi_range(0, mini(2, far.size() - 1))
		for k in far.size():
			var cand: int = far[(start + k) % far.size()]
			spot = _console_spot(g, rooms[cand], is_corridor, used, rng)
			if spot.x >= 0:
				fix_room = cand
				break
		if spot.x < 0:
			return _fail("fix_spot")
		used.append(spot)
		g[spot.y][spot.x] = "F"
		var fid := "f%02d" % (i + 1)
		var sid := "s%02d" % (i + 1)
		fixes.append({"id": fid, "x": spot.x, "y": spot.y, "type": sab["fix_type"], "name": sab["fix_name"], "room": rooms[fix_room]["name"], "param": 0, "sabotage": sid, "difficulty_bonus": 1 if def["big"] else 0})
		sabotages.append({"id": sid, "name": sab["name"], "seconds": 60, "damage": 2 if def["big"] else 1, "big": def["big"], "fix": fid, "line": sab["line"],
			"fire_at": int(def["par"] * (0.26 + 0.34 * i)) + rng.randi_range(-4, 6), "point_room": point_room})
	# --- furniture along walls ---
	_decorate(g, rooms, is_corridor, used, rng)
	# --- spawn in the first room ---
	var spawn := _center(rooms[0]["rect"])
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			g[spawn.y + dy][spawn.x + dx] = "."
	g[spawn.y][spawn.x] = "@"
	# --- everything must be reachable ---
	var reach := _flood(g, spawn, width, height)
	for t in tasks + fixes:
		if not reach.has(Vector2i(int(t["x"]), int(t["y"]) + 1)):
			return _fail("unreachable")
	# --- where the villain starts each sabotage, and where the two vampires wait ---
	for sab in sabotages:
		var pt := _free_tile_near(g, _center(rooms[sab["point_room"]]["rect"]))
		sab["point"] = [pt.x, pt.y]
	var vroom: Array = range(1, rooms.size())
	_shuffle(vroom, rng)
	var roles: Array = ["friend", "villain"]
	_shuffle(roles, rng)
	var vamps: Array = []
	for i in (2 if def["vampires"] else 0):
		var vt := _free_tile_near(g, _center(rooms[vroom[i]]["rect"]))
		vamps.append({"x": vt.x, "y": vt.y, "role": roles[i]})
	# --- sabotage timers from real walking distance (start point to fix console) ---
	for sab in sabotages:
		var fix: Dictionary = {}
		for f in fixes:
			if f["id"] == sab["fix"]:
				fix = f
		var pt2: Array = sab["point"]
		var dist := _path_len(g, Vector2i(int(pt2[0]), int(pt2[1])), Vector2i(int(fix["x"]), int(fix["y"]) + 1), width, height)
		if dist < 0:
			return _fail("path")
		var secs := maxi(30, int(round(float(dist) / WALK_TILES_PER_SEC * (2.7 - 0.3 * level) + 15.0)))
		var base_secs := maxi(28, int(secs * 0.85)) if sab["big"] else secs
		sab["seconds"] = int(base_secs * (1.0 + 0.15 * ease))
	# --- output in the same shape as a station data file ---
	var rows: Array = []
	for y in height:
		rows.append("".join(g[y]))
	var out_rooms: Array = []
	for r in rooms:
		var rr: Rect2i = r["rect"]
		out_rooms.append({"name": r["name"], "x": rr.position.x, "y": rr.position.y, "w": rr.size.x, "h": rr.size.y, "color": r["color"]})
	for t in tasks:
		t.erase("room_index")
	return {
		"mode": "station", "rows": rows, "rooms": out_rooms, "tasks": tasks, "fixes": fixes,
		"sabotages": sabotages, "max_health": 3, "intro": "NARRATOR: " + String(def["intro"]), "par": def["par"], "ease": ease, "vampires": vamps, "disrupt_at": int(def["par"] * 0.5) if int(def["disrupt"]) > 0 else -1,
		"level": level, "title": def["title"],
	}


static func _plan_tasks(spec_list: Array, rng: RandomNumberGenerator, ease := 0) -> Dictionary:
	var out: Array = []
	var specs: Array = spec_list.duplicate()
	for i in ease:
		if specs.size() > 3:
			specs.remove_at(specs.size() - 1) # drop the last task
	for spec: String in specs:
		var parts := spec.split(":")
		var type := parts[0]
		var names: Array = TASK_NAMES[type] if TASK_NAMES.has(type) else TASK_NAMES_NEW[type]
		var t := {"type": type, "name": names[rng.randi_range(0, names.size() - 1)], "param": int(parts[1]) if parts.size() > 1 else 0}
		out.append(t)
	return {"tasks": out}


static func _free_tile_near(g: Array, c: Vector2i) -> Vector2i:
	for r in 14:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var x := c.x + dx
				var y := c.y + dy
				if y > 0 and x > 0 and y < g.size() - 1 and x < g[0].size() - 1 and g[y][x] == ".":
					return Vector2i(x, y)
	return c


static func _center(r: Rect2i) -> Vector2i:
	return r.position + r.size / 2


static func _room_at(rooms: Array[Dictionary], x: int, y: int) -> int:
	for i in rooms.size():
		if (rooms[i]["rect"] as Rect2i).has_point(Vector2i(x, y)):
			return i
	return -1


static func _carve(g: Array, a: Vector2i, b: Vector2i, horizontal_first: bool) -> void:
	var corner := Vector2i(b.x, a.y) if horizontal_first else Vector2i(a.x, b.y)
	_carve_line(g, a, corner)
	_carve_line(g, corner, b)


static func _carve_line(g: Array, a: Vector2i, b: Vector2i) -> void:
	var step := Vector2i(signi(b.x - a.x), signi(b.y - a.y))
	var p := a
	while true:
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var q := p + Vector2i(dx, dy)
				if q.y > 0 and q.y < g.size() - 1 and q.x > 0 and q.x < g[0].size() - 1:
					g[q.y][q.x] = "."
		if p == b:
			break
		p += step


static func _console_spot(g: Array, room: Dictionary, is_corridor: Dictionary, used: Array[Vector2i], rng: RandomNumberGenerator) -> Vector2i:
	var rr: Rect2i = room["rect"]
	var xs: Array = range(rr.position.x + 1, rr.end.x - 1)
	_shuffle(xs, rng)
	for x: int in xs:
		var y := rr.position.y
		if g[y][x] != "." or g[y - 1][x] != "#":
			continue
		var clear := true
		for u in used:
			if absi(u.x - x) < 3 and absi(u.y - y) < 2:
				clear = false
		for dx in range(-2, 3):
			for dy in range(-2, 4):
				if is_corridor.has(Vector2i(x + dx, y + dy)):
					clear = false
		if clear:
			return Vector2i(x, y)
	return Vector2i(-1, -1)


static func _decorate(g: Array, rooms: Array[Dictionary], is_corridor: Dictionary, used: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	var chars := ["c", "t", "p", "b"]
	for room in rooms:
		var rr: Rect2i = room["rect"]
		var placed := 0
		var tries := 0
		var want := rng.randi_range(4, 8)
		while placed < want and tries < 200:
			tries += 1
			var x := rng.randi_range(rr.position.x, rr.end.x - 1)
			var y := rng.randi_range(rr.position.y, rr.end.y - 1)
			var on_edge := x == rr.position.x or x == rr.end.x - 1 or y == rr.position.y or y == rr.end.y - 1
			if not on_edge or g[y][x] != ".":
				continue
			var near := false
			for dx in range(-3, 4):
				for dy in range(-3, 4):
					if is_corridor.has(Vector2i(x + dx, y + dy)):
						near = true
			for u in used:
				if absi(u.x - x) < 2 and absi(u.y - y) < 3:
					near = true
			if near:
				continue
			g[y][x] = chars[rng.randi_range(0, chars.size() - 1)]
			placed += 1
		# a table cluster in the middle of some rooms
		if rng.randf() < 0.5:
			var c := _center(rr)
			for dx in 2:
				for dy in 2:
					if g[c.y + dy][c.x + dx] == ".":
						g[c.y + dy][c.x + dx] = "t"


static func _flood(g: Array, start: Vector2i, width: int, height: int) -> Dictionary:
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	var head := 0
	while head < queue.size():
		var p := queue[head]
		head += 1
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = p + d
			if n.x < 0 or n.y < 0 or n.x >= width or n.y >= height or seen.has(n):
				continue
			if "#KFctpb".contains(g[n.y][n.x]):
				continue
			seen[n] = true
			queue.append(n)
	return seen


static func _path_len(g: Array, a: Vector2i, b: Vector2i, width: int, height: int) -> int:
	var dist := {a: 0}
	var queue: Array[Vector2i] = [a]
	var head := 0
	while head < queue.size():
		var p := queue[head]
		head += 1
		if p == b:
			return dist[p]
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = p + d
			if n.x < 0 or n.y < 0 or n.x >= width or n.y >= height or dist.has(n):
				continue
			if "#KFctpb".contains(g[n.y][n.x]):
				continue
			dist[n] = dist[p] + 1
			queue.append(n)
	return -1


static func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
