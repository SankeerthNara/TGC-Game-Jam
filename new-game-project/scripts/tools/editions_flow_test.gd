extends Node
## Walks through "The Editions" flow headless and checks every step (not part of the game).

var fails := 0


func check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func wait_until(f: Callable, max_frames := 2400) -> bool:
	for i in max_frames:
		if f.call():
			return true
		await get_tree().process_frame
	return false


func find_child_of(node: Node, cls: Variant) -> Node:
	for c in node.get_children():
		if is_instance_of(c, cls):
			return c
	return null


func _ready() -> void:
	Engine.time_scale = 4.0
	get_tree().create_timer(300.0, true, false, true).timeout.connect(func() -> void: print("TIMEOUT"); get_tree().quit())
	var main: Node = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(main)
	await frames(5)
	EventBus.request_start_game.emit()
	await frames(3)
	var d: EditionsDirector = main.director
	check(d != null and d.act == "book" and main._overlay is ComicCutscene and main._overlay.kind == "book", "the book opens first")
	main._overlay.skip()
	check(await wait_until(func() -> bool: return main.state == "world"), "the book glitches into the 144p game")
	check(d.fx.edition == "144p", "the picture is 144p (%s)" % d.fx.edition)
	check(main.level_idx == 0 and main.bomb_left < 0.0, "level 1, no bomb clock")
	main._level_complete()
	await frames(3)
	main._overlay.continue_pressed.emit()
	await frames(5)
	check(main.level_idx == 1, "level 2 of 144p")
	main._level_complete()
	await frames(3)
	main._overlay.continue_pressed.emit()
	check(await wait_until(func() -> bool: return main.state == "boss"), "the Ink Baron fight starts")
	var boss: BossFight = main._overlay
	check(boss != null and boss.boss_name == "THE INK BARON" and boss.heroes == [0], "one hero against the Ink Baron")
	boss.finished.emit("win")
	check(await wait_until(func() -> bool: return find_child_of(main, SettingsTwist) != null), "twist 1: the settings window appears")
	var tw: SettingsTwist = find_child_of(main, SettingsTwist)
	check(tw.mode == "player", "the player chooses the resolution")
	await wait_until(func() -> bool: return tw._phase == "choose")
	tw._pick(3)
	check(tw._phase == "choose", "1080p is not allowed yet")
	tw._pick(2)
	check(await wait_until(func() -> bool: return d.act == "720p"), "720p edition starts")
	check(await wait_until(func() -> bool: return d.fx.edition == "720p"), "the picture is 720p")
	check(await wait_until(func() -> bool: return main._overlay is BrawlerGame), "the 720p brawler starts (neon street)")
	main._overlay.finished.emit("win")
	check(await wait_until(func() -> bool: return main._overlay is BrawlerGame and main._overlay.stage == "train"), "then the Static Twins on the train")
	main._overlay.finished.emit("win")
	check(await wait_until(func() -> bool: return find_child_of(main, SettingsTwist) != null), "twist 2: the settings window again")
	tw = find_child_of(main, SettingsTwist)
	check(tw.mode == "hijack", "the cursor is hijacked")
	check(await wait_until(func() -> bool: return d.act == "2k"), "the cursor picks 2K by itself")
	check(await wait_until(func() -> bool: return d.fx.edition == "2k"), "the picture is 2k")
	print("FAILS: %d" % fails)
	Engine.time_scale = 1.0
	get_tree().quit()
