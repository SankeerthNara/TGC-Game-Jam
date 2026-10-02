class_name HeroActor
extends RefCounted
## The little comic hero who walks the page toward wherever the light ends up,
## and reacts to what he finds. Purely visual; PageView owns and drives him.

enum Mood { THINK, HAPPY, SCARED, CONFUSED }

var pos := Vector2.ZERO
var target := Vector2.ZERO
var gaze := Vector2.ZERO
var mood: Mood = Mood.THINK
var villain := false
var bubble := true ## thought bubble above the head
var torch := true ## carries a flickering torch in the right hand
var glow: Texture2D

var _placed := false
var _t := 0.0
var _walk := 0.0
var _facing := 1.0
var _moving := false


func reset() -> void:
	_placed = false
	mood = Mood.THINK
	villain = false


## Free-movement mode: the world sets the position every frame.
func drive(new_pos: Vector2, moving: bool, face_x: float, look_at: Vector2, delta: float) -> void:
	pos = new_pos
	target = new_pos
	gaze = look_at
	_placed = true
	_t += delta
	_moving = moving
	if moving:
		_walk += delta * 15.0
	if absf(face_x) > 0.1:
		_facing = signf(face_x)


func is_moving() -> bool:
	return _moving


## Teleports the hero (no walking animation).
func snap(stand: Vector2, look_at: Vector2) -> void:
	pos = stand
	target = stand
	gaze = look_at
	_placed = true
	_moving = false


func set_target(stand: Vector2, look_at: Vector2) -> void:
	target = stand
	gaze = look_at
	if not _placed:
		pos = stand
		_placed = true


func update(delta: float, cell: float) -> void:
	_t += delta
	var to := target - pos
	_moving = to.length() > 3.0
	if _moving:
		pos = pos.move_toward(target, cell * 7.0 * delta)
		_walk += delta * 15.0
		if absf(to.x) > 2.0:
			_facing = signf(to.x)
	else:
		_facing = signf(gaze.x - pos.x) if absf(gaze.x - pos.x) > 4.0 else _facing


func draw(c: CanvasItem, s: float, ink: Color, paper: Color, font: Font, base: Vector2) -> void:
	var hop := 0.0
	if mood == Mood.HAPPY and not _moving:
		hop = absf(sin(_t * 7.0)) * s * 0.22
	var step := absf(sin(_walk)) * s * 0.05 if _moving else 0.0
	var shake := Vector2(sin(_t * 60.0) * s * 0.02, 0.0) if mood == Mood.SCARED and not _moving else Vector2.ZERO
	var root := pos + shake
	var feet := root + Vector2(0, s * 0.3)

	# ground shadow
	c.draw_set_transform(base + feet, 0.0, Vector2(1.0, 0.3))
	c.draw_circle(Vector2.ZERO, s * 0.24 - hop * 0.2, Color(0, 0, 0, 0.3))
	c.draw_set_transform(base, 0.0, Vector2.ONE)

	var o := root + Vector2(0, -step - hop)
	var f := _facing
	var suit := Color("3a86ff") if not villain else Color("7b2cbf")
	var cape := Color("e63946") if not villain else Color("240046")
	var skin := Color("ffd9b3")

	# cape, trailing behind him (two triangles, so it is always a valid shape)
	var sway := sin(_t * 6.0 + _walk) * s * 0.04 + (-f * s * 0.1 if _moving else 0.0)
	var cs_l := o + Vector2(-0.12 * s, -0.02 * s)
	var cs_r := o + Vector2(0.12 * s, -0.02 * s)
	var hem_far := o + Vector2(-f * 0.3 * s + sway, 0.3 * s)
	var hem_near := o + Vector2(-f * 0.06 * s + sway, 0.34 * s)
	var mid := (cs_l + cs_r) * 0.5
	for tri in [[cs_l, mid, hem_far], [mid, cs_r, hem_near], [mid, hem_far, hem_near]]:
		c.draw_colored_polygon(PackedVector2Array(tri), cape)
	c.draw_polyline(PackedVector2Array([cs_l, hem_far, hem_near, cs_r]), ink, s * 0.03)

	# legs
	var swing := sin(_walk) * s * 0.09 if _moving else 0.0
	for side in [-1.0, 1.0]:
		var hip := o + Vector2(side * 0.07 * s, 0.2 * s)
		var foot := root + Vector2(side * 0.07 * s + side * swing, 0.34 * s)
		c.draw_line(hip, foot, ink, s * 0.1)
		c.draw_line(hip, foot, suit, s * 0.055)
		c.draw_circle(foot, s * 0.055, ink)

	# body
	c.draw_set_transform(base + o + Vector2(0, 0.08 * s), 0.0, Vector2(1.0, 1.25))
	c.draw_circle(Vector2.ZERO, s * 0.17, ink)
	c.draw_circle(Vector2.ZERO, s * 0.13, suit)
	c.draw_set_transform(base, 0.0, Vector2.ONE)
	var bolt_c := o + Vector2(0, 0.08 * s)
	c.draw_polyline(PackedVector2Array([bolt_c + Vector2(0.03, -0.08) * s, bolt_c + Vector2(-0.03, 0.0) * s, bolt_c + Vector2(0.03, 0.0) * s, bolt_c + Vector2(-0.03, 0.09) * s]), Color("ffd23f"), s * 0.035)
	# arms: wave when happy, up when scared
	var shoulder_l := o + Vector2(-0.12 * s, 0.03 * s)
	var shoulder_r := o + Vector2(0.12 * s, 0.03 * s)
	var hand_l := shoulder_l + Vector2(-0.08 * s, 0.12 * s + sin(_walk + 1.0) * s * 0.03 * (1.0 if _moving else 0.0))
	var hand_r := shoulder_r + Vector2(0.08 * s, 0.12 * s - sin(_walk) * s * 0.03 * (1.0 if _moving else 0.0))
	if mood == Mood.HAPPY and not _moving:
		hand_r = shoulder_r + Vector2(0.1 * s, -0.16 * s - hop * 0.3)
		hand_l = shoulder_l + Vector2(-0.1 * s, -0.16 * s - hop * 0.3)
	elif mood == Mood.SCARED and not _moving:
		hand_r = shoulder_r + Vector2(0.06 * s, -0.12 * s)
		hand_l = shoulder_l + Vector2(-0.06 * s, -0.12 * s)
	elif mood == Mood.THINK and not _moving:
		hand_r = o + Vector2(0.05 * s * f, -0.1 * s) # hand on chin
	if torch:
		hand_r = shoulder_r + Vector2(0.1 * s, -0.05 * s)
	for pair in [[shoulder_l, hand_l], [shoulder_r, hand_r]]:
		c.draw_line(pair[0], pair[1], ink, s * 0.095)
		c.draw_line(pair[0], pair[1], suit, s * 0.05)
		c.draw_circle(pair[1], s * 0.05, skin)
		c.draw_arc(pair[1], s * 0.05, 0.0, TAU, 12, ink, 1.6)

	if torch:
		_draw_torch(c, s, hand_r, ink, base)

	# head
	var h := o + Vector2(0, -0.2 * s)
	c.draw_circle(h, s * 0.215, ink)
	c.draw_circle(h, s * 0.19, skin)
	# hero mask
	c.draw_rect(Rect2(h + Vector2(-0.19 * s, -0.09 * s), Vector2(0.38 * s, 0.1 * s)), ink)
	# eyes follow the light
	var look := (gaze - (root + Vector2(0, -0.2 * s)))
	var look_dir := look.normalized() * s * 0.02 if look.length() > 1.0 else Vector2.ZERO
	var eye_y := -0.045 * s
	for side in [-1.0, 1.0]:
		var ec: Vector2 = h + Vector2(side * 0.075 * s, eye_y)
		c.draw_circle(ec, s * 0.06, Color.WHITE)
		var pupil := ec + look_dir
		if mood == Mood.CONFUSED:
			pupil = ec + Vector2(sin(_t * 5.0 + side) * s * 0.02, cos(_t * 5.0) * s * 0.02)
		c.draw_circle(pupil, s * (0.032 if mood != Mood.SCARED else 0.02), ink)
		if villain:
			c.draw_line(ec + Vector2(-side * 0.07 * s, -0.09 * s), ec + Vector2(side * 0.05 * s, -0.04 * s), ink, s * 0.035)
	# mouth
	var m := h + Vector2(0, 0.1 * s)
	match mood:
		Mood.HAPPY:
			c.draw_arc(m + Vector2(0, -0.02 * s), s * 0.06, 0.15, PI - 0.15, 10, ink, s * 0.03)
		Mood.SCARED:
			c.draw_circle(m, s * 0.04, ink)
		Mood.CONFUSED:
			c.draw_polyline(PackedVector2Array([m + Vector2(-0.06, 0) * s, m + Vector2(-0.02, 0.025) * s, m + Vector2(0.02, -0.025) * s, m + Vector2(0.06, 0) * s]), ink, s * 0.028)
		_:
			c.draw_line(m + Vector2(-0.04 * s, 0), m + Vector2(0.04 * s, 0), ink, s * 0.03)
	if villain:
		c.draw_arc(m + Vector2(0, -0.035 * s), s * 0.07, 0.2, PI - 0.2, 10, ink, s * 0.035)
	if mood == Mood.SCARED:
		var drop := h + Vector2(0.2 * s, -0.12 * s + fmod(_t * s * 0.4, s * 0.15))
		c.draw_circle(drop, s * 0.03, Color("4cc9f0"))

	# thought / shout bubble
	if not bubble:
		return
	var symbol := "?"
	match mood:
		Mood.HAPPY:
			symbol = "!"
		Mood.SCARED:
			symbol = "!?"
		Mood.CONFUSED:
			symbol = "??"
		_:
			symbol = "?" if fmod(_t, 2.4) < 1.2 else "..."
	var bub := h + Vector2(0.3 * s, -0.42 * s - sin(_t * 3.0) * s * 0.02)
	c.draw_circle(h + Vector2(0.2 * s, -0.24 * s), s * 0.025, ink)
	c.draw_circle(h + Vector2(0.25 * s, -0.3 * s), s * 0.04, ink)
	c.draw_set_transform(base + bub, 0.0, Vector2(1.35, 1.0))
	c.draw_circle(Vector2.ZERO, s * 0.2, ink)
	c.draw_circle(Vector2.ZERO, s * 0.17, paper if paper.get_luminance() > 0.5 else Color("fff9e6"))
	c.draw_set_transform(base, 0.0, Vector2.ONE)
	var fs := int(s * 0.34)
	var sz := font.get_string_size(symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	c.draw_string(font, bub + Vector2(-sz.x * 0.5, fs * 0.34), symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("18151d"))


## Offset from the hero's position to the torch flame (so the world can put a light there).
func torch_offset(s: float) -> Vector2:
	return Vector2(0.22 * s, -0.42 * s)


func _draw_torch(c: CanvasItem, s: float, hand: Vector2, ink: Color, base: Vector2) -> void:
	var top := hand + Vector2(0.0, -0.24 * s)
	c.draw_line(hand + Vector2(0, 0.03 * s), top, ink, s * 0.075)
	c.draw_line(hand + Vector2(0, 0.03 * s), top, Color("a0522d"), s * 0.045)
	var flick := sin(_t * 17.0) * 0.1 + sin(_t * 29.0) * 0.06
	var tip := top + Vector2(flick * s * 0.2, -s * (0.3 + flick * 0.5))
	if glow != null:
		c.draw_texture_rect(glow, Rect2(top - Vector2(0.55, 0.62) * s, Vector2(1.1, 1.1) * s), false, Color(1.0, 0.75, 0.3, 0.55))
	c.draw_colored_polygon(PackedVector2Array([top + Vector2(-0.075 * s, 0), tip, top + Vector2(0.075 * s, 0)]), ink)
	c.draw_colored_polygon(PackedVector2Array([top + Vector2(-0.058 * s, -0.005 * s), tip + Vector2(0, s * 0.02), top + Vector2(0.058 * s, -0.005 * s)]), Color("ff8c1a"))
	c.draw_colored_polygon(PackedVector2Array([top + Vector2(-0.03 * s, -0.01 * s), top + Vector2(0, -0.12 * s), top + Vector2(0.03 * s, -0.01 * s)]), Color("ffe066"))
