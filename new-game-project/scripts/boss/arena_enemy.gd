class_name ArenaEnemy
extends RefCounted
## One enemy of the final battle. The Narrator conducts them onto his stage in waves.
## kind: lancer (ink chorister with a quill spear: walks, winds up, lunges)
##       bat (page bat: hovers, then dives at the hero)
##       bomb (ink bomb: drifts close, fizzes, explodes)
##       brute (brass brute: armoured, hammer slam shockwaves and charges)
##       narrator (the Narrator himself, last round)

const INK := Color("18151d")
const FLOOR_Y := 600.0
const STATS := {
	"lancer": {"hp": 5.0, "r": 34.0, "h": 94.0, "s": 1.35},
	"bat": {"hp": 2.0, "r": 28.0, "h": 52.0, "s": 1.3},
	"bomb": {"hp": 1.0, "r": 20.0, "h": 40.0, "s": 1.3},
	"brute": {"hp": 18.0, "r": 70.0, "h": 150.0, "s": 1.15},
	"narrator": {"hp": 60.0, "r": 60.0, "h": 170.0, "s": 1.0},
	"baron": {"hp": 40.0, "r": 62.0, "h": 170.0, "s": 1.0},
	"step": {"hp": 999.0, "r": 30.0, "h": 50.0, "s": 1.3},
	"dancer": {"hp": 4.0, "r": 32.0, "h": 80.0, "s": 1.2},
	"scribe": {"hp": 55.0, "r": 46.0, "h": 150.0, "s": 1.0},
}

var kind := "lancer"
var pos := Vector2.ZERO ## feet for ground enemies, centre for flyers
var vel := Vector2.ZERO
var hp := 1.0
var max_hp := 1.0
var dir := -1.0
var state := "enter"
var st := 0.0 ## time in the current state
var cd := 1.0 ## cooldown before the next attack
var flash := 0.0
var floor_y := FLOOR_Y ## the floor of the fight he is in (the library has floors at several heights)
var anchor := Vector2.ZERO ## a stepping bat bobs around this point
var whiteout := 0.0 ## a frame of pure white when hit
var recoil := 0.0 ## 1 when hit, fades: the body snaps away from the blow
var recoil_dir := 1.0
var stagger := 0.0
var dead := false
var t := 0.0
var seed := 0.0
var target := Vector2.ZERO
var phase2 := false
var posture := 0.0 ## 0..1: parries fill it fast, hits slowly; full = broken, open to a critical strike
var broken := 0.0 ## > 0 while the posture is broken
var chain := 0 ## strikes left in the parryable combo being thrown
var trainee := false ## the first library lancer: single slow thrusts only (the parry lesson)
var ground_y := FLOOR_Y ## the floor or the ledge he stands on
var perch := Rect2() ## the ledge (empty: the fight's floor)
var _perch_t := 0.0
var _wind := 0.0 ## length of the current wind-up (0: none)
var _open_t := 1.0 ## how long the current stagger lasts
var _quiet := 0.0 ## time since he was last hit or parried (posture recovers after a while)
## The states in which a guarding enemy blocks blows from the front.
const GUARDS := {"lancer": ["idle", "windup", "rewind"], "baron": ["idle", "jab_wind", "rewind"]}
## How much one perfect parry fills the posture.
const PARRY_FILL := {"scribe": 0.15, "lancer": 0.34, "bat": 1.0, "dancer": 0.5, "brute": 0.26, "baron": 0.13, "narrator": 0.1}
var guards := true ## the fight turns guarding off in the cheap edition
var _o := Vector2.ZERO ## drawing origin (the camera offset)


func _init(k: String, p: Vector2) -> void:
	kind = k
	pos = p
	hp = float(STATS[k]["hp"])
	max_hp = hp
	seed = randf() * 10.0
	cd = randf_range(0.6, 1.4)


func radius() -> float:
	return float(STATS[kind]["r"])


func flying() -> bool:
	return kind in ["bat", "bomb", "step", "dancer", "scribe"]


## Centre of the body, for hits.
func center() -> Vector2:
	if flying():
		return pos
	return pos + Vector2(0, -float(STATS[kind]["h"]) * 0.5)


func hurt_box() -> Rect2:
	var r := radius()
	var h := float(STATS[kind]["h"])
	if flying():
		return Rect2(pos - Vector2(r, h * 0.5), Vector2(r * 2.0, h))
	return Rect2(pos - Vector2(r, h), Vector2(r * 2.0, h))


## Is this enemy's attack touching the hero right now? Only attacks hurt (and the brute's armoured
## body): standing next to a guarding enemy is safe, so the fight is about reading and parrying.
func hits(hero_box: Rect2) -> bool:
	if state == "enter" or dead or broken > 0.0 or state in ["stagger", "stunned"] or kind == "step":
		return false
	var box := hurt_box().grow(-6.0)
	match kind:
		"scribe":
			if _orb_hits(hero_box):
				return true
			if not state in ["charge", "slam"]:
				return false
		"dancer":
			if state != "spin":
				return false
		"lancer":
			if state != "lunge":
				return false
			box = box.merge(Rect2(pos + Vector2(dir * 14.0, -64), Vector2(dir * 95.0, 14)).abs())
		"bat":
			if state != "dive":
				return false
		"bomb":
			return false
		"brute":
			if state == "slam" and st < 0.15:
				box = box.merge(Rect2(pos + Vector2(dir * 35.0, -70), Vector2(dir * 105.0, 70)).abs())
			elif state == "punch":
				box = box.merge(Rect2(pos + Vector2(dir * 40.0, -110), Vector2(dir * 90.0, 40)).abs())
		"baron":
			if state != "jab":
				return false
			box = box.merge(Rect2(pos + Vector2(dir * 30.0, -112), Vector2(dir * 130.0, 30)).abs())
		"narrator":
			if state == "throw":
				return Rect2(quill - Vector2(36, 18), Vector2(72, 36)).intersects(hero_box)
			if state == "whirl":
				return hero_box.get_center().distance_to(center()) < 140.0
			if not state in ["lunge", "airdash"]:
				return false
	return box.intersects(hero_box)


func boss() -> bool:
	return kind in ["baron", "narrator", "scribe"]


## The attack hitting now can be parried (gold).
func parryable() -> bool:
	match kind:
		"lancer":
			return state == "lunge"
		"bat":
			return state == "dive"
		"dancer":
			return state == "spin"
		"brute":
			return state == "punch"
		"baron":
			return state == "jab"
		"narrator":
			return state in ["lunge", "airdash"]
		"scribe":
			return state == "charge"
	return false


## The attack being wound up: "gold" (parry it), "red" (get away) or "" (none).
func tele() -> String:
	if dead or broken > 0.0:
		return ""
	match kind:
		"lancer", "bat":
			return "gold" if state in ["windup", "rewind"] else ""
		"dancer":
			return "gold" if state == "windup" else ""
		"brute":
			if state == "punch_wind":
				return "gold"
			return "red" if state in ["windup", "charge_wind"] else ""
		"baron":
			if state in ["jab_wind", "rewind"]:
				return "gold"
			return "red" if state in ["sweep", "lob"] and st < _wind else ""
		"scribe":
			if state == "charge_wind":
				return "gold"
			return "red" if state in ["cast_wind", "ring_wind", "slam_wind"] else ""
		"narrator":
			if state in ["lunge_wind", "airdash_wind"]:
				return "gold"
			return "red" if state in ["throw_wind", "whirl_wind"] else ""
		"bomb":
			return "red" if state == "fuse" else ""
	return ""


## Seconds until the wound-up attack strikes (a big number when nothing is wound up).
func strike_in() -> float:
	if _wind <= 0.0 or st >= _wind:
		return 99.0
	return _wind - st


## 0..1: the last moment of a wind-up (the flash the player reacts to).
func flash_k() -> float:
	return clampf(1.0 - strike_in() / 0.22, 0.0, 1.0) if tele() != "" else 0.0


## Guarding: blocks a blow from the front (not during his own attacks, stagger or a broken posture).
func guarding(from_x: float) -> bool:
	if not guards or not GUARDS.has(kind) or broken > 0.0 or stagger > 0.0 or not state in GUARDS[kind]:
		return false
	return absf(from_x - pos.x) < 6.0 or signf(from_x - pos.x) == dir


func take_hit(dmg: float, from_x: float, post := 0.06) -> void:
	hp -= dmg
	if kind == "narrator" and broken <= 0.0 and not state in ["stagger", "stunned"]:
		_hit_taken += dmg
		if _hit_taken > max_hp * 0.09 and hp > 0.0:
			_hit_taken = 0.0
			open(1.3) # staggered: down for a moment
			EventBus.sound_requested.emit("hero_ko")
	flash = 1.0
	whiteout = 0.06
	recoil = 1.0
	recoil_dir = signf(pos.x - from_x) if pos.x != from_x else -dir
	_quiet = 0.0
	if broken <= 0.0:
		posture = minf(1.0, posture + post)
		if posture >= 1.0 and hp > 0.0:
			_break()
	if kind in ["lancer", "bat", "bomb"] and broken <= 0.0 and not state in ["stagger", "stunned"]:
		vel.x = signf(pos.x - from_x) * 320.0
		stagger = 0.18
		if kind == "bat":
			_go("hover")
	if hp <= 0.0:
		dead = true


## A perfect parry: the combo goes on with a fresh wind-up, or (on the last hit) he staggers open.
func parried(from_x: float) -> void:
	_quiet = 0.0
	recoil = 1.0
	recoil_dir = signf(pos.x - from_x) if pos.x != from_x else -dir
	posture = minf(1.0, posture + float(PARRY_FILL.get(kind, 0.2)))
	if posture >= 1.0:
		_break()
		return
	if chain > 0 and kind != "bat":
		chain -= 1
		if not flying():
			vel.x = recoil_dir * 220.0
		else:
			pos += Vector2(recoil_dir * 70.0, -20.0)
		_wind_up("rewind", 0.42 if boss() else 0.34)
		return
	open(1.3 if boss() else 1.0)


## Knocked open for `secs` (after a parried last hit, a riposte or a critical strike).
func open(secs: float) -> void:
	chain = 0
	_go("stunned" if kind == "bat" else "stagger")
	_open_t = secs
	if not flying():
		vel.x = recoil_dir * 300.0


func _break() -> void:
	broken = 2.6 if boss() else 2.3
	posture = 1.0
	chain = 0
	_go("broken")
	vel.x = 0.0


func _go(s: String) -> void:
	state = s
	st = 0.0
	_wind = 0.0


func _wind_up(s: String, dur: float) -> void:
	state = s
	st = 0.0
	_wind = dur
	vel.x = 0.0
	EventBus.sound_requested.emit("enemy_windup")


## Moves the enemy. `fight` is the BossFight (hero position, shockwaves, projectiles).
func update(dt: float, fight: Node) -> void:
	t += dt
	st += dt
	flash = maxf(0.0, flash - dt * 5.0)
	whiteout = maxf(0.0, whiteout - dt)
	recoil = maxf(0.0, recoil - dt * 6.0)
	stagger = maxf(0.0, stagger - dt)
	_quiet += dt
	if _quiet > 2.0 and broken <= 0.0:
		posture = maxf(0.0, posture - dt * (0.07 if boss() else 0.15))
	var hero: Vector2 = fight.hero_pos
	var hc: Vector2 = fight.hero_center()
	if kind == "step":
		pos = anchor + Vector2(sin(t * 1.3 + seed) * 18.0, sin(t * 2.1 + seed) * 10.0)
		vel = Vector2(cos(t * 1.3 + seed), 0.0)
		return
	if state == "enter":
		var heavy := kind in ["brute", "baron", "narrator"]
		if not flying():
			pos.y = minf(ground_y, pos.y + (1500.0 if heavy else 900.0) * dt)
		if st > 0.55 and (not heavy or pos.y >= ground_y):
			_go("idle" if not flying() else "hover")
			if heavy:
				fight.heavy_landing(self)
		return
	if broken > 0.0 or state in ["stagger", "stunned"]:
		# open: no guard, no attacks
		if broken > 0.0:
			broken -= dt
		if kind in ["bat", "dancer"]:
			vel.y = minf(vel.y + 1800.0 * dt, 700.0)
			pos.y = minf(pos.y + vel.y * dt, floor_y - 24.0)
			pos.x += vel.x * dt
			vel.x = move_toward(vel.x, 0.0, 600.0 * dt)
		else:
			_ground(dt)
		var done := broken <= 0.0 if state == "broken" else st > _open_t
		if done:
			broken = 0.0
			if state == "broken":
				posture = 0.0
			vel = Vector2.ZERO
			_go("hover" if flying() else "idle")
			cd = randf_range(0.5, 0.9)
		if not flying() and kind != "bat":
			pos.x = clampf(pos.x, _lo(fight), _hi(fight))
		return
	match kind:
		"lancer":
			_lancer(dt, hero, fight)
		"bat":
			_fl = fight.bound_l()
			_fr = fight.bound_r()
			_bat(dt, hc)
		"dancer":
			_dancer(dt, hc, fight)
		"scribe":
			_scribe(dt, hero, hc, fight)
		"bomb":
			_bomb(dt, hc, fight)
		"brute":
			_brute(dt, hero, fight)
		"narrator":
			_narrator(dt, hero, hc, fight)
		"baron":
			_baron(dt, hero, fight)


## Walking limits: the ledge he stands on, or the stage.
func _lo(fight: Node) -> float:
	return maxf(fight.bound_l(), perch.position.x + 20.0) if perch.size.x > 0.0 else fight.bound_l()


func _hi(fight: Node) -> float:
	return minf(fight.bound_r(), perch.end.x - 20.0) if perch.size.x > 0.0 else fight.bound_r()


func _ground(dt: float) -> void:
	if perch.size.x <= 0.0:
		ground_y = floor_y
	pos.x += vel.x * dt
	vel.x = move_toward(vel.x, 0.0, 1400.0 * dt)
	if pos.y < ground_y:
		vel.y = minf(vel.y + 2400.0 * dt, 1200.0)
		pos.y = minf(pos.y + vel.y * dt, ground_y)
	else:
		pos.y = ground_y
		vel.y = 0.0


func _lancer(dt: float, hero: Vector2, fight: Node) -> void:
	var dx := hero.x - pos.x
	var level := absf(hero.y - ground_y) < 60.0
	match state:
		"idle":
			if stagger <= 0.0:
				dir = signf(dx) if dx != 0.0 else dir
				# close in to spear range and hold there, guarded
				var want: float = 0.0 if absf(dx) < 135.0 or not level else dir * 120.0 * float(fight.enemy_speed())
				vel.x = move_toward(vel.x, want, 600.0 * dt)
			# on a ledge above or below the hero: leap down to his level after a moment
			if perch.size.x > 0.0 and not level and absf(dx) < 340.0:
				_perch_t += dt
				if _perch_t > 1.0:
					perch = Rect2()
					ground_y = FLOOR_Y
					vel = Vector2(dir * 160.0, -420.0)
					pos.y -= 2.0
			cd -= dt
			if cd <= 0.0 and absf(dx) < 260.0 and level and stagger <= 0.0 and pos.y >= ground_y - 1.0:
				var combos := [0] if trainee else [0, 1, 1, 2]
				chain = combos[randi() % combos.size()]
				_wind_up("windup", 0.95 if trainee else 0.55)
		"windup", "rewind":
			vel.x = 0.0
			if st > _wind:
				_go("lunge")
				vel.x = dir * 560.0
		"lunge":
			if st > 0.3:
				if chain > 0:
					chain -= 1
					_wind_up("rewind", 0.34)
				else:
					_go("recover")
		"recover":
			if st > 0.7:
				_go("idle")
				cd = randf_range(1.4, 2.0) if trainee else randf_range(0.9, 1.7)
	_ground(dt)
	pos.x = clampf(pos.x, _lo(fight), _hi(fight))


var _fl := 100.0
var _fr := 1180.0


func _bat(dt: float, hc: Vector2) -> void:
	match state:
		"hover":
			target = hc + Vector2(sin(t * 0.7 + seed) * 220.0, -170.0 + sin(t * 1.3 + seed) * 40.0)
			target.y = clampf(target.y, floor_y - 460.0, floor_y - 150.0)
			vel = vel.lerp((target - pos) * 2.2, minf(1.0, dt * 3.0))
			pos += vel * dt
			cd -= dt
			if cd <= 0.0 and stagger <= 0.0:
				_wind_up("windup", 0.5)
		"windup":
			pos += Vector2(sin(t * 60.0) * 2.0, 0)
			if st > _wind:
				_go("dive")
				vel = (hc - pos).normalized() * 640.0
		"dive":
			pos += vel * dt
			if st > 0.9 or pos.y > floor_y - 20.0:
				_go("hover")
				cd = randf_range(1.2, 2.2)
	pos.x = clampf(pos.x, _fl - 10.0, _fr + 10.0)


func _bomb(dt: float, hc: Vector2, fight: Node) -> void:
	match state:
		"hover":
			vel = vel.lerp((hc - pos).normalized() * 95.0, dt * 2.0)
			pos += vel * dt + Vector2(0, sin(t * 3.0 + seed) * 0.6)
			if pos.distance_to(hc) < 95.0:
				_wind_up("fuse", 0.7)
				EventBus.sound_requested.emit("bomb_fuse")
		"fuse":
			if st > _wind:
				dead = true
				fight.explode(pos, 100.0)


## The brass brute: a red hammer slam (shockwaves) and a red charge, and a parryable gold punch.
func _brute(dt: float, hero: Vector2, fight: Node) -> void:
	var dx := hero.x - pos.x
	match state:
		"idle":
			dir = signf(dx) if dx != 0.0 else dir
			vel.x = dir * 60.0 * fight.enemy_speed()
			cd -= dt
			if cd <= 0.0:
				if absf(dx) < 200.0:
					if randf() < 0.55:
						_wind_up("punch_wind", 0.55)
					else:
						_wind_up("windup", 0.8)
				elif randf() < 0.5:
					_wind_up("charge_wind", 0.6)
				else:
					cd = 0.4
		"punch_wind":
			if st > _wind:
				_go("punch")
				vel.x = dir * 260.0
		"punch":
			vel.x = move_toward(vel.x, 0.0, 1200.0 * dt)
			if st > 0.25:
				_go("recover")
		"recover":
			vel.x = 0.0
			if st > 0.6:
				_go("idle")
				cd = randf_range(1.0, 1.6)
		"windup":
			if st > _wind:
				_go("slam")
				fight.shockwave(pos + Vector2(dir * 80.0, 0), 1.0)
				fight.shockwave(pos + Vector2(dir * 80.0, 0), -1.0)
		"slam":
			if st > 0.7:
				_go("idle")
				cd = randf_range(1.3, 2.0)
		"charge_wind":
			if st > _wind:
				_go("charge")
				vel.x = dir * 420.0
		"charge":
			if st > 1.0 or pos.x <= fight.bound_l() + 10.0 or pos.x >= fight.bound_r() - 10.0:
				_go("idle")
				vel.x = 0.0
				cd = randf_range(1.0, 1.8)
				fight.shake(8.0)
	pos.x += vel.x * dt
	pos.x = clampf(pos.x, fight.bound_l(), fight.bound_r())
	pos.y = floor_y


## The Ink Baron: chains of parryable cane jabs, a red cane sweep (shockwaves), red ink rain from the
## sky, and his choristers. After a sweep or a chain he stands open for a moment.
func _baron(dt: float, hero: Vector2, fight: Node) -> void:
	var dx := hero.x - pos.x
	var sp: float = fight.enemy_speed()
	match state:
		"idle":
			dir = signf(dx) if dx != 0.0 else dir
			vel.x = 0.0 if absf(dx) < 170.0 else dir * 80.0 * sp
			cd -= dt
			if cd <= 0.0:
				var low := hp < max_hp * 0.6
				var picks := ["jab", "jab", "sweep", "lob", "summon"] if low else ["jab", "sweep", "jab", "lob"]
				var pick: String = picks[randi() % picks.size()]
				vel.x = 0.0
				match pick:
					"jab":
						chain = randi_range(1, 2) + (1 if low else 0)
						_wind_up("jab_wind", 0.6)
					"sweep":
						_wind_up("sweep", 0.75)
					"lob":
						_wind_up("lob", 0.5)
					"summon":
						_go("summon")
						EventBus.sound_requested.emit("enemy_windup")
		"jab_wind", "rewind":
			vel.x = 0.0
			if st > _wind:
				_go("jab")
				vel.x = dir * 360.0
		"jab":
			vel.x = move_toward(vel.x, 0.0, 1400.0 * dt)
			if st > 0.26:
				if chain > 0:
					chain -= 1
					_wind_up("rewind", 0.42)
				else:
					_go("recover")
		"recover":
			vel.x = 0.0
			if st > 0.9:
				_baron_rest()
		"sweep":
			if st > _wind and st - dt <= _wind:
				fight.shockwave(pos + Vector2(dir * 60.0, 0), 1.0)
				fight.shockwave(pos + Vector2(dir * 60.0, 0), -1.0)
				fight.shake(10.0)
			if st > 1.4:
				_go("recover")
		"lob":
			if st > _wind and st - dt <= _wind:
				fight.ink_rain(5)
			if st > 1.3:
				_baron_rest()
		"summon":
			if st > 0.6 and st - dt <= 0.6:
				fight.spawn("lancer", Vector2(clampf(pos.x - 220.0, 200.0, 1080.0), FLOOR_Y))
				fight.spawn("lancer", Vector2(clampf(pos.x + 220.0, 200.0, 1080.0), FLOOR_Y))
			if st > 1.2:
				_baron_rest()
	pos.x = clampf(pos.x + vel.x * dt, fight.bound_l() + 30.0, fight.bound_r() - 30.0)
	pos.y = FLOOR_Y


func _baron_rest() -> void:
	_go("idle")
	cd = randf_range(1.0, 1.8)


## The Narrator: chains of parryable quill strikes, a red dash across the stage, a red slam, ink rain
## and bats. He guards while he hovers; after a chain or a slam he rests, open.
## The Narrator's three phases were replaced by a ground duel; kept for the fight's checks.
func stage_phase() -> int:
	return 1


var quill := Vector2.ZERO ## the thrown quill's position (state "throw")
var _quill_from := Vector2.ZERO
var _hit_taken := 0.0 ## damage since his last stagger (enough of it staggers him)


## The Narrator as a fast duelist on foot (like an agile sword duel): he lunges with his quill (gold),
## throws it out on an ink thread and pulls it back (red), leaps and dives diagonally (gold), spins
## in a whirl of ink in the air (red), and hops away. A run of hits staggers him; below half health
## he is faster and chains his moves.
func _narrator(dt: float, hero: Vector2, hc: Vector2, fight: Node) -> void:
	phase2 = hp < max_hp * 0.5
	var sp: float = fight.enemy_speed() * (1.25 if phase2 else 1.0)
	var dx := hero.x - pos.x
	match state:
		"idle":
			dir = signf(dx) if dx != 0.0 else dir
			# keep a duelling distance
			var want := 0.0
			if absf(dx) > 380.0:
				want = dir * 260.0
			elif absf(dx) < 140.0 and absf(pos.x - fight.center_x()) < 380.0:
				want = -dir * 200.0
			vel.x = move_toward(vel.x, want * sp, 1600.0 * dt)
			cd -= dt * sp
			if cd <= 0.0:
				var d := absf(dx)
				var picks: Array
				if d > 420.0:
					picks = ["throw", "jump_dash", "lunge"]
				elif d < 170.0:
					picks = ["whirl", "evade", "lunge"]
				else:
					picks = ["lunge", "throw", "jump_dash", "whirl"]
				var pick: String = picks[randi() % picks.size()]
				EventBus.sound_requested.emit("narrator_attack")
				match pick:
					"lunge":
						_wind_up("lunge_wind", 0.42 / sp)
					"throw":
						_wind_up("throw_wind", 0.45 / sp)
					"jump_dash":
						_go("jump")
						vel = Vector2(dir * 120.0, -980.0)
						target = Vector2(1.0, 0.0)
					"whirl":
						_go("jump")
						vel = Vector2(dir * 60.0, -900.0)
						target = Vector2(2.0, 0.0)
					"evade":
						_go("evade")
						var away := -dir
						if absf(pos.x - fight.center_x()) > 380.0:
							away = signf(fight.center_x() - pos.x) # cornered: hop over toward the middle
						vel = Vector2(away * 520.0, -620.0)
		"lunge_wind", "throw_wind":
			vel.x = 0.0
			if st > _wind:
				if state == "lunge_wind":
					_go("lunge")
					vel.x = dir * 1100.0
					EventBus.sound_requested.emit("dash")
				else:
					_go("throw")
					_quill_from = pos + Vector2(dir * 50.0, -120.0)
					quill = _quill_from
					EventBus.sound_requested.emit("slash")
		"lunge":
			if st > 0.3 or (dir > 0.0 and pos.x >= fight.bound_r() - 20.0) or (dir < 0.0 and pos.x <= fight.bound_l() + 20.0):
				vel.x = 0.0
				_after_move()
		"throw":
			# out along the thread, then pulled back to his hand
			var reach := 560.0
			var k := st / 0.45 if st < 0.45 else 1.0 - (st - 0.45) / 0.4
			quill = _quill_from + Vector2(dir * reach * clampf(k, 0.0, 1.0), 0.0)
			if st > 0.85:
				_after_move()
		"jump":
			vel.y = minf(vel.y + 2700.0 * dt, 1400.0)
			if vel.y > -120.0:
				# the top of the leap: the dive (gold) or the whirl (red)
				if target.x == 1.0:
					_wind_up("airdash_wind", 0.28 / sp)
				else:
					_wind_up("whirl_wind", 0.3 / sp)
				vel = Vector2.ZERO
		"airdash_wind", "whirl_wind":
			vel = Vector2.ZERO
			dir = signf(dx) if dx != 0.0 else dir
			if st > _wind:
				if state == "airdash_wind":
					_go("airdash")
					vel = (hc - center()).normalized() * 1050.0
					if vel.y < 200.0:
						vel.y = 200.0
					EventBus.sound_requested.emit("dash")
				else:
					_go("whirl")
		"airdash":
			if pos.y >= ground_y:
				vel = Vector2.ZERO
				fight.shake(6.0)
				_after_move()
		"whirl":
			vel = Vector2.ZERO
			if st > 0.7:
				_go("fall")
		"fall", "evade":
			vel.x = move_toward(vel.x, 0.0, 400.0 * dt)
			vel.y = minf(vel.y + 2700.0 * dt, 1400.0)
			if pos.y >= ground_y and st > 0.1:
				vel = Vector2.ZERO
				_after_move()
		"recover":
			vel.x = move_toward(vel.x, 0.0, 2400.0 * dt)
			if st > (0.45 if phase2 else 0.6):
				_go("idle")
				cd = randf_range(0.25, 0.6) if phase2 else randf_range(0.5, 1.0)
	if not state in ["jump", "airdash_wind", "whirl_wind", "whirl", "airdash", "fall", "evade"] and pos.y < ground_y:
		vel.y = minf(vel.y + 2700.0 * dt, 1400.0) # on his feet: gravity
	pos += vel * dt
	# keep the duel in view (the stage's sides are behind the curtains)
	pos.x = clampf(pos.x, fight.bound_l() + 110.0, fight.bound_r() - 110.0)
	if pos.y >= ground_y:
		pos.y = ground_y
		if not state in ["jump", "evade", "fall"]:
			vel.y = 0.0


## After a move: a short open moment; in phase 2 he sometimes chains straight into another.
func _after_move() -> void:
	if phase2 and randf() < 0.35:
		_go("idle")
		cd = 0.0
		return
	_go("recover")


func _rest() -> void:
	_go("recover")



## The aerial dancer: circles high under the ceiling, then spins down at the hero and swirls back up.
## Out of reach from the floor: wall jumps, the air dash and pogos get you up to it.
func _dancer(dt: float, hc: Vector2, fight: Node) -> void:
	var cx: float = fight.center_x()
	match state:
		"hover":
			var ang := t * 0.9 + seed
			target = Vector2(cx + cos(ang) * 380.0, floor_y - 430.0 + sin(ang * 2.0) * 50.0)
			pos = pos.move_toward(target, 300.0 * dt)
			cd -= dt
			if cd <= 0.0:
				_wind_up("windup", 0.6)
				target = hc
		"windup":
			pos += Vector2(sin(t * 50.0) * 2.0, -20.0 * dt)
			if st > _wind:
				_go("spin")
				vel = (target - pos).normalized() * 620.0
		"spin":
			# a curling dive: the path bends a little as it spins
			vel = vel.rotated(sin(st * 6.0) * 1.2 * dt)
			pos += vel * dt
			if st > 0.9 or pos.y > floor_y - 40.0:
				_go("rise")
		"rise":
			pos = pos.move_toward(Vector2(pos.x, floor_y - 430.0), 420.0 * dt)
			if st > 0.9:
				state = "hover"
				st = 0.0
				cd = randf_range(1.4, 2.4)
	pos.x = clampf(pos.x, fight.bound_l(), fight.bound_r())


## The brass brute's armour: plain blows to its front bounce off.
func armoured_against(from_x: float) -> bool:
	return kind == "brute" and not state in ["slam", "charge_wind"] and (absf(from_x - pos.x) < 6.0 or signf(from_x - pos.x) == dir)


# --- drawing ----------------------------------------------------------------------------

const GOLD_FLASH := Color("ffe066")
const RED_FLASH := Color("ff2a3a")


func draw(ci: CanvasItem, time: float, origin := Vector2.ZERO) -> void:
	_o = origin
	var a := 1.0
	if state == "enter":
		a = clampf(st / 0.4, 0.0, 1.0)
	var white := flash
	_telegraph(ci, time)
	if not _draw_sprite(ci, a, time):
		match kind:
			"lancer":
				_draw_lancer(ci, white, a)
			"bat":
				_draw_bat(ci, white, a)
			"bomb":
				_draw_bomb(ci, white, a)
			"brute":
				_draw_brute(ci, white, a)
			"narrator":
				_draw_narrator(ci, white, a, time)
			"baron":
				_draw_baron(ci, white, a)
	ci.draw_set_transform(_o, 0.0, Vector2.ONE)
	_draw_tele(ci, time)
	_draw_posture(ci, time)
	if kind == "narrator":
		_draw_duel(ci, time)
	if kind == "scribe":
		_draw_scribe_extras(ci, time)
	ci.draw_set_transform(_o, 0.0, Vector2.ONE)


## The wind-up warning: a gold "!" (parry it) or a red one (get away), and a star-shaped glint on the
## weapon that flares in the last moment before the strike: that is when to press L.
func _draw_tele(ci: CanvasItem, time: float) -> void:
	var tc := tele()
	if tc == "":
		return
	var col := GOLD_FLASH if tc == "gold" else RED_FLASH
	var h := float(STATS[kind]["h"])
	var head := center() + Vector2(0, -h * 0.75 if not flying() else -h * 0.9)
	ComicArt.shout(ci, "!", head + _o, 42, col, 8)
	ci.draw_set_transform(_o, 0.0, Vector2.ONE)
	var k := flash_k()
	if k <= 0.0:
		return
	var tip := center() + Vector2(dir * radius() * 1.1, -h * 0.25 if not flying() else 0.0)
	var r := 10.0 + 34.0 * k
	ci.draw_texture_rect(ArenaArt.TEX_GLOW, Rect2(tip - Vector2(r, r) * 2.0, Vector2(r, r) * 4.0), false, Color(col.r, col.g, col.b, 0.75 * k))
	for i in 4:
		var ang := i * PI * 0.5 + time * 2.0
		var d := Vector2.from_angle(ang)
		var side := d.orthogonal() * r * 0.12
		ci.draw_colored_polygon(PackedVector2Array([tip + d * r * 1.6, tip + side, tip - d * r * 0.2, tip - side]), Color(1, 1, 1, k))
	ci.draw_circle(tip, r * 0.22, Color(1, 1, 1, k))


## A small posture bar over regular enemies (the bosses' is on the HUD); a broken posture flashes
## the critical-strike prompt.
## The Narrator's quill on its ink thread, and the ink whirl around him.
func _draw_duel(ci: CanvasItem, time: float) -> void:
	if state == "throw":
		var hand := pos + Vector2(dir * 50.0, -120.0) + _o
		ci.draw_line(hand, quill + _o, Color(0.12, 0.04, 0.2), 4.0)
		ci.draw_line(hand, quill + _o, Color(0.7, 0.45, 1.0, 0.6), 1.5)
		var q := quill + _o
		ci.draw_colored_polygon(PackedVector2Array([q + Vector2(dir * 46.0, 0), q + Vector2(-dir * 30.0, -10), q + Vector2(-dir * 40.0, 0), q + Vector2(-dir * 30.0, 10)]), Color("f3e7c9"))
		ci.draw_polyline(PackedVector2Array([q + Vector2(dir * 46.0, 0), q + Vector2(-dir * 30.0, -10), q + Vector2(-dir * 40.0, 0), q + Vector2(-dir * 30.0, 10), q + Vector2(dir * 46.0, 0)]), INK, 2.0)
	if state == "whirl":
		var c := center() + _o
		for k in 10:
			var a0 := time * 14.0 + k * TAU / 10.0
			ci.draw_arc(c, 90.0 + (k % 3) * 22.0, a0, a0 + 1.4, 12, Color(0.75, 0.45, 1.0, 0.75), 4.0)


func _draw_posture(ci: CanvasItem, time: float) -> void:
	if dead or boss() or kind == "bomb":
		return
	var h := float(STATS[kind]["h"])
	var top := center() + Vector2(0, -h * 0.62 - 26.0 if not flying() else -h * 0.8 - 18.0)
	if broken > 0.0:
		if int(time * 8.0) % 2 == 0:
			ComicArt.shout(ci, "J!", top + Vector2(0, -16) + _o, 34, Color.WHITE, 8)
			ci.draw_set_transform(_o, 0.0, Vector2.ONE)
		return
	if posture < 0.02:
		return
	var bar := Rect2(top - Vector2(30, 3), Vector2(60, 7))
	ci.draw_rect(bar.grow(2.0), INK)
	ci.draw_rect(Rect2(bar.position, Vector2(bar.size.x * posture, bar.size.y)), Color("ffd23f").lerp(Color("ff8a00"), posture))


const SPRITE_KEYS := {"scribe": "masked_villain", "dancer": "enemy_lancer", "step": "enemy_bat", "lancer": "enemy_lancer", "bat": "enemy_bat", "brute": "enemy_brute", "baron": "enemy_baron", "narrator": "narrator_boss"}
const SPRITE_H := {"scribe": 230.0, "dancer": 120.0, "step": 90.0, "lancer": 160.0, "bat": 96.0, "brute": 220.0, "baron": 255.0, "narrator": 260.0}


func _draw_sprite(ci: CanvasItem, a: float, time: float) -> bool:
	var key: String = SPRITE_KEYS.get(kind, "")
	if key == "" or not Sprites.has(key):
		return false
	var feet := pos + _o
	var h: float = SPRITE_H[kind]
	var face := dir
	var squash := 1.0
	var rot := 0.0
	match kind:
		"bat", "step":
			feet = pos + _o + Vector2(0, h * 0.5)
		"dancer":
			# a whirling ink dancer: ribbons trail behind it, it spins hard when it dives
			feet = pos + _o + Vector2(0, h * 0.5)
			rot = st * 18.0 if state == "spin" else sin(t * 3.0) * 0.4
			for k in 3:
				var ang := t * 4.0 + k * TAU / 3.0
				var r0 := pos + _o + Vector2.from_angle(ang) * 24.0
				ci.draw_line(r0, r0 + Vector2.from_angle(ang + 1.2) * 46.0 - vel.normalized() * 30.0, Color(0.75, 0.4, 1.0, 0.7 * a), 5.0)
			face = 1.0 if vel.x >= 0.0 else -1.0
			squash = 1.0 + sin(t * 24.0) * 0.08
		"scribe":
			feet = pos + _o + Vector2(0, h * 0.55)
			face = dir
			var frame := _scribe_frame()
			if frame != "":
				key = frame
			if state in ["tele_out", "tele_in"]:
				a *= (1.0 - st / 0.22) if state == "tele_out" else st / 0.18
			if state == "charge":
				rot = 0.5 * dir
			elif state in ["fake_death"]:
				rot = 1.4 * dir
				feet.y += 40.0
		"narrator":
			feet = pos + _o
			face = dir
			if state == "whirl":
				rot = st * 22.0
			elif state in ["lunge", "airdash"]:
				rot = 0.25 * dir
			elif tele() != "":
				rot = -0.12 * dir
			elif state in ["stagger", "stunned"]:
				rot = -0.5 * dir
		_:
			squash = 1.0 + sin(t * 6.0) * 0.015
			if tele() != "":
				rot = -0.12 * dir
			elif state in ["lunge", "slam", "charge", "sweep", "jab", "punch"]:
				rot = 0.12 * dir
	var tint := Color(1, 1.0 - flash * 0.6, 1.0 - flash * 0.6, a)
	if kind == "scribe" and key == "masked_villain":
		tint = Color(tint.r * 0.55, tint.g * 0.7, tint.b, tint.a) # ink-blue until his own art arrives
	var fk := flash_k()
	if fk > 0.0:
		var tcol := GOLD_FLASH if tele() == "gold" else RED_FLASH
		tint = Color(lerpf(tint.r, tcol.r, 0.35 * fk), lerpf(tint.g, tcol.g, 0.35 * fk), lerpf(tint.b, tcol.b, 0.35 * fk), a)
	if broken > 0.0:
		tint = tint.darkened(0.25)
		rot += 0.12 * dir # sagging, off balance
	if whiteout > 0.0:
		tint = Color(8, 8, 8, a) # blown out to white for a frame
	if recoil > 0.0:
		# knocked back from the side the blow came from (bosses barely budge)
		var heavy := 0.35 if kind in ["baron", "narrator", "brute"] else 1.0
		feet.x += recoil * recoil_dir * 12.0 * heavy
		rot += recoil * recoil_dir * 0.16 * heavy
	if kind != "narrator":
		# the painted enemies are dark: a warm aura behind them keeps them readable on dark stages
		var c := feet - Vector2(0, h * (0.45 if kind != "bat" else 0.5))
		var r := h * 0.62
		ci.draw_texture_rect(ArenaArt.TEX_GLOW, Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(1.0, 0.45, 0.32, 0.8 * a))
	Sprites.draw(ci, key, feet, h, face, tint, squash, rot)
	ci.draw_set_transform(_o, 0.0, Vector2.ONE)
	return true


func _col(c: Color, white: float, a: float) -> Color:
	var r := c.lerp(Color.WHITE, white)
	r.a = a
	return r


## Clear warnings before the big attacks: the Narrator's dash lane and slam spot, the Baron's sweep.
func _telegraph(ci: CanvasItem, time: float) -> void:
	var pulse := 0.5 + 0.5 * sin(time * 24.0)
	if kind == "narrator" and state == "dash" and st < 0.75:
		var y := clampf(target.y, 300.0, 560.0) - 20.0
		ci.draw_rect(Rect2(Vector2(-200.0, y - 45.0) + Vector2(0, _o.y), Vector2(4000.0, 90.0)), Color(1, 0.1, 0.25, 0.10 + 0.12 * pulse))
		ci.draw_line(Vector2(-200.0, y) + Vector2(0, _o.y), Vector2(4000.0, y) + Vector2(0, _o.y), Color(1, 0.3, 0.4, 0.5 + 0.4 * pulse), 3.0)
	elif kind == "narrator" and state == "slam" and st < 0.6:
		ci.draw_set_transform(Vector2(target.x, FLOOR_Y) + _o, 0.0, Vector2(1.0, 0.25))
		ci.draw_circle(Vector2.ZERO, 90.0, Color(1, 0.1, 0.25, 0.15 + 0.15 * pulse))
		ci.draw_arc(Vector2.ZERO, 90.0, 0.0, TAU, 32, Color(1, 0.3, 0.4, 0.8), 4.0)
		ci.draw_set_transform(_o, 0.0, Vector2.ONE)
	elif kind == "baron" and state == "sweep" and st < 0.75:
		for side in [-1.0, 1.0]:
			ci.draw_line(Vector2(pos.x, FLOOR_Y - 6.0) + _o, Vector2(pos.x + side * (160.0 + 300.0 * st), FLOOR_Y - 6.0) + _o, Color(1, 0.3, 0.4, 0.4 + 0.4 * pulse), 6.0)


func _sc() -> float:
	return float(STATS[kind]["s"])


func _draw_lancer(ci: CanvasItem, white: float, a: float) -> void:
	ci.draw_set_transform(pos + _o, 0.0, Vector2(dir * _sc(), _sc()))
	var back := 8.0 if state == "windup" else (-10.0 if state == "lunge" else 0.0)
	var bob := sin(t * 8.0) * 2.0 if state == "idle" and absf(vel.x) > 5.0 else 0.0
	# robe of ink
	ArenaArt.poly(ci, PackedVector2Array([Vector2(-22 + back, 0), Vector2(22 + back, 0), Vector2(14 - back * 0.5, -46 + bob), Vector2(-12 - back * 0.5, -48 + bob)]), _col(Color("2b2140"), white, a), 3.0)
	ci.draw_line(Vector2(-18, -6), Vector2(18, -6), _col(Color("ffd23f"), white, a), 3.0)
	# pale theatre mask
	var h := Vector2(2 - back * 0.5, -58 + bob)
	ci.draw_circle(h, 15.0, _col(INK, 0.0, a))
	ci.draw_circle(h, 13.0, _col(Color("f1e3d3"), white, a))
	ci.draw_colored_polygon(PackedVector2Array([h + Vector2(2, -4), h + Vector2(11, -6), h + Vector2(10, -1)]), _col(INK, 0.0, a))
	ci.draw_arc(h + Vector2(4, 6), 5.0, PI + 0.3, TAU - 0.3, 6, _col(INK, 0.0, a), 2.0)
	# quill spear
	var hand := Vector2(10 - back, -30)
	var tip := hand + Vector2(64 if state == "lunge" else 46, -4 if state != "windup" else -18)
	ci.draw_line(hand - Vector2(30, -6), tip, _col(INK, 0.0, a), 5.0)
	ci.draw_line(hand - Vector2(30, -6), tip, _col(Color("d8cbb0"), white, a), 2.5)
	ci.draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-12, -5), tip + Vector2(-12, 5)]), _col(Color("ffd23f"), white, a))
	ci.draw_set_transform(_o, 0.0, Vector2.ONE)


func _draw_bat(ci: CanvasItem, white: float, a: float) -> void:
	var flap := sin(t * (24.0 if state != "dive" else 8.0)) * 0.6
	ci.draw_set_transform(pos + _o, 0.0, Vector2((1.0 if vel.x >= 0.0 else -1.0) * _sc(), _sc()))
	for side in [-1.0, 1.0]:
		ArenaArt.poly(ci, PackedVector2Array([Vector2(side * 8, -6), Vector2(side * 36, -14 - flap * 18.0), Vector2(side * 24, 8)]), _col(Color("3c2a4d"), white, a), 2.0)
	# body: a folded comic page
	ArenaArt.poly(ci, PackedVector2Array([Vector2(-12, -14), Vector2(12, -14), Vector2(14, 12), Vector2(-14, 12)]), _col(Color("f4e8c1"), white, a), 3.0)
	ci.draw_line(Vector2(-8, -4), Vector2(8, -4), _col(Color("c2a878"), 0.0, a), 2.0)
	ci.draw_line(Vector2(-8, 2), Vector2(6, 2), _col(Color("c2a878"), 0.0, a), 2.0)
	ci.draw_circle(Vector2(-4, -8), 3.0, _col(Color("e63946"), 0.0, a))
	ci.draw_circle(Vector2(5, -8), 3.0, _col(Color("e63946"), 0.0, a))
	ci.draw_set_transform(_o, 0.0, Vector2.ONE)


func _draw_bomb(ci: CanvasItem, white: float, a: float) -> void:
	var blink := state == "fuse" and int(st * 12.0) % 2 == 0
	var real := pos
	ci.draw_set_transform(pos + _o, 0.0, Vector2(_sc(), _sc()))
	pos = Vector2.ZERO
	ci.draw_circle(pos, 17.0, _col(INK, 0.0, a))
	ci.draw_circle(pos, 14.0, _col(Color("e63946") if blink else Color("2b2d42"), white, a))
	ci.draw_circle(pos + Vector2(-4, -5), 4.0, Color(1, 1, 1, 0.35 * a))
	ci.draw_line(pos + Vector2(6, -13), pos + Vector2(12, -22), _col(Color("c9ada7"), 0.0, a), 3.0)
	ci.draw_circle(pos + Vector2(12, -23), 3.0 + sin(t * 30.0) * 1.5, _col(Color("ffb703"), 0.0, a))
	ci.draw_circle(pos + Vector2(-5, 1), 2.5, _col(Color.WHITE, 0.0, a))
	ci.draw_circle(pos + Vector2(4, 1), 2.5, _col(Color.WHITE, 0.0, a))
	pos = real
	ci.draw_set_transform(_o, 0.0, Vector2.ONE)


func _draw_brute(ci: CanvasItem, white: float, a: float) -> void:
	ci.draw_set_transform(pos + _o, 0.0, Vector2(dir * _sc(), _sc()))
	var shell := _col(Color("b5512f"), white, a)
	# little legs
	for k in 3:
		var lx := -30.0 + k * 30.0
		var step := sin(t * 10.0 + k) * 5.0 if absf(vel.x) > 5.0 else 0.0
		ci.draw_line(Vector2(lx, -24), Vector2(lx - 8 + step, 0), _col(INK, 0.0, a), 7.0)
	# the armoured dome
	var dome := PackedVector2Array()
	for k in 17:
		var ang := PI + k * PI / 16.0
		dome.append(Vector2(cos(ang) * 64.0, -22.0 + sin(ang) * 92.0))
	ArenaArt.poly(ci, dome, shell, 4.0)
	for k in 3:
		ci.draw_arc(Vector2(0, -22), 30.0 + k * 18.0, PI * 1.15, PI * 1.85, 12, _col(Color("7f2e17"), 0.0, a), 4.0)
	ci.draw_circle(Vector2(-10, -60), 8.0, Color(1, 0.9, 0.7, 0.3 * a))
	# face slit
	ci.draw_rect(Rect2(Vector2(36, -48), Vector2(22, 10)), _col(INK, 0.0, a))
	ci.draw_circle(Vector2(50, -43), 3.0, _col(Color("ffd23f"), 0.0, a))
	# the hammer
	var up := state in ["windup", "charge_wind"]
	var swing := -1.8 if up else (0.4 if state == "slam" else -0.3)
	var hand := Vector2(40, -60)
	var head := hand + Vector2.from_angle(swing) * 70.0
	ci.draw_line(hand, head, _col(INK, 0.0, a), 8.0)
	ci.draw_line(hand, head, _col(Color("6b4226"), white, a), 4.0)
	ci.draw_set_transform(pos + _o + head * Vector2(dir, 1.0) * _sc(), swing * dir, Vector2(dir * _sc(), _sc()))
	ArenaArt.poly(ci, PackedVector2Array([Vector2(-14, -22), Vector2(14, -22), Vector2(14, 22), Vector2(-14, 22)]), _col(Color("c9a227"), white, a), 3.0)
	ci.draw_set_transform(_o, 0.0, Vector2.ONE)


func _draw_baron(ci: CanvasItem, white: float, a: float) -> void:
	ci.draw_set_transform(pos + _o, 0.0, Vector2(dir, 1.0))
	var wind := state in ["sweep", "lob", "summon"] and st < 0.75
	var bob := sin(t * 4.0) * 3.0
	# coat tails and legs
	ArenaArt.poly(ci, PackedVector2Array([Vector2(-60, -70), Vector2(-74, -6), Vector2(-40, -18), Vector2(-20, -60)]), _col(Color("9b1d20"), white, a), 3.0)
	for k in 2:
		ci.draw_line(Vector2(-18 + k * 36, -40), Vector2(-22 + k * 40, 0), _col(INK, 0.0, a), 14.0)
	# the hulking ink body
	var body := PackedVector2Array()
	for k in 20:
		var ang := k * TAU / 20.0
		body.append(Vector2(cos(ang) * 62.0, -96.0 + bob + sin(ang) * 66.0 + (sin(t * 6.0 + k) * 2.0)))
	ArenaArt.poly(ci, body, _col(Color("1e1530"), white, a), 4.0)
	# ringmaster coat front, gold buttons
	ArenaArt.poly(ci, PackedVector2Array([Vector2(-40, -140 + bob), Vector2(40, -140 + bob), Vector2(48, -40), Vector2(-48, -40)]), _col(Color("b5172a"), white, a), 3.0)
	for k in 3:
		ci.draw_circle(Vector2(0, -122 + k * 24 + bob), 5.0, _col(Color("ffd23f"), white, a))
	# pale mask face with a stitched grin
	var h := Vector2(6, -168 + bob)
	ci.draw_circle(h, 30.0, _col(INK, 0.0, a))
	ci.draw_circle(h, 27.0, _col(Color("efe4d2"), white, a))
	ci.draw_colored_polygon(PackedVector2Array([h + Vector2(-14, -8), h + Vector2(-2, -4), h + Vector2(-12, 0)]), _col(INK, 0.0, a))
	ci.draw_colored_polygon(PackedVector2Array([h + Vector2(16, -8), h + Vector2(4, -4), h + Vector2(14, 0)]), _col(INK, 0.0, a))
	ci.draw_arc(h + Vector2(2, 6), 14.0, 0.2, PI - 0.2, 10, _col(INK, 0.0, a), 3.0)
	for k in 5:
		var sx := -10.0 + k * 5.0
		ci.draw_line(h + Vector2(sx + 2, 14), h + Vector2(sx + 2, 22), _col(INK, 0.0, a), 2.0)
	# crooked top hat
	ci.draw_set_transform(pos + _o + Vector2(dir * 10.0, -200 + bob), -0.2 * dir, Vector2(dir, 1.0))
	ArenaArt.poly(ci, PackedVector2Array([Vector2(-34, 0), Vector2(34, 0), Vector2(34, -8), Vector2(-34, -8)]), _col(INK, 0.0, a), 2.0)
	ArenaArt.poly(ci, PackedVector2Array([Vector2(-20, -8), Vector2(20, -8), Vector2(18, -54), Vector2(-18, -54)]), _col(Color("1b1b22"), white, a), 3.0)
	ci.draw_rect(Rect2(Vector2(-20, -20), Vector2(40, 7)), _col(Color("b5172a"), white, a))
	# the cane
	ci.draw_set_transform(pos + _o, 0.0, Vector2(dir, 1.0))
	var hand := Vector2(56, -110 + bob)
	var tip := hand + (Vector2(10, -90) if wind else Vector2(30, 104))
	ci.draw_line(hand, tip, _col(INK, 0.0, a), 9.0)
	ci.draw_line(hand, tip, _col(Color("2b1d14"), white, a), 5.0)
	ci.draw_circle(hand + (tip - hand).normalized() * -6.0, 9.0, _col(Color("ffd23f"), white, a))
	ci.draw_set_transform(_o, 0.0, Vector2.ONE)


func _draw_narrator(ci: CanvasItem, white: float, a: float, time: float) -> void:
	var c := pos + Vector2(0, -20)
	# coat tail below him
	var sway := sin(time * 3.0) * 10.0
	ArenaArt.poly(ci, PackedVector2Array([c + Vector2(-40, 40), c + Vector2(40, 40), c + Vector2(28 + sway, 120), c + Vector2(0 + sway, 100), c + Vector2(-28 + sway, 125)]), _col(Color("3c096c"), white, a), 3.0)
	ComicArt.narrator(ci, c, 0.72, 1.0, "grin" if state != "rest" else "shock", time)
	if white > 0.0:
		ci.draw_circle(c + Vector2(0, 20), 70.0, Color(1, 1, 1, 0.4 * white))
	# the conductor's baton / quill
	var hand := c + Vector2(55, 30)
	var tip := hand + Vector2.from_angle(-1.0 + sin(time * 6.0) * 0.5) * 60.0
	ci.draw_line(hand, tip, INK, 5.0)
	ci.draw_line(hand, tip, Color("fff3d1"), 2.5)
	if phase2:
		ci.draw_arc(c + Vector2(0, 20), 80.0, 0.0, TAU, 32, Color(0.8, 0.3, 1.0, 0.4), 4.0)


# --- the Ink Scribe ---------------------------------------------------------------------------

var orbs: Array[Dictionary] = [] ## his ink orbs: pos, vel, t, wait (hover before homing), ring (no homing)
var fake_dead := false ## the fake death has happened (second phase)
var _slams := 0


func _scribe_tele(fight: Node, to: Vector2, then: String, wind: float) -> void:
	_go("tele_out")
	target = to
	_next_state = then
	_next_wind = wind
	EventBus.sound_requested.emit("dash")


var _next_state := ""
var _next_wind := 0.0


## The Ink Scribe: a floating ink sorcerer who teleports between attacks: homing ink orbs (red), a
## charge across the room at the hero's height (gold), a slam from above with shockwaves (red; he is
## dazed after it). At half health he fakes his death, then crashes through the floor: the second
## half is fought in the archive below, faster, with spiralling orb rings and double slams.
func _scribe(dt: float, hero: Vector2, hc: Vector2, fight: Node) -> void:
	var sp := 1.35 if fake_dead else 1.0
	var cx: float = fight.center_x()
	_update_orbs(dt, hc, fight)
	if not fake_dead and hp <= max_hp * 0.5 and not state in ["fake_death", "laugh", "crash"]:
		_go("fake_death")
		vel = Vector2.ZERO
		orbs.clear()
		fight.scribe_fake_death(self)
		return
	match state:
		"hover":
			dir = signf(hero.x - pos.x) if hero.x != pos.x else dir
			target = Vector2(cx + sin(t * 0.7) * 280.0, floor_y - 300.0 + sin(t * 1.6) * 24.0)
			pos = pos.move_toward(target, 160.0 * dt)
			cd -= dt * sp
			if cd <= 0.0:
				var picks: Array = ["orbs", "charge", "slam"]
				if fake_dead:
					picks = ["ring", "charge", "slam", "orbs", "slam"]
				var pick: String = picks[randi() % picks.size()]
				match pick:
					"orbs":
						_scribe_tele(fight, Vector2(cx + randf_range(-300, 300), floor_y - 330.0), "cast_wind", 0.6 / sp)
					"ring":
						_scribe_tele(fight, Vector2(cx, floor_y - 260.0), "ring_wind", 0.6 / sp)
					"charge":
						var side := -1.0 if hero.x > cx else 1.0
						_scribe_tele(fight, Vector2(cx + side * 470.0, clampf(hc.y, floor_y - 300.0, floor_y - 60.0)), "charge_wind", 0.55 / sp)
					"slam":
						_slams = 2 if fake_dead else 1
						_scribe_tele(fight, Vector2(hero.x, floor_y - 420.0), "slam_wind", 0.45 / sp)
		"tele_out":
			if st > 0.22:
				pos = Vector2(clampf(target.x, fight.bound_l() + 60.0, fight.bound_r() - 60.0), target.y)
				dir = signf(hero.x - pos.x) if hero.x != pos.x else dir
				_go("tele_in")
				EventBus.sound_requested.emit("enemy_spawn")
		"tele_in":
			if st > 0.18:
				_wind_up(_next_state, _next_wind)
		"cast_wind", "ring_wind":
			if st > _wind:
				var n := 5 if fake_dead else 3
				if state == "ring_wind":
					for k in 10:
						var a := k * TAU / 10.0
						orbs.append({"pos": pos, "vel": Vector2.from_angle(a) * 230.0, "t": 0.0, "wait": 0.0, "ring": true})
				else:
					for k in n:
						var a := -PI * 0.5 + (k - (n - 1) * 0.5) * 0.7
						orbs.append({"pos": pos + Vector2.from_angle(a) * 90.0, "vel": Vector2.ZERO, "t": 0.0, "wait": 0.5 + k * 0.22, "ring": false})
				EventBus.sound_requested.emit("power_prism")
				_go("after")
		"charge_wind":
			dir = signf(cx - pos.x)
			if st > _wind:
				_go("charge")
				vel = Vector2(dir * 1150.0, 0.0)
				EventBus.sound_requested.emit("dash")
		"charge":
			pos += vel * dt
			if (dir > 0.0 and pos.x >= fight.bound_r() - 40.0) or (dir < 0.0 and pos.x <= fight.bound_l() + 40.0):
				vel = Vector2.ZERO
				_go("after")
		"slam_wind":
			pos.x = move_toward(pos.x, hero.x, 260.0 * dt) # tracks the hero a little
			if st > _wind:
				_go("slam")
				vel = Vector2(0, 1500.0)
		"slam":
			pos += vel * dt
			if pos.y >= floor_y - 70.0:
				pos.y = floor_y - 70.0
				fight.shockwave(Vector2(pos.x, floor_y), 1.0)
				fight.shockwave(Vector2(pos.x, floor_y), -1.0)
				fight.shake(12.0)
				EventBus.sound_requested.emit("shockwave")
				_slams -= 1
				if _slams > 0:
					_scribe_tele(fight, Vector2(hero.x, floor_y - 420.0), "slam_wind", 0.35)
				else:
					_go("dazed")
		"dazed":
			# the moment to hit him
			if st > 0.9:
				_scribe_tele(fight, Vector2(cx + randf_range(-250, 250), floor_y - 300.0), "hover_in", 0.0)
		"hover_in", "after":
			if st > (0.35 if state == "after" else 0.0):
				_go("hover")
				cd = randf_range(0.4, 0.8) if fake_dead else randf_range(0.8, 1.4)
		"fake_death":
			# he drops to the floor and lies still: THE END?
			pos.y = move_toward(pos.y, floor_y - 40.0, 900.0 * dt)
			if st > 3.0:
				_go("laugh")
				fight.scribe_laugh(self)
		"laugh":
			pos.y = move_toward(pos.y, floor_y - 160.0, 300.0 * dt)
			if st > 1.6:
				_go("crash")
				vel = Vector2(0, 1800.0)
		"crash":
			pos += vel * dt
			if pos.y >= floor_y - 60.0:
				fake_dead = true
				fight.scribe_break_floor(self)
				floor_y = fight.floor_y
				pos.y = floor_y - 300.0
				_go("hover")
				cd = 1.2


func _update_orbs(dt: float, hc: Vector2, fight: Node) -> void:
	for o in orbs:
		o["t"] = float(o["t"]) + dt
		if bool(o["ring"]):
			o["vel"] = (o["vel"] as Vector2).rotated(0.9 * dt) # a spiral
		elif float(o["t"]) < float(o["wait"]):
			o["pos"] = (o["pos"] as Vector2) + Vector2(0, sin(float(o["t"]) * 8.0) * 0.6)
			continue
		else:
			var want := ((hc - (o["pos"] as Vector2)).normalized()) * 250.0
			o["vel"] = (o["vel"] as Vector2).lerp(want, minf(1.0, 2.2 * dt))
		o["pos"] = (o["pos"] as Vector2) + (o["vel"] as Vector2) * dt
		fight.glows.append([o["pos"], 150.0, 0.7])
	orbs = orbs.filter(func(o: Dictionary) -> bool: return float(o["t"]) < 5.5 and absf((o["pos"] as Vector2).x - hc.x) < 1400.0 and (o["pos"] as Vector2).y < floor_y + 40.0)


## An orb touching this box (the hero's slash, a pogo): it bursts. True if one did.
func pop_orb(box: Rect2) -> bool:
	for o in orbs:
		if box.grow(16.0).has_point(o["pos"]):
			orbs.erase(o)
			return true
	return false


func _orb_hits(hero_box: Rect2) -> bool:
	for o in orbs:
		if hero_box.grow(10.0).has_point(o["pos"]):
			orbs.erase(o)
			return true
	return false


func _draw_scribe_extras(ci: CanvasItem, time: float) -> void:
	for o in orbs:
		var p: Vector2 = (o["pos"] as Vector2) + _o
		ci.draw_texture_rect(ArenaArt.TEX_GLOW, Rect2(p - Vector2(34, 34), Vector2(68, 68)), false, Color(0.75, 0.5, 1.0, 0.8))
		if not Sprites.draw(ci, "ink_orb", p + Vector2(0, 22), 44.0):
			ci.draw_circle(p, 15.0, Color("1b0a2e"))
			ci.draw_arc(p, 15.0, 0.0, TAU, 20, Color(1, 0.9, 0.6), 3.0)
			ci.draw_circle(p + Vector2(-4, -4), 4.0, Color(1, 1, 1, 0.8))
	if state in ["tele_out", "tele_in"]:
		var k := st / 0.22 if state == "tele_out" else 1.0 - st / 0.18
		for i in 8:
			var a := i * TAU / 8.0 + time * 6.0
			ci.draw_circle(pos + _o + Vector2.from_angle(a) * (30.0 + 60.0 * k), 6.0 * (1.0 - k) + 2.0, Color(0.2, 0.1, 0.35, 0.8))


## His painted frame for the state (Antigravity's boss_scribe_* when they exist).
func _scribe_frame() -> String:
	var set_name := "float"
	match state:
		"cast_wind", "ring_wind":
			set_name = "cast"
		"charge_wind", "charge":
			set_name = "charge"
		"slam_wind", "slam", "dazed":
			set_name = "slam"
		"tele_out", "tele_in":
			set_name = "tele"
		"fake_death", "laugh":
			set_name = "fall"
	for n in [2, 1]:
		var k := "boss_scribe_%s_%d" % [set_name, n]
		if Sprites.has(k) and (n == 1 or int(t * 8.0) % 2 == 0):
			return k
	return ""
