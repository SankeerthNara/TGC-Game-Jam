extends SceneTree
## Random level generator that keeps layouts whose minimum solution length is in a range.
##   godot --headless --path . --script res://scripts/tools/level_gen.gd -- seed=1 cols=2 rows=2 pw=3 ph=3 walls=4 mirrors=2 min=3 max=6 count=3 rule=normal
## Prints a ready-to-paste "cells" array. Always playtest and add captions yourself.

const CH := {PageModel.Kind.EMPTY: ".", PageModel.Kind.WALL: "#", PageModel.Kind.MIRROR_SLASH: "/",
	PageModel.Kind.MIRROR_BACK: "\\", PageModel.Kind.TARGET_GOOD: "T"}


func _init() -> void:
	var a := {"seed": 1, "cols": 2, "rows": 2, "pw": 3, "ph": 3, "walls": 4, "mirrors": 2, "min": 3, "max": 6,
		"count": 3, "rule": "normal", "tries": 4000}
	for arg in OS.get_cmdline_user_args():
		var kv := arg.split("=")
		if kv.size() == 2:
			a[kv[0]] = kv[1] if kv[0] == "rule" else int(kv[1])
	seed(a["seed"])
	var found := 0
	for t in a["tries"]:
		var m := _random_model(a)
		var start := m.snapshot()
		var res := LevelSolver.solve(m, false)
		m.restore(start)
		if res["dist"] >= a["min"] and res["dist"] <= a["max"]:
			found += 1
			print("--- min moves ", res["dist"])
			_print(m)
			if found >= a["count"]:
				break
	quit()


func _random_model(a: Dictionary) -> PageModel:
	var data := {"panel_size": [a["pw"], a["ph"]], "layout": [a["cols"], a["rows"]], "rule": a["rule"], "cells": []}
	var w: int = a["cols"] * a["pw"]
	var h: int = a["rows"] * a["ph"]
	var grid: Array = []
	for y in h:
		grid.append(".".repeat(w))
	var m := PageModel.from_data({"panel_size": data["panel_size"], "layout": data["layout"], "rule": a["rule"], "cells": grid})
	var free: Array[int] = []
	for i in m.kind.size():
		free.append(i)
	free.shuffle()
	var e: int = free.pop_back()
	m.kind[e] = PageModel.Kind.EMITTER
	m.dir[e] = randi() % 4
	var t: int = free.pop_back()
	m.kind[t] = PageModel.Kind.TARGET_GOOD
	for i in a["walls"]:
		m.kind[free.pop_back()] = PageModel.Kind.WALL
	for i in a["mirrors"]:
		m.kind[free.pop_back()] = PageModel.Kind.MIRROR_SLASH if randi() % 2 == 0 else PageModel.Kind.MIRROR_BACK
	return m


func _print(m: PageModel) -> void:
	var rows: Array[String] = []
	for y in m.height:
		var line := ""
		for x in m.width:
			var i := y * m.width + x
			if m.kind[i] == PageModel.Kind.EMITTER:
				line += [">", "v", "<", "^"][m.dir[i]]
			else:
				line += CH.get(m.kind[i], ".")
		rows.append("\"" + line.replace("\\", "\\\\") + "\"")
	print("[", ", ".join(rows), "]")
