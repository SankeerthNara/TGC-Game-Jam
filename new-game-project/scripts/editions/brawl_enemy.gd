class_name BrawlEnemy
extends RefCounted
## An enemy of the 720p brawler (the pixel edition).
##   thug:    a TV-headed street goon. Jabs (yellow flash: dodge it) and heavy swings (RED eyes:
##            press V to counter).
##   gunner:  stays back, aims a laser sight that turns RED before the shot (counter or dodge).
##   twin_a / twin_b: the Static Twins, the boss pair on the train roof. They take turns: a dash
##            (red), an eye beam (jump or roll), a heavy swing (red), a channel-hop (they vanish into
##            static and reappear behind the hero for a heavy swing), a leap and dive kick (yellow:
##            dodge the marked spot), static orbs that home in (punch them). Every few turns both
##            hop to the edges and dash across at once (CROSSFIRE: roll or counter). A run of hits
##            staggers a twin. The last one standing absorbs the other's signal: faster, chains moves.

const INK := Color("0d0b12")
const GROUND := 630.0
const STATS := {
	"thug": {"hp": 6.0, "speed": 120.0},
	"gunner": {"hp": 4.0, "speed": 80.0},
	"twin_a": {"hp": 55.0, "speed": 170.0},
	"twin_b": {"hp": 55.0, "speed": 170.0},
}

var kind := "thug"
var pos := Vector2.ZERO
var vel := Vector2.ZERO
var dir := -1.0
var hp := 1.0
var max_hp := 1.0
var state := "enter"
var st := 0.0
var cd := 1.0
var flash := 0.0
var stun := 0.0
var dead := false
var dying_t := -1.0 ## >= 0 while the knocked-out body tumbles away
var _dvel := Vector2.ZERO
var t := 0.0
var attack := "" ## "jab" | "heavy" | "shot" | "beam" | "dash"
var hit_done := false
var active := true ## the twins take turns
var seed := 0.0
var berserk := false ## the last twin standing: faster, chains moves
var air := false ## leaping / diving (not snapped to the roof)
var just_staggered := false ## the game shows "STAGGERED!" and clears this
var _hit_taken := 0.0 ## damage since the last stagger
var _hop_to := 0.0 ## where a channel-hop reappears / where a dive lands


func _init(k: String, p: Vector2) -> void:
	kind = k
	pos = p
	hp = float(STATS[k]["hp"])
	max_hp = hp
	seed = randf() * 10.0
	cd = randf_range(0.6, 1.6)


func twin() -> bool:
	return kind.begins_with("twin")


func body() -> Rect2:
	var w := 46.0 if not twin() else 56.0
	var h := 120.0 if not twin() else 150.0
	return Rect2(pos - Vector2(w * 0.5, h), Vector2(w, h))


func center() -> Vector2:
	return pos + Vector2(0, -body().size.y * 0.55)


## A channel-hop: vanish into static, reappear at x, then wind up the attack.
func hop_to(x: float, atk: String) -> void:
	state = "hop_out"
	st = 0.0
	attack = atk
	_hop_to = x
	air = false
	vel = Vector2.ZERO
	EventBus.sound_requested.emit("static")


## The red moment: the hero can counter now.
func counterable() -> bool:
	return state == "windup" and attack in ["heavy", "shot", "dash", "xdash"] and st > 0.15


func take_hit(dmg: float, from_x: float, knock := 260.0) -> void:
	if dead or state in ["hop_out", "hop_in"]:
		return # mid channel-hop: the blow passes through static
	hp -= dmg
	flash = 1.0
	if not twin():
		vel.x = signf(pos.x - from_x) * knock
		stun = 0.35
		if state == "windup":
			state = "idle"
			st = 0.0
			cd = 0.8
	else:
		stun = 0.12
		_hit_taken += dmg
		if _hit_taken >= max_hp * 0.15 and not air and state != "stagger":
			_hit_taken = 0.0
			state = "stagger"
			st = 0.0
			vel = Vector2.ZERO
			just_staggered = true
	if hp <= 0.0:
		dead = true


func update(dt: float, g: Node) -> void:
	t += dt
	st += dt
	flash = maxf(0.0, flash - dt * 5.0)
	stun = maxf(0.0, stun - dt)
	var hx: float = g.hero_pos.x
	var dx := hx - pos.x
	if state == "enter":
		pos.x += dir * 160.0 * dt
		if st > 0.6:
			state = "idle"
			st = 0.0
		return
	if stun > 0.0:
		pos.x += vel.x * dt
		vel.x = move_toward(vel.x, 0.0, 900.0 * dt)
		return
	var bk := 1.3 if berserk else 1.0
	match state:
		"idle":
			dir = signf(dx) if absf(dx) > 4.0 else dir
			var want := 90.0 if kind == "thug" else (360.0 if kind == "gunner" else 120.0)
			if twin() and not active:
				want = 420.0
			var speed: float = float(STATS[kind]["speed"]) * g.enemy_speed()
			if absf(dx) > want + 20.0:
				pos.x += dir * speed * dt
			elif absf(dx) < want - 40.0 and (kind == "gunner" or (twin() and not active)):
				pos.x -= dir * speed * 0.8 * dt
			cd -= dt * g.enemy_speed()
			if cd <= 0.0 and (not twin() or active) and g.may_attack(self):
				_choose(absf(dx), hx)
		"hop_out":
			if st > 0.25:
				pos.x = clampf(_hop_to, g.lock_left + 70.0, g.lock_right - 70.0)
				dir = signf(hx - pos.x) if absf(hx - pos.x) > 4.0 else dir
				if attack == "xdash":
					dir = signf((g.lock_left + g.lock_right) * 0.5 - pos.x)
				state = "hop_in"
				st = 0.0
		"hop_in":
			if st > 0.2:
				state = "windup"
				st = 0.0
				EventBus.sound_requested.emit("counter_flash")
		"leap":
			pos += vel * dt
			vel.y += 2600.0 * dt
			if vel.y > -60.0:
				state = "dive_wind"
				st = 0.0
				vel = Vector2.ZERO
				_hop_to = hx
		"dive_wind":
			# hangs in the air, the landing spot marked on the roof (yellow: get out of there)
			_hop_to = move_toward(_hop_to, hx, 220.0 * dt)
			dir = signf(_hop_to - pos.x) if absf(_hop_to - pos.x) > 4.0 else dir
			if st > 0.42 / bk:
				state = "dive"
				st = 0.0
				vel = (Vector2(_hop_to, GROUND) - pos).normalized() * 1700.0
				EventBus.sound_requested.emit("dash")
		"dive":
			pos += vel * dt
			if body().intersects(g.hero_box()):
				g.hurt_hero(self, 2)
			if pos.y >= GROUND:
				pos.y = GROUND
				air = false
				vel = Vector2.ZERO
				g.twin_landed(self)
				state = "recover"
				st = 0.0
		"stagger":
			# dazed: the moment to punish
			if st > 1.3:
				state = "idle"
				st = 0.0
				cd = 0.3
				g.twin_turn_done(self)
		"windup":
			var wind := {"jab": 0.38, "heavy": 0.7, "shot": 0.9, "beam": 0.8, "dash": 0.65, "xdash": 0.85, "orbs": 0.6}
			if st > float(wind[attack]) / g.enemy_speed() / bk:
				state = "strike"
				st = 0.0
				hit_done = false
				if attack == "dash":
					vel.x = dir * 900.0
				if attack == "xdash":
					vel.x = dir * 1300.0
				if attack == "orbs":
					g.enemy_orbs(self, 5 if berserk else 3)
				if attack == "shot":
					g.enemy_shot(self)
				if attack == "beam":
					g.enemy_beam(self)
				EventBus.sound_requested.emit("punch_heavy" if attack in ["heavy", "dash"] else "punch")
		"strike":
			if attack == "dash":
				pos.x += vel.x * dt
				vel.x = move_toward(vel.x, 0.0, 1500.0 * dt)
			if attack == "xdash":
				pos.x += vel.x * dt # all the way across the roof
				if (dir > 0.0 and pos.x >= g.lock_right - 60.0) or (dir < 0.0 and pos.x <= g.lock_left + 60.0):
					st = 9.0
			if not hit_done and attack in ["jab", "heavy", "dash", "xdash"]:
				var reach := 70.0 if attack == "jab" else (95.0 if attack == "heavy" else 60.0)
				var box := Rect2(Vector2(pos.x + (0.0 if dir > 0.0 else -reach), pos.y - 110.0), Vector2(reach, 80.0))
				if box.intersects(g.hero_box()):
					hit_done = true
					g.hurt_hero(self, 1 if attack == "jab" else 2)
			if st > (0.25 if attack not in ["dash", "xdash"] else (0.5 if attack == "dash" else 1.6)):
				state = "recover"
				st = 0.0
		"recover":
			if st > (0.3 if berserk else 0.5):
				state = "idle"
				st = 0.0
				cd = randf_range(0.9, 1.8) if not twin() else (randf_range(0.15, 0.45) if berserk else randf_range(0.5, 1.0))
				if twin():
					g.twin_turn_done(self)
	pos.x = clampf(pos.x, g.lock_left + 20.0, g.lock_right - 20.0)
	if not state in ["leap", "dive_wind", "dive"]:
		pos.y = GROUND


func _choose(dist: float, hx: float) -> void:
	match kind:
		"thug":
			if dist > 140.0:
				return
			attack = "heavy" if randf() < 0.45 else "jab"
		"gunner":
			attack = "shot"
		_:
			var picks := ["dash", "beam", "hop", "dive", "orbs", "heavy"] if dist > 160.0 else ["heavy", "dash", "jab", "hop", "dive"]
			attack = picks[randi() % picks.size()]
			if attack == "hop":
				var side := signf(hx - pos.x) if hx != pos.x else 1.0
				hop_to(hx + side * 120.0, "heavy") # reappears behind the hero
				return
			if attack == "dive":
				state = "leap"
				st = 0.0
				air = true
				vel = Vector2(signf(hx - pos.x) * 140.0, -1250.0)
				EventBus.sound_requested.emit("dash")
				return
	state = "windup"
	st = 0.0
	if attack in ["heavy", "shot", "dash"]:
		EventBus.sound_requested.emit("counter_flash")


# --- drawing (in pixel-art spirit: chunky shapes, few colours) -----------------------------------

## Knocked out: the body flies back, spins and fades (instead of vanishing).
func start_dying(from_x: float) -> void:
	dying_t = 0.0
	_dvel = Vector2(signf(pos.x - from_x) * 520.0 if pos.x != from_x else -dir * 520.0, -620.0)


func update_dying(dt: float) -> bool:
	dying_t += dt
	pos += _dvel * dt
	_dvel.y += 1900.0 * dt
	if pos.y > GROUND:
		pos.y = GROUND
		_dvel = Vector2(_dvel.x * 0.4, -_dvel.y * 0.25)
	return dying_t < 0.9


func draw(ci: CanvasItem, cam: float) -> void:
	var p := pos - Vector2(cam, 0)
	if dying_t >= 0.0:
		var a := clampf(1.0 - (dying_t - 0.4) / 0.5, 0.0, 1.0)
		var spin := -signf(_dvel.x) * minf(dying_t * 7.0, 1.4)
		var dkey := "px_thug" if kind == "thug" else ("px_gunner" if kind == "gunner" else "px_" + kind)
		if Sprites.draw(ci, dkey, p, 170.0 if not twin() else 230.0, dir, Color(1, 0.85, 0.85, a), 1.0, spin):
			return
		ci.draw_set_transform(p, spin, Vector2(dir, 1.0))
		ci.draw_rect(Rect2(Vector2(-22, -112), Vector2(44, 112)), Color(0.2, 0.2, 0.25, a))
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	if state in ["hop_out", "hop_in"]:
		var hk := st / 0.25 if state == "hop_out" else 1.0 - st / 0.2
		for i in 9:
			var y := p.y - randf_range(0, 230)
			var w := randf_range(30, 110)
			ci.draw_rect(Rect2(Vector2(p.x - w * 0.5 + randf_range(-20, 20), y), Vector2(w, randf_range(3, 9))), Color(0.3, 1.0, 1.0, 0.55) if i % 2 == 0 else Color(1.0, 0.25, 0.6, 0.5))
		if randf() < hk:
			return
	if state == "dive_wind" or state == "dive":
		var mx := _hop_to - cam
		var pulse := 0.5 + 0.5 * sin(t * 30.0)
		ci.draw_texture_rect(ArenaArt.TEX_GLOW, Rect2(Vector2(mx - 90, GROUND - 40), Vector2(180, 70)), false, Color(1, 0.82, 0.25, 0.4 + 0.3 * pulse))
		ci.draw_line(Vector2(mx - 60, GROUND - 2), Vector2(mx + 60, GROUND - 2), Color("ffd23f"), 4.0)
	if berserk:
		ci.draw_texture_rect(ArenaArt.TEX_GLOW, Rect2(p + Vector2(-110, -260), Vector2(220, 270)), false, Color(1, 0.2, 0.5, 0.35 + 0.15 * sin(t * 9.0)))
	if state == "stagger":
		for i in 3:
			var a := t * 5.0 + i * TAU / 3.0
			ci.draw_circle(p + Vector2(cos(a) * 34.0, -250.0 + sin(a) * 10.0), 6.0, Color("ffd23f"))
	var key := "px_thug" if kind == "thug" else ("px_gunner" if kind == "gunner" else "px_" + kind)
	if Sprites.has(key):
		var h := 170.0 if not twin() else 230.0
		var lean := 0.0
		if state == "windup":
			lean = -0.12 * dir
		elif state == "strike" or state == "dive":
			lean = 0.15 * dir
		elif state == "stagger":
			lean = -0.3 * dir + sin(t * 6.0) * 0.08
		var tint := Color(1, 1.0 - flash * 0.6, 1.0 - flash * 0.6)
		Sprites.draw(ci, key, p, h, dir, tint, 1.0 + sin(t * 8.0) * 0.02, lean)
		# the eyes still glow red / yellow on top of the sprite: that is the counter cue
		var red := counterable() or (state == "strike" and attack in ["heavy", "dash", "shot", "xdash"])
		var yellow := (state == "windup" and attack in ["jab", "orbs"]) or state == "dive_wind"
		if red or yellow:
			var glow := Color("ff2a3a") if red else Color("ffd23f")
			var eye := p + Vector2(dir * 8.0, -h * 0.82)
			ci.draw_circle(eye, 16.0, Color(glow.r, glow.g, glow.b, 0.35))
			ci.draw_circle(eye, 6.0, glow)
		if kind == "gunner" and state == "windup":
			var from := p + Vector2(dir * 40.0, -h * 0.62)
			ci.draw_line(from, from + Vector2(dir * 1400.0, 0), Color(1, 0.1, 0.15, 0.85) if counterable() else Color(1, 0.3, 0.3, 0.35), 2.0)
		return
	var white := flash
	var lean := 0.0
	if state == "windup":
		lean = -0.25
	elif state == "strike":
		lean = 0.35
	ci.draw_set_transform(p, 0.0, Vector2(dir, 1.0))
	var big := 1.25 if twin() else 1.0
	var coat := Color("2b2f3a") if kind == "thug" else (Color("3d2b3a") if kind == "gunner" else Color("1d2433"))
	if twin():
		coat = Color("5a1a2a") if kind == "twin_a" else Color("1a3a5a")
	coat = coat.lerp(Color.WHITE, white)
	# legs
	var stride := sin(t * 10.0) * 10.0 if state == "idle" else 0.0
	ci.draw_rect(Rect2(Vector2(-14 + stride, -50) * big, Vector2(11, 50) * big), INK)
	ci.draw_rect(Rect2(Vector2(4 - stride, -50) * big, Vector2(11, 50) * big), INK)
	# torso (a long coat)
	var tl := Vector2(-20 + lean * 20.0, -112) * big
	ci.draw_colored_polygon(PackedVector2Array([tl, tl + Vector2(42, 0) * big, Vector2(24, -40) * big, Vector2(-24, -40) * big]), coat)
	ci.draw_polyline(PackedVector2Array([tl, tl + Vector2(42, 0) * big, Vector2(24, -40) * big, Vector2(-24, -40) * big, tl]), INK, 3.0)
	# arm
	var sh := tl + Vector2(30, 6) * big
	var hand := sh + Vector2(10, 36) * big
	if state == "windup":
		hand = sh + Vector2(-26, -18) * big
	elif state == "strike":
		hand = sh + Vector2(52, 4) * big
	ci.draw_line(sh, hand, INK, 11.0 * big)
	ci.draw_line(sh, hand, coat.lightened(0.15), 6.0 * big)
	if kind == "gunner":
		ci.draw_rect(Rect2(hand + Vector2(0, -5), Vector2(26, 8)), Color("6c757d"))
	# the TV head
	var head := tl + Vector2(21, -24) * big
	var hr := Rect2(head - Vector2(20, 18) * big, Vector2(40, 32) * big)
	ci.draw_rect(hr.grow(3.0), INK)
	ci.draw_rect(hr, Color("3a3f4a").lerp(Color.WHITE, white))
	var screen := hr.grow(-5.0 * big)
	var red := counterable() or (state == "strike" and attack in ["heavy", "dash", "shot"])
	var yellow := state == "windup" and attack == "jab"
	var glow := Color("ff2a3a") if red else (Color("ffd23f") if yellow else Color("3ef0ff"))
	ci.draw_rect(screen, Color(glow.r * 0.25, glow.g * 0.25, glow.b * 0.25))
	# two pixel eyes on the screen
	for k in 2:
		ci.draw_rect(Rect2(screen.position + Vector2(6 + k * 14, 6) * big, Vector2(6, 6) * big), glow)
	if red and int(t * 16.0) % 2 == 0:
		ci.draw_rect(screen.grow(8.0), Color(1, 0.1, 0.15, 0.25))
	ci.draw_line(hr.position + Vector2(8, 0), hr.position + Vector2(0, -14) * big, INK, 2.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# the gunner's laser sight
	if kind == "gunner" and state == "windup":
		var from := p + Vector2(dir * 60.0, -84.0)
		var col := Color(1, 0.1, 0.15, 0.85) if counterable() else Color(1, 0.3, 0.3, 0.35)
		ci.draw_line(from, from + Vector2(dir * 1400.0, 0), col, 2.0)
