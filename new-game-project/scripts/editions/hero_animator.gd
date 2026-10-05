class_name HeroAnimator
extends RefCounted
## Smooth hero animation for the 2K fights and the 720p brawler, from whatever frames exist.
## Frame sets are looked up as <prefix>_<set>_1..N (hero_run_1..12, hero_attack1_1..3, px_hero_jump_1..4),
## counted once when first needed;
## so full animation sets can arrive at any time; without them the single frames we have are used.
## On top of the frames: short crossfades between animations, a quick turn-around, a motion smear on
## strikes, and a mesh warp of the picture that gives lean with speed, squash and stretch, breathing,
## anticipation and follow-through on attacks, hit recoil, and a spring-driven cape and hair that
## trail behind the body.

const GRID := 6 ## the picture is drawn as a GRID x GRID mesh so it can bend
const LOOP := ["idle", "run", "heal"]
## Short transitions played once when their frame set exists, then the hero goes on to the next state.
const LOCOMOTION := ["idle", "run", "skid", "land", "turn", "runstart"]
## Animations whose frames follow the attack's progress (0..1) instead of a frame rate.
const BY_PROGRESS := ["attack1", "attack2", "attack3", "attack_up", "attack_down", "counter", "blade"]

var prefix := "hero"
## anim -> the frames to use when no <prefix>_<anim>_N set exists
var fallback := {}
## anim -> the name of its frame set when it differs (attack_up -> upslash, attack1 -> punch1)
var aliases := {}
## anim -> frames per second
var rates := {"idle": 8.0, "run": 14.0, "runstart": 18.0, "jump": 10.0, "fall": 10.0, "attack1": 24.0, "attack2": 24.0,
	"attack3": 18.0, "attack_up": 22.0, "attack_down": 22.0, "dash": 16.0, "roll": 16.0, "hurt": 12.0,
	"skid": 20.0, "land": 16.0, "heal": 8.0, "counter": 20.0, "turn": 18.0, "blade": 14.0, "ko": 8.0}

var anim := "idle"
var t := 0.0 ## time in the current animation
var key := "" ## the frame on screen
var face := 1.0 ## drawn facing: swings through zero on a turn
var lean := 0.0 ## shear of the body toward +x (world)
var lag := Vector2.ZERO ## how far the cape and hair trail behind (pixels)
var squash := 1.0 ## >1 stretched tall, <1 squashed
var recoil := 0.0 ## 1 on a hit taken, fades
var attack := -1.0 ## 0..1 through an attack, -1 when not attacking
var combo := 1 ## 1, 2, 3: each hit of a combo moves differently

var _prev_key := ""
var _prev_alpha := 0.0
var _lean_v := 0.0
var _lag_v := Vector2.ZERO
var _squash_v := 0.0
var _prev_vel := Vector2.ZERO
var _clock := 0.0
var _oneshot := "" ## a transition set playing once (turn, runstart, skid, land)
var _oneshot_t := 0.0
var _last_face := 1.0
var _last_want := "idle"
var _landed_now := false
static var _sets := {}
static var _full := {}


func _init(p: String, fb: Dictionary, al := {}) -> void:
	prefix = p
	fallback = fb
	aliases = al


## The frame set <prefix>_<set>_1..N, counted once (empty if there is none).
func _frame_set(name: String) -> Array:
	var id := prefix + "_" + name
	if not _full.has(id):
		var list: Array = []
		var n := 1
		while Sprites.has("%s_%d" % [id, n]):
			list.append("%s_%d" % [id, n])
			n += 1
		_full[id] = list
	return _full[id]


## True when a real frame set exists for this animation (not just the fallback frames).
func has_set(a: String) -> bool:
	return not frames(a).is_empty() and frames(a)[0].ends_with("_1") and frames(a)[0].begins_with(prefix + "_")


## The frames of an animation: its full set if it exists, else the fallback frames.
## "air" is the whole jump arc (the frame is picked by vertical speed).
func frames(a: String) -> Array:
	var id := prefix + "|" + a
	if not _sets.has(id):
		var list: Array = _frame_set(String(aliases.get(a, "jump" if a == "air" else a))).duplicate()
		if list.is_empty():
			for k: String in fallback.get(a, fallback.get("idle", [])):
				if Sprites.has(k):
					list.append(k)
		_sets[id] = list
	return _sets[id]


func has_art() -> bool:
	return not frames("idle").is_empty()


# --- events from the game ---------------------------------------------------------------------

func jumped() -> void:
	squash = 1.16
	_squash_v = 0.0


func landed(impact: float) -> void:
	squash = 1.0 - clampf(impact / 2000.0, 0.06, 0.26)
	_squash_v = 0.0
	_landed_now = true


func hurt() -> void:
	recoil = 1.0


func start_attack(n: int) -> void:
	combo = n
	attack = 0.0


# --- per frame -----------------------------------------------------------------------------------

## want: the animation the game asks for; vel: the hero's velocity; want_face: +1 / -1.
func update(delta: float, want: String, vel: Vector2, want_face: float, run_speed: float, ground: bool) -> void:
	_clock += delta
	# one jump arc for going up and coming down, when the set exists
	if want in ["jump", "fall"] and has_set("air"):
		want = "air"
	# transitions played once when their sets exist: turn, run start, skid, land
	var wf := signf(want_face) if want_face != 0.0 else _last_face
	if ground and want in LOCOMOTION:
		if wf != _last_face and has_set("turn"):
			_start_oneshot("turn")
		elif want == "skid" and _last_want != "skid" and has_set("skid"):
			_start_oneshot("skid")
		elif _landed_now and has_set("land"):
			_start_oneshot("land")
		elif want == "run" and _last_want in ["idle", "land"] and has_set("runstart"):
			_start_oneshot("runstart")
	_landed_now = false
	_last_face = wf
	_last_want = want
	_oneshot_t = maxf(0.0, _oneshot_t - delta)
	if _oneshot_t > 0.0 and want in LOCOMOTION:
		want = _oneshot
	else:
		_oneshot_t = 0.0
	if want != anim:
		if key != "":
			_prev_key = key
			_prev_alpha = 1.0
		anim = want
		t = 0.0
	var rate: float = rates.get(anim, 10.0)
	if anim == "run":
		rate *= clampf(absf(vel.x) / run_speed, 0.45, 1.3)
	t += delta
	var fr := frames(anim)
	if not fr.is_empty():
		var i := int(t * rate)
		if anim in BY_PROGRESS and attack >= 0.0:
			i = int(attack * fr.size()) # the frames follow the swing: wind-up, strike, recovery
		elif anim == "air":
			i = _arc_frame(fr.size(), vel.y)
		key = fr[i % fr.size()] if anim in LOOP else fr[mini(i, fr.size() - 1)]
	_prev_alpha = maxf(0.0, _prev_alpha - delta / 0.1)
	var f := signf(want_face) if want_face != 0.0 else signf(face)
	if has_set("turn") and ground:
		face = f # the turn frames show the turn; no squeeze through the edge
	else:
		face = move_toward(face, f, delta * 16.0) # a turn takes about an eighth of a second
	# lean: into the run, back on a skid or a hit, with the swing of an attack
	var acc := (vel - _prev_vel) / maxf(delta, 0.001)
	_prev_vel = vel
	var lean_target := clampf(vel.x / run_speed, -1.2, 1.2) * (0.11 if ground else 0.05)
	if anim == "skid":
		lean_target = -signf(vel.x) * 0.16
	if attack >= 0.0:
		lean_target += _attack_lean() * f
	lean_target -= recoil * 0.3 * f
	_lean_v += (lean_target - lean) * 300.0 * delta
	_lean_v *= exp(-17.0 * delta)
	lean += _lean_v * delta
	# the cape trails behind the motion and overshoots when the hero stops: a damped spring
	var lag_target := Vector2(-vel.x * 0.05 - acc.x * 0.005, -vel.y * 0.022 - acc.y * 0.0015).limit_length(46.0)
	_lag_v += (lag_target - lag) * 150.0 * delta
	_lag_v *= exp(-6.5 * delta)
	lag += _lag_v * delta
	# squash and stretch spring back
	_squash_v += (1.0 - squash) * 320.0 * delta
	_squash_v *= exp(-13.0 * delta)
	squash += _squash_v * delta
	recoil = maxf(0.0, recoil - delta * 4.0)


func _start_oneshot(a: String) -> void:
	_oneshot = a
	_oneshot_t = frames(a).size() / float(rates.get(a, 14.0))


## The frame of the jump arc for a vertical speed. 6 frames (2K): crouch, take-off, rising, apex,
## falling, about to land. 4 frames (720p): take-off, rising, apex, falling. Any other count: spread.
func _arc_frame(n: int, vy: float) -> int:
	if n >= 6:
		if t < 0.06 and vy < -600.0:
			return 0
		if vy < -450.0:
			return 1
		if vy < -130.0:
			return 2
		if vy < 160.0:
			return 3
		return 4 if vy < 650.0 else 5
	if n == 4:
		if vy < -450.0:
			return 0
		if vy < -130.0:
			return 1
		return 2 if vy < 160.0 else 3
	return clampi(int(clampf((vy + 900.0) / 1800.0, 0.0, 0.999) * n), 0, n - 1)


## Anticipation, strike and follow-through of an attack, as a lean (+ = toward the enemy).
func _attack_lean() -> float:
	var p := attack
	var back := -0.1 if combo != 2 else -0.05
	var strike := 0.2 if combo == 1 else (0.12 if combo == 2 else 0.3)
	if p < 0.18:
		return back * p / 0.18
	if p < 0.45:
		return lerpf(back, strike, (p - 0.18) / 0.27)
	return lerpf(strike, 0.0, clampf((p - 0.45) / 0.55, 0.0, 1.0))


# --- drawing -------------------------------------------------------------------------------------

## Draws the hero with his feet at `feet`, the picture `height` pixels tall. False if there is no art.
func draw(ci: CanvasItem, feet: Vector2, height: float, tint := Color.WHITE) -> bool:
	if key == "" or not Sprites.has(key):
		return false
	ci.draw_set_transform(Vector2.ZERO)
	if _prev_alpha > 0.0 and _prev_key != "" and _prev_key != key and Sprites.has(_prev_key):
		_mesh(ci, _prev_key, feet, height, Color(tint.r, tint.g, tint.b, tint.a * _prev_alpha * 0.55))
	if attack >= 0.18 and attack < 0.5:
		# a smear of the strike
		for k in 2:
			_mesh(ci, key, feet - Vector2(signf(face) * (16.0 + 16.0 * k), 0), height, Color(tint.r, tint.g, tint.b, tint.a * (0.26 / (k + 1))))
	_mesh(ci, key, feet, height, tint)
	return true


func _mesh(ci: CanvasItem, k: String, feet: Vector2, height: float, col: Color) -> void:
	var tex := Sprites.get_tex(k)
	var ts := tex.get_size()
	var sq := squash
	if anim == "idle":
		sq *= 1.0 + sin(_clock * 2.6) * 0.012 # breathing
	var h := height * sq
	var w := ts.x * (height / ts.y) / sq
	var fs := face if absf(face) > 0.12 else 0.12 * signf(face if face != 0.0 else 1.0)
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	var cols := PackedColorArray()
	for j in GRID + 1:
		var v := j / float(GRID)
		for i in GRID + 1:
			var u := i / float(GRID)
			var lx := (u - 0.5) * w
			var ly := (v - 1.0) * h
			if anim == "idle":
				lx *= 1.0 + sin(_clock * 2.6) * 0.015 * sin(v * PI) # the chest swells a little
			var p := Vector2(lx * fs, ly)
			p.x += lean * -ly
			# loose parts: the back of the picture (the cape; sprites face right) and its lower half most
			var back := clampf(1.0 - u * 1.7, 0.0, 1.0)
			p += lag * back * (0.15 + 0.85 * v)
			pts.append(feet + p)
			uvs.append(Vector2(lerpf(0.5 / ts.x, 1.0 - 0.5 / ts.x, u), lerpf(0.5 / ts.y, 1.0 - 0.5 / ts.y, v)))
			cols.append(col)
	var idx := PackedInt32Array()
	for j in GRID:
		for i in GRID:
			var a := j * (GRID + 1) + i
			idx.append_array([a, a + 1, a + GRID + 1, a + 1, a + GRID + 2, a + GRID + 1])
	RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), idx, pts, cols, uvs, PackedInt32Array(), PackedFloat32Array(), tex.get_rid())
