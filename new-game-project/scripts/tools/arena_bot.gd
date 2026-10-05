class_name ArenaBot
extends RefCounted
## The test bot for the 2K / arena fights (not part of the game). It reads telegraphs like a player:
## taps L as a gold strike lands (parry), then J (riposte); gets away from red attacks; doesn't swing
## at a guard; finishes broken enemies; heals when low. `press(key, on)` and `tap(key)` drive input.


static func drive(b: BossFight, press: Callable, tap: Callable) -> void:
	for k in [KEY_J, KEY_Z, KEY_K, KEY_L, KEY_F]:
		press.call(k, false)
	if not b._phase in ["wave", "wave_intro", "explore"]:
		press.call(KEY_LEFT, false)
		press.call(KEY_RIGHT, false)
		return
	var hero := b.hero_pos
	var hc := b.hero_center()
	var best: ArenaEnemy = null
	var best_d := 1e9
	for e in b._enemies:
		if e.state == "enter" or e.dead:
			continue
		var d := e.center().distance_to(hc)
		if d < best_d:
			best_d = d
			best = e
	# parry: a gold strike about to land, or one already flying in
	for e in b._enemies:
		if e.dead or b._parry_cd > 0.0:
			continue
		var d := e.center().distance_to(hc)
		var soon := e.tele() == "gold" and e.strike_in() < 0.08 and d < 240.0
		var flying_in := e.parryable() and d < (150.0 if e.kind != "narrator" else 190.0)
		if soon or flying_in:
			tap.call(KEY_L)
			return
	var want := b.level_width - 60.0 if b._exploring else b.center_x()
	if best != null and (not b._exploring or best_d < 420.0):
		want = best.pos.x - signf(best.pos.x - hero.x) * (70.0 if best.tele() != "gold" else 90.0)
	# red attacks and hazards: get away
	var danger := false
	for e in b._enemies:
		var red := e.tele() == "red" or e.state in ["charge", "dash", "slam", "fuse"]
		if red and e.center().distance_to(hc) < 260.0:
			danger = true
			want = hero.x + signf(hero.x - e.pos.x) * 220.0
	press.call(KEY_LEFT, want < hero.x - 12.0)
	press.call(KEY_RIGHT, want > hero.x + 12.0)
	for w in b._waves:
		if absf(float(w["x"]) - hero.x) < 120.0 and signf(hero.x - float(w["x"])) == float(w["dir"]) and b._ground:
			tap.call(KEY_Z)
	for d in b._drops:
		if absf(float(d["x"]) - hero.x) < 40.0:
			press.call(KEY_RIGHT, float(d["x"]) < hero.x)
			press.call(KEY_LEFT, float(d["x"]) >= hero.x)
	if danger and b._dash_cd <= 0.0 and randf() < 0.1:
		tap.call(KEY_K)
	if best != null and b._atk_cd <= 0.0:
		var dv := best.center() - hc
		# no point swinging at a raised guard (unless it's a riposte or he's broken)
		var walled := best.guarding(hero.x) and b._riposte <= 0.0 and best.broken <= 0.0
		if not walled:
			if absf(dv.x) < 120.0 and dv.y < -60.0:
				press.call(KEY_UP, true)
				tap.call(KEY_J)
			elif absf(dv.x) < 125.0 and absf(dv.y) < 70.0:
				press.call(KEY_UP, false)
				tap.call(KEY_J)
			elif dv.y < -80.0 and absf(dv.x) < 160.0 and b._ground:
				tap.call(KEY_Z)
	else:
		press.call(KEY_UP, false)
	if b._hp <= 2 and b._ink >= 6 and not danger:
		tap.call(KEY_F)
