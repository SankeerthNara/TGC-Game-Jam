class_name BossFight
extends Control
## The final battle: a locked arena on the Narrator's opera stage. He conducts waves of ink creatures
## from his balcony, then comes down himself. The heroes fight in relay:
##   round 1 the noir detective (power DEDUCTION: slow time), waves 1-2
##   round 2 the ninja (power LIGHT DASH: a dash that cuts through enemies), waves 3-4
##   round 3 the space hero (power PRISM CANNON: a beam across the stage), wave 5 and the Narrator.
## Rounds 1 and 2 always end with the Narrator writing THE END on that hero (the story), but every
## wave they clear cracks his shield and weakens him for round 3. The bomb keeps ticking (main.gd).
## Controls: arrows move, Z jump, X attack (hold up / down for up and down slashes, down slashes
## bounce off enemies), C dash, V power (3 ink), F heal (6 ink). Hits fill the ink meter.
## finished("win") or finished("lose").

signal finished(result: String)

const FONT_SHOUT := preload("res://assets/fonts/Bangers-Regular.ttf")
const FONT_BODY := preload("res://assets/fonts/ComicNeue-Bold.ttf")
const INK := Color("18151d")
const PAPER := Color("fff3d1")
const GOLD := Color("ffd23f")
const RED := Color("e63946")
const FLOOR_Y := 600.0
const LEFT_X := 110.0
const RIGHT_X := 1170.0
const GRAV := 2700.0
const RUN := 360.0
const JUMP_V := -900.0
const DASH_V := 1150.0
const MAX_HP_CLASSIC := 5
const MAX_INK := 9
const HEROES := [1, 2, 3] ## ArenaArt / ComicArt hero kinds: noir detective, ninja, space hero
const POWERS := ["DEDUCTION", "LIGHT DASH", "PRISM CANNON"]
const POWER_TEXT := ["slows every enemy for 4 seconds", "a dash that cuts through every enemy in the way", "a beam of light across the whole stage"]
## Waves: [kind, where, delay]. where: "L"/"R"/"C" on the floor, "AL"/"AR"/"AC" in the air.
const WAVES := [
	[[["lancer", "L", 0.0], ["lancer", "R", 0.3], ["lancer", "C", 5.0], ["lancer", "R", 9.0]],
	 [["lancer", "L", 0.0], ["bat", "AR", 0.4], ["bat", "AL", 2.5], ["lancer", "R", 5.0], ["bat", "AC", 8.0], ["lancer", "L", 10.0]]],
	[[["brute", "C", 0.0], ["bat", "AL", 4.0], ["bat", "AR", 6.0], ["lancer", "L", 9.0]],
	 [["lancer", "L", 0.0], ["lancer", "R", 0.0], ["bomb", "AC", 2.0], ["bomb", "AL", 3.5], ["bat", "AR", 5.0], ["bomb", "AR", 7.0], ["brute", "C", 9.0]]],
	[[["brute", "L", 0.0], ["lancer", "R", 0.5], ["bat", "AC", 4.0], ["lancer", "L", 6.0], ["bat", "AR", 8.0], ["lancer", "R", 11.0]],
	 [["narrator", "BALCONY", 0.0]]],
]

## Configuration (the editions reuse this arena): which waves, which heroes, relay or not.
var waves: Array = WAVES
var heroes: Array = HEROES
var relay := true ## rounds before the last end in the scripted THE END
var intro_lines: Array = [] ## replaces the round card text when set
var win_text := "SOLAR FLARE!"
var boss_name := "THE NARRATOR"
var boss_hp_scale := 1.0
var narrator_line := "ENOUGH! I'LL END THIS MYSELF!"
var fight_title := "" ## the Editions name each fight; empty = the classic "ROUND n: hero"
## Levels (the editions' 2k act): stage art, a wide scrolling level with ledges, pre-placed roamers,
## and the x where the locked fight begins.
var stage := "opera" ## opera | hall | dark
var level_width := 1280.0
var platforms: Array[Rect2] = []
var roamers: Array = [] ## [kind, Vector2]
var arena_x := 0.0
var caged_heroes := false ## the three captured heroes hang in cages (the final stage)
var _cam := 0.0
var _lock_l := LEFT_X
var _lock_r := RIGHT_X
var _exploring := false
var _bg := {}
const POWER_BY_KIND := {0: "LIGHT BLADE", 1: "DEDUCTION", 2: "LIGHT DASH", 3: "PRISM CANNON"}
const POWER_TEXT_BY_KIND := {0: "a huge arc of light that cuts everything in front of you", 1: "slows every enemy for 4 seconds", 2: "a dash that cuts through every enemy in the way", 3: "a beam of light across the whole stage"}

var friends_revealed := 0
var friends_killed := 0
var bomb_left := 180.0 ## set by main every frame
var intensity := 0 ## for the music: 0 calm, 1 waves, 2 heavy, 3 the Narrator

var hero_pos := Vector2(640, FLOOR_Y)
var _vel := Vector2.ZERO
var _ground := true
var _face := 1.0
var _coyote := 0.0
var _combo := 0 ## 1, 2, 3: the hit of the combo in progress
var _combo_t := 0.0 ## time left to chain the next hit
var _skid := 0.0 ## turning at speed: a short skid
var _land_lock := 0.0 ## a hard landing slows the first steps
var _anim := HeroAnimator.new("hero", {"idle": ["hero_idle"], "run": ["hero_run1", "hero_run2"],
	"jump": ["hero_jump"], "fall": ["hero_jump"], "attack1": ["hero_attack"], "attack2": ["hero_attack"],
	"attack3": ["hero_attack"], "attack_up": ["hero_attack"], "attack_down": ["hero_jump"],
	"dash": ["hero_dash"], "hurt": ["hero_hurt"], "skid": ["hero_idle"], "land": ["hero_idle"], "heal": ["hero_idle"],
	"turn": ["hero_idle"], "blade": ["hero_attack"], "ko": ["hero_hurt"]},
	{"attack_up": "upslash", "attack_down": "downslash"})
var _blade_t := 0.0 ## the Light Blade swing is playing
var _jump_buf := 0.0
var _dash_t := 0.0
var _dash_cd := 0.0
var _air_dash := true
var _light_dash := false
var _atk_t := 0.0
var _atk_cd := 0.0
var _atk_dir := "side"
var _atk_hit := {}
var max_hp := MAX_HP_CLASSIC ## the editions give the single hero a little more
var checkpoints := false ## the editions: dying restarts only the current wave
var _hp := MAX_HP_CLASSIC
var _ink := 0
var _invuln := 0.0
var _heal_t := -1.0
var _slow := 0.0
var _hurt_flash := 0.0
var _atk_buf := 0.0 ## X pressed just before the swing is ready: it fires as soon as it can
var _land := 0.0 ## landing squash
var _was_ground := true
var _boss_carry := -1.0 ## a retry keeps most of the damage done to the boss

var _round := 0
var _wave := 0
var _phase := "round_intro" ## round_intro | wave_intro | wave | the_end | ko | won | lost
var _pt := 0.0 ## time in the phase
var _t := 0.0
var _freeze := 0.0
var _shake := 0.0
var _white := 0.0
var _gate := 0.0
var _enemies: Array[ArenaEnemy] = []
var _pending: Array[Dictionary] = [] ## spawns waiting for their delay / ink splash
var _waves: Array[Dictionary] = [] ## shockwaves along the floor
var _drops: Array[Dictionary] = [] ## ink rain
var _beams: Array[Dictionary] = []
var _fx: Array[Dictionary] = [] ## particles, sparks, words
var _corpses: Array[Dictionary] = []
var _cleared := 0 ## waves cleared in rounds 1 and 2 (they crack the shield)
var _narrator: ArenaEnemy = null
var _paper: Array[Vector3] = []


func _ready() -> void:
	# run frames 3 and 6 lose the blade (and 6 is drawn smaller): left out until redrawn
	_anim.skip = {"run": [3, 6]}
	position = Vector2.ZERO
	size = get_viewport_rect().size
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	grab_focus()
	for key in ["hall_far", "hall_mid", "hall_near", "arena_far", "arena_mid", "arena_near", "arena_dark"]:
		for ext in [".jpg", ".png"]:
			var path: String = "res://assets/editions/2k/" + key + ext
			if ResourceLoader.exists(path):
				_bg[key] = load(path)
	if stage == "opera" or stage == "dark":
		platforms.append(ArenaArt.PODIUM)
	for i in 50:
		_paper.append(Vector3(randf() * 1280.0, randf() * 720.0, randf()))
	_begin_round(0)


# --- API used by the enemies -------------------------------------------------------------

func _hero_kind() -> int:
	return int(heroes[mini(_round, heroes.size() - 1)])


func _relay_round() -> bool:
	return relay and _round < waves.size() - 1


func _last_wave() -> bool:
	return _round == waves.size() - 1 and _wave == waves[_round].size() - 1


func _total_waves() -> int:
	var n := 0
	for r: Array in waves:
		n += r.size()
	return n


func bound_l() -> float:
	return 40.0 if _exploring else _lock_l


func bound_r() -> float:
	return level_width - 40.0 if _exploring else _lock_r


func center_x() -> float:
	return (_lock_l + _lock_r) * 0.5


func hero_center() -> Vector2:
	return hero_pos + Vector2(0, -46)


func _hero_box() -> Rect2:
	return Rect2(hero_pos + Vector2(-17, -86), Vector2(34, 84))


func enemy_speed() -> float:
	return 0.35 if _slow > 0.0 else 1.0


func shake(a: float) -> void:
	_shake = maxf(_shake, a)


func spawn(kind: String, p: Vector2) -> void:
	_pending.append({"kind": kind, "pos": p, "delay": 0.0, "mark": 0.5})


func shockwave(p: Vector2, dir: float) -> void:
	_waves.append({"x": p.x, "dir": dir, "life": 2.6})
	EventBus.sound_requested.emit("shockwave")


func explode(p: Vector2, r: float) -> void:
	_fx.append({"kind": "boom", "pos": p, "t": 0.0, "life": 0.5, "r": r})
	shake(10.0)
	EventBus.sound_requested.emit("explosion")
	if p.distance_to(hero_center()) < r:
		_hurt(p.x)


## A brute or the Ink Baron crashes onto the stage.
func heavy_landing(e: ArenaEnemy) -> void:
	if e.kind == "baron":
		var comms: Node = get_tree().get_first_node_in_group("comms")
		if comms != null:
			comms.say("Ah, fresh paper! I'll blot you out, hero!", "ink_baron", 2.0)
	shake(16.0)
	_freeze = maxf(_freeze, 0.08)
	EventBus.sound_requested.emit("shockwave")
	for k in 18:
		var ang := PI + k * PI / 17.0
		_fx.append({"kind": "dust", "pos": e.pos + Vector2(cos(ang) * 30.0, -6), "vel": Vector2(cos(ang) * randf_range(200, 420), randf_range(-260, -60)), "t": 0.0, "life": 0.7, "size": randf_range(6, 12)})
	if e.kind == "baron":
		_say("THE INK BARON!", e.pos + Vector2(0, -260), Color("ff6b6b"), 60)


func ink_rain(n: int) -> void:
	for k in n:
		_drops.append({"x": randf_range(_lock_l + 30.0, _lock_r - 30.0), "y": -40.0, "warn": 0.8 + k * 0.12})
	var aim := clampf(hero_pos.x, _lock_l + 30.0, _lock_r - 30.0)
	_drops.append({"x": aim, "y": -40.0, "warn": 0.9})


# --- flow ---------------------------------------------------------------------------------

func _begin_round(r: int) -> void:
	_round = r
	_wave = 0
	_phase = "round_intro"
	_pt = 0.0
	_exploring = level_width > 1280.0
	hero_pos = Vector2(200 if _exploring else 640, FLOOR_Y)
	_vel = Vector2.ZERO
	_hp = max_hp
	_ink = 3
	_invuln = 0.0
	_slow = 0.0
	_heal_t = -1.0
	_enemies.clear()
	_pending.clear()
	_waves.clear()
	_drops.clear()
	_beams.clear()
	intensity = 0
	if _exploring:
		for rm: Array in roamers:
			var e := ArenaEnemy.new(String(rm[0]), rm[1])
			e.state = "hover" if e.flying() else "idle"
			_enemies.append(e)


func _begin_wave() -> void:
	_phase = "wave_intro"
	_pt = 0.0
	EventBus.sound_requested.emit("wave_start")


func _start_spawns() -> void:
	_phase = "wave"
	_pt = 0.0
	var wave: Array = waves[_round][_wave]
	for s: Array in wave:
		var kind: String = s[0]
		var where: String = s[1]
		var p := Vector2(640, FLOOR_Y)
		match where:
			"L":
				p = Vector2(_lock_l + 110.0, FLOOR_Y)
			"R":
				p = Vector2(_lock_r - 110.0, FLOOR_Y)
			"C":
				p = Vector2(center_x(), FLOOR_Y)
			"AL":
				p = Vector2(_lock_l + 150.0, 220)
			"AR":
				p = Vector2(_lock_r - 150.0, 220)
			"AC":
				p = Vector2(center_x(), 180)
			"BALCONY":
				p = Vector2(center_x(), 150)
		_pending.append({"kind": kind, "pos": p, "delay": float(s[2]), "mark": 0.7})
	intensity = 3 if _last_wave() else (2 if _round >= 1 or _wave >= 1 else 1)


func _wave_done() -> void:
	if _relay_round():
		_cleared += 1
	_wave += 1
	if _wave < waves[_round].size():
		_begin_wave()
	elif _relay_round():
		# the story: the Narrator writes THE END on this hero
		_phase = "the_end"
		_pt = 0.0
		intensity = 0
		EventBus.sound_requested.emit("narrator_attack")
	else:
		_win()


func _win() -> void:
	_phase = "won"
	_pt = 0.0
	_white = 1.0
	_say(win_text, Vector2(640, 300), GOLD, 80)
	EventBus.sound_requested.emit("power_solar")


## How much the first two heroes cracked his shield (0..1).
func crack_share() -> float:
	var relay_waves := 0
	for r in waves.size() - 1:
		relay_waves += waves[r].size()
	return clampf(_cleared / float(maxi(relay_waves, 1)), 0.0, 1.0) if relay else 1.0


func _narrator_hp() -> float:
	return maxf(50.0, 110.0 * (1.0 - 0.4 * crack_share()) * (1.0 - 0.06 * friends_revealed) * (1.0 + 0.15 * friends_killed))


func _process(delta: float) -> void:
	_t += delta
	_pt += delta
	_shake = maxf(0.0, _shake - delta * 40.0)
	_white = maxf(0.0, _white - delta * 2.5)
	_hurt_flash = maxf(0.0, _hurt_flash - delta * 2.5)
	_update_fx(delta)
	if _freeze > 0.0:
		_freeze -= delta # hit-stop: the world holds its breath
		queue_redraw()
		return
	match _phase:
		"round_intro":
			_gate = move_toward(_gate, 0.0, delta * 2.0)
			if _pt > 3.4:
				_gate = 0.0
				if _exploring:
					_phase = "explore"
					_pt = 0.0
				else:
					_begin_wave()
		"explore":
			_update_hero(delta)
			_update_world(delta)
			if hero_pos.x > arena_x:
				# the doors slam: a locked fight, like the video
				_exploring = false
				_lock_l = arena_x - 530.0
				_lock_r = arena_x + 530.0
				# roamers left behind outside the doors stay behind (no teleporting into the fight)
				_enemies = _enemies.filter(func(e: ArenaEnemy) -> bool: return e.pos.x > _lock_l and e.pos.x < _lock_r)
				_begin_wave()
		"wave_intro":
			_gate = move_toward(_gate, 1.0, delta * 2.5)
			_update_hero(delta)
			if _pt > 1.6:
				_start_spawns()
		"wave":
			_update_hero(delta)
			_update_world(delta)
			if _pending.is_empty() and _enemies.is_empty() and _phase == "wave":
				_wave_done()
		"retry":
			_anim.update(delta, "ko", Vector2.ZERO, _face, RUN, true)
			if _pt > 2.2:
				# back to the start of this wave, full health (the Narrator heals too)
				_hp = max_hp
				_invuln = 1.5
				if _narrator != null and _narrator.kind in ["narrator", "baron"]:
					_boss_carry = minf(_narrator.max_hp, _narrator.hp + _narrator.max_hp * 0.15)
				_enemies.clear()
				_pending.clear()
				_waves.clear()
				_drops.clear()
				_narrator = null
				hero_pos.x = center_x()
				hero_pos.y = FLOOR_Y
				_vel = Vector2.ZERO
				_begin_wave()
		"the_end":
			_update_world(delta * 0.3)
			if _pt > 2.4:
				_knockout()
		"ko":
			if _pt > 3.6:
				_begin_round(_round + 1)
		"won", "lost":
			if _pt > 2.4:
				set_process(false)
				finished.emit("win" if _phase == "won" else "lose")
	queue_redraw()


func _knockout() -> void:
	_phase = "ko"
	_pt = 0.0
	_enemies.clear()
	_pending.clear()
	_waves.clear()
	_drops.clear()
	intensity = 0
	EventBus.sound_requested.emit("hero_ko")


# --- the hero ------------------------------------------------------------------------------

func _update_hero(delta: float) -> void:
	_invuln = maxf(0.0, _invuln - delta)
	_dash_cd = maxf(0.0, _dash_cd - delta)
	_atk_cd = maxf(0.0, _atk_cd - delta)
	_atk_t = maxf(0.0, _atk_t - delta)
	_slow = maxf(0.0, _slow - delta)
	_jump_buf = maxf(0.0, _jump_buf - delta)
	_coyote = maxf(0.0, _coyote - delta)
	_combo_t = maxf(0.0, _combo_t - delta)
	_blade_t = maxf(0.0, _blade_t - delta)
	_land = maxf(0.0, _land - delta * 6.0)
	if _atk_buf > 0.0:
		_atk_buf -= delta
		_start_attack()
	var move := Input.get_axis("move_left", "move_right") # arrows or A / D
	if _heal_t >= 0.0:
		_heal_t += delta
		move = 0.0
		if _heal_t > 0.6:
			_heal_t = -1.0
			_hp = mini(max_hp, _hp + 2)
			_ink -= 6
			_fx.append({"kind": "ring", "pos": hero_center(), "t": 0.0, "life": 0.5, "col": Color("8ef0ff")})
			_say("HEAL!", hero_center() + Vector2(0, -60), Color("8ef0ff"), 40)
			EventBus.sound_requested.emit("heal")
	if _dash_t > 0.0:
		_dash_t -= delta
		_vel.y = 0.0
		if _light_dash:
			for e in _enemies:
				if not _atk_hit.has(e) and e.state != "enter" and e.hurt_box().grow(10.0).intersects(_hero_box()):
					_atk_hit[e] = true
					_hit_enemy(e, 4.0, false)
		if _dash_t <= 0.0:
			_vel.x = _face * RUN * 0.6
			_light_dash = false
	else:
		if move != 0.0 and _atk_t <= 0.1:
			_face = move
		_vel.x = _run_physics(move, delta)
		_vel.y = minf(_vel.y + GRAV * delta, 1150.0)
	if _ground:
		_coyote = 0.1
		_air_dash = true
	if _jump_buf > 0.0 and _coyote > 0.0 and _heal_t < 0.0:
		_vel.y = JUMP_V
		_ground = false
		_coyote = 0.0
		_jump_buf = 0.0
		_anim.jumped()
		EventBus.sound_requested.emit("hero_jump")
	var fall_v := _vel.y
	var prev_y := hero_pos.y
	hero_pos += _vel * delta
	hero_pos.x = clampf(hero_pos.x, bound_l(), bound_r())
	_ground = false
	if hero_pos.y >= FLOOR_Y:
		hero_pos.y = FLOOR_Y
		_vel.y = 0.0
		_ground = true
	for rim in platforms:
		if _vel.y >= 0.0 and prev_y <= rim.position.y + 1.0 and hero_pos.y >= rim.position.y and hero_pos.x > rim.position.x and hero_pos.x < rim.end.x and not Input.is_action_pressed("move_down"):
			hero_pos.y = rim.position.y
			_vel.y = 0.0
			_ground = true
	# the camera follows in wide levels and frames the locked fight
	var cam_target := clampf(hero_pos.x - 560.0, 0.0, level_width - 1280.0) if _exploring else clampf(center_x() - 640.0, 0.0, maxf(0.0, level_width - 1280.0))
	_cam = lerpf(_cam, cam_target, minf(1.0, delta * 5.0))
	if _ground and not _was_ground:
		_land = 1.0
		_anim.landed(fall_v)
		if fall_v > 700.0:
			_land_lock = 0.09 # a hard landing: the knees take it
		for k in 6:
			_fx.append({"kind": "dust", "pos": hero_pos + Vector2(randf_range(-16, 16), -4), "vel": Vector2(randf_range(-160, 160), randf_range(-160, -40)), "t": 0.0, "life": 0.45, "size": randf_range(4, 8)})
	elif _ground and absf(_vel.x) > 200.0 and int(_t * 9.0) != int((_t - delta) * 9.0):
		_fx.append({"kind": "dust", "pos": hero_pos + Vector2(-_face * 10.0, -4), "vel": Vector2(-_face * 60.0, -60.0), "t": 0.0, "life": 0.35, "size": 4.0})
	_was_ground = _ground
	_anim.attack = 1.0 - _atk_t / 0.22 if _atk_t > 0.0 else (1.0 - _blade_t / 0.35 if _blade_t > 0.0 else -1.0)
	_anim.update(delta, _anim_name(), _vel, _face, RUN, _ground)
	# the slash hits during its first frames
	if _atk_t > 0.12:
		var box := _attack_box()
		for e in _enemies:
			if not _atk_hit.has(e) and e.state != "enter" and e.hurt_box().intersects(box):
				_atk_hit[e] = true
				_hit_enemy(e, 1.0, _atk_dir == "down")


## Ground and air feel: speed builds up and runs out with a short slide, turning at speed skids,
## the air keeps the momentum of the jump, and a hard landing slows the first steps.
func _run_physics(move: float, delta: float) -> float:
	_skid = maxf(0.0, _skid - delta)
	_land_lock = maxf(0.0, _land_lock - delta)
	var v := _vel.x
	var target := move * RUN * (0.5 if _land_lock > 0.0 else 1.0)
	if _ground and move != 0.0 and absf(v) > RUN * 0.55 and signf(move) != signf(v) and _skid <= 0.0:
		_skid = 0.14
		for k in 5:
			_fx.append({"kind": "dust", "pos": hero_pos + Vector2(signf(v) * 14.0, -4), "vel": Vector2(signf(v) * randf_range(60, 200), randf_range(-140, -40)), "t": 0.0, "life": 0.4, "size": randf_range(4, 7)})
	var rate := 0.0
	if not _ground:
		rate = 2300.0 if move != 0.0 else 650.0
	elif move == 0.0:
		rate = 3200.0
	elif _skid > 0.0:
		rate = 4600.0
	else:
		rate = 3000.0
	return move_toward(v, target, rate * delta)


## Which animation the hero's state asks for.
func _anim_name() -> String:
	if _hp <= 0:
		return "ko"
	if _blade_t > 0.0:
		return "blade"
	if _heal_t >= 0.0:
		return "heal"
	if _invuln > 1.0:
		return "hurt"
	if _dash_t > 0.0:
		return "dash"
	if _atk_t > 0.0:
		return ("attack%d" % maxi(_combo, 1)) if _atk_dir == "side" else ("attack_up" if _atk_dir == "up" else "attack_down")
	if not _ground:
		return "jump" if _vel.y < 0.0 else "fall"
	if _skid > 0.0:
		return "skid"
	if absf(_vel.x) > 30.0:
		return "run"
	if _land > 0.5:
		return "land"
	return "idle"


## Turns to the closest enemy within reach, in front or behind, before a hit lands.
func _face_nearest(reach := 300.0) -> void:
	var best := reach
	for e in _enemies:
		if e.dead or e.state == "enter":
			continue
		var c := e.center()
		var d := absf(c.x - hero_pos.x)
		if d < best and absf(c.y - hero_center().y) < 220.0:
			best = d
			if d > 4.0:
				_face = signf(c.x - hero_pos.x)


func _start_attack() -> bool:
	if _atk_cd > 0.0 or _heal_t >= 0.0:
		return false
	_atk_dir = "up" if Input.is_action_pressed("move_up") else ("down" if Input.is_action_pressed("move_down") and not _ground else "side")
	_atk_t = 0.22
	_atk_cd = 0.3
	_atk_buf = 0.0
	# a combo: each hit in a row moves differently; the hero always turns to the enemy he is hitting
	_combo = (_combo % 3) + 1 if _combo_t > 0.0 else 1
	_combo_t = 0.55
	_face_nearest()
	_anim.start_attack(_combo)
	if _combo == 3 and _ground and _atk_dir == "side":
		_vel.x += _face * 220.0 # the third hit steps in
	_atk_hit.clear()
	EventBus.sound_requested.emit("slash")
	return true


func _attack_box() -> Rect2:
	var c := hero_center()
	match _atk_dir:
		"up":
			return Rect2(c + Vector2(-48, -140), Vector2(96, 130))
		"down":
			return Rect2(c + Vector2(-48, 10), Vector2(96, 120))
	return Rect2(c + Vector2(0.0 if _face > 0.0 else -115.0, -55.0), Vector2(115, 95))


func _hit_enemy(e: ArenaEnemy, dmg: float, pogo: bool) -> void:
	if e.dead:
		return # already beaten: hitting him again would restart the hit-stop forever (powers fire during it)
	if e.kind == "bomb":
		e.dead = true # a slashed bomb fizzles out
	else:
		e.take_hit(dmg, hero_pos.x)
	_ink = mini(MAX_INK, _ink + 1)
	_freeze = 0.05
	_fx.append({"kind": "spark", "pos": e.center().lerp(hero_center(), 0.3), "t": 0.0, "life": 0.25, "size": 1.0})
	for k in 6:
		_fx.append({"kind": "ink", "pos": e.center(), "vel": Vector2(randf_range(-260, 260), randf_range(-320, -60)), "t": 0.0, "life": 0.6, "size": randf_range(3, 7)})
	EventBus.sound_requested.emit("hit")
	if pogo:
		_vel.y = -760.0
		_air_dash = true
	elif _atk_dir == "side":
		_vel.x -= _face * 140.0
	if e.dead:
		_kill_fx(e)


func _kill_fx(e: ArenaEnemy) -> void:
	_freeze = 0.1 if e.kind != "brute" else 0.18
	_white = 0.35 if e.kind != "brute" else 0.7
	shake(6.0 if e.kind != "brute" else 14.0)
	_fx.append({"kind": "spark", "pos": e.center(), "t": 0.0, "life": 0.4, "size": 2.0 if e.kind == "brute" else 1.4})
	for k in 14:
		_fx.append({"kind": "paper", "pos": e.center(), "vel": Vector2(randf_range(-380, 380), randf_range(-480, -80)), "t": 0.0, "life": 1.2, "size": randf_range(4, 9)})
	_say(["SPLAT!", "POW!", "KRAK!", "BLAM!"][randi() % 4], e.center() + Vector2(0, -50), GOLD, 42)
	EventBus.sound_requested.emit("kill")
	if e.kind != "bomb" and e.kind != "narrator":
		_corpses.append({"x": e.pos.x, "kind": e.kind, "dir": e.dir})
		if _corpses.size() > 24:
			_corpses.pop_front()


func _hurt(from_x: float) -> void:
	if _invuln > 0.0 or _dash_t > 0.0 or not _phase in ["wave", "wave_intro", "explore"]:
		return
	_anim.hurt()
	_hp -= 1
	if _hp <= 0 and _narrator != null and _narrator.dead:
		_hp = 1 # the boss fell on this very frame: the hero's blow counts, he stays on his feet
	_invuln = 1.3
	_heal_t = -1.0
	_hurt_flash = 1.0
	_freeze = 0.14
	shake(12.0)
	var away := signf(hero_pos.x - from_x)
	if away == 0.0:
		away = -_face
	_vel = Vector2(away * 380.0, -420.0)
	EventBus.sound_requested.emit("hero_hurt")
	if _hp <= 0:
		if _relay_round():
			_phase = "the_end"
			_pt = 0.0
		elif checkpoints:
			_phase = "retry"
			_pt = 0.0
			_say("TRY AGAIN!", hero_center() + Vector2(0, -60), RED, 56)
			EventBus.sound_requested.emit("hero_ko")
		else:
			_phase = "lost"
			_pt = 0.0
			_say("NOOO!", hero_center() + Vector2(0, -60), RED, 60)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or event.echo:
		return
	if not _phase in ["wave", "wave_intro", "explore"]:
		return
	if not event.pressed:
		if event.is_action("jump") and _vel.y < -300.0:
			_vel.y *= 0.45 # short hop
		return
	# the InputMap: Z / Space jump, J attack, K dash, L Light Blade, F heal
	if event.is_action("jump"):
		_jump_buf = 0.12
	elif event.is_action("attack"):
		if not _start_attack():
			_atk_buf = 0.2
	elif event.is_action("dash"):
		if _dash_cd <= 0.0 and (_ground or _air_dash) and _heal_t < 0.0:
			_dash(false)
	elif event.is_action("power"):
		_power()
	elif event.is_action("heal"):
		if _ink >= 6 and _ground and _hp < max_hp and _heal_t < 0.0:
			_heal_t = 0.0
	else:
		return
	get_viewport().set_input_as_handled()


func _dash(light: bool) -> void:
	_dash_t = 0.16 if not light else 0.24
	_dash_cd = 0.45
	_vel.x = _face * (DASH_V if not light else 1500.0)
	_vel.y = 0.0
	_light_dash = light
	_atk_hit.clear()
	if not _ground:
		_air_dash = false
	EventBus.sound_requested.emit("dash")


func _power() -> void:
	_face_nearest()
	if _ink < 3:
		_say("NEED 3 INK", hero_center() + Vector2(0, -70), Color("8d99ae"), 30)
		return
	_ink -= 3
	match _hero_kind() - 1:
		-1:
			# LIGHT BLADE: one huge arc of light in front of the pulp hero
			_blade_t = 0.35
			_anim.start_attack(3)
			_atk_dir = "side"
			_atk_t = 0.22
			_fx.append({"kind": "bigslash", "pos": hero_center(), "dir": _face, "t": 0.0, "life": 0.35})
			var reach := Rect2(hero_center() + Vector2(0.0 if _face > 0.0 else -260.0, -110.0), Vector2(260, 190))
			for e in _enemies:
				if e.state != "enter" and e.hurt_box().intersects(reach):
					_hit_enemy(e, 4.0, false)
			shake(9.0)
			_say("LIGHT BLADE!", hero_center() + Vector2(0, -80), GOLD, 46)
			EventBus.sound_requested.emit("power_prism")
		0:
			_slow = 4.0
			_say("DEDUCTION!", hero_center() + Vector2(0, -70), Color("c2a878"), 46)
			EventBus.sound_requested.emit("power_deduction")
		1:
			_dash(true)
			_invuln = maxf(_invuln, 0.3)
			_say("LIGHT DASH!", hero_center() + Vector2(0, -70), Color("f77f00"), 46)
			EventBus.sound_requested.emit("power_dash")
		2:
			var y := hero_center().y
			var x0 := hero_pos.x
			var x1 := _lock_r + 120.0 if _face > 0.0 else _lock_l - 120.0
			_beams.append({"from": Vector2(x0, y), "to": Vector2(x1, y), "t": 0.35})
			var band := Rect2(Vector2(minf(x0, x1), y - 40.0), Vector2(absf(x1 - x0), 80.0))
			for e in _enemies:
				if e.state != "enter" and e.hurt_box().intersects(band):
					_hit_enemy(e, 5.0, false)
			shake(8.0)
			_say("PRISM CANNON!", hero_center() + Vector2(0, -70), Color("2ec4b6"), 46)
			EventBus.sound_requested.emit("power_prism")


# --- enemies, hazards, effects ---------------------------------------------------------------

func _update_world(delta: float) -> void:
	var et := delta * enemy_speed()
	for p in _pending:
		p["delay"] = float(p["delay"]) - et
		if float(p["delay"]) <= 0.0:
			p["mark"] = float(p["mark"]) - et
	var ready: Array[Dictionary] = []
	for p in _pending:
		if float(p["delay"]) <= 0.0 and float(p["mark"]) <= 0.0:
			ready.append(p)
	for p in ready:
		_pending.erase(p)
		var e := ArenaEnemy.new(String(p["kind"]), p["pos"])
		if e.kind == "narrator":
			e.hp = _narrator_hp() * boss_hp_scale
			e.max_hp = e.hp
			e.state = "hover"
			_narrator = e
			if _boss_carry > 0.0:
				e.hp = _boss_carry
				_boss_carry = -1.0
			_say(narrator_line, Vector2(center_x(), 220), Color("c77dff"), 40)
			_white = maxf(_white, 0.6)
			shake(14.0)
			EventBus.sound_requested.emit("narrator_attack")
		elif e.kind in ["baron", "twin"]:
			e.hp *= boss_hp_scale
			e.max_hp = e.hp
			e.pos.y = FLOOR_Y - 520.0 # he drops in from the flies
			_narrator = e
			if _boss_carry > 0.0:
				e.hp = _boss_carry
				_boss_carry = -1.0
		elif not e.flying():
			e.pos.y = FLOOR_Y - (520.0 if e.kind == "brute" else 260.0) # drops onto the stage
		_enemies.append(e)
		EventBus.sound_requested.emit("enemy_spawn")
	for e in _enemies:
		e.update(et, self)
		if not e.dead and e.hits(_hero_box()):
			_hurt(e.pos.x)
	var dead: Array[ArenaEnemy] = []
	for e in _enemies:
		if e.dead:
			dead.append(e)
	for e in dead:
		_enemies.erase(e)
		if e == _narrator:
			_narrator = null
			_enemies.clear()
			_pending.clear()
			_freeze = 0.55
			_white = 1.0
			shake(22.0)
			for k in 40:
				var ang := randf() * TAU
				_fx.append({"kind": "paper", "pos": e.center(), "vel": Vector2.from_angle(ang) * randf_range(250, 700), "t": 0.0, "life": 1.6, "size": randf_range(5, 11)})
			_fx.append({"kind": "spark", "pos": e.center(), "t": 0.0, "life": 0.6, "size": 3.5})
			_win()
	for w in _waves:
		w["x"] = float(w["x"]) + float(w["dir"]) * 470.0 * et
		w["life"] = float(w["life"]) - et
		if absf(float(w["x"]) - hero_pos.x) < 26.0 and hero_pos.y > FLOOR_Y - 40.0:
			_hurt(float(w["x"]) - float(w["dir"]) * 10.0)
	_waves = _waves.filter(func(w: Dictionary) -> bool: return float(w["life"]) > 0.0 and float(w["x"]) > bound_l() - 40.0 and float(w["x"]) < bound_r() + 40.0)
	for d in _drops:
		if float(d["warn"]) > 0.0:
			d["warn"] = float(d["warn"]) - et
			continue
		d["y"] = float(d["y"]) + 1100.0 * et
		if Rect2(float(d["x"]) - 16.0, float(d["y"]) - 30.0, 32.0, 60.0).intersects(_hero_box()):
			d["y"] = 9999.0
			_hurt(float(d["x"]))
	_drops = _drops.filter(func(d: Dictionary) -> bool: return float(d["y"]) < FLOOR_Y)
	for b in _beams:
		b["t"] = float(b["t"]) - delta


func _update_fx(delta: float) -> void:
	for f in _fx:
		f["t"] = float(f["t"]) + delta
		if f.has("vel"):
			f["vel"] = (f["vel"] as Vector2) + Vector2(0, 900.0 * delta)
			f["pos"] = (f["pos"] as Vector2) + (f["vel"] as Vector2) * delta
	_fx = _fx.filter(func(f: Dictionary) -> bool: return float(f["t"]) < float(f["life"]))
	_beams = _beams.filter(func(b: Dictionary) -> bool: return float(b["t"]) > 0.0)


func _say(text: String, at: Vector2, col: Color, fs := 44) -> void:
	_fx.append({"kind": "word", "text": text, "pos": at, "col": col, "fs": fs, "t": 0.0, "life": 1.1})


# --- drawing ---------------------------------------------------------------------------------

func _bg_layer(key: String, par: float, off: Vector2, mod := Color.WHITE) -> bool:
	if not _bg.has(key):
		return false
	var tex: Texture2D = _bg[key]
	var sc := 720.0 / tex.get_height()
	var w := tex.get_width() * sc
	var x := -_cam * par + off.x
	if w <= 1281.0:
		draw_texture_rect(tex, Rect2(Vector2(off.x * 0.5, off.y * 0.5), Vector2(1280, 720)), false, mod)
		return true
	x = -fposmod(_cam * par, maxf(w - 1280.0, 1.0)) if par < 1.0 else -_cam * par
	draw_texture_rect(tex, Rect2(Vector2(x, 0) + off, Vector2(w, 720)), false, mod)
	return true


func _draw() -> void:
	var shake_off := Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake)) if _shake > 0.0 else Vector2.ZERO
	var off := shake_off - Vector2(_cam, 0)
	draw_set_transform(shake_off)
	var glow := 1.0 + 0.15 * sin(_t * 1.3) + (0.3 if intensity >= 3 else 0.0)
	var art := false
	match stage:
		"hall":
			art = _bg_layer("hall_far", 0.0, shake_off)
			if art:
				_bg_layer("hall_mid", 0.45, shake_off)
		"dark":
			art = _bg_layer("arena_dark", 0.0, shake_off)
			if art:
				_bg_layer("arena_mid", 0.0, shake_off)
		_:
			art = _bg_layer("arena_far", 0.0, shake_off)
			if art:
				_bg_layer("arena_mid", 0.0, shake_off)
	if not art:
		ArenaArt.stage_back(self, size, _t, glow)
	draw_set_transform(off)
	if stage == "opera" and _narrator == null:
		draw_set_transform(shake_off)
		_draw_balcony()
		draw_set_transform(off)
	if stage == "dark" and caged_heroes:
		_draw_cages(off)
	if stage == "hall":
		_draw_hall_floor(off)
	elif not art:
		ArenaArt.stage_floor(self, size)
	for c in _corpses:
		_draw_corpse(c, off)
	draw_set_transform(off)
	ArenaArt.gate(self, _lock_l - 34.0, _gate, _t)
	ArenaArt.gate(self, _lock_r + 34.0, _gate, _t)
	# spawn marks: ink splashes before an enemy drops in
	for p in _pending:
		if float(p["delay"]) <= 0.0:
			var k := 1.0 - float(p["mark"]) / 0.7
			var pp: Vector2 = p["pos"]
			var at := Vector2(pp.x, FLOOR_Y) if pp.y >= FLOOR_Y - 1.0 else pp
			draw_circle(at, 10.0 + 40.0 * k, Color(0.1, 0.05, 0.15, 0.6))
			draw_arc(at, 12.0 + 44.0 * k, 0.0, TAU, 24, Color(1, 0.85, 0.5, 0.6), 3.0)
	for w in _waves:
		var x := float(w["x"])
		var pts := PackedVector2Array([Vector2(x - 26, FLOOR_Y), Vector2(x - 10, FLOOR_Y - 40), Vector2(x + 2, FLOOR_Y - 22), Vector2(x + 12, FLOOR_Y - 46), Vector2(x + 26, FLOOR_Y)])
		draw_colored_polygon(pts, Color("2b1d3a"))
		draw_polyline(pts, Color(1, 0.85, 0.5, 0.8), 2.0)
	for d in _drops:
		var dx := float(d["x"])
		if float(d["warn"]) > 0.0:
			draw_set_transform(Vector2(dx, FLOOR_Y) + off, 0.0, Vector2(1.0, 0.25))
			draw_circle(Vector2.ZERO, 26.0, Color(0.6, 0.1, 0.3, 0.35 + 0.25 * sin(_t * 20.0)))
			draw_set_transform(off)
		else:
			var dy := float(d["y"])
			draw_colored_polygon(PackedVector2Array([Vector2(dx, dy - 34), Vector2(dx + 14, dy), Vector2(dx, dy + 12), Vector2(dx - 14, dy)]), Color("3c096c"))
			draw_line(Vector2(dx, dy - 80), Vector2(dx, dy - 34), Color(0.5, 0.2, 0.8, 0.4), 4.0)
	for e in _enemies:
		e.draw(self, _t, off)
		draw_set_transform(off)
	_draw_hero(off)
	draw_set_transform(off)
	for b in _beams:
		var k := float(b["t"]) / 0.35
		draw_line(b["from"], b["to"], Color(1, 1, 1, 0.6 * k), 70.0 * k)
		draw_line(b["from"], b["to"], Color(0.55, 1.0, 0.95, k), 34.0 * k)
	for f in _fx:
		_draw_fx(f, off)
		draw_set_transform(off)
	# drifting paper confetti in the light
	for p in _paper:
		var px := fposmod(p.x + sin(_t * 0.6 + p.z * 9.0) * 30.0, size.x)
		var py := fposmod(p.y + _t * (18.0 + p.z * 22.0), size.y)
		draw_set_transform(Vector2(px, py) + off, _t * 2.0 + p.z * 6.0, Vector2.ONE)
		draw_rect(Rect2(-3, -1.5, 6, 3), Color(1, 0.95, 0.85, 0.35 + 0.3 * p.z))
	draw_set_transform(shake_off)
	var near := false
	match stage:
		"hall":
			# see-through foreground drapes: nothing in the fight may hide behind them
			near = _bg_layer("hall_near", 1.15, shake_off, Color(1, 1, 1, 0.55))
		_:
			near = _bg_layer("arena_near", 0.0, shake_off)
	if not near:
		ArenaArt.curtains(self, size, _t)
	ArenaArt.foreground(self, size)
	draw_set_transform(Vector2.ZERO)
	if _slow > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.75, 0.6, 0.3, 0.12))
	if _hurt_flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.8, 0.0, 0.1, 0.22 * _hurt_flash))
	if _white > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.5 * _white))
	_draw_hud()
	if _phase == "explore":
		if _pt < 6.0:
			ComicArt.shout(self, "GO  >>", Vector2(1100, 300), 48, GOLD, 10, 0.0)
		# the objective, and the controls for the first seconds
		var obj := "REACH THE END OF THE LIBRARY"
		var ow := FONT_SHOUT.get_string_size(obj, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
		draw_string(FONT_SHOUT, Vector2(640 - ow * 0.5, 120), obj, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, PAPER)
		if _pt < 10.0:
			draw_string(FONT_BODY, Vector2(210, 700), "WASD / ARROWS move   Z / SPACE jump   J attack (+UP, or +DOWN in the air)   K dash   L power   F heal", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, PAPER)
	elif _phase == "wave" and _narrator == null:
		# the objective while there is no boss bar: how many are left on stage
		var left := _enemies.size() + _pending.size()
		if left > 0:
			var obj2 := "CLEAR THE STAGE  (%d left)" % left
			var ow2 := FONT_SHOUT.get_string_size(obj2, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
			draw_string_outline(FONT_SHOUT, Vector2(640 - ow2 * 0.5, 120), obj2, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, 6, INK)
			draw_string(FONT_SHOUT, Vector2(640 - ow2 * 0.5, 120), obj2, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, PAPER)
	match _phase:
		"round_intro":
			_draw_round_card()
		"wave_intro":
			var k := clampf(_pt / 0.3, 0.0, 1.0)
			ComicArt.shout(self, "WAVE %d" % _global_wave(), Vector2(640, 300), int(90 * k) + 1, GOLD, 14, -0.04)
		"the_end":
			_draw_the_end()
		"ko":
			_draw_ko()
		"won":
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.96, 0.75, clampf(_pt * 0.6, 0.0, 1.0)))
			ComicArt.shout(self, win_text, Vector2(640, 330), 96, GOLD, 14, -0.04)
		"lost":
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.3, 0.02, 0.05, clampf(_pt * 0.5, 0.0, 0.85)))


## The library hall's stone floor and ledges.
func _draw_hall_floor(off: Vector2) -> void:
	draw_set_transform(Vector2(0, off.y))
	draw_rect(Rect2(0, FLOOR_Y, 1280, 120), Color("0e1416"))
	draw_line(Vector2(0, FLOOR_Y), Vector2(1280, FLOOR_Y), Color("c79a55"), 3.0)
	draw_set_transform(off)
	for r in platforms:
		var ledge := Rect2(r.position, Vector2(r.size.x, 22))
		draw_rect(ledge.grow(3.0), Color("06090a"))
		draw_rect(ledge, Color("23302f"))
		draw_line(ledge.position, Vector2(ledge.end.x, ledge.position.y), Color(1, 0.8, 0.5, 0.7), 3.0)
		for k in 3:
			draw_line(Vector2(r.position.x + 12 + k * r.size.x / 3.0, r.position.y + 22), Vector2(r.position.x + 20 + k * r.size.x / 3.0, r.position.y + 60), Color("06090a"), 4.0)


## The three captured heroes hanging in ink cages above the Narrator's stage.
func _draw_cages(off: Vector2) -> void:
	for i in 3:
		var cx: float = [430.0, 640.0, 850.0][i]
		var cy := 230.0 + sin(_t * 1.5 + i) * 6.0 - (40.0 if i == 1 else 0.0)
		draw_line(Vector2(cx, 0), Vector2(cx, cy - 60), INK, 4.0)
		ComicArt.hero_bust(self, i + 1, Vector2(cx, cy - 6), 0.26, "scared", _t)
		ComicArt.cage(self, Vector2(cx, cy), 0.42)
		draw_set_transform(off)


func _global_wave() -> int:
	var n := 0
	for r in _round:
		n += waves[r].size()
	return n + _wave + 1


func _draw_balcony() -> void:
	# the Narrator conducting from his balcony (until he comes down himself)
	var b := Vector2(640, 150)
	if _bg.has("arena_far"):
		# on the painted stage he floats in a spotlight instead of standing on a drawn balcony
		draw_texture_rect(ArenaArt.TEX_GLOW, Rect2(b + Vector2(0, 110) - Vector2(160, 160), Vector2(320, 320)), false, Color(1, 0.8, 0.5, 0.35))
	else:
		ArenaArt.poly(self, PackedVector2Array([b + Vector2(-110, 40), b + Vector2(110, 40), b + Vector2(90, 90), b + Vector2(-90, 90)]), Color("2a1a2e"), 4.0)
		draw_line(b + Vector2(-110, 40), b + Vector2(110, 40), GOLD, 3.0)
	if (_narrator != null and _narrator.kind == "narrator") or (_last_wave() and _phase == "wave" and boss_name == "THE NARRATOR"):
		return
	var beat := sin(_t * (5.0 if _phase == "wave" else 2.5))
	# below the curtain's valance on the painted stage (it hides anything higher)
	var feet := b + (Vector2(0, 200) if _bg.has("arena_far") else Vector2(0, 70))
	if Sprites.draw(self, "masked_villain", feet, 190.0, -1.0, Color.WHITE, 1.0 + sin(_t * 2.0) * 0.01, beat * 0.03):
		return # the masked villain conducts his choir (his face stays hidden until the reveal)
	ComicArt.narrator(self, b + Vector2(0, -18), 0.42, 1.0, "grin", _t)
	var hand := b + Vector2(30, 20)
	var tip := hand + Vector2.from_angle(-1.2 + beat * 0.6) * 46.0
	draw_line(hand, tip, INK, 4.0)
	draw_line(hand, tip, PAPER, 2.0)
	if _phase == "wave_intro" or _phase == "the_end":
		for k in 3:
			var nk := fposmod(_t * 0.8 + k * 0.33, 1.0)
			draw_circle(tip + Vector2(20 + nk * 60.0, -nk * 50.0), 6.0, Color(1, 0.9, 0.6, 1.0 - nk))
			draw_line(tip + Vector2(25 + nk * 60.0, -nk * 50.0), tip + Vector2(25 + nk * 60.0, -nk * 50.0 - 20.0), Color(1, 0.9, 0.6, 1.0 - nk), 2.0)


func _draw_corpse(c: Dictionary, off: Vector2) -> void:
	var x := float(c["x"])
	var big := String(c["kind"]) == "brute"
	draw_set_transform(Vector2(x, FLOOR_Y - 4) + off, 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 46.0 if big else 26.0, Color("120c18"))
	draw_set_transform(off)
	if big:
		var dome := PackedVector2Array()
		for k in 11:
			var ang := PI + k * PI / 10.0
			dome.append(Vector2(x + cos(ang) * 60.0, FLOOR_Y + sin(ang) * 34.0))
		draw_colored_polygon(dome, Color("6e2a16"))
		draw_polyline(dome, INK, 3.0)
	else:
		var lump := PackedVector2Array([Vector2(x - 30, FLOOR_Y), Vector2(x - 18, FLOOR_Y - 16), Vector2(x + 6, FLOOR_Y - 20), Vector2(x + 28, FLOOR_Y)])
		draw_colored_polygon(lump, Color("241b33"))
		draw_polyline(lump, INK, 3.0)
		var mk := Vector2(x + 14.0 * float(c["dir"]), FLOOR_Y - 14)
		draw_set_transform(mk + off, 0.5 * float(c["dir"]), Vector2(1.0, 0.8))
		draw_circle(Vector2.ZERO, 12.0, INK)
		draw_circle(Vector2.ZERO, 10.0, Color("e9dccb"))
		draw_line(Vector2(-5, -2), Vector2(5, -3), INK, 2.0)
		draw_set_transform(off)


func _draw_hero(off: Vector2) -> void:
	if _phase == "ko":
		return
	var kind: int = _hero_kind()
	var pose := "idle"
	if _heal_t >= 0.0:
		pose = "heal"
	elif _invuln > 1.0:
		pose = "hurt"
	elif _dash_t > 0.0:
		pose = "dash"
	elif _atk_t > 0.0:
		pose = "attack" if _atk_dir == "side" else ("attack_up" if _atk_dir == "up" else "attack_down")
	elif not _ground:
		pose = "jump" if _vel.y < 0.0 else "fall"
	elif absf(_vel.x) > 30.0:
		pose = "run"
	var blink := _invuln > 0.0 and int(_t * 18.0) % 2 == 0
	if _dash_t > 0.0:
		for k in 3:
			ArenaArt.hero(self, kind, hero_pos + off + Vector2(-_face * (k + 1) * 26.0, 0), _face, "dash", _t, 0.6, ArenaArt.HERO_SCALE)
	if not blink and (kind != 0 or not _anim.draw(self, hero_pos + off + Vector2(0, 4), 128.0 * ArenaArt.HERO_SCALE)):
		ArenaArt.land_squash = _land
		ArenaArt.hero(self, kind, hero_pos + off, _face, pose, _t, 0.0, ArenaArt.HERO_SCALE)
		ArenaArt.land_squash = 0.0
	draw_set_transform(off)
	if _atk_t > 0.0:
		var k := 1.0 - _atk_t / 0.22
		# each hit of the combo cuts on its own line: high, low backhand, then a big flat one
		var dir := Vector2(_face, [-0.2, 0.42, -0.04][clampi(_combo - 1, 0, 2)]).normalized()
		if _atk_dir == "up":
			dir = Vector2(0, -1)
		elif _atk_dir == "down":
			dir = Vector2(0, 1)
		ArenaArt.slash(self, hero_center() + dir * 18.0, dir, k, _combo == 3 and _atk_dir == "side")
	if _heal_t >= 0.0:
		draw_arc(hero_center(), 40.0, -PI * 0.5, -PI * 0.5 + TAU * _heal_t / 0.6, 24, Color("8ef0ff"), 5.0)


func _draw_fx(f: Dictionary, off: Vector2) -> void:
	var k := float(f["t"]) / float(f["life"])
	match String(f["kind"]):
		"spark":
			ArenaArt.hit_spark(self, f["pos"], k, float(f["size"]))
		"ink":
			draw_circle(f["pos"], maxf(0.5, float(f["size"]) * (1.0 - k)), Color(0.15, 0.06, 0.2, 1.0 - k))
		"dust":
			draw_circle(f["pos"], maxf(0.5, float(f["size"]) * (1.0 + k)), Color(0.85, 0.78, 0.68, 0.35 * (1.0 - k)))
		"paper":
			draw_set_transform((f["pos"] as Vector2) + off, float(f["t"]) * 9.0, Vector2.ONE)
			draw_rect(Rect2(-float(f["size"]), -float(f["size"]) * 0.6, float(f["size"]) * 2.0, float(f["size"]) * 1.2), Color(1, 0.97, 0.88, 1.0 - k))
		"ring":
			draw_arc(f["pos"], 20.0 + 70.0 * k, 0.0, TAU, 32, Color(f["col"]).lerp(Color(1, 1, 1, 0), k), 6.0)
		"boom":
			var r := float(f["r"]) * (0.4 + 0.8 * k)
			draw_circle(f["pos"], r, Color(1, 0.6, 0.2, 0.6 * (1.0 - k)))
			draw_circle(f["pos"], r * 0.6, Color(1, 0.95, 0.7, 0.8 * (1.0 - k)))
		"bigslash":
			ArenaArt.slash(self, (f["pos"] as Vector2) + Vector2(float(f["dir"]) * 60.0, 0), Vector2(float(f["dir"]), 0), k, true)
			ArenaArt.slash(self, (f["pos"] as Vector2) + Vector2(float(f["dir"]) * 110.0, -10), Vector2(float(f["dir"]), -0.2).normalized(), k, true)
		"word":
			var s := 1.0 + 0.4 * (1.0 - minf(float(f["t"]) * 6.0, 1.0))
			ComicArt.shout(self, String(f["text"]), (f["pos"] as Vector2) + off + Vector2(0, -30.0 * k), int(f["fs"]), Color(f["col"]), 10, -0.05, s)


## The painted pulp hero portrait for the HUD medallion (the code-drawn bust if it is missing).
var _portrait: Texture2D = load("res://assets/editions/portraits/hero.png") if ResourceLoader.exists("res://assets/editions/portraits/hero.png") else null


func _draw_hud() -> void:
	var kind: int = _hero_kind()
	# portrait medallion, masks and the ink meter (top left)
	var pc := Vector2(70, 72)
	draw_circle(pc, 44.0, INK)
	draw_circle(pc, 39.0, Color("2d1420"))
	if kind == 0 and _portrait != null:
		ComicArt.portrait_disc(self, _portrait, pc, 39.0)
	else:
		ComicArt.hero_bust(self, kind, pc + Vector2(0, -6), 0.32, "determined", _t)
	draw_arc(pc, 42.0, 0.0, TAU, 32, GOLD, 3.0)
	for i in max_hp:
		var m := Vector2(130 + i * 34, 52)
		var full := i < _hp
		var drop := PackedVector2Array([m + Vector2(0, -16), m + Vector2(11, 2), m + Vector2(0, 14), m + Vector2(-11, 2)])
		draw_colored_polygon(drop, Color("f8f4ea") if full else Color(0.2, 0.2, 0.25, 0.8))
		draw_polyline(PackedVector2Array([drop[0], drop[1], drop[2], drop[3], drop[0]]), INK, 3.0)
		if full:
			draw_circle(m + Vector2(-3, -2), 3.0, INK)
	for i in MAX_INK:
		var r := Rect2(Vector2(126 + i * 19, 80), Vector2(15, 16))
		draw_rect(r, INK)
		draw_rect(r.grow(-2.0), Color("2ec4b6") if i < _ink else Color(0.15, 0.15, 0.2))
	draw_string(FONT_BODY, Vector2(126, 116), "L %s (3)   F heal (6)" % POWER_BY_KIND[_hero_kind()], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, GOLD if _ink >= 3 else Color("8d99ae"))
	# round, wave, bomb (top right)
	draw_string(FONT_SHOUT, Vector2(930, 46), ("ROUND %d  -  %s" % [_round + 1, ComicArt.HERO_NAMES[kind]]) if fight_title == "" else fight_title, HORIZONTAL_ALIGNMENT_LEFT, 330, 22, GOLD)
	if bomb_left >= 0.0:
		var bs := int(ceil(bomb_left))
		draw_string(FONT_SHOUT, Vector2(930, 82), "BOMB %d:%02d" % [bs / 60, bs % 60], HORIZONTAL_ALIGNMENT_LEFT, -1, 32, RED if bomb_left < 60.0 else PAPER)
	draw_string(FONT_SHOUT, Vector2(1110, 82), "WAVE %d/%d" % [mini(_global_wave(), _total_waves()), _total_waves()], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, PAPER)
	# the Narrator's health (bottom)
	if _narrator != null:
		var bar := Rect2(Vector2(668, 660), Vector2(580, 20))
		draw_string(FONT_SHOUT, Vector2(668, 652), boss_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("c77dff"))
		draw_rect(bar, INK)
		draw_rect(Rect2(bar.position + Vector2(3, 3), Vector2((bar.size.x - 6) * clampf(_narrator.hp / _narrator.max_hp, 0.0, 1.0), bar.size.y - 6)), Color("9d4edd"))
	elif _phase in ["wave", "wave_intro"] and _wave == 0 and _pt < 8.0:
		draw_string(FONT_BODY, Vector2(210, 700), "WASD / ARROWS move   Z / SPACE jump   J attack (+UP, or +DOWN in the air)   K dash   L power   F heal", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, PAPER)


func _card(title: String, lines: Array, col: Color) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.55))
	var panel := Rect2(Vector2(230, 150), Vector2(820, 410))
	draw_rect(Rect2(panel.position + Vector2(8, 8), panel.size), Color(0, 0, 0, 0.5))
	draw_rect(panel, PAPER)
	draw_rect(panel, INK, false, 6.0)
	ComicArt.shout(self, title, Vector2(640, 200), 56, col, 12, -0.03)
	for i in lines.size():
		var s := String(lines[i])
		var w := FONT_BODY.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
		draw_string(FONT_BODY, Vector2(640 - w * 0.5, 470 + i * 32), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, INK)


func _draw_round_card() -> void:
	var kind: int = _hero_kind()
	var lines: Array = []
	if not intro_lines.is_empty():
		lines = intro_lines
	else:
		match _round:
			0:
				lines = ["The Narrator locks the stage and conducts his ink choir.", "Power: L DEDUCTION, %s." % POWER_TEXT[0]]
			1:
				lines = ["The detective cleared %d of 2 waves. TAG IN, NINJA!" % mini(_cleared, 2), "Power: L LIGHT DASH, %s." % POWER_TEXT[1]]
			2:
				lines = ["His shield is cracked %d%%: he is weaker now." % int(crack_share() * 100.0), "Power: L PRISM CANNON, %s." % POWER_TEXT[2]]
	_card(("ROUND %d: %s" % [_round + 1, ComicArt.HERO_NAMES[kind]]) if fight_title == "" else fight_title, lines, GOLD)
	var k := clampf(_pt / 0.4, 0.0, 1.0)
	ArenaArt.hero(self, kind, Vector2(640 - 120 * (1.0 - k), 440), 1.0, "idle", _t, 0.0, 1.85)


func _draw_the_end() -> void:
	# a giant quill comes down on the hero: the Narrator writes the ending
	var k := clampf(_pt / 1.2, 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.1, 0.0, 0.15, 0.6 * k))
	var tip := Vector2(hero_pos.x, lerpf(-200.0, hero_pos.y - 30.0, k * k))
	draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-40, -260), tip + Vector2(40, -260)]), PAPER)
	draw_polyline(PackedVector2Array([tip, tip + Vector2(-40, -260), tip + Vector2(40, -260), tip]), INK, 5.0)
	ComicArt.shout(self, "THE END", Vector2(640, 300), int(70 + 60 * k), Color("c77dff"), 14, -0.05)


func _draw_ko() -> void:
	var kind: int = _hero_kind()
	var cleared_now := clampi(_cleared - 2 * _round, 0, 2)
	_card("%s IS DOWN!" % ComicArt.HERO_NAMES[kind], ["...but %d of 2 waves were cleared: the shield cracks!" % cleared_now, "The next hero takes the stage!"], RED)
	ComicArt.hero_bust(self, kind, Vector2(640, 330), 0.8, "scared", _t)
	ComicArt.shout(self, "CRACK!", Vector2(900, 300), 60, GOLD, 12, 0.15)
