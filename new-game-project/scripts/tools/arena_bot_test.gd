extends Node
## Plays the final battle with a crude bot (not part of the game): checks that every wave spawns and
## clears, the relay works and the fight ends, and prints timings. A bot is not a player.
## Screenshots are saved to user:// when run with a window.

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
	var runs := 1
	for run in runs:
		var b := BossFight.new()
		b.bomb_left = 900.0
		layer.add_child(b)
		var result := [""]
		b.finished.connect(func(r: String) -> void: result[0] = r)
		var frames := 0
		var log_phase := ""
		var shots := 0
		while result[0] == "" and frames < 60 * 600:
			await get_tree().process_frame
			frames += 1
			_drive(b)
			var ph := "%s r%d w%d" % [b._phase, b._round, b._wave]
			if ph != log_phase:
				log_phase = ph
				print("  t=%5.1f  %s  hp %d  enemies %d" % [b._t, ph, b._hp, b._enemies.size()])
			if DisplayServer.get_name() != "headless" and frames % 900 == 450 and shots < 8:
				get_viewport().get_texture().get_image().save_png("user://arena_%d.png" % shots)
				shots += 1
		for k in _keys.keys():
			press(k, false)
		print("run %d: %s after %.0f s (cracked %.0f%%)" % [run, result[0], b._t, b.crack_share() * 100.0])
		b.queue_free()
		await get_tree().process_frame
	get_tree().quit()


func _drive(b: BossFight) -> void:
	for k in [KEY_X, KEY_Z, KEY_C, KEY_V, KEY_F]:
		press(k, false)
	if not b._phase in ["wave", "wave_intro"]:
		press(KEY_LEFT, false)
		press(KEY_RIGHT, false)
		return
	var hero := b.hero_pos
	var best: ArenaEnemy = null
	var best_d := 1e9
	for e in b._enemies:
		if e.state == "enter":
			continue
		var d := e.center().distance_to(b.hero_center())
		if d < best_d:
			best_d = d
			best = e
	var want := 640.0
	if best != null:
		want = best.pos.x - signf(best.pos.x - hero.x) * 70.0
	# keep away from danger: lunges, charges, dives, fuses
	var danger := false
	for e in b._enemies:
		if e.state in ["windup", "charge_wind", "fuse", "dive", "lunge", "charge", "dash"] and e.center().distance_to(b.hero_center()) < 200.0:
			danger = true
			want = hero.x + signf(hero.x - e.pos.x) * 200.0
	press(KEY_LEFT, want < hero.x - 12.0)
	press(KEY_RIGHT, want > hero.x + 12.0)
	for w in b._waves:
		if absf(float(w["x"]) - hero.x) < 120.0 and signf(hero.x - float(w["x"])) == float(w["dir"]) and b._ground:
			tap(KEY_Z)
	for d in b._drops:
		if absf(float(d["x"]) - hero.x) < 40.0:
			press(KEY_RIGHT, float(d["x"]) < hero.x)
			press(KEY_LEFT, float(d["x"]) >= hero.x)
	if danger and b._dash_cd <= 0.0 and randf() < 0.1:
		tap(KEY_C)
	if best != null and b._atk_cd <= 0.0:
		var dv := best.center() - b.hero_center()
		if absf(dv.x) < 120.0 and dv.y < -60.0:
			press(KEY_UP, true)
			tap(KEY_X)
		elif absf(dv.x) < 125.0 and absf(dv.y) < 70.0:
			press(KEY_UP, false)
			tap(KEY_X)
		elif dv.y < -80.0 and absf(dv.x) < 160.0 and b._ground:
			tap(KEY_Z)
	else:
		press(KEY_UP, false)
	if b._ink >= 3 and best != null and best_d < 300.0 and (b._ink >= 7 or b._hp > 2):
		tap(KEY_V)
	if b._hp <= 2 and b._ink >= 6 and not danger:
		tap(KEY_F)
