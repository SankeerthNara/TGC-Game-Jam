extends SceneTree
## Checks the run task plan over many seeds: 4/6/8/8 tasks, no type repeated, no mirror pages,
## and every level generates (not part of the game).

func _init() -> void:
	var bad := 0
	for seed_value in 60:
		var plan: Array = LevelGenerator.run_plan(seed_value)
		var seen := {}
		var counts: Array = []
		for lv in plan:
			counts.append(lv.size())
			for t: String in lv:
				if t.begins_with("mirror") or seen.has(t):
					bad += 1
					print("BAD seed %d: %s" % [seed_value, t])
				seen[t] = true
		if counts != [4, 6, 8, 8]:
			bad += 1
			print("BAD counts seed %d: %s" % [seed_value, counts])
		if seed_value < 15:
			for i in 4:
				var data := LevelGenerator.generate(i, seed_value)
				if data.is_empty() or data["tasks"].size() != counts[i]:
					bad += 1
					print("BAD generate seed %d level %d" % [seed_value, i])
	print("BAD: %d" % bad)
	quit()
