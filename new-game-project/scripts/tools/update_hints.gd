extends SceneTree
## Regenerate optimal move counts for every level listed in data/levels/index.json.
## Run from the repository root with:
##   godot --headless --path new-game-project --script res://scripts/tools/update_hints.gd


func _init() -> void:
	var index_path := "res://data/levels/index.json"
	if not FileAccess.file_exists(index_path):
		push_error("Missing level index: %s" % index_path)
		quit(1)
		return
	var index: Variant = JSON.parse_string(FileAccess.get_file_as_string(index_path))
	if not index is Dictionary or not index.get("levels", null) is Array:
		push_error("Invalid level index: expected an object with a levels array")
		quit(1)
		return

	var output := {
		"source": "LevelSolver.solve via scripts/tools/update_hints.gd",
		"levels": [],
	}
	var failed := false
	for file: String in index["levels"]:
		var level_path := "res://data/levels/" + file
		if not FileAccess.file_exists(level_path):
			push_error("Missing indexed level: %s" % level_path)
			failed = true
			continue
		var level: Variant = JSON.parse_string(FileAccess.get_file_as_string(level_path))
		if not level is Dictionary:
			push_error("Invalid level JSON: %s" % level_path)
			failed = true
			continue

		var initial := LevelSolver.solve(PageModel.from_data(level), false)
		var entry := {
			"file": file,
			"optimal_moves": initial["dist"],
		}
		if level.get("twist", "none") == "flip":
			var twist_moves := -1
			if initial["state"] != null:
				var after_twist := LevelSolver.solve(PageModel.from_data(level), true, initial["state"])
				twist_moves = after_twist["dist"]
			entry["twist_optimal_moves"] = twist_moves
			if twist_moves < 0:
				failed = true

		if initial["dist"] < 0:
			failed = true
		print("%s: optimal_moves=%d%s" % [file, initial["dist"], " twist_optimal_moves=%d" % entry["twist_optimal_moves"] if entry.has("twist_optimal_moves") else ""])
		output["levels"].append(entry)

	var output_path := "res://data/balance/level_hints.json"
	var output_file := FileAccess.open(output_path, FileAccess.WRITE)
	if output_file == null:
		push_error("Could not write hint data: %s" % output_path)
		quit(1)
		return
	output_file.store_string(JSON.stringify(output, "\t") + "\n")
	output_file.close()
	print("HINT DATA: ", "FAILED" if failed else "OK", " (", output["levels"].size(), " levels)")
	quit(1 if failed else 0)
