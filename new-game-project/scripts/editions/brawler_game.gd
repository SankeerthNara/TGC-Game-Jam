class_name BrawlerGame
extends Control
## The 720p "pixel edition": a side-scrolling brawler in the spirit of REPLACED.
## stage "street": three locked fights along a neon street at night.
## stage "train":  the Static Twins on the roof of a speeding train in the rain (boss).
## Controls: arrows move, Z jump, X attack (3-hit combo), C dodge roll, V counter (when an enemy's
## eyes or laser sight turn RED). Hearts at the top left; losing them all restarts the current fight.
## finished("win").

signal finished(result: String)

const FONT_SHOUT := preload("res://assets/fonts/Bangers-Regular.ttf")
const FONT_BODY := preload("res://assets/fonts/ComicNeue-Bold.ttf")
const TEX_GLOW := preload("res://assets/art/radial_glow.png")
const ART := "res://assets/editions/720/"
const GROUND := 630.0
const GRAV := 2600.0
const RUN := 340.0
const MAX_HP := 8
const HERO_SCALE := 1.55
## Street fights: zone start x, then spawns [kind, side ("L"/"R"), delay].
const STREET := [
	[0.0, [["thug", "R", 0.0], ["thug", "R", 0.8], ["thug", "L", 2.5]]],
	[1280.0, [["thug", "R", 0.0], ["gunner", "R", 0.6], ["thug", "L", 1.0], ["thug", "R", 4.0], ["thug", "L", 5.0]]],
	[2560.0, [["gunner", "R", 0.0], ["thug", "R", 0.4], ["thug", "L", 0.8], ["gunner", "L", 3.0], ["thug", "R", 4.0], ["thug", "R", 6.0]]],
]

var stage := "street"
var hero_pos := Vector2(200, GROUND)
var lock_left := 0.0
var lock_right := 1280.0

var _vel := Vector2.ZERO
var _ground := true
var _face := 1.0
var _hp := MAX_HP
var _inv := 0.0
var _combo := 0
var _combo_t := 0.0
var _atk_t := 0.0
var _atk_hit := {}
var _roll_t := 0.0
var _roll_cd := 0.0
var _counter_t := 0.0
var _counter_cd := 0.0
var _counters := 0
var _slow := 0.0
var _freeze := 0.0
var _shake := 0.0
var _flash := 0.0
var _t := 0.0
var _cam := 0.0
var _zone := -1
var _zone_live := false
var _pending: Array[Dictionary] = []
var _enemies: Array[BrawlEnemy] = []
var _shots: Array[Dictionary] = []
var _beams: Array[Dictionary] = []
var _fx: Array[Dictionary] = []
var _rain: Array[Vector3] = []
var _phase := "intro" ## intro | play | dead | won
var _pt := 0.0
var _go_hint := 0.0
var _tex := {}
var _twin_turn := 0
var _dying: Array[BrawlEnemy] = []
var _atk_buf := 0.0 ## X pressed during a swing: the next hit of the combo follows right after
var _was_ground := true
var _skid := 0.0 ## turning at speed: a short skid
var _anim := HeroAnimator.new("px_hero", {"idle": ["px_hero"], "run": ["px_hero_run1", "px_hero_run2"],
	"jump": ["px_hero"], "fall": ["px_hero"], "attack1": ["px_hero_punch"], "attack2": ["px_hero_punch"],
	"attack3": ["px_hero_kick"], "roll": ["px_hero_roll"], "hurt": ["px_hero_hurt"], "skid": ["px_hero"],
	"land": ["px_hero"], "counter": ["px_hero_punch"], "ko": ["px_hero_hurt"]},
	{"attack1": "punch1", "attack2": "punch2", "attack3": "punch3"})
var _land := 0.0


func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	grab_focus()
	for key in ["neon_far", "neon_mid", "neon_near", "train_far", "train_mid"]:
		var p: String = ART + key + ".png"
		if ResourceLoader.exists(p):
			_tex[key] = load(p)
	for i in 160:
		_rain.append(Vector3(randf() * 1400.0, randf() * 720.0, randf()))
	if stage == "train":
		lock_left = 0.0
		lock_right = 1280.0
		hero_pos = Vector2(260, GROUND)
		var a := BrawlEnemy.new("twin_a", Vector2(980, GROUND))
		var b := BrawlEnemy.new("twin_b", Vector2(1120, GROUND))
		b.active = false
		_enemies = [a, b]


# --- API used by the enemies ------------------------------------------------------------------

func hero_box() -> Rect2:
	return Rect2(hero_pos + Vector2(-16, -110), Vector2(32, 108))


func enemy_speed() -> float:
	return 0.3 if _slow > 0.0 else 1.0


## Only two attackers at a time, so a crowd stays fair.
func may_attack(e: BrawlEnemy) -> bool:
	var busy := 0
	for o in _enemies:
		if o != e and o.state in ["windup", "strike"]:
			busy += 1
	return busy < 2


func hurt_hero(e: BrawlEnemy, dmg: int) -> void:
	if _inv > 0.0 or _roll_t > 0.0 or _phase != "play":
		return
	_hp -= dmg
	_inv = 1.0
	_freeze = 0.12
	_shake = 10.0
	_flash = 0.6
	_anim.hurt()
	_vel = Vector2(signf(hero_pos.x - e.pos.x) * 360.0, -380.0)
	_ground = false
	EventBus.sound_requested.emit("hero_hurt")
	if _hp <= 0:
		_phase = "dead"
		_pt = 0.0


func enemy_shot(e: BrawlEnemy) -> void:
	_shots.append({"pos": e.pos + Vector2(e.dir * 60.0, -84.0), "vel": Vector2(e.dir * 1100.0, 0), "from": e})


func enemy_beam(e: BrawlEnemy) -> void:
	_beams.append({"y": e.pos.y - 120.0, "x": e.pos.x, "dir": e.dir, "t": 0.45, "hit": false})
	_shake = 6.0


func twin_turn_done(e: BrawlEnemy) -> void:
	# the twins take turns: the other one steps in
	for o in _enemies:
		if o.twin():
			o.active = o != e or _alive_twins() == 1


func _alive_twins() -> int:
	var n := 0
	for o in _enemies:
		if o.twin() and not o.dead:
			n += 1
	return n


# --- flow ---------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	_t += delta
	_pt += delta
	_shake = maxf(0.0, _shake - delta * 40.0)
	_flash = maxf(0.0, _flash - delta * 2.5)
	_go_hint = maxf(0.0, _go_hint - delta)
	_update_fx(delta)
	if _freeze > 0.0:
		_freeze -= delta
		queue_redraw()
		return
	match _phase:
		"intro":
			if stage == "train":
				_train_intro(delta)
			if _pt > _intro_len():
				_phase = "play"
				_pt = 0.0
		"play":
			_update_hero(delta)
			_update_world(delta)
		"dead":
			_anim.update(delta, "ko", Vector2.ZERO, _face, RUN, true)
			if _pt > 2.0:
				_restart_fight()
		"won":
			if _pt > 2.2:
				set_process(false)
				finished.emit("win")
	queue_redraw()


func _intro_len() -> float:
	return 3.2 if stage == "train" else 2.2


## The Twins' entrance: the hero lands on the train roof, then the Twins tune in out of static.
func _train_intro(delta: float) -> void:
	var before := _pt - delta
	if before < 0.45 and _pt >= 0.45:
		_shake = 10.0
		EventBus.sound_requested.emit("punch_heavy")
		for i in 10:
			_fx.append({"kind": "dust", "pos": hero_pos + Vector2(randf_range(-40, 40), -6), "vel": Vector2(randf_range(-260, 260), -randf_range(60, 220)), "t": 0.0, "life": 0.5})
	if before < 0.75 and _pt >= 0.75:
		EventBus.sound_requested.emit("static")
	if before < 1.6 and _pt >= 1.6:
		var comms: Node = get_tree().get_first_node_in_group("comms")
		if comms != null:
			comms.say("Two channels. One signal. Zero chance.", "static_twins", 2.0)
		_shake = 18.0
		_flash = 1.0
		EventBus.sound_requested.emit("counter_flash")
		EventBus.sound_requested.emit("shockwave")
		for e in _enemies:
			for i in 26:
				_fx.append({"kind": "px", "pos": e.pos + Vector2(randf_range(-50, 50), -randf_range(0, 230)), "vel": Vector2(randf_range(-420, 420), -randf_range(100, 520)), "t": 0.0, "life": 0.7})


## The hero is still falling onto the roof at the start of the Twins' fight.
func _drop() -> float:
	if stage != "train" or _phase != "intro":
		return 0.0
	var k := clampf(_pt / 0.45, 0.0, 1.0)
	return 560.0 * (1.0 - k * k)


## Before they fully tune in, the Twins are only static and flickers.
func _tuning_in() -> bool:
	return stage == "train" and _phase == "intro" and _pt < 1.6


func _draw_static_twin(e: BrawlEnemy) -> void:
	var p := e.pos - Vector2(_cam, 0)
	if _pt > 0.75 and randf() < (_pt - 0.75) / 0.85:
		e.draw(self, _cam + randf_range(-16, 16))
		return
	for k in 9:
		var y := p.y - randf_range(0, 230)
		var w := randf_range(30, 110)
		draw_rect(Rect2(Vector2(p.x - w * 0.5 + randf_range(-20, 20), y), Vector2(w, randf_range(3, 9))), Color(0.3, 1.0, 1.0, 0.55) if k % 2 == 0 else Color(1.0, 0.25, 0.6, 0.5))


func _restart_fight() -> void:
	_hp = MAX_HP
	_phase = "play"
	_pt = 0.0
	_inv = 1.5
	_shots.clear()
	_beams.clear()
	if stage == "train":
		for e in _enemies:
			e.hp = e.max_hp
			e.dead = false
			e.state = "idle"
		_enemies = _enemies.filter(func(e: BrawlEnemy) -> bool: return true)
		hero_pos = Vector2(260, GROUND)
	else:
		_enemies.clear()
		_pending.clear()
		hero_pos.x = lock_left + 160.0
		_zone -= 1
		_zone_live = false
		_start_zone(_zone + 1)


func _start_zone(z: int) -> void:
	_zone = z
	_zone_live = true
	var zone: Array = STREET[z]
	lock_left = float(zone[0])
	lock_right = lock_left + 1280.0
	for s: Array in zone[1]:
		var side: String = s[1]
		var x := lock_right + 60.0 if side == "R" else lock_left - 60.0
		_pending.append({"kind": s[0], "x": x, "dir": -1.0 if side == "R" else 1.0, "delay": float(s[2])})
	EventBus.sound_requested.emit("wave_start")


func _update_world(delta: float) -> void:
	var et := delta * enemy_speed()
	# street: fights start when the hero walks into the next zone
	if stage == "street" and not _zone_live:
		var next := _zone + 1
		if next < STREET.size() and hero_pos.x > float(STREET[next][0]) + 260.0:
			_start_zone(next)
		elif next >= STREET.size() and hero_pos.x > lock_right - 140.0:
			_phase = "won"
			_pt = 0.0
	for p in _pending:
		p["delay"] = float(p["delay"]) - et
	var ready := _pending.filter(func(p: Dictionary) -> bool: return float(p["delay"]) <= 0.0)
	for p: Dictionary in ready:
		_pending.erase(p)
		var e := BrawlEnemy.new(p["kind"], Vector2(p["x"], GROUND))
		e.dir = p["dir"]
		_enemies.append(e)
	for e in _enemies:
		e.update(et, self)
	_dying = _dying.filter(func(e: BrawlEnemy) -> bool: return e.update_dying(delta))
	var dead := _enemies.filter(func(e: BrawlEnemy) -> bool: return e.dead)
	for e: BrawlEnemy in dead:
		_enemies.erase(e)
		_kill_fx(e)
		e.start_dying(hero_pos.x)
		_dying.append(e)
		if e.twin():
			for o in _enemies:
				if o.twin():
					o.active = true # the survivor goes berserk
	if stage == "street" and _zone_live and _pending.is_empty() and _enemies.is_empty():
		_zone_live = false
		_go_hint = 3.0
		if _zone + 1 < STREET.size():
			lock_right = float(STREET[_zone + 1][0]) + 1280.0
		EventBus.sound_requested.emit("chase_checkpoint")
	if stage == "train" and _enemies.is_empty() and _phase == "play":
		_phase = "won"
		_pt = 0.0
	# gunner shots
	for s in _shots:
		s["pos"] = (s["pos"] as Vector2) + (s["vel"] as Vector2) * et
		if hero_box().has_point(s["pos"]):
			s["dead"] = true
			hurt_hero(s["from"], 2)
	_shots = _shots.filter(func(s: Dictionary) -> bool: return not s.get("dead", false) and absf((s["pos"] as Vector2).x - hero_pos.x) < 1600.0)
	# twin eye beams: jump or roll
	for b in _beams:
		b["t"] = float(b["t"]) - et
		if not b["hit"] and _roll_t <= 0.0 and hero_pos.y > GROUND - 60.0:
			var bx := float(b["x"])
			if (float(b["dir"]) > 0.0 and hero_pos.x > bx) or (float(b["dir"]) < 0.0 and hero_pos.x < bx):
				b["hit"] = true
				var src: BrawlEnemy = _enemies[0] if not _enemies.is_empty() else BrawlEnemy.new("thug", Vector2(bx, GROUND))
				hurt_hero(src, 2)
	_beams = _beams.filter(func(b: Dictionary) -> bool: return float(b["t"]) > 0.0)


# --- the hero -------------------------------------------------------------------------------------

func _update_hero(delta: float) -> void:
	_inv = maxf(0.0, _inv - delta)
	_atk_t = maxf(0.0, _atk_t - delta)
	_combo_t = maxf(0.0, _combo_t - delta)
	_roll_cd = maxf(0.0, _roll_cd - delta)
	_counter_cd = maxf(0.0, _counter_cd - delta)
	_slow = maxf(0.0, _slow - delta)
	if _combo_t <= 0.0:
		_combo = 0
	if _atk_buf > 0.0:
		_atk_buf -= delta
		_start_attack()
	var move := 0.0
	if Input.is_key_pressed(KEY_LEFT):
		move -= 1.0
	if Input.is_key_pressed(KEY_RIGHT):
		move += 1.0
	if _counter_t > 0.0:
		_counter_t -= delta
		move = 0.0
	elif _roll_t > 0.0:
		_roll_t -= delta
		_vel.x = _face * 520.0
	else:
		if move != 0.0 and _atk_t <= 0.0:
			_face = move
		var target := move * RUN * (0.35 if _atk_t > 0.0 else 1.0)
		# speed builds and runs out with a short slide; turning at speed skids; the air keeps momentum
		_skid = maxf(0.0, _skid - delta)
		if _ground and move != 0.0 and absf(_vel.x) > RUN * 0.55 and signf(move) != signf(_vel.x) and _skid <= 0.0 and _atk_t <= 0.0:
			_skid = 0.14
			_dust(hero_pos, 4)
		var rate := 3000.0
		if not _ground:
			rate = 2100.0 if move != 0.0 else 600.0
		elif move == 0.0:
			rate = 3200.0
		elif _skid > 0.0:
			rate = 4600.0
		_vel.x = move_toward(_vel.x, target, rate * delta)
	_vel.y = minf(_vel.y + GRAV * delta, 1200.0)
	var fall_v := _vel.y
	hero_pos += _vel * delta
	hero_pos.x = clampf(hero_pos.x, lock_left + 30.0, lock_right - 30.0)
	_ground = false
	if hero_pos.y >= GROUND:
		hero_pos.y = GROUND
		_vel.y = 0.0
		_ground = true
	_land = maxf(0.0, _land - delta * 6.0)
	if _ground and not _was_ground:
		_dust(hero_pos, 6)
		_anim.landed(fall_v)
		_land = 1.0
	elif _ground and absf(_vel.x) > 200.0 and int(_t * 10.0) != int((_t - delta) * 10.0):
		_dust(hero_pos, 1)
	_was_ground = _ground
	var atk_len := 0.24 if _combo < 3 else 0.32
	_anim.attack = 1.0 - _atk_t / atk_len if _atk_t > 0.0 else (1.0 - _counter_t / 0.25 if _counter_t > 0.0 else -1.0)
	_anim.update(delta, _anim_name(), _vel, _face, RUN, _ground)
	# punches land a moment into the swing
	if _atk_t > 0.0 and _atk_t < 0.16:
		var reach := 90.0 if _combo < 3 else 110.0
		var box := Rect2(Vector2(hero_pos.x + (0.0 if _face > 0.0 else -reach), hero_pos.y - 110.0), Vector2(reach, 90.0))
		for e in _enemies:
			if not _atk_hit.has(e) and e.state != "enter" and e.body().intersects(box):
				_atk_hit[e] = true
				var dmg := 1.0 if _combo < 3 else 2.0
				e.take_hit(dmg, hero_pos.x, 220.0 if _combo < 3 else 520.0)
				_hit_fx(e.center().lerp(hero_pos + Vector2(0, -70), 0.3), 1.0 if _combo < 3 else 1.5)
				_freeze = 0.05 if _combo < 3 else 0.1
				EventBus.sound_requested.emit("punch" if _combo < 3 else "punch_heavy")
	# hug the camera to the hero inside the locked zone
	var target_cam := clampf(hero_pos.x - 560.0, lock_left, maxf(lock_left, lock_right - 1280.0))
	_cam = lerpf(_cam, target_cam, minf(1.0, delta * 6.0))


func _unhandled_input(event: InputEvent) -> void:
	if _phase != "play" or not (event is InputEventKey) or event.echo:
		return
	if not event.pressed:
		if event.keycode in [KEY_Z, KEY_SPACE] and _vel.y < -300.0:
			_vel.y *= 0.5
		return
	match event.keycode:
		KEY_Z, KEY_SPACE:
			if _ground and _roll_t <= 0.0:
				_vel.y = -860.0
				_ground = false
				_anim.jumped()
				EventBus.sound_requested.emit("hero_jump")
		KEY_X:
			if not _start_attack():
				_atk_buf = 0.25
		KEY_C:
			if _roll_cd <= 0.0 and _ground:
				_roll_t = 0.34
				_roll_cd = 0.6
				_inv = maxf(_inv, 0.36)
				EventBus.sound_requested.emit("dash")
		KEY_V:
			_try_counter()
		_:
			return
	get_viewport().set_input_as_handled()


func _start_attack() -> bool:
	if _atk_t > 0.05 or _roll_t > 0.0 or _counter_t > 0.0:
		return false
	_combo = (_combo % 3) + 1
	_combo_t = 0.55
	_atk_t = 0.24 if _combo < 3 else 0.32
	_face_nearest()
	_anim.start_attack(_combo)
	_atk_hit.clear()
	_atk_buf = 0.0
	# a small step into each punch
	_vel.x += _face * (140.0 if _combo < 3 else 260.0)
	EventBus.sound_requested.emit("slash")
	return true


## V when an enemy flashes red: the hero blurs to him and hits back hard.
## Turns to the closest enemy within reach, in front or behind, before a punch.
func _face_nearest(reach := 260.0) -> void:
	var best := reach
	for e in _enemies:
		if e.dead or e.state == "enter":
			continue
		var d := absf(e.pos.x - hero_pos.x)
		if d < best:
			best = d
			if d > 4.0:
				_face = signf(e.pos.x - hero_pos.x)


## Which animation the hero's state asks for.
func _anim_name() -> String:
	if _counter_t > 0.0:
		return "counter"
	if _roll_t > 0.0:
		return "roll"
	if _inv > 0.8 and _roll_t <= 0.0:
		return "hurt"
	if _atk_t > 0.0:
		return "attack%d" % maxi(_combo, 1)
	if not _ground:
		return "jump" if _vel.y < 0.0 else "fall"
	if _skid > 0.0:
		return "skid"
	if absf(_vel.x) > 30.0:
		return "run"
	if _land > 0.5:
		return "land"
	return "idle"


func _try_counter() -> void:
	if _counter_cd > 0.0:
		return
	var best: BrawlEnemy = null
	var best_d := 340.0
	for e in _enemies:
		if e.counterable() and absf(e.pos.x - hero_pos.x) < best_d:
			best_d = absf(e.pos.x - hero_pos.x)
			best = e
	for s in _shots:
		var from: BrawlEnemy = s["from"]
		if absf((s["pos"] as Vector2).x - hero_pos.x) < 200.0 and from != null and not from.dead:
			best = from # deflect the bullet back at the gunner
			s["dead"] = true
	if best == null:
		_counter_cd = 0.5
		return
	_counters += 1
	_counter_t = 0.25
	_inv = maxf(_inv, 0.5)
	_face = signf(best.pos.x - hero_pos.x) if best.pos.x != hero_pos.x else _face
	hero_pos.x = best.pos.x - _face * 70.0
	best.take_hit(5.0 if not best.twin() else 3.0, hero_pos.x, 700.0)
	best.state = "recover"
	best.st = 0.0
	_slow = 0.6
	_freeze = 0.16
	_shake = 12.0
	_flash = 0.4
	_hit_fx(best.center(), 2.0)
	_fx.append({"kind": "word", "text": "COUNTER!", "pos": best.center() + Vector2(0, -80), "t": 0.0, "life": 0.9})
	_fx.append({"kind": "burst", "pos": best.center(), "t": 0.0, "life": 0.35})
	EventBus.sound_requested.emit("counter_hit")


func _dust(at: Vector2, n: int) -> void:
	for k in n:
		_fx.append({"kind": "dust", "pos": at + Vector2(randf_range(-14, 14), -4), "vel": Vector2(randf_range(-120, 120), randf_range(-140, -40)), "t": 0.0, "life": 0.45})


func _hit_fx(p: Vector2, size: float) -> void:
	_fx.append({"kind": "spark", "pos": p, "t": 0.0, "life": 0.22, "size": size})
	for k in 5:
		_fx.append({"kind": "px", "pos": p, "vel": Vector2(randf_range(-300, 300), randf_range(-360, -60)), "t": 0.0, "life": 0.5})


func _kill_fx(e: BrawlEnemy) -> void:
	_freeze = 0.12 if not e.twin() else 0.3
	_shake = 10.0 if not e.twin() else 18.0
	_flash = 0.35
	EventBus.sound_requested.emit("kill")
	for k in 16:
		_fx.append({"kind": "px", "pos": e.center(), "vel": Vector2(randf_range(-420, 420), randf_range(-520, -100)), "t": 0.0, "life": 0.9})
	_fx.append({"kind": "word", "text": ["KRAK!", "POW!", "ZZT!"][randi() % 3], "pos": e.center() + Vector2(0, -70), "t": 0.0, "life": 0.9})


func _update_fx(delta: float) -> void:
	for f in _fx:
		f["t"] = float(f["t"]) + delta
		if f.has("vel"):
			f["vel"] = (f["vel"] as Vector2) + Vector2(0, 1000.0 * delta)
			f["pos"] = (f["pos"] as Vector2) + (f["vel"] as Vector2) * delta
	_fx = _fx.filter(func(f: Dictionary) -> bool: return float(f["t"]) < float(f["life"]))


# --- drawing --------------------------------------------------------------------------------------

func _layer(key: String, par: float, y := 0.0) -> bool:
	if not _tex.has(key):
		return false
	var tex: Texture2D = _tex[key]
	var sc := 1280.0 / 480.0
	var w := tex.get_width() * sc
	var x := -fposmod(_cam * par, w)
	while x < 1280.0:
		draw_texture_rect(tex, Rect2(Vector2(x, y), Vector2(w, tex.get_height() * sc)), false)
		x += w
	return true


func _draw() -> void:
	var off := Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake)) if _shake > 0.0 else Vector2.ZERO
	draw_set_transform(off)
	if stage == "street":
		_draw_street()
	else:
		_draw_train()
	# enemies, shots, beams, hero
	for e in _enemies:
		if _tuning_in():
			_draw_static_twin(e)
		else:
			e.draw(self, _cam)
		draw_set_transform(off)
	for e in _dying:
		e.draw(self, _cam)
		draw_set_transform(off)
	for s in _shots:
		var sp := (s["pos"] as Vector2) - Vector2(_cam, 0)
		draw_line(sp - (s["vel"] as Vector2).normalized() * 30.0, sp, Color(1, 0.3, 0.3), 4.0)
		draw_circle(sp, 4.0, Color.WHITE)
	for b in _beams:
		var by := float(b["y"])
		var bx := float(b["x"]) - _cam
		var x1 := 1400.0 if float(b["dir"]) > 0.0 else -120.0
		draw_line(Vector2(bx, by), Vector2(x1, by), Color(0.3, 1.0, 1.0, 0.4), 34.0)
		draw_line(Vector2(bx, by), Vector2(x1, by), Color(0.9, 1.0, 1.0), 10.0)
	_draw_hero()
	for f in _fx:
		var k := float(f["t"]) / float(f["life"])
		var fp := (f["pos"] as Vector2) - Vector2(_cam, 0)
		match String(f["kind"]):
			"spark":
				ArenaArt.hit_spark(self, fp, k, float(f["size"]))
			"px":
				draw_rect(Rect2(fp, Vector2(6, 6)), Color(0.4, 1.0, 1.0, 1.0 - k))
			"burst":
				# speed lines bursting out of a counter
				for i in 16:
					var ang := i * TAU / 16.0
					var r0 := 40.0 + 220.0 * k
					draw_line(fp + Vector2.from_angle(ang) * r0, fp + Vector2.from_angle(ang) * (r0 + 70.0), Color(1, 0.95, 0.8, 1.0 - k), 4.0)
			"dust":
				draw_rect(Rect2(fp - Vector2(4, 4), Vector2(8, 8)), Color(0.75, 0.7, 0.75, 0.5 * (1.0 - k)))
			"word":
				ComicArt.shout(self, String(f["text"]), fp + Vector2(0, -30.0 * k), 46, Color("ffd23f"), 10, -0.05)
	draw_set_transform(off)
	if stage == "street":
		_layer("neon_near", 1.25)
	_draw_rain()
	draw_set_transform(Vector2.ZERO)
	if _flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.35 * _flash))
	if _slow > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.4, 0.0, 0.05, 0.18))
	_draw_hud()


func _draw_street() -> void:
	if not _layer("neon_far", 0.15):
		# code-drawn fallback: a red neon night (until the pixel art arrives)
		for k in 12:
			draw_rect(Rect2(0, k * 60.0, 1280, 61), Color("12060a").lerp(Color("2a0a10"), k / 11.0))
		for k in 14:
			var bx := fposmod(k * 150.0 - _cam * 0.15, 1500.0) - 100.0
			var bh := 220.0 + (k * 53 % 180)
			draw_rect(Rect2(bx, 520.0 - bh, 110, bh + 200), Color("1a0b10"))
			for wy in range(int(540.0 - bh), 500, 26):
				for wx in range(int(bx) + 10, int(bx) + 100, 22):
					if (wx * 3 + wy + k) % 4 != 0:
						draw_rect(Rect2(wx, wy, 10, 12), Color(1, 0.15, 0.2, 0.35))
	if not _layer("neon_mid", 0.6):
		# the street front: huge red window grids, doors, green accent lights (REPLACED-like mood)
		for k in 8:
			var sx := k * 520.0 - _cam * 0.6
			if sx < -520.0 or sx > 1300.0:
				continue
			draw_rect(Rect2(sx, 160, 500, 470), Color("1c0d12"))
			var grid := Rect2(sx + 40, 220, 200, 220)
			draw_texture_rect(TEX_GLOW, grid.grow(80.0), false, Color(1, 0.1, 0.15, 0.25))
			draw_rect(grid, Color("ff2a3a").darkened(0.15))
			for gx in 8:
				draw_line(Vector2(grid.position.x + gx * 25.0, grid.position.y), Vector2(grid.position.x + gx * 25.0, grid.end.y), Color("2a0508"), 4.0)
			for gy in 9:
				draw_line(Vector2(grid.position.x, grid.position.y + gy * 25.0), Vector2(grid.end.x, grid.position.y + gy * 25.0), Color("2a0508"), 4.0)
			draw_rect(Rect2(sx + 280, 300, 90, 330), Color("0f0609"))
			draw_texture_rect(TEX_GLOW, Rect2(sx + 290, 250, 70, 70), false, Color(0.3, 1.0, 0.5, 0.5))
			draw_rect(Rect2(sx + 380, 230, 100, 60), Color("ff2a3a").darkened(0.5))
			draw_rect(Rect2(sx, 150, 500, 14), Color("3a1018"))
	# wet street with red reflections
	draw_rect(Rect2(0, GROUND, 1280, 90), Color("0a0507"))
	for k in 20:
		var rx := fposmod(k * 97.0 - _cam, 1280.0)
		draw_rect(Rect2(rx, GROUND + 8 + (k % 4) * 14.0, 40 + (k % 3) * 20.0, 3), Color(1, 0.2, 0.25, 0.25))
	draw_line(Vector2(0, GROUND), Vector2(1280, GROUND), Color("5a1a22"), 3.0)
	# fog over the street
	draw_texture_rect(TEX_GLOW, Rect2(-200, 380, 1700, 420), false, Color(1, 0.25, 0.3, 0.12))
	# the "GO" arrow when a fight is cleared
	if _go_hint > 0.0 and int(_t * 3.0) % 2 == 0:
		ComicArt.shout(self, "GO  >>", Vector2(1120, 300), 54, Color("ffd23f"), 10, 0.0)


func _draw_train() -> void:
	var speed := _t * 1400.0
	if not _layer("train_far", 0.0):
		for k in 12:
			draw_rect(Rect2(0, k * 60.0, 1280, 61), Color("0a1018").lerp(Color("1c2a3a"), k / 11.0))
		for k in 16:
			var bx := fposmod(k * 130.0 - speed * 0.08, 1500.0) - 100.0
			var bh := 160.0 + (k * 61 % 220)
			draw_rect(Rect2(bx, 500.0 - bh, 100, bh), Color("0d1620"))
			for wy in range(int(520.0 - bh), 480, 24):
				if (wy + k) % 3 == 0:
					draw_rect(Rect2(bx + 14, wy, 70, 6), Color(1, 0.3, 0.35, 0.3))
	if int(_t * 0.5) % 5 == 0 and fposmod(_t, 2.0) < 0.08:
		draw_rect(Rect2(0, 0, 1280, 720), Color(0.8, 0.9, 1.0, 0.35)) # lightning
	if not _layer("train_mid", 0.0):
		for k in 4:
			var px := fposmod(k * 420.0 - speed * 0.9, 1700.0) - 200.0
			draw_rect(Rect2(px, 120, 18, 420), Color("060a10"))
			draw_line(Vector2(px - 300, 160), Vector2(px + 320, 160), Color("060a10"), 3.0)
	# the train roof
	draw_rect(Rect2(0, GROUND, 1280, 90), Color("1b2433"))
	draw_rect(Rect2(0, GROUND, 1280, 8), Color("c9d6e3"))
	for k in 5:
		var gx := fposmod(k * 300.0 - speed * 0.02, 1500.0) - 100.0
		draw_rect(Rect2(gx, GROUND + 16, 180, 30), Color("2b3647"))
		draw_texture_rect(TEX_GLOW, Rect2(gx + 60, GROUND + 40, 60, 40), false, Color(1, 0.2, 0.3, 0.6))
	draw_texture_rect(TEX_GLOW, Rect2(-200, 300, 1700, 500), false, Color(0.5, 0.7, 1.0, 0.08))


func _draw_rain() -> void:
	var wind := 0.35 if stage == "train" else 0.12
	for r in _rain:
		var x := fposmod(r.x - _t * 900.0 * wind - _cam * 0.8, 1400.0) - 60.0
		var y := fposmod(r.y + _t * (900.0 + r.z * 400.0), 760.0) - 20.0
		draw_line(Vector2(x, y), Vector2(x - 18.0 * wind * 3.0, y + 22.0), Color(0.75, 0.85, 1.0, 0.18 + 0.2 * r.z), 1.5)


func _draw_hero() -> void:
	var pose := "idle"
	if _counter_t > 0.0 or _atk_t > 0.0:
		pose = "attack"
	elif _roll_t > 0.0:
		pose = "dash"
	elif _inv > 0.8:
		pose = "hurt"
	elif not _ground:
		pose = "jump" if _vel.y < 0.0 else "fall"
	elif absf(_vel.x) > 30.0:
		pose = "run"
	var p := hero_pos - Vector2(_cam, _drop())
	draw_texture_rect(TEX_GLOW, Rect2(p + Vector2(-90, -170), Vector2(180, 180)), false, Color(0.3, 0.9, 1.0, 0.12))
	if _inv > 0.0 and _roll_t <= 0.0 and int(_t * 18.0) % 2 == 0:
		return
	# a pixel sprite if there is one; else the painted hero frames, which the 720p filter turns into pixel art
	if not _anim.draw(self, p + Vector2(0, 4), 180.0) and not Sprites.draw(self, _px_frame(pose), p + Vector2(0, 4), 180.0, _face, Color.WHITE, 1.0 + (sin(_t * 3.0) * 0.015 if pose == "idle" else 0.0), 0.18 * _face if pose == "dash" and _px_frame(pose) == "px_hero" else 0.0):
		ArenaArt.hero(self, 0, p, _face, pose, _t, 0.0, 1.25)
	draw_set_transform(Vector2.ZERO)
	if _atk_t > 0.12:
		ArenaArt.slash(self, p + Vector2(_face * 56.0, -70), Vector2(_face, -0.1 if _combo < 3 else -0.6).normalized(), 1.0 - (_atk_t - 0.12) / 0.2, _combo == 3)


## The pixel hero frame for a pose (falls back to px_hero when a frame is missing).
func _px_frame(pose: String) -> String:
	var key := "px_hero"
	match pose:
		"run":
			key = "px_hero_run1" if int(_t * 9.0) % 2 == 0 else "px_hero_run2"
		"attack":
			key = "px_hero_kick" if _combo == 3 else "px_hero_punch"
		"dash":
			key = "px_hero_roll"
		"hurt":
			key = "px_hero_hurt"
	return key if Sprites.has(key) else "px_hero"


func _subtitle(text: String, y: float, a: float) -> void:
	var w := FONT_BODY.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	draw_string_outline(FONT_BODY, Vector2(640 - w * 0.5, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, 6, Color(0, 0, 0, a))
	draw_string(FONT_BODY, Vector2(640 - w * 0.5, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1, 0.95, 0.85, a))


func _draw_hud() -> void:
	# REPLACED-like: a row of small pixel hearts top left
	for i in MAX_HP:
		var hp := Vector2(36 + i * 26, 36)
		var col := Color("ff3a4a") if i < _hp else Color(0.25, 0.1, 0.12)
		draw_rect(Rect2(hp + Vector2(-8, -6), Vector2(7, 7)), col)
		draw_rect(Rect2(hp + Vector2(1, -6), Vector2(7, 7)), col)
		draw_rect(Rect2(hp + Vector2(-8, 0), Vector2(16, 6)), col)
		draw_rect(Rect2(hp + Vector2(-4, 6), Vector2(8, 4)), col)
	if _counters == 0 and _phase == "play":
		var msg := "PRESS  V  WHEN THE ENEMY'S EYES TURN RED"
		var w := FONT_BODY.get_string_size(msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
		draw_string(FONT_BODY, Vector2(640 - w * 0.5, 70), msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("fff3d1"))
	draw_string(FONT_BODY, Vector2(30, 704), "ARROWS move   Z jump   X punch (combo)   C roll   V counter", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.6))
	if stage == "street" and _phase == "play" and _counters > 0:
		var obj := ""
		if _zone_live:
			obj = "BEAT THE GOONS  (%d left)" % (_enemies.size() + _pending.size())
		elif _zone + 1 < STREET.size():
			obj = "KEEP GOING  >>"
		else:
			obj = "TO THE TRAIN  >>"
		var ow := FONT_SHOUT.get_string_size(obj, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
		draw_string(FONT_SHOUT, Vector2(640 - ow * 0.5, 70), obj, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("fff3d1"))
	if stage == "train":
		var bar := Rect2(Vector2(668, 664), Vector2(580, 16))
		draw_string(FONT_SHOUT, Vector2(668, 656), "THE STATIC TWINS", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("3ef0ff"))
		var hp_sum := 0.0
		var hp_max := 80.0
		for e in _enemies:
			if e.twin():
				hp_sum += maxf(0.0, e.hp)
		draw_rect(bar, Color.BLACK)
		draw_rect(Rect2(bar.position + Vector2(2, 2), Vector2((bar.size.x - 4) * hp_sum / hp_max, bar.size.y - 4)), Color("ff2a3a"))
	match _phase:
		"intro":
			var fade_at := _intro_len() - 0.6
			draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.5 * (1.0 - clampf((_pt - fade_at) / 0.6, 0.0, 1.0))))
			if stage == "street":
				var k := clampf(_pt / 0.3, 0.0, 1.0)
				ComicArt.shout(self, "NEON STREET", Vector2(640, 320), int(84 * k) + 1, Color("ff3a4a"), 12, -0.03)
				_subtitle("CLEAR THE STREET OF THE VILLAIN'S GOONS", 390.0, k)
			elif _pt > 1.6:
				# the title tunes in like a bad TV signal: cyan and magenta ghosts snap together
				var k2 := clampf((_pt - 1.6) / 0.3, 0.0, 1.0)
				var split := 14.0 * (1.0 - k2) + (5.0 if int(_t * 24.0) % 9 == 0 else 0.0)
				var fs := 84
				var tw := FONT_SHOUT.get_string_size("THE STATIC TWINS", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
				draw_string(FONT_SHOUT, Vector2(640 - tw * 0.5 - split, 348), "THE STATIC TWINS", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.2, 1.0, 1.0, 0.75))
				draw_string(FONT_SHOUT, Vector2(640 - tw * 0.5 + split, 348), "THE STATIC TWINS", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.2, 0.6, 0.75))
				ComicArt.shout(self, "THE STATIC TWINS", Vector2(640, 320), fs, Color("3ef0ff"), 12, -0.03)
				_subtitle("TWO BODIES. ONE SIGNAL.", 390.0, k2)
		"dead":
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.3, 0.0, 0.05, clampf(_pt, 0.0, 0.7)))
			ComicArt.shout(self, "KNOCKED OUT", Vector2(640, 330), 80, Color("ff3a4a"), 12, -0.03)
		"won":
			ComicArt.shout(self, "CLEAR!" if stage == "street" else "TWINS DOWN!", Vector2(640, 320), 90, Color("ffd23f"), 12, -0.03)
