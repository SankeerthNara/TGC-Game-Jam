class_name PageModel
extends RefCounted
## Pure data model of one comic page: a grid of cells split into swappable panels.
## No rendering or scene code lives here, so it can be tested headless.

enum Kind { EMPTY, WALL, MIRROR_SLASH, MIRROR_BACK, FIXED_SLASH, FIXED_BACK, EMITTER, TARGET_GOOD, TARGET_BAD }
enum Rule { NORMAL, LYING, BEND }

## Directions are clockwise: 0 right, 1 down, 2 left, 3 up.
const DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]

const CHAR_KIND := {
	".": Kind.EMPTY, "#": Kind.WALL, "/": Kind.MIRROR_SLASH, "\\": Kind.MIRROR_BACK,
	"a": Kind.FIXED_SLASH, "b": Kind.FIXED_BACK, "T": Kind.TARGET_GOOD, "X": Kind.TARGET_BAD,
}
const EMITTER_CHARS := {">": 0, "v": 1, "<": 2, "^": 3}

var cols := 1 ## panels across
var rows := 1 ## panels down
var pw := 1 ## panel width in cells
var ph := 1 ## panel height in cells
var width := 1
var height := 1
var kind := PackedInt32Array()
var dir := PackedInt32Array()
var rule: Rule = Rule.NORMAL
var flipped := false ## the narrator's twist: good and bad targets trade places
var locked: Array[int] = []
var moves := 0


static func from_data(data: Dictionary) -> PageModel:
	var m := PageModel.new()
	m.pw = int(data["panel_size"][0])
	m.ph = int(data["panel_size"][1])
	m.cols = int(data["layout"][0])
	m.rows = int(data["layout"][1])
	m.width = m.cols * m.pw
	m.height = m.rows * m.ph
	m.kind.resize(m.width * m.height)
	m.dir.resize(m.width * m.height)
	var lines: Array = data["cells"]
	assert(lines.size() == m.height, "level has %d rows, expected %d" % [lines.size(), m.height])
	for y in m.height:
		var line: String = lines[y]
		assert(line.length() == m.width, "row %d has %d chars, expected %d" % [y, line.length(), m.width])
		for x in m.width:
			var ch := line[x]
			var i := y * m.width + x
			if EMITTER_CHARS.has(ch):
				m.kind[i] = Kind.EMITTER
				m.dir[i] = EMITTER_CHARS[ch]
			else:
				m.kind[i] = CHAR_KIND.get(ch, Kind.EMPTY)
	var rule_name: String = data.get("rule", "normal")
	m.rule = {"normal": Rule.NORMAL, "lying": Rule.LYING, "bend": Rule.BEND}.get(rule_name, Rule.NORMAL)
	for p in data.get("locked_panels", []):
		m.locked.append(int(p))
	return m


func panel_count() -> int:
	return cols * rows


func in_bounds(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < width and p.y < height


@warning_ignore("integer_division")
func panel_index(p: Vector2i) -> int:
	return (p.y / ph) * cols + p.x / pw


@warning_ignore("integer_division")
func panel_origin(panel: int) -> Vector2i:
	return Vector2i((panel % cols) * pw, (panel / cols) * ph)


func index_of(p: Vector2i) -> int:
	return p.y * width + p.x


func is_rotatable(i: int) -> bool:
	return kind[i] == Kind.MIRROR_SLASH or kind[i] == Kind.MIRROR_BACK


func is_target(i: int) -> bool:
	return kind[i] == Kind.TARGET_GOOD or kind[i] == Kind.TARGET_BAD


## Whether a target currently counts as "good" (must be lit). The twist flips this.
func target_is_good(i: int) -> bool:
	return (kind[i] == Kind.TARGET_GOOD) != flipped


func swap_panels(a: int, b: int) -> bool:
	if a == b or locked.has(a) or locked.has(b):
		return false
	var oa := panel_origin(a)
	var ob := panel_origin(b)
	for ly in ph:
		for lx in pw:
			var ia := index_of(oa + Vector2i(lx, ly))
			var ib := index_of(ob + Vector2i(lx, ly))
			var tk := kind[ia]
			var td := dir[ia]
			kind[ia] = kind[ib]
			dir[ia] = dir[ib]
			kind[ib] = tk
			dir[ib] = td
	moves += 1
	return true


func toggle_mirror(p: Vector2i) -> bool:
	if not in_bounds(p):
		return false
	var i := index_of(p)
	if not is_rotatable(i):
		return false
	kind[i] = Kind.MIRROR_BACK if kind[i] == Kind.MIRROR_SLASH else Kind.MIRROR_SLASH
	moves += 1
	return true


func snapshot() -> Dictionary:
	return {"kind": kind.duplicate(), "dir": dir.duplicate(), "moves": moves, "flipped": flipped}


func restore(s: Dictionary) -> void:
	kind = (s["kind"] as PackedInt32Array).duplicate()
	dir = (s["dir"] as PackedInt32Array).duplicate()
	moves = s["moves"]
	flipped = s["flipped"]


## trace is the dictionary returned by BeamSolver.trace().
func status(trace: Dictionary) -> Dictionary:
	var good_total := 0
	var good_lit := 0
	var bad_lit := 0
	var lit: Dictionary = trace["lit"]
	for i in kind.size():
		if not is_target(i):
			continue
		if target_is_good(i):
			good_total += 1
			if lit.has(i):
				good_lit += 1
		elif lit.has(i):
			bad_lit += 1
	return {
		"good_total": good_total, "good_lit": good_lit, "bad_lit": bad_lit,
		"solved": good_total > 0 and good_lit == good_total and bad_lit == 0,
	}
