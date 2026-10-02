class_name BeamSolver
extends RefCounted
## Traces every emitter's beam across the page. Pure logic, no scene access.

const SLASH_REFLECT := [3, 2, 1, 0] ## '/' : right->up, down->left, left->down, up->right
const BACK_REFLECT := [1, 0, 3, 2] ## '\' : right->down, down->right, left->up, up->left


## Returns {"paths": Array[PackedVector2Array] in cell units, "lit": {cell_index: true}}.
static func trace(m: PageModel) -> Dictionary:
	var paths: Array[PackedVector2Array] = []
	var lit := {}
	for i in m.kind.size():
		if m.kind[i] != PageModel.Kind.EMITTER:
			continue
		paths.append(_trace_one(m, i, lit))
	return {"paths": paths, "lit": lit}


static func _center(p: Vector2i) -> Vector2:
	return Vector2(p) + Vector2(0.5, 0.5)


@warning_ignore("integer_division")
static func _trace_one(m: PageModel, start: int, lit: Dictionary) -> PackedVector2Array:
	var pos := Vector2i(start % m.width, start / m.width)
	var d: int = m.dir[start]
	var path := PackedVector2Array([_center(pos)])
	var seen := {}
	while true:
		var nxt := pos + PageModel.DIRS[d]
		if not m.in_bounds(nxt):
			path.append(_center(pos) + Vector2(PageModel.DIRS[d]) * 0.5)
			break
		var crossed := m.rule == PageModel.Rule.BEND and m.panel_index(nxt) != m.panel_index(pos)
		var entered := d
		pos = nxt
		var c := _center(pos)
		if crossed:
			path.append(c)
			d = (d + 1) % 4
		var idx := m.index_of(pos)
		var k := m.kind[idx]
		var stop := false
		match k:
			PageModel.Kind.WALL, PageModel.Kind.EMITTER:
				path.append(c if crossed else c - Vector2(PageModel.DIRS[entered]) * 0.5)
				stop = true
			PageModel.Kind.TARGET_GOOD, PageModel.Kind.TARGET_BAD:
				lit[idx] = true
				path.append(c)
				stop = true
			PageModel.Kind.MIRROR_SLASH, PageModel.Kind.MIRROR_BACK, PageModel.Kind.FIXED_SLASH, PageModel.Kind.FIXED_BACK:
				path.append(c)
				d = reflect(m, k, d)
		if stop:
			break
		var key := idx * 4 + d
		if seen.has(key):
			break
		seen[key] = true
	return path


static func reflect(m: PageModel, k: int, d: int) -> int:
	var slash := k == PageModel.Kind.MIRROR_SLASH or k == PageModel.Kind.FIXED_SLASH
	if m.rule == PageModel.Rule.LYING:
		slash = not slash
	return SLASH_REFLECT[d] if slash else BACK_REFLECT[d]
