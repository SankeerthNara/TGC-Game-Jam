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
var perch := Rect2() ## the ledge (empty: the stage floor)
var _perch_t := 0.0
var _wind := 0.0 ## length of the current wind-up (0: none)
var _open_t := 1.0 ## how long the current stagger lasts
var _quiet := 0.0 ## time since he was last hit or parried (posture recovers after a while)
## The states in which a guarding enemy blocks blows from the front.
const GUARDS := {"lancer": ["idle", "windup", "rewind"], "baron": ["idle", "jab_wind", "rewind"], "narrator": ["hover", "quill_wind", "rewind"]}
## How much one perfect parry fills the posture.
const PARRY_FILL := {"lancer": 0.34, "bat": 1.0, "brute": 0.26, "baron": 0.13, "narrator": 0.1}
var guards := true ## the fight turns guarding off in the 144p edition
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
	return kind in ["bat", "bomb", "narrator"]


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
	if state == "enter" or dead or broken > 0.0 or state in ["stagger", "stunned"]:
		return false
	var box := hurt_box().grow(-6.0)
	match kind:
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
			if not state in ["quill", "dash", "slam"]:
				return false
			if state == "dash" and st < _wind:
				return false
	return box.intersects(hero_box)


func boss() -> bool:
	return kind in ["baron", "narrator"]


## The attack hitting now can be parried (gold).
func parryable() -> bool:
	match kind:
		"lancer":
			return state == "lunge"
		"bat":
			return state == "dive"
		"brute":
			return state == "punch"
		"baron":
			return state == "jab"
		"narrator":
			return state == "quill"
	return false


## The attack being wound up: "gold" (parry it), "red" (get away) or "" (none).
func tele() -> String:
	if dead or broken > 0.0:
		return ""
	match kind:
		"lancer", "bat":
			return "gold" if state in ["windup", "rewind"] else ""
		"brute":
			if state == "punch_wind":
				return "gold"
			return "red" if state in ["windup", "charge_wind"] else ""
		"baron":
			if state in ["jab_wind", "rewind"]:
				return "gold"
			return "red" if state in ["sweep", "lob"] and st < _wind else ""
		"narrator":
			if state in ["quill_wind", "rewind"]:
				return "gold"
			return "red" if state in ["dash", "slam"] and st < _wind else ""
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
	flash = 1.0
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
	recoil = maxf(0.0, recoil - dt * 6.0)
	stagger = maxf(0.0, stagger - dt)
	_quiet += dt
	if _quiet > 2.0 and broken <= 0.0:
		posture = maxf(0.0, posture - dt * (0.07 if boss() else 0.15))
	var hero: Vector2 = fight.hero_pos
	var hc: Vector2 = fight.hero_center()
	if state == "enter":
		var heavy := kind in ["brute", "baron"]
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
		if kind == "bat":
			vel.y = minf(vel.y + 1800.0 * dt, 700.0)
			pos.y = minf(pos.y + vel.y * dt, FLOOR_Y - 24.0)
			pos.x += vel.x * dt
			vel.x = move_toward(vel.x, 0.0, 600.0 * dt)
		elif kind == "narrator":
			pos = pos.move_toward(Vector2(pos.x + recoil_dir * 40.0 * dt, 470.0), 260.0 * dt)
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
			target.y = clampf(target.y, 140.0, 450.0)
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
			if st > 0.9 or pos.y > FLOOR_Y - 20.0:
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
	pos.y = FLOOR_Y


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
func _narrator(dt: float, hero: Vector2, hc: Vector2, fight: Node) -> void:
	phase2 = hp < max_hp * 0.5
	var sp: float = fight.enemy_speed() * (1.25 if phase2 else 1.0)
	dir = signf(hero.x - pos.x) if hero.x != pos.x else dir
	match state:
		"hover":
			target = Vector2(fight.center_x() + sin(t * 0.6) * 360.0, 320.0 + sin(t * 1.1) * 30.0)
			pos = pos.move_toward(target, 220.0 * sp * dt)
			cd -= dt * sp
			if cd <= 0.0:
				var picks := ["quill", "quill", "dash", "slam", "rain", "summon"]
				var pick: String = picks[randi() % picks.size()]
				target = hc
				EventBus.sound_requested.emit("narrator_attack")
				match pick:
					"quill":
						chain = 2 if phase2 else 1
						_wind_up("quill_wind", 0.7 / sp)
					"dash":
						_wind_up("dash", 0.75 / sp)
					"slam":
						_wind_up("slam", 0.6 / sp)
					"rain":
						_go("rain")
						fight.ink_rain(6 if not phase2 else 9)
					"summon":
						_go("summon")
						fight.spawn("bat", pos + Vector2(-60, 0))
						fight.spawn("bat", pos + Vector2(60, 0))
						if phase2:
							fight.spawn("bomb", pos + Vector2(0, 40))
		"quill_wind", "rewind":
			# he glides in beside the hero, quill raised, and flashes gold before he strikes
			var side := signf(pos.x - hero.x) if pos.x != hero.x else 1.0
			pos = pos.move_toward(Vector2(hero.x + side * 150.0, clampf(hc.y - 30.0, 300.0, 540.0)), 520.0 * dt)
			if st > _wind:
				_go("quill")
				vel = (hc - pos).normalized() * 720.0
		"quill":
			pos += vel * dt
			if st > 0.24:
				if chain > 0:
					chain -= 1
					_wind_up("rewind", 0.5 / sp)
				else:
					_rest()
		"dash":
			# telegraph a line at the hero's height, then sweep across the stage
			if st < _wind:
				var cx: float = fight.center_x()
				pos = pos.move_toward(Vector2(cx - 700.0 if hero.x > cx else cx + 700.0, clampf(target.y, 300.0, 560.0)), 900.0 * dt)
			else:
				var cx2: float = fight.center_x()
				var goal_x := cx2 + 700.0 if target.x > cx2 or pos.x < cx2 else cx2 - 700.0
				pos.x = move_toward(pos.x, goal_x, 1300.0 * dt)
				if absf(pos.x - goal_x) < 1.0 or st > 2.2:
					pos.x = clampf(pos.x, fight.bound_l(), fight.bound_r())
					_rest()
		"slam":
			if st < _wind:
				pos = pos.move_toward(Vector2(target.x, 280.0), 700.0 * dt)
			else:
				pos.y = move_toward(pos.y, FLOOR_Y - 70.0, 1500.0 * dt)
				if pos.y >= FLOOR_Y - 71.0 and state == "slam":
					fight.shockwave(Vector2(pos.x, FLOOR_Y), 1.0)
					fight.shockwave(Vector2(pos.x, FLOOR_Y), -1.0)
					fight.shake(12.0)
					_rest()
		"rain", "summon":
			if st > 1.0:
				_rest()
		"rest":
			# tired and low: the moment to strike
			pos = pos.move_toward(Vector2(pos.x, 470.0), 200.0 * dt)
			if st > 1.3 / sp:
				_go("hover")
				cd = randf_range(0.6, 1.2)


func _rest() -> void:
	_go("rest")


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


const SPRITE_KEYS := {"lancer": "enemy_lancer", "bat": "enemy_bat", "brute": "enemy_brute", "baron": "enemy_baron", "narrator": "narrator_boss"}
const SPRITE_H := {"lancer": 160.0, "bat": 96.0, "brute": 220.0, "baron": 255.0, "narrator": 260.0}


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
		"bat":
			feet = pos + _o + Vector2(0, h * 0.5)
			face = 1.0 if vel.x >= 0.0 else -1.0
			squash = 1.0 + sin(t * 24.0) * 0.08
		"narrator":
			feet = pos + _o + Vector2(0, 110)
			face = 1.0 if pos.x < 640.0 else -1.0
			rot = sin(time * 1.5) * 0.04
		_:
			squash = 1.0 + sin(t * 6.0) * 0.015
			if tele() != "":
				rot = -0.12 * dir
			elif state in ["lunge", "slam", "charge", "sweep", "jab", "punch"]:
				rot = 0.12 * dir
	var tint := Color(1, 1.0 - flash * 0.6, 1.0 - flash * 0.6, a)
	var fk := flash_k()
	if fk > 0.0:
		var tcol := GOLD_FLASH if tele() == "gold" else RED_FLASH
		tint = Color(lerpf(tint.r, tcol.r * 1.4, 0.55 * fk), lerpf(tint.g, tcol.g * 1.4, 0.55 * fk), lerpf(tint.b, tcol.b * 1.4, 0.55 * fk), a)
	if broken > 0.0:
		tint = tint.darkened(0.25)
		rot += 0.12 * dir # sagging, off balance
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
