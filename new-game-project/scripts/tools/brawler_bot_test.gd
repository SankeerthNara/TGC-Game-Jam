extends Node
## Plays the 720p brawler (street, then the Twins) with a crude bot to check it runs and can be won
## (not part of the game; a bot is not a player).

var _keys := {}


func press(k: Key, on: bool) -> void:
	if _keys.get(k, false) == on:
		return
	_keys[k] = on
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.pressed = on
	Input.parse_input_event(ev)


func tap(k: Key) -> void:
	press(k, false)
	press(k, true)


func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	for stage in ["street", "train"]:
		var g := BrawlerGame.new()
		g.stage = stage
		layer.add_child(g)
		var result := [""]
		g.finished.connect(func(r: String) -> void: result[0] = r)
		var frames := 0
		var deaths := 0
		var was_dead := false
		while result[0] == "" and frames < 60 * 400:
			await get_tree().process_frame
			frames += 1
			_drive(g)
			if g._phase == "dead" and not was_dead:
				deaths += 1
			was_dead = g._phase == "dead"
		for k in _keys.keys():
			press(k, false)
		print("%s: %s after %.0f s, deaths %d, counters %d" % [stage, result[0] if result[0] != "" else "TIMEOUT", g._t, deaths, g._counters])
		g.queue_free()
		await get_tree().process_frame
	get_tree().quit()


func _drive(g: BrawlerGame) -> void:
	for k in [KEY_J, KEY_L, KEY_K, KEY_Z]:
		press(k, false)
	if g._phase != "play":
		press(KEY_LEFT, false)
		press(KEY_RIGHT, false)
		return
	var best: BrawlEnemy = null
	var best_d := 1e9
	for e in g._enemies:
		var d := absf(e.pos.x - g.hero_pos.x)
		if d < best_d:
			best_d = d
			best = e
	var want := g.lock_right - 100.0
	if best != null:
		want = best.pos.x - signf(best.pos.x - g.hero_pos.x) * 70.0
	press(KEY_LEFT, want < g.hero_pos.x - 10.0)
	press(KEY_RIGHT, want > g.hero_pos.x + 10.0)
	for e in g._enemies:
		if e.counterable() and absf(e.pos.x - g.hero_pos.x) < 300.0 and randf() < 0.5:
			tap(KEY_L)
			return
	if not g._beams.is_empty() and g._ground:
		tap(KEY_Z)
	if best != null and best_d < 100.0:
		if best.state == "windup" and best.attack == "jab" and randf() < 0.3:
			tap(KEY_K)
		else:
			tap(KEY_J)
