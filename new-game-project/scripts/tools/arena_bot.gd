class_name ArenaBot
extends RefCounted
## The test bot for the arena fights and the library climb (not part of the game). It fights like the
## old bot (dodges hazards, slashes, pogoes, heals) and dives on enemies below; in a climb it follows
## the level's waypoints with wall jumps, jumps, air dashes and pogos. When it makes no progress for
## 8 s it is moved to the next waypoint (counted in BossFight.bot_assists, reported by the tests).


static func drive(b: BossFight, press: Callable, tap: Callable) -> void:
	if b._phase == "explore" and not b.route.is_empty():
		for k in [KEY_J, KEY_K, KEY_L, KEY_F]:
			press.call(k, false)
		_climb(b, press, tap)
		return
	for k in [KEY_J, KEY_Z, KEY_K, KEY_L, KEY_F]:
		press.call(k, false)
	b.set_meta("z_held", false)
	if not b._phase in ["wave", "wave_intro", "explore"]:
		press.call(KEY_LEFT, false)
		press.call(KEY_RIGHT, false)
		press.call(KEY_DOWN, false)
		return
	press.call(KEY_DOWN, false)
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
	var want := b.level_width - 60.0 if b._exploring else b.center_x()
	if best != null and (not b._exploring or best_d < 400.0):
		want = best.pos.x - signf(best.pos.x - hero.x) * 70.0
	var danger := false
	for e in b._enemies:
		if e.state in ["windup", "charge_wind", "fuse", "dive", "lunge", "charge", "dash"] and e.center().distance_to(b.hero_center()) < 200.0:
			danger = true
			want = hero.x + signf(hero.x - e.pos.x) * 200.0
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
		var dv := best.center() - b.hero_center()
		if not b._ground and dv.y > 60.0 and absf(dv.x) < 220.0 and signf(dv.x) == b._face and b._air_dash and randf() < 0.3:
			# an enemy below and ahead: dive strike
			press.call(KEY_DOWN, true)
			tap.call(KEY_K)
		elif absf(dv.x) < 120.0 and dv.y < -60.0:
			press.call(KEY_UP, true)
			tap.call(KEY_J)
		elif absf(dv.x) < 125.0 and absf(dv.y) < 70.0:
			press.call(KEY_UP, false)
			tap.call(KEY_J)
		elif dv.y < -80.0 and absf(dv.x) < 160.0 and b._ground:
			tap.call(KEY_Z)
	else:
		press.call(KEY_UP, false)
	if b._ink >= 3 and best != null and best_d < 300.0 and (b._ink >= 7 or b._hp > 2):
		tap.call(KEY_L)
	if b._hp <= 2 and b._ink >= 6 and not danger:
		tap.call(KEY_F)


## A new jump: Z goes down (released first if it was still held), and is held while rising.
static func _jump(b: BossFight, press: Callable) -> void:
	if b.get_meta("z_held", false):
		press.call(KEY_Z, false)
		b.set_meta("z_held", false)
		b.set_meta("z_next", true)
	else:
		press.call(KEY_Z, true)
		b.set_meta("z_held", true)
	b.set_meta("z_frames", 0)


## Follow the climb's waypoints with the parkour moves.
static func _climb(b: BossFight, press: Callable, tap: Callable) -> void:
	var hero := b.hero_pos
	var zf: int = b.get_meta("z_frames", 0) + 1
	b.set_meta("z_frames", zf)
	if b.get_meta("z_next", false):
		b.set_meta("z_next", false)
		press.call(KEY_Z, true)
		b.set_meta("z_held", true)
	elif b.get_meta("z_held", false) and zf > 6 and b._vel.y >= 0.0 and not b._ground:
		press.call(KEY_Z, false) # the top of the jump: let go
		b.set_meta("z_held", false)
	var idx: int = b.get_meta("bot_wp", 0)
	# skip waypoints already passed (standing at or above them)
	while idx < b.route.size() and hero.distance_to(b.route[idx]) < 50.0:
		idx += 1
		b.set_meta("bot_wp_t", 0.0)
	b.set_meta("bot_wp", idx)
	if idx >= b.route.size():
		press.call(KEY_LEFT, false)
		press.call(KEY_RIGHT, false)
		return
	var t: float = b.get_meta("bot_wp_t", 0.0) + b.get_process_delta_time()
	b.set_meta("bot_wp_t", t)
	var goal: Vector2 = b.route[idx]
	if t > 8.0:
		# no progress: an assist (counted) to the waypoint
		b.bot_assists += 1
		b.hero_pos = goal
		b._vel = Vector2.ZERO
		b.set_meta("bot_wp_t", 0.0)
		return
	var dx := goal.x - hero.x
	var dy := goal.y - hero.y
	press.call(KEY_DOWN, false)
	press.call(KEY_UP, false)
	var dir := signf(dx) if absf(dx) > 10.0 else 0.0
	# on a wall with the goal above: slide and kick off it
	if false and not b._ground and b._wall != 0 and dy < -40.0 and hero.y > goal.y + 30.0:
		press.call(KEY_LEFT, b._wall < 0)
		press.call(KEY_RIGHT, b._wall > 0)
		if b._vel.y > -250.0:
			_jump(b, press)
		return
	# below a wall with the goal high above: walk to the open gap beside it first
	var head := Rect2(hero + Vector2(-17, -260), Vector2(34, 170))
	for w in b.walls:
		if dy < -150.0 and head.intersects(w):
			var to_l := absf(hero.x - (w.position.x - 30.0))
			var to_r := absf((w.end.x + 30.0) - hero.x)
			# prefer the side the goal's way up lies on: the gap between two walls
			var gap_x := w.position.x - 60.0 if to_l < to_r else w.end.x + 60.0
			for w2 in b.walls:
				if w2 != w and absf(w2.end.x - w.position.x) < 260.0:
					gap_x = (w2.end.x + w.position.x) * 0.5
				elif w2 != w and absf(w2.position.x - w.end.x) < 260.0:
					gap_x = (w.end.x + w2.position.x) * 0.5
			dir = signf(gap_x - hero.x)
			break
	# in the air between walls with the goal above: like a player, hold toward one wall, kick off it
	# when sliding, then hold toward the other one
	if not b._ground and dy < -60.0:
		var near_wall := false
		for w in b.walls:
			if hero.y > w.position.y and hero.y - 86.0 < w.end.y and (absf(w.position.x - hero.x) < 260.0 or absf(hero.x - w.end.x) < 260.0):
				near_wall = true
		if near_wall:
			var side: float = b.get_meta("chim_side", 1.0)
			if b._sliding:
				_jump(b, press)
				side = -side
				b.set_meta("chim_side", side)
			press.call(KEY_LEFT, side < 0.0)
			press.call(KEY_RIGHT, side > 0.0)
			return
	press.call(KEY_LEFT, dir < 0.0)
	press.call(KEY_RIGHT, dir > 0.0)
	if b._ground and dy < -30.0 and absf(dx) < 260.0 and not b.get_meta("z_held", false):
		_jump(b, press)
	elif b._ground and absf(dx) > 200.0 and absf(dx) < 420.0 and dy < 40.0 and not b.get_meta("z_held", false):
		_jump(b, press) # a gap: jump it (and dash below)
	elif b._ground and b.get_meta("z_held", false) and zf > 6:
		press.call(KEY_Z, false)
		b.set_meta("z_held", false)
	if not b._ground:
		# a paper bat or a book below on the way up: pogo off it
		for e in b._steps:
			var v := e.center() - b.hero_center()
			if v.y > 20.0 and v.y < 140.0 and absf(v.x) < 70.0 and dy < 0.0 and b._atk_cd <= 0.0:
				press.call(KEY_DOWN, true)
				tap.call(KEY_J)
				return
		if b._vel.y > -150.0 and absf(dx) > 120.0 and b._air_dash and b._dash_cd <= 0.0:
			tap.call(KEY_K)
		elif b._air_jump and b._vel.y > 0.0 and dy < -40.0:
			_jump(b, press)
