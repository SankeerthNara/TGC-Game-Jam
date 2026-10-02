class_name LevelSolver
extends RefCounted
## Brute-force BFS over every panel arrangement and mirror orientation.
## All actions are reversible, so a level is solvable iff some reachable state is solved.

const MAX_STATES := 300000


static func _key(s: Dictionary) -> String:
	return (s["kind"] as PackedInt32Array).to_byte_array().hex_encode()


static func _solved(m: PageModel) -> bool:
	return m.status(BeamSolver.trace(m))["solved"]


@warning_ignore("integer_division")
static func _children(m: PageModel, s: Dictionary, flipped: bool) -> Array:
	var out: Array = []
	for a in m.panel_count():
		for b in range(a + 1, m.panel_count()):
			m.restore(s)
			m.flipped = flipped
			if m.swap_panels(a, b):
				out.append(m.snapshot())
	for i in m.kind.size():
		m.restore(s)
		m.flipped = flipped
		if m.is_rotatable(i) and m.toggle_mirror(Vector2i(i % m.width, i / m.width)):
			out.append(m.snapshot())
	return out


## Returns {"dist": min moves or -1, "state": solved snapshot, "states": explored}.
static func solve(m: PageModel, flipped: bool, start_state: Variant = null) -> Dictionary:
	if start_state != null:
		m.restore(start_state)
	m.flipped = flipped
	var first := m.snapshot()
	var frontier: Array = [first]
	var seen := {_key(first): true}
	var dist := 0
	var states := 1
	while not frontier.is_empty() and states < MAX_STATES:
		var next: Array = []
		for s: Dictionary in frontier:
			m.restore(s)
			m.flipped = flipped
			if _solved(m):
				return {"dist": dist, "state": s, "states": states}
			for child: Dictionary in _children(m, s, flipped):
				var k := _key(child)
				if not seen.has(k):
					seen[k] = true
					states += 1
					next.append(child)
		frontier = next
		dist += 1
	return {"dist": -1, "state": null, "states": states}
