extends SceneTree
## Headless level validator. Run from the project folder:
##   godot --headless --path . --script res://scripts/tools/level_check.gd
## Reports the minimum number of moves to solve every level in data/levels/index.json,
## and for twist levels the moves needed to re-solve after the twist.


func _init() -> void:
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels/index.json"))
	var failed := false
	for file: String in index["levels"]:
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels/" + file))
		var m := PageModel.from_data(data)
		var res := LevelSolver.solve(m, false)
		var line := "%s: solve=%s" % [file, str(res["dist"]) if res["dist"] >= 0 else "UNSOLVABLE"]
		if res["dist"] <= 0:
			failed = true
			line += " (already solved or impossible!)"
		if data.get("twist", "none") == "flip" and res["dist"] > 0:
			var after := LevelSolver.solve(PageModel.from_data(data), true, res["state"])["dist"] as int
			line += " twist_resolve=%s" % (str(after) if after > 0 else "BROKEN")
			if after <= 0:
				failed = true
		print(line, " states=", res["states"])
	print("LEVEL CHECK: ", "FAILED" if failed else "OK")
	quit(1 if failed else 0)
