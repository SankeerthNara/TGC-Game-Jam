extends Node
## The 2K parkour moves with real key presses (not part of the game): wall slide, wall jump, one air
## dash that a wall touch gives back, pogo off an enemy (refreshes a jump), dive strike.

var fails := 0


func ok(c: bool, what: String) -> void:
	print(("PASS " if c else "FAIL ") + what)
	if not c:
		fails += 1


func key(k: Key, on: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.pressed = on
	Input.parse_input_event(ev)


func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func fight(walls: Array[Rect2]) -> BossFight:
	var b := BossFight.new()
	b.heroes = [0]
	b.relay = false
	b.bomb_left = -1.0
	b.waves = [[[["lancer", "L", 999.0]]]]
	b.walls = walls
	add_child(b)
	await frames(3)
	b._pt = 10.0
	await frames(110)
	return b


func _ready() -> void:
	var b := await fight([Rect2(800, 100, 60, 420)])
	# wall slide: jump toward the wall and hold
	b.hero_pos = Vector2(700, BossFight.FLOOR_Y)
	key(KEY_D, true)
	key(KEY_Z, true)
	await frames(3)
	key(KEY_Z, false)
	var slid := false
	for i in 60:
		await get_tree().process_frame
		if b._sliding:
			slid = true
			break
	ok(slid and b._vel.y <= BossFight.WALL_SLIDE + 1.0, "wall slide: holding toward the wall slows the fall (%.0f)" % b._vel.y)
	ok(b._wall == 1, "touching the wall on the right")
	# wall jump
	key(KEY_Z, true)
	await frames(2)
	key(KEY_Z, false)
	ok(b._vel.y < -500.0 and b._vel.x < -300.0, "wall jump: up and away from the wall (%s)" % str(b._vel))
	key(KEY_D, false)
	# air dash, and the wall gives it back
	await frames(6)
	key(KEY_K, true)
	await frames(2)
	key(KEY_K, false)
	ok(b._dash_t > 0.0 and not b._air_dash, "air dash used")
	await frames(14)
	key(KEY_K, true)
	await frames(2)
	key(KEY_K, false)
	ok(b._dash_t <= 0.0 or b._air_dash == false, "only one air dash")
	b.queue_free()
	# pogo off an enemy: bounce and a jump back
	b = await fight([])
	var e := ArenaEnemy.new("lancer", Vector2(640, BossFight.FLOOR_Y))
	e.state = "idle"
	e.hp = 99.0
	b._enemies.append(e)
	b.hero_pos = Vector2(640, 380)
	b._vel = Vector2(0, 200)
	b._ground = false
	key(KEY_S, true)
	key(KEY_J, true)
	var bounced := false
	for i in 40:
		await get_tree().process_frame
		if b._vel.y < -600.0:
			bounced = true
			break
	key(KEY_J, false)
	key(KEY_S, false)
	ok(bounced and b._air_jump, "pogo: S + J bounces off an enemy and gives a jump back")
	await frames(6)
	ok(b._anim.anim == "pogo" and b._anim.key.begins_with("hero_pogo_"), "the pogo frames play after the bounce (%s)" % b._anim.key)
	# dive strike
	b.hero_pos = Vector2(470, 330)
	b._vel = Vector2.ZERO
	b._ground = false
	b._air_dash = true
	b._face = 1.0
	await frames(1)
	key(KEY_S, true)
	key(KEY_K, true)
	await frames(2)
	await frames(6)
	key(KEY_K, false)
	key(KEY_S, false)
	ok(b._dive_t > 0.0 and b._vel.y > 800.0 and b._vel.x > 400.0, "dive strike: S + K in the air dives down and forward")
	var hit := false
	for i in 60:
		await get_tree().process_frame
		if b._vel.y < -500.0:
			hit = true
			break
	ok(hit and e.hp < 99.0, "the dive hits the enemy and bounces off (hp %.0f)" % e.hp)
	print("PARKOUR FAILS: ", fails)
	get_tree().quit()
