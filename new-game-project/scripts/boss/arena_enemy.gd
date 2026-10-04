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
var stagger := 0.0
var dead := false
var t := 0.0
var seed := 0.0
var target := Vector2.ZERO
var phase2 := false
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


## Is this enemy's attack touching the hero right now?
func hits(hero_box: Rect2) -> bool:
	if state == "enter" or dead:
		return false
	var box := hurt_box().grow(-6.0)
	if kind == "lancer" and state == "lunge":
		box = box.merge(Rect2(pos + Vector2(dir * 14.0, -64), Vector2(dir * 95.0, 14)).abs())
	if kind == "brute" and state == "slam" and st < 0.15:
		box = box.merge(Rect2(pos + Vector2(dir * 35.0, -70), Vector2(dir * 105.0, 70)).abs())
	return box.intersects(hero_box)


func take_hit(dmg: float, from_x: float) -> void:
	hp -= dmg
	flash = 1.0
	if kind in ["lancer", "bat", "bomb"]:
		vel.x = signf(pos.x - from_x) * 320.0
		stagger = 0.18
		if kind == "bat":
			state = "hover"
			st = 0.0
	if hp <= 0.0:
		dead = true


## Moves the enemy. `fight` is the BossFight (hero position, shockwaves, projectiles).
func update(dt: float, fight: Node) -> void:
	t += dt
	st += dt
	flash = maxf(0.0, flash - dt * 5.0)
	stagger = maxf(0.0, stagger - dt)
	var hero: Vector2 = fight.hero_pos
	var hc: Vector2 = fight.hero_center()
	if state == "enter":
		if st > 0.55:
			state = "idle" if not flying() else "hover"
			st = 0.0
		if not flying():
			pos.y = minf(FLOOR_Y, pos.y + 900.0 * dt)
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


func _ground(dt: float) -> void:
	pos.x += vel.x * dt
	vel.x = move_toward(vel.x, 0.0, 1400.0 * dt)
	pos.y = FLOOR_Y


func _lancer(dt: float, hero: Vector2, fight: Node) -> void:
	var dx := hero.x - pos.x
	match state:
		"idle":
			if stagger <= 0.0:
				dir = signf(dx) if dx != 0.0 else dir
				vel.x = move_toward(vel.x, dir * 120.0 * fight.enemy_speed(), 600.0 * dt)
			cd -= dt
			if cd <= 0.0 and absf(dx) < 260.0 and stagger <= 0.0:
				state = "windup"
				st = 0.0
				vel.x = 0.0
				EventBus.sound_requested.emit("enemy_windup")
		"windup":
			if st > 0.5 / fight.enemy_speed():
				state = "lunge"
				st = 0.0
				vel.x = dir * 560.0
		"lunge":
			if st > 0.32:
				state = "recover"
				st = 0.0
		"recover":
			if st > 0.6:
				state = "idle"
				st = 0.0
				cd = randf_range(0.8, 1.6)
	_ground(dt)
	pos.x = clampf(pos.x, fight.bound_l(), fight.bound_r())


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
				state = "windup"
				st = 0.0
				EventBus.sound_requested.emit("enemy_windup")
		"windup":
			pos += Vector2(sin(t * 60.0) * 2.0, 0)
			if st > 0.45:
				state = "dive"
				st = 0.0
				vel = (hc - pos).normalized() * 640.0
		"dive":
			pos += vel * dt
			if st > 0.9 or pos.y > FLOOR_Y - 20.0:
				state = "hover"
				st = 0.0
				cd = randf_range(1.2, 2.2)
	pos.x = clampf(pos.x, _fl - 10.0, _fr + 10.0)


func _bomb(dt: float, hc: Vector2, fight: Node) -> void:
	match state:
		"hover":
			vel = vel.lerp((hc - pos).normalized() * 95.0, dt * 2.0)
			pos += vel * dt + Vector2(0, sin(t * 3.0 + seed) * 0.6)
			if pos.distance_to(hc) < 95.0:
				state = "fuse"
				st = 0.0
				EventBus.sound_requested.emit("bomb_fuse")
		"fuse":
			if st > 0.7:
				dead = true
				fight.explode(pos, 100.0)


func _brute(dt: float, hero: Vector2, fight: Node) -> void:
	var dx := hero.x - pos.x
	match state:
		"idle":
			dir = signf(dx) if dx != 0.0 else dir
			vel.x = dir * 60.0 * fight.enemy_speed()
			cd -= dt
			if cd <= 0.0:
				state = "windup" if absf(dx) < 360.0 or randf() < 0.5 else "charge_wind"
				st = 0.0
				vel.x = 0.0
				EventBus.sound_requested.emit("enemy_windup")
		"windup":
			if st > 0.8 / fight.enemy_speed():
				state = "slam"
				st = 0.0
				fight.shockwave(pos + Vector2(dir * 80.0, 0), 1.0)
				fight.shockwave(pos + Vector2(dir * 80.0, 0), -1.0)
		"slam":
			if st > 0.7:
				state = "idle"
				st = 0.0
				cd = randf_range(1.3, 2.0)
		"charge_wind":
			if st > 0.6:
				state = "charge"
				st = 0.0
				vel.x = dir * 420.0
		"charge":
			if st > 1.0 or pos.x <= fight.bound_l() + 10.0 or pos.x >= fight.bound_r() - 10.0:
				state = "idle"
				st = 0.0
				vel.x = 0.0
				cd = randf_range(1.0, 1.8)
				fight.shake(8.0)
	pos.x += vel.x * dt
	pos.x = clampf(pos.x, fight.bound_l(), fight.bound_r())
	pos.y = FLOOR_Y


## The Ink Baron (144p boss): a hulking ringmaster of ink. Cane sweeps send shockwaves, he lobs ink
## from the sky and whistles for his choristers.
func _baron(dt: float, hero: Vector2, fight: Node) -> void:
	var dx := hero.x - pos.x
	var sp: float = fight.enemy_speed()
	match state:
		"idle":
			dir = signf(dx) if dx != 0.0 else dir
			vel.x = dir * 80.0 * sp
			cd -= dt
			if cd <= 0.0:
				var picks := ["sweep", "sweep", "lob", "summon"] if hp < max_hp * 0.6 else ["sweep", "lob", "sweep"]
				state = picks[randi() % picks.size()]
				st = 0.0
				vel.x = 0.0
				EventBus.sound_requested.emit("enemy_windup")
		"sweep":
			if st > 0.75 / sp and st - dt <= 0.75 / sp:
				fight.shockwave(pos + Vector2(dir * 60.0, 0), 1.0)
				fight.shockwave(pos + Vector2(dir * 60.0, 0), -1.0)
				fight.shake(10.0)
			if st > 1.4:
				_baron_rest()
		"lob":
			if st > 0.5 and st - dt <= 0.5:
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
	state = "idle"
	st = 0.0
	cd = randf_range(1.0, 1.8)


func _narrator(dt: float, hero: Vector2, hc: Vector2, fight: Node) -> void:
	phase2 = hp < max_hp * 0.5
	var sp: float = fight.enemy_speed() * (1.25 if phase2 else 1.0)
	match state:
		"hover":
			target = Vector2(fight.center_x() + sin(t * 0.6) * 380.0, 230.0 + sin(t * 1.1) * 30.0)
			pos = pos.move_toward(target, 220.0 * sp * dt)
			cd -= dt * sp
			if cd <= 0.0:
				var picks := ["dash", "rain", "slam", "summon"]
				state = picks[randi() % picks.size()]
				st = 0.0
				target = hc
				EventBus.sound_requested.emit("narrator_attack")
				if state == "rain":
					fight.ink_rain(6 if not phase2 else 9)
				elif state == "summon":
					fight.spawn("bat", pos + Vector2(-60, 0))
					fight.spawn("bat", pos + Vector2(60, 0))
					if phase2:
						fight.spawn("bomb", pos + Vector2(0, 40))
		"dash":
			# telegraph a line at the hero's height, then sweep across the stage
			if st < 0.75 / sp:
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
			if st < 0.6 / sp:
				pos = pos.move_toward(Vector2(target.x, 200.0), 700.0 * dt)
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
				state = "hover"
				st = 0.0
				cd = randf_range(0.6, 1.2)


func _rest() -> void:
	state = "rest"
	st = 0.0


# --- drawing ----------------------------------------------------------------------------

func draw(ci: CanvasItem, time: float, origin := Vector2.ZERO) -> void:
	_o = origin
	var a := 1.0
	if state == "enter":
		a = clampf(st / 0.4, 0.0, 1.0)
	var white := flash
	if _draw_sprite(ci, a, time):
		if state in ["windup", "charge_wind", "fuse"]:
			var c2 := center() + Vector2(0, -float(STATS[kind]["h"]) * 0.7)
			ComicArt.shout(ci, "!", c2 + _o, 40, Color("ffd23f"), 8)
			ci.draw_set_transform(_o, 0.0, Vector2.ONE)
		return
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
	if state in ["windup", "charge_wind", "fuse"]:
		var c := center() + Vector2(0, -float(STATS[kind]["h"]) * 0.7)
		ComicArt.shout(ci, "!", c + _o, 40, Color("ffd23f"), 8)
		ci.draw_set_transform(_o, 0.0, Vector2.ONE)


const SPRITE_KEYS := {"lancer": "enemy_lancer", "bat": "enemy_bat", "brute": "enemy_brute", "baron": "enemy_baron", "narrator": "narrator_boss"}
const SPRITE_H := {"lancer": 120.0, "bat": 64.0, "brute": 190.0, "baron": 230.0, "narrator": 260.0}


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
			if state == "windup" or state == "charge_wind":
				rot = -0.12 * dir
			elif state in ["lunge", "slam", "charge", "sweep"]:
				rot = 0.12 * dir
	var tint := Color(1, 1.0 - flash * 0.6, 1.0 - flash * 0.6, a)
	Sprites.draw(ci, key, feet, h, face, tint, squash, rot)
	ci.draw_set_transform(_o, 0.0, Vector2.ONE)
	return true


func _col(c: Color, white: float, a: float) -> Color:
	var r := c.lerp(Color.WHITE, white)
	r.a = a
	return r


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
