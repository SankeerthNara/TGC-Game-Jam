extends Node
## The library as the game builds it, played by the arena bot: fights, the climb, the exit (not part
## of the game). Prints time, assists and whether the level was finished.

var _keys := {}


func press(k: Key, on: bool) -> void:
	if _keys.get(k, false) == on:
		return
	_keys[k] = on
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.pressed = on
	Input.parse_input_event(ev)


func tap(k: Key) -> void:
	press(k, false)
	press(k, true)


func _ready() -> void:
	var main: Node = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(main)
	for i in 5:
		await get_tree().process_frame
	EventBus.request_start_game.emit()
	for i in 10:
		await get_tree().process_frame
	main._overlay.skip()
	for i in 200:
		await get_tree().process_frame
	main.director.act = "2k"
	main.director.fx.set_edition("2k")
	main.director.comms.clear()
	main.director.start_2k()
	var b: BossFight = main._overlay
	var result := [""]
	b.finished.connect(func(r: String) -> void: result[0] = r)
	var f := 0
	var last_wp := -1
	while result[0] == "" and f < 60 * 300:
		ArenaBot.drive(b, press, tap)
		await get_tree().process_frame
		f += 1
		if b._phase == "explore" and b.get_meta("bot_wp", 0) == 1 and f % 10 == 0:
			print("    chimney: pos %s vel %s ground %s wall %d slide %s wcoy %.2f wj %.2f" % [str(b.hero_pos.round()), str(b._vel.round()), b._ground, b._wall, b._sliding, b._wall_coyote, b._wj_lock])
		if b._phase == "wave" and f % 300 == 0:
			var es := []
			for e in b._enemies:
				es.append("%s %s %s fy%.0f" % [e.kind, str(e.pos.round()), e.state, e.floor_y])
			print("  wave: hero %s ground %s floor %.0f lock %.0f-%.0f pending %d enemies %s" % [str(b.hero_pos.round()), b._ground, b.floor_y, b._lock_l, b._lock_r, b._pending.size(), str(es)])
		var wp: int = b.get_meta("bot_wp", 0)
		if wp != last_wp:
			print("t=%.1f waypoint %d  hero %s  assists %d" % [b._t, wp, str(b.hero_pos.round()), b.bot_assists])
			last_wp = wp
	print("CLIMB RESULT: %s after %.0f s, assists %d, phase %s" % [result[0], b._t, b.bot_assists, b._phase])
	get_tree().quit()
