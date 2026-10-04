class_name BrawlEnemy
extends RefCounted
## An enemy of the 720p brawler (the pixel edition).
##   thug:    a TV-headed street goon. Jabs (yellow flash: dodge it) and heavy swings (RED eyes:
##            press V to counter).
##   gunner:  stays back, aims a laser sight that turns RED before the shot (counter or dodge).
##   twin_a / twin_b: the Static Twins, the boss pair on the train roof.

const INK := Color("0d0b12")
const GROUND := 630.0
const STATS := {
	"thug": {"hp": 6.0, "speed": 120.0},
	"gunner": {"hp": 4.0, "speed": 80.0},
	"twin_a": {"hp": 26.0, "speed": 170.0},
	"twin_b": {"hp": 26.0, "speed": 170.0},
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
var t := 0.0
var attack := "" ## "jab" | "heavy" | "shot" | "beam" | "dash"
var hit_done := false
var active := true ## the twins take turns
var seed := 0.0


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


## The red moment: the hero can counter now.
func counterable() -> bool:
	return state == "windup" and attack in ["heavy", "shot", "dash"] and st > 0.15


func take_hit(dmg: float, from_x: float, knock := 260.0) -> void:
	if dead:
		return
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
				_choose(absf(dx))
		"windup":
			var wind := {"jab": 0.38, "heavy": 0.7, "shot": 0.9, "beam": 0.8, "dash": 0.65}
			if st > float(wind[attack]) / g.enemy_speed():
				state = "strike"
				st = 0.0
				hit_done = false
				if attack == "dash":
					vel.x = dir * 900.0
				if attack == "shot":
					g.enemy_shot(self)
				if attack == "beam":
					g.enemy_beam(self)
				EventBus.sound_requested.emit("punch_heavy" if attack in ["heavy", "dash"] else "punch")
		"strike":
			if attack == "dash":
				pos.x += vel.x * dt
				vel.x = move_toward(vel.x, 0.0, 1500.0 * dt)
			if not hit_done and attack in ["jab", "heavy", "dash"]:
				var reach := 70.0 if attack == "jab" else (95.0 if attack == "heavy" else 60.0)
				var box := Rect2(Vector2(pos.x + (0.0 if dir > 0.0 else -reach), pos.y - 110.0), Vector2(reach, 80.0))
				if box.intersects(g.hero_box()):
					hit_done = true
					g.hurt_hero(self, 1 if attack == "jab" else 2)
			if st > (0.25 if attack != "dash" else 0.5):
				state = "recover"
				st = 0.0
		"recover":
			if st > 0.5:
				state = "idle"
				st = 0.0
				cd = randf_range(0.9, 1.8) if not twin() else randf_range(0.5, 1.0)
				if twin():
					g.twin_turn_done(self)
	pos.x = clampf(pos.x, g.lock_left + 20.0, g.lock_right - 20.0)
	pos.y = GROUND


func _choose(dist: float) -> void:
	match kind:
		"thug":
			if dist > 140.0:
				return
			attack = "heavy" if randf() < 0.45 else "jab"
		"gunner":
			attack = "shot"
		_:
			var picks := ["dash", "beam", "heavy"] if dist > 160.0 else ["heavy", "dash", "jab"]
			attack = picks[randi() % picks.size()]
	state = "windup"
	st = 0.0
	if attack in ["heavy", "shot", "dash"]:
		EventBus.sound_requested.emit("counter_flash")


# --- drawing (in pixel-art spirit: chunky shapes, few colours) -----------------------------------

func draw(ci: CanvasItem, cam: float) -> void:
	var p := pos - Vector2(cam, 0)
	var key := "px_thug" if kind == "thug" else ("px_gunner" if kind == "gunner" else "px_" + kind)
	if Sprites.has(key):
		var h := 140.0 if not twin() else 190.0
		var lean := 0.0
		if state == "windup":
			lean = -0.12 * dir
		elif state == "strike":
			lean = 0.15 * dir
		var tint := Color(1, 1.0 - flash * 0.6, 1.0 - flash * 0.6)
		Sprites.draw(ci, key, p, h, dir, tint, 1.0 + sin(t * 8.0) * 0.02, lean)
		# the eyes still glow red / yellow on top of the sprite: that is the counter cue
		var red := counterable() or (state == "strike" and attack in ["heavy", "dash", "shot"])
		var yellow := state == "windup" and attack == "jab"
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
