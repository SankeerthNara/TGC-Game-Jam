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
	check(main.world.tasks.size() == 3, "144p level 1 is short: 3 tasks (%d)" % main.world.tasks.size())
	var first_id: String = main.world.tasks[0]["id"]
	main.world.complete_task(first_id)
	main._on_player_died()
	await frames(3)
	var death: DeathOverlay = find_child_of(main._task_layer, DeathOverlay)
	check(death != null, "dying shows the death screen")
	if death != null:
		death.restart.emit()
	await frames(5)
	check(main.world.tasks_done.has(first_id) and main.state == "world", "after a death the finished task stays finished")
	main._level_complete()
	await frames(3)
	main._overlay.continue_pressed.emit()
	await frames(5)
	check(main.level_idx == 1, "level 2 of 144p")
	check(main.world.tasks.size() == 5, "144p level 2: 5 tasks (%d)" % main.world.tasks.size())
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
	check(await wait_until(func() -> bool: return main._overlay is BossFight and main._overlay.stage == "hall"), "2k level 1: the library hall")
	check(main._overlay._exploring and main._overlay.level_width > 1280.0, "the hall scrolls")
	main._overlay.finished.emit("win")
	check(await wait_until(func() -> bool: return main._overlay is BossFight and main._overlay.stage == "opera"), "2k level 2: the opera arena")
	main._overlay.finished.emit("win")
	check(await wait_until(func() -> bool: return d.comms.dead), "the comms die")
	check(await wait_until(func() -> bool: return main._overlay is ComicCutscene and main._overlay.kind == "reveal"), "the reveal cutscene")
	main._overlay.skip()
	check(await wait_until(func() -> bool: return main._overlay is BossFight and main._overlay.stage == "dark"), "the final boss: the Narrator")
	check(main._overlay.caged_heroes, "the three heroes hang in cages")
	main._overlay.finished.emit("win")
	check(await wait_until(func() -> bool: return find_child_of(main, BrightnessFinale) != null), "the brightness finale")
	find_child_of(main, BrightnessFinale)._value = 1.0
	check(await wait_until(func() -> bool: return main._overlay is ComicCutscene and main._overlay.kind == "ending_editions"), "the ending")
	main._overlay.skip()
	check(await wait_until(func() -> bool: return main._overlay is LevelOverlay and main._overlay.final), "the final screen")
	print("FAILS: %d" % fails)
	Engine.time_scale = 1.0
	get_tree().quit()
