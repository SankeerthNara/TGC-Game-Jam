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
var guards := true ## guarding enemies block blows from the front (off in the cheap edition)
## Solid blocks (bookshelves, walls): the hero lands on them, bumps his head and clings to their sides.
var walls: Array[Rect2] = []
## A level taller than the screen scrolls up to this height (0: no vertical scrolling).
var level_top := 0.0
var floor_y := FLOOR_Y ## the floor of the current fight (enemies, shockwaves, ink rain)
## Separate locked fights in a scrolling level, one per wave: {"at": Rect2 the hero walks into,
## "l": lock left, "r": lock right, "floor": its floor}. Empty: one locked arena at arena_x.
var encounters: Array = []
## Reaching this (after the last fight) ends the level; empty: the level ends with its last wave.
var exit_rect := Rect2()
## Harmless paper bats that hang in the air to be pogoed off (the climb).
var steppers: Array[Vector2] = []
## On-screen tips for the parkour moves: {"at": Rect2, "text": String, "say": comms line}.
var tips: Array = []
## Columns where books fall from the shelves above while the hero climbs: [x, period].
var book_columns: Array = []
## Waypoints through a climb for the test bot (not used by the game itself).
var route: Array[Vector2] = []
var bot_assists := 0
## Chandeliers to stand on: [Rect2, swing amplitude in px]. Added to the platforms; a swinging one
## carries the hero standing on it.
var chandeliers: Array = []
## Hanging lanterns (world positions): the few light sources left; the rest of the stage is dark.
var lamps: Array[Vector2] = []
var _light: LightOverlay
var glows: Array = [] ## extra lights this frame: [world pos, radius, intensity] (orbs, quills)
var _chand_idx: Array[int] = []
var _chand_base: Array[Rect2] = []
var _base_floor := FLOOR_Y ## the solid floor under everything (lower once the Scribe breaks it)
var _floor_broken := false
var _flood := 0.0 ## 0..1: the Narrator's ink flooding the stage floor (his second and third phases)
var _boss_phase := 1
var _cam_y := 0.0
var _steps: Array[ArenaEnemy] = []
var _books: Array[Dictionary] = []
var _book_t := 0.0
var _tip := ""
var _tips_said := {}
var _safe_pos := Vector2(200, FLOOR_Y)
var _exit_open := false
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
	"turn": ["hero_idle"], "blade": ["hero_attack"], "ko": ["hero_hurt"],
	"wallslide": ["hero_jump_6"], "walljump": ["hero_jump_2"], "airdash": ["hero_dash_1", "hero_dash_2", "hero_dash_3"],
	"dive": ["hero_downslash_2", "hero_downslash_3"], "pogo": ["hero_jump_3"],
	"parry": ["hero_blade_1"], "riposte": ["hero_attack3_1", "hero_attack3_2", "hero_attack3_3", "hero_attack3_4"]},
	{"attack_up": "upslash", "attack_down": "downslash"})
var _blade_t := 0.0 ## the Light Blade swing is playing
var _jump_buf := 0.0
# --- parkour: wall slide and wall jump, one air dash, pogo, dive strike
const WALL_SLIDE := 170.0 ## fall speed while sliding down a wall
const WALL_JUMP := Vector2(520.0, -840.0)
var _wall := 0 ## -1 / +1: a wall touching the hero's left / right side
var _wall_side := 0 ## the last wall touched (for the wall jump's coyote time)
var _wall_coyote := 0.0
var _wj_lock := 0.0 ## after a wall jump the push away from the wall can't be steered for a moment
var _sliding := false
var _air_jump := false ## a pogo refreshes one jump in the air
var _dive_t := 0.0 ## > 0: the diagonal dive strike
var _pogo_t := 0.0 ## > 0: just bounced off something (the pogo frames)
var _slowmo := 0.0
var _zoom := 0.0
var _zoom_at := Vector2(640, 360)
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
# --- the parry (tap L), the riposte, posture and the critical strike; hold L for the Light Blade
const PARRY_WINDOW := 0.18
const PARRY_COOLDOWN := 0.32 ## after the window, so the parry can't be spammed
const BLADE_HOLD := 0.3
var _parry_t := 0.0
var _parry_cd := 0.0
var _parry_pose := 0.0
var _riposte := 0.0 ## > 0 after a perfect parry: the next hit is a riposte
var _riposting := false
var _l_hold := -1.0
var _blade_done := false
var _clash := {}
var _hint := ""
var _hint_t := 0.0
var _hints_seen := {}
var _block_say := 0.0
var parries := 0
var ripostes := 0
var criticals := 0

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
	position = Vector2.ZERO
	size = get_viewport_rect().size
	_light = LightOverlay.new()
	add_child(_light)
	if lamps.is_empty() and level_top >= 0.0:
		lamps.assign([Vector2(170, 410), Vector2(1110, 410)] if stage != "hall" else [Vector2(300, 400), Vector2(980, 400)])
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	grab_focus()
	add_to_group("boss_fight")
	_anim.rim = Color(0.75, 1.0, 1.0, 0.6)
	for key in ["hall_far", "hall_mid", "hall_near", "arena_far", "arena_mid", "arena_near", "arena_dark"]:
		# the soft (blurred, hazed) versions keep the background behind the fighters
		for name in [key + "_soft", key]:
			if _bg.has(key):
				break
			for ext in [".jpg", ".png"]:
				var path: String = "res://assets/editions/2k/" + name + ext
				if ResourceLoader.exists(path):
					_bg[key] = load(path)
					break
	if stage == "opera" or stage == "dark":
		platforms.append(ArenaArt.PODIUM)
	for ch: Array in chandeliers:
		_chand_idx.append(platforms.size())
		_chand_base.append(ch[0])
		platforms.append(ch[0])
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
	_exploring = level_width > 1280.0 or level_top < 0.0
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
	for sp in steppers:
		var st_e := ArenaEnemy.new("step", sp)
		st_e.anchor = sp
		st_e.state = "hover"
		_steps.append(st_e)
	_safe_pos = hero_pos
	if _exploring:
		for rm: Array in roamers:
			var e := ArenaEnemy.new(String(rm[0]), rm[1])
			e.state = "hover" if e.flying() else "idle"
			_enemies.append(e)


func _encounter() -> Dictionary:
	if not encounters.is_empty():
		return encounters[mini(_wave, encounters.size() - 1)]
	return {"at": Rect2(arena_x, -9999.0, 99999.0, 99999.0), "l": arena_x - 530.0, "r": arena_x + 530.0, "floor": FLOOR_Y}


func _entered_fight() -> bool:
	var at: Rect2 = _encounter()["at"]
	return at.has_point(hero_pos)


## The climb between the fights: stepping bats, falling books, tips, a safe spot to come back to.
## The Ink Scribe's fake death: a false victory banner, the music drops; then he laughs and breaks the floor.
func scribe_fake_death(e: ArenaEnemy) -> void:
	_say("THE INK SCRIBE IS DEFEATED!", Vector2(640, 250), GOLD, 64)
	_white = 0.8
	shake(14.0)
	intensity = 0
	_invuln = maxf(_invuln, 3.0)
	_waves.clear()
	EventBus.sound_requested.emit("power_solar")


func scribe_laugh(e: ArenaEnemy) -> void:
	_say("...HA. HA HA HA!", e.center() + Vector2(0, -120), Color("c77dff"), 52)
	shake(8.0)
	var d: Node = get_tree().get_first_node_in_group("editions_director")
	if d != null and d.fx != null:
		d.fx.glitch(0.8, 1.2)
	EventBus.sound_requested.emit("glitch")
	var comms: Node = get_tree().get_first_node_in_group("comms")
	if comms != null:
		comms.say("Did you think a story ends that easily? Down we go!", "narrator_evil", 1.5)


## He crashes through the floor: everyone falls into the archive below, and the fight goes on there.
func scribe_break_floor(e: ArenaEnemy) -> void:
	_floor_broken = true
	floor_y = FLOOR_Y + 300.0
	_base_floor = floor_y
	for x in [_lock_l + 160.0, 640.0, _lock_r - 160.0]:
		lamps.append(Vector2(x, FLOOR_Y + 170.0)) # the archive's own lanterns
	_ground = false
	intensity = 3
	_white = 1.0
	shake(24.0)
	_big_hit(e.center(), 0.8)
	for k in 40:
		_fx.append({"kind": "paper", "pos": Vector2(randf_range(_lock_l, _lock_r), FLOOR_Y), "vel": Vector2(randf_range(-300, 300), randf_range(-500, 100)), "t": 0.0, "life": 1.6, "size": randf_range(6, 14)})
	_say("THE FLOOR GIVES WAY!", Vector2(640, 220), PAPER, 48)
	EventBus.sound_requested.emit("explosion")


## The Narrator's phases: the ink flood (the stage floor hurts and throws the hero up, so he lives on
## the podium, the chandeliers and the walls), then the Narrator rises high above the stage.
func _update_flood(delta: float) -> void:
	var ph := _narrator.stage_phase() if _narrator != null and _narrator.kind == "narrator" else 1
	if ph != _boss_phase and _narrator != null and _narrator.kind == "narrator":
		_boss_phase = ph
		var comms: Node = get_tree().get_first_node_in_group("comms")
		if ph == 2:
			_say("THE STAGE FLOODS WITH INK!", Vector2(640, 250), Color("c77dff"), 46)
			shake(12.0)
			EventBus.sound_requested.emit("narrator_attack")
			if comms != null:
				comms.say("Drown in my ink, hero! Stay off my stage!", "narrator_evil", 2.0)
		elif ph == 3:
			_say("HE RISES ABOVE THE STAGE!", Vector2(640, 250), Color("c77dff"), 46)
			if comms != null:
				comms.say("Up here, the story is mine. You'll never reach me!", "narrator_evil", 2.0)
	_flood = move_toward(_flood, 1.0 if _boss_phase >= 2 and _narrator != null else 0.0, delta * 0.6)
	if _flood > 0.6 and _ground and hero_pos.y >= FLOOR_Y - 0.5 and _invuln <= 0.0:
		_hurt(hero_pos.x)
		_vel.y = -820.0 # the ink throws him up: get onto a ledge
		_ground = false
		for k in 10:
			_fx.append({"kind": "ink", "pos": hero_pos + Vector2(randf_range(-20, 20), -4), "vel": Vector2(randf_range(-200, 200), randf_range(-420, -160)), "t": 0.0, "life": 0.6, "size": randf_range(3, 7)})


func _draw_flood(off: Vector2) -> void:
	if _flood <= 0.0:
		return
	draw_set_transform(off)
	var top := FLOOR_Y - 26.0 * _flood
	var pts := PackedVector2Array([Vector2(_lock_l - 80.0, FLOOR_Y + 130.0)])
	for i in 33:
		var x := _lock_l - 80.0 + i * (_lock_r - _lock_l + 160.0) / 32.0
		pts.append(Vector2(x, top + sin(_t * 3.0 + i * 0.7) * 5.0 * _flood))
	pts.append(Vector2(_lock_r + 80.0, FLOOR_Y + 130.0))
	draw_colored_polygon(pts, Color(0.12, 0.03, 0.2, 0.9 * _flood))
	for i in 12:
		var bx := _lock_l + fposmod(i * 97.0 + _t * 30.0, _lock_r - _lock_l)
		draw_circle(Vector2(bx, top + 10.0 + sin(_t * 4.0 + i) * 4.0), 3.0 + (i % 3), Color(0.6, 0.3, 0.9, 0.5 * _flood))


func _update_climb(delta: float) -> void:
	if _ground:
		_safe_pos = hero_pos
	for e in _steps:
		e.update(delta, self)
	# books slip off the shelves above
	_book_t += delta
	for col: Array in book_columns:
		var x := float(col[0])
		var period := float(col[1])
		if fposmod(_book_t, period) < delta and absf(x - hero_pos.x) < 700.0:
			_books.append({"pos": Vector2(x + randf_range(-20, 20), _cam_y - 40.0), "vel": Vector2(0, 120), "spin": randf_range(-6, 6), "a": 0.0, "warn": 0.6})
	for b in _books:
		if float(b["warn"]) > 0.0:
			b["warn"] = float(b["warn"]) - delta
			continue
		b["vel"] = (b["vel"] as Vector2) + Vector2(0, 1300.0 * delta)
		b["pos"] = (b["pos"] as Vector2) + (b["vel"] as Vector2) * delta
		b["a"] = float(b["a"]) + float(b["spin"]) * delta
		if _hero_box().grow(4.0).has_point(b["pos"]):
			b["dead"] = true
			_hurt((b["pos"] as Vector2).x)
	_books = _books.filter(func(b: Dictionary) -> bool: return not b.get("dead", false) and (b["pos"] as Vector2).y < _cam_y + 800.0)
	# tips for the moves, each in a safe spot
	_tip = ""
	for tp: Dictionary in tips:
		if (tp["at"] as Rect2).has_point(hero_pos):
			_tip = String(tp["text"])
			if not _tips_said.has(_tip):
				_tips_said[_tip] = true
				var comms: Node = get_tree().get_first_node_in_group("comms")
				if comms != null and tp.has("say"):
					comms.say(String(tp["say"]), "narrator", 2.5)


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
		var where: String = s[1] if s[1] is String else ""
		var p: Vector2 = s[1] if s[1] is Vector2 else Vector2(640, floor_y)
		match where:
			"L":
				p = Vector2(_lock_l + 110.0, floor_y)
			"R":
				p = Vector2(_lock_r - 110.0, floor_y)
			"C":
				p = Vector2(center_x(), floor_y)
			"AL":
				p = Vector2(_lock_l + 150.0, floor_y - 380.0)
			"AR":
				p = Vector2(_lock_r - 150.0, floor_y - 380.0)
			"AC":
				p = Vector2(center_x(), floor_y - 420.0)
			"BALCONY":
				p = Vector2(center_x(), 150)
		_pending.append({"kind": kind, "pos": p, "delay": float(s[2]), "mark": 0.7, "opts": s[3] if s.size() > 3 else {}})
	intensity = 3 if _last_wave() else (2 if _round >= 1 or _wave >= 1 else 1)


func _wave_done() -> void:
	if _relay_round():
		_cleared += 1
	_wave += 1
	if not encounters.is_empty() and (_wave < waves[_round].size() or exit_rect.size.x > 0.0):
		# a breather: the doors open and the hero climbs on
		_exploring = true
		_exit_open = _wave >= waves[_round].size()
		_phase = "explore"
		_pt = 0.0
		_gate = 0.0
		EventBus.sound_requested.emit("chase_checkpoint")
	elif _wave < waves[_round].size():
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


## The light is gone: only the hero's glow, the lanterns, the candles and glowing things light the dark.
func _update_lights() -> void:
	if _light == null:
		return
	var off := Vector2(_cam, _cam_y)
	var ls: Array = [[hero_center() - off, 330.0, 1.0]]
	for lp in lamps:
		ls.append([lp - off, 250.0, 0.85 + 0.08 * sin(_t * 7.0 + lp.x)])
	for i in _chand_idx.size():
		var r: Rect2 = platforms[_chand_idx[i]]
		ls.append([r.get_center() - off + Vector2(0, -16), 210.0, 0.8])
	for g: Array in glows:
		ls.append([(g[0] as Vector2) - off, float(g[1]), float(g[2])])
	# every fighter carries a little light, so the dark never hides one
	for e in _enemies:
		if not e.dead:
			ls.append([e.center() - off, 170.0, 0.55])
	if level_top < 0.0:
		var n := 0
		for r in platforms:
			var c := Vector2(r.get_center().x, r.position.y) - off
			if c.y > -60.0 and c.y < 780.0 and n < 8:
				ls.append([c, 150.0, 0.6])
				n += 1
	glows.clear()
	var dark := 0.5 # the backgrounds are pre-darkened (soft versions)
	if _phase in ["round_intro", "won", "lost", "ko", "the_end"]:
		dark = 0.5 * clampf((_pt - 3.0) / 0.6, 0.0, 1.0) if _phase == "round_intro" else 0.15
	dark *= 1.0 - clampf(_white, 0.0, 1.0)
	_light.set_lights(ls, dark)


func _draw_lamps(off: Vector2) -> void:
	draw_set_transform(off)
	for lp in lamps:
		draw_line(lp + Vector2(0, -160), lp + Vector2(0, -22), Color("120d08"), 3.0)
		draw_texture_rect(ArenaArt.TEX_GLOW, Rect2(lp - Vector2(70, 70), Vector2(140, 140)), false, Color(1, 0.75, 0.4, 0.55))
		draw_colored_polygon(PackedVector2Array([lp + Vector2(-14, -22), lp + Vector2(14, -22), lp + Vector2(18, 16), lp + Vector2(-18, 16)]), Color("2a1d10"))
		draw_rect(Rect2(lp + Vector2(-10, -14), Vector2(20, 24)), Color(1, 0.85, 0.5, 0.9 + 0.1 * sin(_t * 9.0 + lp.x)))
		draw_rect(Rect2(lp + Vector2(-20, 14), Vector2(40, 6)), Color("120d08"))


func _swing_chandeliers() -> void:
	for i in _chand_idx.size():
		var amp := float(chandeliers[i][1])
		if amp <= 0.0:
			continue
		var r: Rect2 = platforms[_chand_idx[i]]
		var nx := _chand_base[i].position.x + sin(_t * 1.1 + i) * amp
		var dx := nx - r.position.x
		if _ground and absf(hero_pos.y - r.position.y) < 1.0 and hero_pos.x > r.position.x and hero_pos.x < r.end.x:
			hero_pos.x += dx # it carries the hero
		r.position.x = nx
		platforms[_chand_idx[i]] = r


func _process(delta: float) -> void:
	_t += delta
	_swing_chandeliers()
	_update_lights()
	hints_seen += delta
	_pt += delta
	_shake = maxf(0.0, _shake - delta * 40.0)
	_white = maxf(0.0, _white - delta * 2.5)
	_hurt_flash = maxf(0.0, _hurt_flash - delta * 2.5)
	_zoom = maxf(0.0, _zoom - delta * 1.8)
	_hint_t = maxf(0.0, _hint_t - delta)
	if not _clash.is_empty():
		_clash["t"] = float(_clash["t"]) + delta
		if float(_clash["t"]) > 0.45:
			_clash = {}
	pivot_offset = _zoom_at
	scale = Vector2.ONE * (1.0 + 0.12 * _zoom * _zoom)
	_update_fx(delta)
	if _freeze > 0.0:
		_freeze -= delta # hit-stop: the world holds its breath
		queue_redraw()
		return
	if _slowmo > 0.0:
		_slowmo -= delta
		delta *= 0.35
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
			_update_climb(delta)
			if _exit_open and exit_rect.intersects(_hero_box()):
				_exploring = false
				_win()
			elif not _exit_open and _entered_fight():
				# the doors slam: a locked fight, like the video
				_exploring = false
				var enc := _encounter()
				_lock_l = float(enc["l"])
				_lock_r = float(enc["r"])
				floor_y = float(enc["floor"])
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
				_big_hit(hero_center(), 0.4, 0.5)
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
				hero_pos.y = floor_y
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
	_wall_coyote = maxf(0.0, _wall_coyote - delta)
	_wj_lock = maxf(0.0, _wj_lock - delta)
	_pogo_t = maxf(0.0, _pogo_t - delta)
	_combo_t = maxf(0.0, _combo_t - delta)
	_blade_t = maxf(0.0, _blade_t - delta)
	_parry_t = maxf(0.0, _parry_t - delta)
	_parry_cd = maxf(0.0, _parry_cd - delta)
	_parry_pose = maxf(0.0, _parry_pose - delta)
	_riposte = maxf(0.0, _riposte - delta)
	_block_say = maxf(0.0, _block_say - delta)
	if _l_hold >= 0.0:
		if Input.is_action_pressed("power"):
			_l_hold += delta
			if _l_hold > BLADE_HOLD and not _blade_done:
				_blade_done = true
				_power() # hold L: the Light Blade
		else:
			_l_hold = -1.0
	_land = maxf(0.0, _land - delta * 6.0)
	if _atk_buf > 0.0:
		_atk_buf -= delta
		_start_attack()
	var move := Input.get_axis("move_left", "move_right") # arrows or A / D
	var steer := move
	if _wj_lock > 0.0:
		move = 0.0 # just pushed off a wall
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
	if _dive_t > 0.0:
		_update_dive(delta)
	elif _dash_t > 0.0:
		_dash_t -= delta
		_vel.y = 0.0
		if _light_dash:
			for e in _enemies:
				if not _atk_hit.has(e) and e.state != "enter" and e.hurt_box().grow(10.0).intersects(_hero_box()):
					_atk_hit[e] = true
					_hit_enemy(e, 4.0, false, true)
		if _dash_t <= 0.0:
			_vel.x = _face * RUN * 0.6
			_light_dash = false
	else:
		if move != 0.0 and _atk_t <= 0.1:
			_face = move
		if _wj_lock > 0.0:
			_vel.x = move_toward(_vel.x, 0.0, 300.0 * delta)
		else:
			_vel.x = _run_physics(move, delta)
		_vel.y = minf(_vel.y + GRAV * delta, 1150.0)
		# holding toward a wall in the air: slide down it slowly
		_sliding = not _ground and _wall != 0 and signf(steer) == float(_wall) and _vel.y > 0.0
		if _sliding:
			_vel.y = minf(_vel.y, WALL_SLIDE)
			_face = float(_wall) # the slide frames face the wall, a hand on it
			if int(_t * 12.0) != int((_t - delta) * 12.0):
				_fx.append({"kind": "dust", "pos": hero_pos + Vector2(float(_wall) * 16.0, -60.0), "vel": Vector2(-float(_wall) * 40.0, -30.0), "t": 0.0, "life": 0.35, "size": 3.0})
	if _ground:
		_coyote = 0.1
		_air_dash = true
		_air_jump = false
	if _wall != 0 and not _ground:
		_wall_coyote = 0.12
		_wall_side = _wall
		_air_dash = true # touching a wall gives the air dash back
	if _jump_buf > 0.0 and _coyote > 0.0 and _heal_t < 0.0:
		_vel.y = JUMP_V
		_ground = false
		_coyote = 0.0
		_jump_buf = 0.0
		_anim.jumped()
		EventBus.sound_requested.emit("hero_jump")
	elif _jump_buf > 0.0 and _wall_coyote > 0.0 and not _ground and _heal_t < 0.0:
		# wall jump: up and away from the wall
		_vel = Vector2(-float(_wall_side) * WALL_JUMP.x, WALL_JUMP.y)
		_face = -float(_wall_side)
		_wj_lock = 0.15
		_wall_coyote = 0.0
		_jump_buf = 0.0
		_dive_t = 0.0
		_anim.jumped()
		_fx.append({"kind": "speed", "pos": hero_center(), "dir": Vector2(-float(_wall_side), -1.0).normalized(), "t": 0.0, "life": 0.25})
		EventBus.sound_requested.emit("hero_jump")
	elif _jump_buf > 0.0 and _air_jump and not _ground and _heal_t < 0.0:
		_vel.y = JUMP_V * 0.9 # the jump a pogo gave back
		_air_jump = false
		_jump_buf = 0.0
		_anim.jumped()
		EventBus.sound_requested.emit("hero_jump")
	var fall_v := _vel.y
	var prev_y := hero_pos.y
	hero_pos += _vel * delta
	hero_pos.x = clampf(hero_pos.x, bound_l(), bound_r())
	_ground = false
	if hero_pos.y >= _base_floor:
		hero_pos.y = _base_floor
		_vel.y = 0.0
		_ground = true
	if not _exploring and floor_y < FLOOR_Y and hero_pos.y >= floor_y and prev_y <= floor_y + 1.0:
		# a locked fight's floor is solid, even where it is a ledge you can drop through on the climb
		hero_pos.y = floor_y
		_vel.y = 0.0
		_ground = true
	for rim in platforms:
		if _vel.y >= 0.0 and prev_y <= rim.position.y + 1.0 and hero_pos.y >= rim.position.y and hero_pos.x > rim.position.x and hero_pos.x < rim.end.x and not Input.is_action_pressed("move_down"):
			hero_pos.y = rim.position.y
			_vel.y = 0.0
			_ground = true
	_collide_walls(prev_y, delta)
	# the camera follows in wide levels and frames the locked fight
	var cam_target := clampf(hero_pos.x - 560.0, 0.0, level_width - 1280.0) if _exploring else clampf(center_x() - 640.0, 0.0, maxf(0.0, level_width - 1280.0))
	_cam = lerpf(_cam, cam_target, minf(1.0, delta * 5.0))
	if level_top < 0.0:
		var cam_y_target := clampf(hero_pos.y - 450.0, level_top, 0.0) if _exploring else clampf(floor_y - 600.0, level_top, 0.0)
		_cam_y = lerpf(_cam_y, cam_y_target, minf(1.0, delta * 5.0))
	elif floor_y > FLOOR_Y:
		_cam_y = lerpf(_cam_y, floor_y - FLOOR_Y, minf(1.0, delta * 3.0)) # down into the archive
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
	# the slash lands while the strike frame is on screen (swing progress 0.09-0.45)
	if _atk_t > 0.12 and _atk_t < 0.2:
		var box := _attack_box()
		for e in _enemies:
			if not _atk_hit.has(e) and e.state != "enter" and e.hurt_box().intersects(box):
				_atk_hit[e] = true
				_hit_enemy(e, 1.0, _atk_dir == "down")
		var popped := false
		for e in _enemies:
			if e.kind == "scribe" and e.pop_orb(box):
				popped = true
				_fx.append({"kind": "spark", "pos": box.get_center(), "t": 0.0, "life": 0.25, "size": 1.0})
				EventBus.sound_requested.emit("hit")
				_ink = mini(MAX_INK, _ink + 1)
		if popped and _atk_dir == "down" and not _ground:
			_bounce_up(box.get_center())
		elif _atk_dir == "down" and not _ground and _pogo_props(box):
			pass
		elif _atk_dir == "down" and not _ground:
			# a down-slash bounces off falling ink too
			for d in _drops:
				if float(d["warn"]) <= 0.0 and box.grow(10.0).has_point(Vector2(float(d["x"]), float(d["y"]))):
					d["y"] = 9999.0
					_vel.y = -760.0
					_pogo_t = 0.3
					_air_dash = true
					_air_jump = true
					_fx.append({"kind": "spark", "pos": Vector2(float(d["x"]), float(d["y"])), "t": 0.0, "life": 0.25, "size": 1.0})
					EventBus.sound_requested.emit("hit")
					break


## Solid blocks: land on top, bump the head below, stop at the sides (and cling to them).
## The edges of the stage are walls too.
func _collide_walls(prev_y: float, delta: float) -> void:
	_wall = 0
	var prev_x := hero_pos.x - _vel.x * delta
	for w in walls:
		var hb := Rect2(hero_pos + Vector2(-17, -86), Vector2(34, 84))
		if not hb.intersects(w):
			continue
		if prev_y <= w.position.y + 1.0 and _vel.y >= 0.0:
			hero_pos.y = w.position.y
			_vel.y = 0.0
			_ground = true
		elif prev_y - 86.0 >= w.end.y - 1.0 and _vel.y < 0.0:
			hero_pos.y = w.end.y + 86.0
			_vel.y = 0.0
		elif prev_x <= w.position.x + 17.0:
			hero_pos.x = w.position.x - 17.0
			_vel.x = minf(_vel.x, 0.0)
		else:
			hero_pos.x = w.end.x + 17.0
			_vel.x = maxf(_vel.x, 0.0)
	if _ground:
		return
	var body := Rect2(hero_pos + Vector2(-17, -80), Vector2(34, 60))
	for w in walls:
		if body.grow_individual(2.0, 0.0, 0.0, 0.0).intersects(w):
			_wall = -1
		elif body.grow_individual(0.0, 0.0, 2.0, 0.0).intersects(w):
			_wall = 1
	if hero_pos.x <= bound_l() + 0.5:
		_wall = -1
	elif hero_pos.x >= bound_r() - 0.5:
		_wall = 1


## Down + K in the air: a fast diagonal strike down and forward; it bounces off whatever it hits.
func _start_dive() -> void:
	_dive_t = 0.45
	_air_dash = false
	_atk_hit.clear()
	_invuln = maxf(_invuln, 0.15)
	_fx.append({"kind": "speed", "pos": hero_center(), "dir": Vector2(_face, 1.2).normalized(), "t": 0.0, "life": 0.3})
	EventBus.sound_requested.emit("dash")


func _update_dive(delta: float) -> void:
	_dive_t -= delta
	_vel = Vector2(_face * 640.0, 980.0)
	var box := _hero_box().grow(18.0)
	for e in _enemies:
		if not e.dead and e.state != "enter" and e.hurt_box().intersects(box):
			_hit_enemy(e, 2.0, false, true)
			_dive_bounce()
			_big_hit(e.center(), 0.5)
			return
	for d in _drops:
		if float(d["warn"]) <= 0.0 and box.has_point(Vector2(float(d["x"]), float(d["y"]))):
			d["y"] = 9999.0
			_dive_bounce()
			return
	if _pogo_props(box):
		_dive_bounce()
		return
	if _ground or _dive_t <= 0.0:
		_dive_t = 0.0
		if _ground:
			shake(6.0)
			for k in 8:
				_fx.append({"kind": "dust", "pos": hero_pos + Vector2(randf_range(-20, 20), -4), "vel": Vector2(randf_range(-220, 220), randf_range(-200, -60)), "t": 0.0, "life": 0.45, "size": randf_range(4, 8)})


## Pogo off a stepping bat or a falling book: bounce, the jump and the air dash come back.
func _pogo_props(box: Rect2) -> bool:
	for e in _steps:
		if e.hurt_box().grow(6.0).intersects(box):
			e.whiteout = 0.06
			e.flash = 1.0
			_bounce_up(e.center())
			return true
	for b in _books:
		if float(b["warn"]) <= 0.0 and box.grow(10.0).has_point(b["pos"]):
			b["dead"] = true
			_bounce_up(b["pos"])
			return true
	return false


func _bounce_up(at: Vector2) -> void:
	_pogo_t = 0.3
	_vel.y = -760.0
	_air_dash = true
	_air_jump = true
	_atk_t = minf(_atk_t, 0.11)
	_fx.append({"kind": "spark", "pos": at, "t": 0.0, "life": 0.25, "size": 1.0})
	EventBus.sound_requested.emit("hit")


func _dive_bounce() -> void:
	_dive_t = 0.0
	_vel = Vector2(-_face * 260.0, -760.0)
	_air_dash = true
	_air_jump = true


## A camera nudge toward a big hit, and slow motion (a wave cleared).
func _big_hit(at: Vector2, zoom: float, slow := 0.0) -> void:
	_zoom = maxf(_zoom, zoom)
	_zoom_at = at - Vector2(_cam, 0)
	_slowmo = maxf(_slowmo, slow)


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
	if _dive_t > 0.0:
		return "dive"
	if _pogo_t > 0.0 and not _ground:
		return "pogo"
	if _sliding:
		return "wallslide"
	if _wj_lock > 0.0:
		return "walljump"
	if _dash_t > 0.0 and not _ground:
		return "airdash"
	if _hp <= 0:
		return "ko"
	if _blade_t > 0.0:
		return "blade"
	if _parry_pose > 0.0:
		return "parry"
	if _atk_t > 0.0 and _riposting:
		return "riposte"
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
	_riposting = _riposte > 0.0
	_riposte = 0.0
	_anim.start_attack(3 if _riposting else _combo)
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


func _hit_enemy(e: ArenaEnemy, dmg: float, pogo: bool, pierce := false) -> void:
	if e.dead:
		return # already beaten: hitting him again would restart the hit-stop forever (powers fire during it)
	if e.kind == "scribe" and e.state in ["tele_out", "tele_in", "fake_death", "laugh", "crash"]:
		return # mid-teleport or playing dead: the blow passes through ink
	var riposte := _riposting and not pierce
	if not e.guarding(hero_pos.x) or pogo or pierce or riposte:
		# the hit lands: the enemy flashes white and a burst of paper petals flies off
		e.whiteout = 0.06
		for k in 8:
			_fx.append({"kind": "paper", "pos": e.center(), "vel": Vector2(randf_range(-380, 380), randf_range(-420, 80)), "t": 0.0, "life": 0.7, "size": randf_range(4, 8)})
	if e.kind != "bomb" and e.broken > 0.0 and not pierce:
		_critical(e)
		if e.dead:
			_kill_fx(e)
		return
	# a guard blocks the front; a riposte, a pogo, a dive and the powers get through
	if e.kind != "bomb" and not riposte and not pierce and not pogo and e.guarding(hero_pos.x):
		_block(e)
		return
	if not pogo and not pierce and not riposte and e.armoured_against(hero_pos.x) and hero_pos.y > e.pos.y - 130.0:
		# the brute's armoured front: CLANG. From above (pogo, dive), from behind, or the Light Blade.
		e.flash = 0.6
		_freeze = 0.04
		_vel.x = -_face * 280.0
		_fx.append({"kind": "spark", "pos": e.center().lerp(hero_center(), 0.4), "t": 0.0, "life": 0.2, "size": 0.9})
		_say("CLANG!", e.center() + Vector2(0, -80), Color("c9d1d9"), 34)
		EventBus.sound_requested.emit("enemy_grunt")
		return
	if e.kind == "bomb":
		e.dead = true # a slashed bomb fizzles out
	elif riposte:
		ripostes += 1
		_riposting = false
		e.take_hit(dmg * (3.0 if e.boss() else 4.0), hero_pos.x, 0.12 if e.boss() else 0.2)
		if not e.dead and e.broken <= 0.0:
			e.open(0.5 if e.boss() else 0.8) # the riposte knocks him open: the combo can follow
		_freeze = 0.12
		shake(8.0)
		_say("RIPOSTE!", e.center() + Vector2(0, -125), Color("fff3d1"), 40)
		EventBus.sound_requested.emit("punch_heavy")
		if _hint == "riposte":
			_hint_t = 0.0
	else:
		var post := 0.03 if e.boss() else 0.06
		if pierce or pogo:
			post = 0.2 if e.boss() else 0.3 # from above or with the Light Blade: it rocks the posture
		e.take_hit(dmg, hero_pos.x, post)
		if e.broken > 0.0:
			_show_hint("broken", true)
	_ink = mini(MAX_INK, _ink + 1)
	_freeze = 0.05
	_fx.append({"kind": "spark", "pos": e.center().lerp(hero_center(), 0.3), "t": 0.0, "life": 0.25, "size": 1.0})
	for k in 6:
		_fx.append({"kind": "ink", "pos": e.center(), "vel": Vector2(randf_range(-260, 260), randf_range(-320, -60)), "t": 0.0, "life": 0.6, "size": randf_range(3, 7)})
	EventBus.sound_requested.emit("hit")
	if pogo:
		_vel.y = -760.0
		_air_dash = true
		_air_jump = true
		_pogo_t = 0.3
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
		_corpses.append({"x": e.pos.x, "y": e.floor_y, "kind": e.kind, "dir": e.dir})
		if _corpses.size() > 24:
			_corpses.pop_front()


func _hurt(from_x: float) -> void:
	if _invuln > 0.0 or _dash_t > 0.0 or not _phase in ["wave", "wave_intro", "explore"]:
		return
	if _phase == "explore" and _hp <= 1:
		# beaten on the climb: back on the last safe ledge, healed
		_hp = max_hp
		hero_pos = _safe_pos
		_vel = Vector2.ZERO
		_invuln = 1.5
		_hurt_flash = 1.0
		_say("TRY AGAIN", hero_center() + Vector2(0, -80), PAPER, 40)
		EventBus.sound_requested.emit("hero_hurt")
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
		if not _ground and Input.is_action_pressed("move_down") and _air_dash and _heal_t < 0.0 and _dive_t <= 0.0:
			_start_dive()
		elif _dash_cd <= 0.0 and (_ground or _air_dash) and _heal_t < 0.0:
			_dash(false)
	elif event.is_action("power"):
		if _hero_kind() == 0:
			_start_parry() # tap L: parry; hold L: the Light Blade (in _update_hero)
			_l_hold = 0.0
			_blade_done = false
		else:
			_power()
	elif event.is_action("heal"):
		if _ink >= 6 and _ground and _hp < max_hp and _heal_t < 0.0:
			_heal_t = 0.0
	else:
		return
	get_viewport().set_input_as_handled()


func _start_parry() -> void:
	if _parry_cd > 0.0 or _heal_t >= 0.0 or _dash_t > 0.0 or _dive_t > 0.0:
		return
	_face_nearest()
	_parry_t = PARRY_WINDOW
	_parry_cd = PARRY_WINDOW + PARRY_COOLDOWN
	_parry_pose = 0.3
	EventBus.sound_requested.emit("slash")


## A perfect parry: clash flash, sparks, hit-stop and a breath of slow motion; the enemy reels (or
## goes on with his combo), the hero gains ink and his next hit is a riposte. In the air it also
## gives back the air dash and a jump, so parries chain into the parkour.
func _perfect_parry(e: ArenaEnemy) -> void:
	parries += 1
	_parry_t = 0.0
	_parry_cd = 0.06 # ready at once for the next strike of a combo
	_parry_pose = 0.25
	_invuln = maxf(_invuln, 0.3)
	_riposte = 1.6
	_ink = mini(MAX_INK, _ink + 2)
	if not _ground:
		_air_dash = true
		_air_jump = true
		_vel.y = minf(_vel.y, -380.0) # the clash lifts him a little
	var at := e.center().lerp(hero_center(), 0.45)
	_clash = {"pos": at, "t": 0.0}
	_freeze = 0.1
	_slowmo = maxf(_slowmo, 0.35)
	_white = maxf(_white, 0.7)
	shake(10.0)
	for k in 18:
		var ang := randf() * TAU
		_fx.append({"kind": "ink", "pos": at, "vel": Vector2.from_angle(ang) * randf_range(200, 520), "t": 0.0, "life": 0.45, "size": randf_range(2, 4), "col": Color("ffe9a0")})
	_fx.append({"kind": "spark", "pos": at, "t": 0.0, "life": 0.45, "size": 2.4})
	_say("PARRY!", at + Vector2(0, -60), GOLD, 46)
	EventBus.sound_requested.emit("counter_hit")
	EventBus.sound_requested.emit("counter_flash")
	e.parried(hero_pos.x)
	if _ground:
		_vel.x = -_face * 120.0
	if e.broken > 0.0:
		_show_hint("broken", true)
	elif not _hints_seen.has("riposte"):
		_show_hint("riposte", true)


## A blow on a guarding enemy's front: a clang, a little push back, a sliver of posture.
func _block(e: ArenaEnemy) -> void:
	e.posture = minf(1.0, e.posture + 0.04)
	e.recoil = 0.4
	e.recoil_dir = signf(e.pos.x - hero_pos.x)
	_freeze = 0.04
	_vel.x = -_face * 260.0
	_fx.append({"kind": "spark", "pos": e.center().lerp(hero_center(), 0.4), "t": 0.0, "life": 0.2, "size": 0.8})
	if _block_say <= 0.0:
		_block_say = 1.0
		_say("BLOCK", e.center() + Vector2(0, -70), Color("c9d1d9"), 30)
	EventBus.sound_requested.emit("enemy_grunt")
	_show_hint("guard")


## The critical strike on a broken enemy: a big finisher with the camera punching in.
func _critical(e: ArenaEnemy) -> void:
	criticals += 1
	var dmg := e.hp if not e.boss() else e.max_hp * 0.16 + 4.0
	e.broken = 0.0
	e.posture = 0.0
	e.open(0.5)
	e.take_hit(dmg, hero_pos.x, 0.0)
	_ink = mini(MAX_INK, _ink + 2)
	_freeze = 0.32
	_white = 1.0
	shake(20.0)
	_big_hit(e.center(), 1.4)
	_say("CRITICAL!", e.center() + Vector2(0, -90), GOLD, 64)
	for k in 30:
		var ang := randf() * TAU
		_fx.append({"kind": "paper", "pos": e.center(), "vel": Vector2.from_angle(ang) * randf_range(250, 750), "t": 0.0, "life": 1.3, "size": randf_range(5, 11)})
	_fx.append({"kind": "spark", "pos": e.center(), "t": 0.0, "life": 0.6, "size": 3.2})
	EventBus.sound_requested.emit("punch_heavy")
	EventBus.sound_requested.emit("shockwave")


func _show_hint(k: String, again := false) -> void:
	if _hints_seen.has(k) and not again:
		return
	_hints_seen[k] = true
	_hint = k
	_hint_t = 3.2


func _dash(light: bool) -> void:
	_dash_t = 0.16 if not light else 0.24
	_dash_cd = 0.45
	_vel.x = _face * (DASH_V if not light else 1500.0)
	_vel.y = 0.0
	_light_dash = light
	_atk_hit.clear()
	_fx.append({"kind": "speed", "pos": hero_center(), "dir": Vector2(_face, 0), "t": 0.0, "life": 0.25})
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
					_hit_enemy(e, 4.0, false, true)
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
					_hit_enemy(e, 5.0, false, true)
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
		e.floor_y = floor_y
		e.ground_y = floor_y
		e.guards = guards
		e.trainee = bool(p.get("opts", {}).get("trainee", false))
		if e.trainee:
			var comms: Node = get_tree().get_first_node_in_group("comms")
			if comms != null:
				comms.say("He's guarding, hero: hitting his front just bounces off. When his spear flashes GOLD, tap L to parry, then strike back with J!", "narrator", 3.0)
		if not e.flying():
			for rim in platforms:
				if absf(e.pos.y - rim.position.y) < 24.0 and e.pos.x > rim.position.x and e.pos.x < rim.end.x:
					e.perch = rim
					e.ground_y = rim.position.y
		if e.kind == "narrator":
			e.hp = _narrator_hp() * boss_hp_scale
			e.max_hp = e.hp
			e.state = "enter" # he drops from his balcony onto the stage: a duel on foot
			_narrator = e
			if _boss_carry > 0.0:
				e.hp = _boss_carry
				_boss_carry = -1.0
			_say(narrator_line, Vector2(center_x(), 220), Color("c77dff"), 40)
			_white = maxf(_white, 0.6)
			shake(14.0)
			EventBus.sound_requested.emit("narrator_attack")
		elif e.kind == "scribe":
			e.hp *= boss_hp_scale
			e.max_hp = e.hp
			e.state = "hover"
			_narrator = e
			if _boss_carry > 0.0:
				e.hp = _boss_carry
				_boss_carry = -1.0
			_white = maxf(_white, 0.5)
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
			e.pos.y = e.ground_y - (520.0 if e.kind == "brute" else 260.0) # drops onto the stage
		_enemies.append(e)
		EventBus.sound_requested.emit("enemy_spawn")
	for e in _enemies:
		e.update(et, self)
		if not e.dead and e.hits(_hero_box()):
			if _parry_t > 0.0 and e.parryable():
				_perfect_parry(e)
			else:
				_hurt(e.pos.x)
		if not e.dead:
			var tc := e.tele()
			if tc != "" and e.center().distance_to(hero_center()) < 520.0:
				_show_hint(tc)
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
	_update_flood(delta)
	for w in _waves:
		w["x"] = float(w["x"]) + float(w["dir"]) * 470.0 * et
		w["life"] = float(w["life"]) - et
		if absf(float(w["x"]) - hero_pos.x) < 26.0 and hero_pos.y > floor_y - 40.0:
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
	_drops = _drops.filter(func(d: Dictionary) -> bool: return float(d["y"]) < floor_y)
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
	if level_top < 0.0:
		# a climb: the painting is drawn taller and slides down slowly as the hero climbs
		var k := clampf(_cam_y / level_top, 0.0, 1.0)
		var tall := 720.0 * (1.0 + par * 0.0 + 0.3)
		draw_texture_rect(tex, Rect2(Vector2(-_cam * par, -(tall - 720.0) * (1.0 - k)) + off * 0.5, Vector2(maxf(w, 1280.0) * 1.3, tall)), false, mod)
		return true
	if w <= 1281.0:
		draw_texture_rect(tex, Rect2(Vector2(off.x * 0.5, off.y * 0.5), Vector2(1280, 720)), false, mod)
		return true
	x = -fposmod(_cam * par, maxf(w - 1280.0, 1.0)) if par < 1.0 else -_cam * par
	draw_texture_rect(tex, Rect2(Vector2(x, 0) + off, Vector2(w, 720)), false, mod)
	return true


func _draw() -> void:
	var shake_off := Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake)) if _shake > 0.0 else Vector2.ZERO
	var off := shake_off - Vector2(_cam, _cam_y)
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
	_draw_climb(off)
	_draw_archive(off)
	_draw_chandeliers(off)
	_draw_lamps(off)
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
			var at := Vector2(pp.x, floor_y) if pp.y >= floor_y - 1.0 else pp
			draw_circle(at, 10.0 + 40.0 * k, Color(0.1, 0.05, 0.15, 0.6))
			draw_arc(at, 12.0 + 44.0 * k, 0.0, TAU, 24, Color(1, 0.85, 0.5, 0.6), 3.0)
	for w in _waves:
		var x := float(w["x"])
		var fy := floor_y
		var pts := PackedVector2Array([Vector2(x - 26, fy), Vector2(x - 10, fy - 40), Vector2(x + 2, fy - 22), Vector2(x + 12, fy - 46), Vector2(x + 26, fy)])
		draw_colored_polygon(pts, Color("2b1d3a"))
		draw_polyline(pts, Color(1, 0.85, 0.5, 0.8), 2.0)
	for d in _drops:
		var dx := float(d["x"])
		if float(d["warn"]) > 0.0:
			draw_set_transform(Vector2(dx, floor_y) + off, 0.0, Vector2(1.0, 0.25))
			draw_circle(Vector2.ZERO, 26.0, Color(0.6, 0.1, 0.3, 0.35 + 0.25 * sin(_t * 20.0)))
			draw_set_transform(off)
		else:
			var dy := float(d["y"])
			draw_colored_polygon(PackedVector2Array([Vector2(dx, dy - 34), Vector2(dx + 14, dy), Vector2(dx, dy + 12), Vector2(dx - 14, dy)]), Color("3c096c"))
			draw_line(Vector2(dx, dy - 80), Vector2(dx, dy - 34), Color(0.5, 0.2, 0.8, 0.4), 4.0)
	for e in _steps:
		e.draw(self, _t, off)
		draw_set_transform(off)
	for e in _enemies:
		e.draw(self, _t, off)
		draw_set_transform(off)
	for b in _books:
		var bp: Vector2 = b["pos"]
		if float(b["warn"]) > 0.0:
			draw_rect(Rect2(Vector2(bp.x - 16, _cam_y + 4), Vector2(32, 6)), Color(1, 0.3, 0.3, 0.5 + 0.4 * sin(_t * 30.0)))
			continue
		draw_set_transform(bp + off, float(b["a"]), Vector2.ONE)
		draw_rect(Rect2(-16, -11, 32, 22), INK)
		draw_rect(Rect2(-14, -9, 28, 18), Color("7a2e2e"))
		draw_rect(Rect2(-14, -3, 28, 4), Color("e0c27a"))
		draw_set_transform(off)
	_draw_hero(off)
	_draw_flood(off)
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
	_draw_hints()
	if _phase == "explore":
		if _pt < 6.0:
			ComicArt.shout(self, "GO  >>", Vector2(1100, 300), 48, GOLD, 10, 0.0)
		# the objective, and the controls for the first seconds
		var obj := ("REACH THE DOOR AT THE TOP" if _exit_open else "CLIMB THE LIBRARY") if level_top < 0.0 else "REACH THE END OF THE LIBRARY"
		var ow := FONT_SHOUT.get_string_size(obj, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
		draw_string(FONT_SHOUT, Vector2(640 - ow * 0.5, 120), obj, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, PAPER)
		if _pt < 10.0 and _hints_on():
			draw_string(FONT_BODY, Vector2(70, 700), "WASD move   Z jump (on a wall: wall jump)   J attack   S+J in the air: pogo   K dash   S+K in the air: dive   L parry (hold: blade)   F heal", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, PAPER)
	elif _phase == "wave" and _narrator == null:
		# the objective while there is no boss bar: how many are left on stage
		var left := _enemies.size() + _pending.size()
		if left > 0:
			var obj2 := "CLEAR THE STAGE  (%d left)" % left
			var ow2 := FONT_SHOUT.get_string_size(obj2, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
			draw_string_outline(FONT_SHOUT, Vector2(640 - ow2 * 0.5, 120), obj2, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, 6, INK)
			draw_string(FONT_SHOUT, Vector2(640 - ow2 * 0.5, 120), obj2, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, PAPER)
	if _tip != "" and _phase == "explore":
		var tw := FONT_SHOUT.get_string_size(_tip, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
		var ta := Vector2(640 - tw * 0.5, 165)
		draw_rect(Rect2(ta + Vector2(-14, -28), Vector2(tw + 28, 42)), Color(0, 0, 0, 0.55))
		draw_string_outline(FONT_SHOUT, ta, _tip, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, 6, INK)
		draw_string(FONT_SHOUT, ta, _tip, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, GOLD)
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


func _draw_chandeliers(off: Vector2) -> void:
	draw_set_transform(off)
	for i in _chand_idx.size():
		var r: Rect2 = platforms[_chand_idx[i]]
		var top := Vector2(r.get_center().x if float(chandeliers[i][1]) <= 0.0 else _chand_base[i].get_center().x, r.position.y - 400.0)
		draw_line(top, r.get_center() + Vector2(0, -2), Color("1a1206"), 4.0)
		draw_texture_rect(ArenaArt.TEX_GLOW, Rect2(r.get_center() - Vector2(110, 80), Vector2(220, 160)), false, Color(1, 0.8, 0.45, 0.45))
		draw_rect(Rect2(r.position + Vector2(-4, -2), Vector2(r.size.x + 8, 12)), Color("1a1206"))
		draw_rect(Rect2(r.position, Vector2(r.size.x, 8)), Color("c9963c"))
		var n := int(r.size.x / 30.0)
		for k in n:
			var cx := r.position.x + 15.0 + k * 30.0
			draw_rect(Rect2(Vector2(cx - 3, r.position.y - 14), Vector2(6, 14)), Color("f3e7c9"))
			draw_circle(Vector2(cx, r.position.y - 18), 4.0 + sin(_t * 9.0 + k) * 1.0, Color(1, 0.8, 0.3, 0.9))
		draw_colored_polygon(PackedVector2Array([r.position + Vector2(10, 8), r.end + Vector2(-10, -12), Vector2(r.get_center().x, r.end.y + 26)]), Color("8a6424"))


## The climb: bookshelf walls (solid blocks) and, once the last fight is won, the door at the top.
func _draw_climb(off: Vector2) -> void:
	draw_set_transform(off)
	for w in walls:
		draw_rect(w.grow(3.0), Color("06090a"))
		draw_rect(w, Color("2a1d17"))
		var y := w.position.y + 8.0
		var row := 0
		while y < w.end.y - 30.0:
			var x := w.position.x + 4.0
			var i := 0
			while x < w.end.x - 6.0:
				var bw := 6.0 + float((row * 7 + i * 3) % 5) * 2.0
				var bh := 24.0 + float((row + i) % 3) * 3.0
				var col: Color = [Color("6b2f2a"), Color("2f4a5c"), Color("5c4a2a"), Color("3d5a3a"), Color("7a6a4a")][(row * 3 + i) % 5]
				draw_rect(Rect2(Vector2(x, y + 30.0 - bh), Vector2(bw, bh)), col)
				x += bw + 1.0
				i += 1
			draw_rect(Rect2(Vector2(w.position.x, y + 30.0), Vector2(w.size.x, 5.0)), Color("140d0a"))
			y += 36.0
			row += 1
		draw_texture_rect(ArenaArt.TEX_GLOW, Rect2(w.position + Vector2(-30, -36), Vector2(w.size.x + 60, 60)), false, Color(1, 0.8, 0.45, 0.45))
		draw_rect(Rect2(w.position, Vector2(w.size.x, 5)), Color(1, 0.86, 0.55))
	if exit_rect.size.x > 0.0:
		var d := exit_rect
		var lit := 1.0 if _exit_open else 0.25
		draw_texture_rect(ArenaArt.TEX_GLOW, d.grow(70.0), false, Color(1, 0.85, 0.5, 0.6 * lit))
		draw_rect(d.grow(6.0), Color("06090a"))
		draw_rect(d, Color(1, 0.92, 0.7, 0.85 * lit) if _exit_open else Color("1b1410"))
		if _exit_open:
			ComicArt.shout(self, "OPERA  >>", d.get_center() + Vector2(0, -d.size.y * 0.5 - 30.0) + off, 30, GOLD, 8, 0.0)
			draw_set_transform(off)


func _draw_archive(off: Vector2) -> void:
	if not _floor_broken:
		return
	draw_set_transform(off)
	draw_rect(Rect2(Vector2(_lock_l - 200.0, FLOOR_Y + 20.0), Vector2(_lock_r - _lock_l + 400.0, 300.0)), Color("0b0807"))
	for k in 9:
		var x := _lock_l + k * 130.0
		draw_rect(Rect2(Vector2(x, FLOOR_Y + 60.0), Vector2(110.0, 220.0)), Color("1c130e"))
		for r in 4:
			draw_rect(Rect2(Vector2(x + 4, FLOOR_Y + 80.0 + r * 52.0), Vector2(102.0, 6.0)), Color("2e2017"))
	draw_rect(Rect2(Vector2(_lock_l - 200.0, floor_y), Vector2(_lock_r - _lock_l + 400.0, 140.0)), Color("0e1416"))
	draw_line(Vector2(_lock_l - 200.0, floor_y), Vector2(_lock_r + 200.0, floor_y), Color("c79a55"), 3.0)
	for side: float in [-1.0, 1.0]:
		var edge: float = 640.0 + side * 330.0
		var x0: float = _lock_l - 200.0 if side < 0.0 else edge
		var x1: float = edge if side < 0.0 else _lock_r + 200.0
		draw_rect(Rect2(Vector2(x0, FLOOR_Y), Vector2(x1 - x0, 24.0)), Color("23302f"))
		for k in 6:
			var jx: float = edge - side * k * 14.0
			draw_colored_polygon(PackedVector2Array([Vector2(jx, FLOOR_Y), Vector2(jx + side * 14.0, FLOOR_Y), Vector2(jx + side * 6.0, FLOOR_Y + 30.0 + (k % 3) * 10.0)]), Color("23302f"))


## The library hall's stone floor and ledges.
func _draw_hall_floor(off: Vector2) -> void:
	draw_set_transform(Vector2(0, off.y))
	if not _floor_broken:
		draw_rect(Rect2(0, FLOOR_Y, 1280, 120), Color("0e1416"))
		draw_line(Vector2(0, FLOOR_Y), Vector2(1280, FLOOR_Y), Color("c79a55"), 3.0)
	draw_set_transform(off)
	for r in platforms:
		var ledge := Rect2(r.position, Vector2(r.size.x, 22))
		# lit from above: a warm glow on top, a bright edge, so every ledge reads at a glance
		draw_texture_rect(ArenaArt.TEX_GLOW, Rect2(ledge.position + Vector2(-30, -36), Vector2(ledge.size.x + 60, 60)), false, Color(1, 0.8, 0.45, 0.45))
		draw_rect(ledge.grow(3.0), Color("06090a"))
		draw_rect(ledge, Color("3b4a48"))
		draw_rect(Rect2(ledge.position, Vector2(ledge.size.x, 5)), Color(1, 0.86, 0.55))
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
	var fy := float(c.get("y", FLOOR_Y))
	var x := float(c["x"])
	var big := String(c["kind"]) == "brute"
	draw_set_transform(Vector2(x, fy - 4) + off, 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 46.0 if big else 26.0, Color("120c18"))
	draw_set_transform(off)
	if big:
		var dome := PackedVector2Array()
		for k in 11:
			var ang := PI + k * PI / 10.0
			dome.append(Vector2(x + cos(ang) * 60.0, fy + sin(ang) * 34.0))
		draw_colored_polygon(dome, Color("6e2a16"))
		draw_polyline(dome, INK, 3.0)
	else:
		var lump := PackedVector2Array([Vector2(x - 30, fy), Vector2(x - 18, fy - 16), Vector2(x + 6, fy - 20), Vector2(x + 28, fy)])
		draw_colored_polygon(lump, Color("241b33"))
		draw_polyline(lump, INK, 3.0)
		var mk := Vector2(x + 14.0 * float(c["dir"]), fy - 14)
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
		# a big white arc on every swing (over the painted frames' own smear too)
		ArenaArt.slash(self, hero_center() + dir * 24.0, dir, k, _combo == 3 and _atk_dir == "side")
	if _heal_t >= 0.0:
		draw_arc(hero_center(), 40.0, -PI * 0.5, -PI * 0.5 + TAU * _heal_t / 0.6, 24, Color("8ef0ff"), 5.0)
	if _parry_t > 0.0:
		var g := hero_center() + Vector2(_face * 34.0, -14.0)
		var gk := _parry_t / PARRY_WINDOW
		draw_texture_rect(ArenaArt.TEX_GLOW, Rect2(g - Vector2(46, 46), Vector2(92, 92)), false, Color(1, 0.95, 0.7, 0.6 * gk))
		draw_line(g + Vector2(-_face * 6.0, 38.0), g + Vector2(_face * 10.0, -40.0), Color(1, 1, 0.92, 0.9 * gk), 5.0)
	if not _clash.is_empty():
		var ck := float(_clash["t"]) / 0.45
		var cp: Vector2 = _clash["pos"]
		var r := 20.0 + 90.0 * ck
		draw_texture_rect(ArenaArt.TEX_GLOW, Rect2(cp - Vector2(r, r) * 1.6, Vector2(r, r) * 3.2), false, Color(1, 0.95, 0.65, 1.0 - ck))
		for i in 8:
			var d := Vector2.from_angle(i * TAU / 8.0 + 0.3)
			draw_line(cp + d * r * 0.3, cp + d * r * (1.2 if i % 2 == 0 else 0.8), Color(1, 1, 0.9, 1.0 - ck), 4.0 * (1.0 - ck) + 1.0)
		draw_arc(cp, r, 0.0, TAU, 32, Color(1, 0.9, 0.5, 1.0 - ck), 3.0)


func _draw_fx(f: Dictionary, off: Vector2) -> void:
	var k := float(f["t"]) / float(f["life"])
	match String(f["kind"]):
		"spark":
			ArenaArt.hit_spark(self, f["pos"], k, float(f["size"]))
		"speed":
			# radial speed lines streaming back from a dash or dive
			var sd: Vector2 = f["dir"]
			var sp: Vector2 = f["pos"]
			for i in 9:
				var off2 := sd.orthogonal() * (i - 4) * 9.0
				var a0 := sp + off2 - sd * (30.0 + 160.0 * k + (i % 3) * 20.0)
				draw_line(a0, a0 - sd * (60.0 + (i % 2) * 40.0) * (1.0 - k), Color(1, 0.97, 0.85, 0.7 * (1.0 - k)), 3.0)
		"ink":
			var ic: Color = f.get("col", Color(0.15, 0.06, 0.2))
			draw_circle(f["pos"], maxf(0.5, float(f["size"]) * (1.0 - k)), Color(ic.r, ic.g, ic.b, 1.0 - k))
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


## The key hints show in the first fights of a run only (the pause menu lists the controls).
static var hints_seen := 0.0


func _hints_on() -> bool:
	return hints_seen < 40.0


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
	var power_line := "L parry   hold L: %s (3)   F heal (6)" % POWER_BY_KIND[0] if _hero_kind() == 0 else "L %s (3)   F heal (6)" % POWER_BY_KIND[_hero_kind()]
	if _hints_on():
		draw_string(FONT_BODY, Vector2(126, 116), power_line, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, GOLD if _ink >= 3 else Color("8d99ae"))
	# round, wave, bomb (top right)
	draw_string(FONT_SHOUT, Vector2(930, 46), ("ROUND %d  -  %s" % [_round + 1, ComicArt.HERO_NAMES[kind]]) if fight_title == "" else fight_title, HORIZONTAL_ALIGNMENT_LEFT, 330, 22, GOLD)
	if bomb_left >= 0.0:
		var bs := int(ceil(bomb_left))
		draw_string(FONT_SHOUT, Vector2(930, 82), "BOMB %d:%02d" % [bs / 60, bs % 60], HORIZONTAL_ALIGNMENT_LEFT, -1, 32, RED if bomb_left < 60.0 else PAPER)
	if _total_waves() > 1:
		draw_string(FONT_SHOUT, Vector2(1110, 82), "WAVE %d/%d" % [mini(_global_wave(), _total_waves()), _total_waves()], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, PAPER)
	# the Narrator's health (bottom)
	if _narrator != null:
		var bar := Rect2(Vector2(668, 660), Vector2(580, 20))
		draw_string(FONT_SHOUT, Vector2(668, 652), boss_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("c77dff"))
		draw_rect(bar, INK)
		draw_rect(Rect2(bar.position + Vector2(3, 3), Vector2((bar.size.x - 6) * clampf(_narrator.hp / _narrator.max_hp, 0.0, 1.0), bar.size.y - 6)), Color("9d4edd"))
		if _narrator.posture > 0.01 or _narrator.broken > 0.0:
			var pb := Rect2(bar.position + Vector2(0, bar.size.y + 4), Vector2(bar.size.x, 8))
			draw_rect(pb, INK)
			var pcol := Color.WHITE if _narrator.broken > 0.0 and int(_t * 8.0) % 2 == 0 else Color("ffd23f").lerp(Color("ff8a00"), _narrator.posture)
			draw_rect(Rect2(pb.position + Vector2(2, 2), Vector2((pb.size.x - 4) * clampf(_narrator.posture, 0.0, 1.0), pb.size.y - 4)), pcol)
	elif _phase in ["wave", "wave_intro"] and _wave == 0 and _pt < 8.0 and _hints_on():
		draw_string(FONT_BODY, Vector2(70, 700), "WASD move   Z jump (on a wall: wall jump)   J attack   S+J in the air: pogo   K dash   S+K in the air: dive   L parry (hold: blade)   F heal", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, PAPER)


const HINTS := {
	"gold": "GOLD FLASH: TAP  L  AS IT HITS - PARRY!",
	"red": "RED FLASH: YOU CAN'T PARRY THAT - DASH (K) OR JUMP AWAY",
	"riposte": "PARRIED! NOW  J : RIPOSTE",
	"broken": "POSTURE BROKEN!  J : CRITICAL STRIKE",
	"guard": "HE'S GUARDING: PARRY, OR HIT HIM FROM BEHIND OR FROM ABOVE (POGO, DIVE)",
}


func _draw_hints() -> void:
	var text := ""
	var col := PAPER
	var lesson := false
	for e in _enemies:
		if e.trainee and not e.dead:
			lesson = true
	if _phase == "wave" and lesson and parries == 0:
		text = "TAP  L  THE MOMENT HIS SPEAR FLASHES GOLD"
		col = GOLD
	elif _hint_t > 0.0:
		text = String(HINTS.get(_hint, ""))
		col = Color("ff6b6b") if _hint == "red" else (GOLD if _hint in ["gold", "riposte", "broken"] else PAPER)
	if text == "":
		return
	var fs := 24
	var w := FONT_SHOUT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var at := Vector2(640 - w * 0.5, 200)
	draw_rect(Rect2(at + Vector2(-14, -fs - 2), Vector2(w + 28, fs + 16)), Color(0, 0, 0, 0.55))
	draw_string_outline(FONT_SHOUT, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, INK)
	draw_string(FONT_SHOUT, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


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
