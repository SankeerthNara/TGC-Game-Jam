extends Node
## Measures the length of a full Editions run (not part of the game). The story cutscenes auto-advance
## (nobody presses Z), the fights are played by simple bots, the settings window is clicked after a
## few seconds of "reading". The 144p task levels cannot be played by a bot, so they are skipped and
## their par times (what the levels are tuned for) are added afterwards.
## Prints the time of every part and the total in game seconds.

const LEVEL_PAR := [120.0, 180.0] ## 144p levels 1 and 2 (par times)
const READ := 3.0 ## seconds a first-time player looks at a score card or settings window

var main: Node
var _keys := {}
var _parts := {}
var _order: Array[String] = []
var _total := 0.0
var _wait := 0.0


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


func release_all() -> void:
	for k in _keys.keys():
		press(k, false)


func _ready() -> void:
	Engine.time_scale = 2.0
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(main)
	for i in 5:
		await get_tree().process_frame
	EventBus.request_start_game.emit()


func _label() -> String:
	var d: EditionsDirector = main.director
	if d == null:
		return "start"
	var ov: Variant = main._overlay
	if ov is ComicCutscene:
		return "cutscene: " + String(ov.kind)
	if ov is BossFight:
		return "fight: " + (ov.fight_title if ov.fight_title != "" else ov.stage)
	if ov is BrawlerGame:
		return "brawler: " + String(ov.stage)
	if ov is FakeCredits:
		return "twist 2 (credits + hijack)"
	if ov is LevelOverlay:
		return "score cards"
	return "between scenes (%s)" % d.act


func _process(delta: float) -> void:
	if main == null or main.director == null:
		return
	var label := _label()
	if not _parts.has(label):
		_parts[label] = 0.0
		_order.append(label)
	_parts[label] = float(_parts[label]) + delta
	_total += delta
	_wait = maxf(0.0, _wait - delta)
	var ov: Variant = main._overlay
	# 144p levels: skip them (their par time is added at the end)
	if main.state == "world" and _wait <= 0.0:
		main._level_complete()
		_wait = READ
		return
	if ov is LevelOverlay and not ov.final and _wait <= 0.0:
		ov.continue_pressed.emit()
		return
	if ov is LevelOverlay and ov.final:
		release_all()
		_report()
		set_process(false)
		get_tree().quit()
		return
	for c in main.get_children():
		if c is SettingsTwist and c.mode == "player" and c._phase == "choose":
			if _wait <= 0.0 and c._t > READ:
				c._pick(2)
		if c is BrightnessFinale:
			press(KEY_RIGHT, true)
	if ov is BossFight:
		_drive_arena(ov)
	elif ov is BrawlerGame:
		_drive_brawler(ov)
	else:
		for k in [KEY_LEFT, KEY_RIGHT, KEY_X, KEY_Z, KEY_C, KEY_V, KEY_F, KEY_UP]:
			if k != KEY_RIGHT or not _has_finale():
				press(k, false)
	if _total > 3600.0:
		print("TIMEOUT")
		_report()
		get_tree().quit()


func _has_finale() -> bool:
	for c in main.get_children():
		if c is BrightnessFinale:
			return true
	return false


func _report() -> void:
	Engine.time_scale = 1.0
	print("PLAYTIME (game seconds, bots in the fights, no cutscene skipping):")
	for k in _order:
		print("  %-40s %6.1f s" % [k, float(_parts[k])])
	var measured := _total
	var levels := 0.0
	for p in LEVEL_PAR:
		levels += p
	print("  %-40s %6.1f s (par, not played)" % ["144p task levels", levels])
	print("TOTAL %.1f s = %.1f min (measured %.1f + 144p levels %.1f)" % [measured + levels, (measured + levels) / 60.0, measured, levels])


# --- bots (the same as arena_bot_test / brawler_bot_test) ------------------------------------

func _drive_arena(b: BossFight) -> void:
	for k in [KEY_X, KEY_Z, KEY_C, KEY_V, KEY_F]:
		press(k, false)
	if not b._phase in ["wave", "wave_intro", "explore"]:
		press(KEY_LEFT, false)
		press(KEY_RIGHT, false)
		return
	var hero := b.hero_pos
	var best: ArenaEnemy = null
	var best_d := 1e9
	for e in b._enemies:
		if e.state == "enter":
			continue
		var d := e.center().distance_to(b.hero_center())
		if d < best_d:
			best_d = d
			best = e
	var want := b.level_width - 60.0 if b._exploring else b.center_x()
	if best != null and (not b._exploring or best_d < 400.0):
		want = best.pos.x - signf(best.pos.x - hero.x) * 70.0
	var danger := false
	for e in b._enemies:
		if e.state in ["windup", "charge_wind", "fuse", "dive", "lunge", "charge", "dash"] and e.center().distance_to(b.hero_center()) < 200.0:
			danger = true
			want = hero.x + signf(hero.x - e.pos.x) * 200.0
	press(KEY_LEFT, want < hero.x - 12.0)
	press(KEY_RIGHT, want > hero.x + 12.0)
	for w in b._waves:
		if absf(float(w["x"]) - hero.x) < 120.0 and signf(hero.x - float(w["x"])) == float(w["dir"]) and b._ground:
			tap(KEY_Z)
	for d in b._drops:
		if absf(float(d["x"]) - hero.x) < 40.0:
			press(KEY_RIGHT, float(d["x"]) < hero.x)
			press(KEY_LEFT, float(d["x"]) >= hero.x)
	if danger and b._dash_cd <= 0.0 and randf() < 0.1:
		tap(KEY_C)
	if best != null and b._atk_cd <= 0.0:
		var dv := best.center() - b.hero_center()
		if absf(dv.x) < 120.0 and dv.y < -60.0:
			press(KEY_UP, true)
			tap(KEY_X)
		elif absf(dv.x) < 125.0 and absf(dv.y) < 70.0:
			press(KEY_UP, false)
			tap(KEY_X)
		elif dv.y < -80.0 and absf(dv.x) < 160.0 and b._ground:
			tap(KEY_Z)
	else:
		press(KEY_UP, false)
	if b._ink >= 3 and best != null and best_d < 300.0 and (b._ink >= 7 or b._hp > 2):
		tap(KEY_V)
	if b._hp <= 2 and b._ink >= 6 and not danger:
		tap(KEY_F)


func _drive_brawler(g: BrawlerGame) -> void:
	for k in [KEY_X, KEY_V, KEY_C, KEY_Z]:
		press(k, false)
	if g._phase != "play":
		press(KEY_LEFT, false)
		press(KEY_RIGHT, false)
		return
	var best: BrawlEnemy = null
	var best_d := 1e9
	for e in g._enemies:
		var d := absf(e.pos.x - g.hero_pos.x)
		if d < best_d:
			best_d = d
			best = e
	var want := g.lock_right - 100.0
	if best != null:
		want = best.pos.x - signf(best.pos.x - g.hero_pos.x) * 70.0
	press(KEY_LEFT, want < g.hero_pos.x - 10.0)
	press(KEY_RIGHT, want > g.hero_pos.x + 10.0)
	for e in g._enemies:
		if e.counterable() and absf(e.pos.x - g.hero_pos.x) < 300.0 and randf() < 0.5:
			tap(KEY_V)
			return
	if not g._beams.is_empty() and g._ground:
		tap(KEY_Z)
	if best != null and best_d < 100.0:
		tap(KEY_X)
