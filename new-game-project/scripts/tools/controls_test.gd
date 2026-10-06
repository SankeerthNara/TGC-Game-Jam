extends Node
## The new controls (not part of the game): WASD moves like the arrows, Space jumps like Z,
## J/K/L attack, dash/roll and power/counter, and X/C/V no longer do anything.

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


func _ready() -> void:
	var b := BossFight.new()
	b.heroes = [0]
	b.relay = false
	b.bomb_left = -1.0
	b.waves = [[[["lancer", "L", 999.0]]]]
	add_child(b)
	await frames(3)
	b._pt = 10.0
	await frames(120)
	var x0: float = b.hero_pos.x
	key(KEY_D, true)
	await frames(20)
	key(KEY_D, false)
	ok(b.hero_pos.x > x0 + 40.0, "2K: D moves right (%.0f -> %.0f)" % [x0, b.hero_pos.x])
	x0 = b.hero_pos.x
	key(KEY_A, true)
	await frames(20)
	key(KEY_A, false)
	ok(b.hero_pos.x < x0 - 40.0, "2K: A moves left")
	await frames(20)
	key(KEY_SPACE, true)
	await frames(3)
	ok(b._vel.y < 0.0, "2K: Space jumps")
	key(KEY_SPACE, false)
	await frames(80)
	key(KEY_W, true)
	key(KEY_J, true)
	await frames(2)
	ok(b._atk_t > 0.0 and b._atk_dir == "up", "2K: W + J up-slash (%s)" % b._atk_dir)
	key(KEY_J, false)
	key(KEY_W, false)
	await frames(30)
	key(KEY_K, true)
	await frames(2)
	ok(b._dash_t > 0.0, "2K: K dashes")
	key(KEY_K, false)
	await frames(40)
	b._ink = 3
	key(KEY_L, true)
	await frames(2)
	ok(b._parry_t > 0.0 and b._ink == 3, "2K: tap L opens the parry window")
	await frames(25)
	ok(b._ink == 0, "2K: hold L fires the Light Blade (ink %d)" % b._ink)
	key(KEY_L, false)
	await frames(40)
	b._atk_cd = 0.0
	b._ink = 6
	for k in [KEY_X, KEY_C, KEY_V]:
		key(k, true)
		await frames(2)
		key(k, false)
	ok(b._atk_t <= 0.0 and b._dash_t <= 0.0 and b._ink == 6, "2K: X / C / V do nothing now")
	b.queue_free()
	var g := BrawlerGame.new()
	g.stage = "street"
	add_child(g)
	await frames(3)
	g._phase = "play"
	g._counters = 1
	x0 = g.hero_pos.x
	key(KEY_D, true)
	await frames(20)
	key(KEY_D, false)
	ok(g.hero_pos.x > x0 + 40.0, "720p: D moves right")
	await frames(20)
	key(KEY_J, true)
	await frames(2)
	ok(g._atk_t > 0.0, "720p: J punches")
	key(KEY_J, false)
	await frames(40)
	key(KEY_K, true)
	await frames(2)
	ok(g._roll_t > 0.0, "720p: K rolls")
	key(KEY_K, false)
	await frames(60)
	key(KEY_L, true)
	await frames(2)
	ok(g._counter_cd > 0.0, "720p: L tries a counter")
	key(KEY_L, false)
	print("CONTROLS FAILS: ", fails)
	get_tree().quit()
