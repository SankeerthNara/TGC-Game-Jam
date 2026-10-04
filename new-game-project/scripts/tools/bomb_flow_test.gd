extends Node
## Checks the bomb flow: opening cutscene -> level 1 with the clock ticking -> keys -> bomb room;
## and a second run where the clock runs out. Prints PASS/FAIL lines (not part of the game).

var fails := 0


func check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func skip_overlay(main: Node) -> void:
	var ov: Node = main._overlay
	if ov is CutScene or ov is ComicCutscene:
		ov.skip()
	elif ov is LevelOverlay:
		ov.continue_pressed.emit()
	await frames(3)


func shot(name: String) -> void:
	if DisplayServer.get_name() != "headless":
		get_viewport().get_texture().get_image().save_png("C:/Users/sanke/AppData/Local/Temp/t/flow_%s.png" % name)


func _ready() -> void:
	await get_tree().process_frame
	var root := get_tree().root
	var main: Node = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await frames(5)
	EventBus.request_start_game.emit()
	await frames(3)
	check(main.state == "cutscene", "opening cutscene plays first (state=%s)" % main.state)
	var b0: float = main.bomb_left
	await frames(30)
	check(is_equal_approx(main.bomb_left, b0), "bomb clock paused during the cutscene")
	await skip_overlay(main)
	check(main.state == "world" and main.level_idx == 0, "level 1 starts after the opening (state=%s)" % main.state)
	await frames(60)
	check(main.bomb_left < b0, "bomb clock ticks in the level (%.2f)" % main.bomb_left)
	shot("hud")
	# finish all four levels by force
	for lv in 4:
		main._level_complete()
		await frames(3)
		check(main.keys_found == lv + 1, "key %d found" % (lv + 1))
		if lv == 0 or lv == 3:
			await frames(40)
			shot("levelend_%d" % lv)
		var t: float = main.bomb_left
		await frames(20)
		check(is_equal_approx(main.bomb_left, t), "clock paused on the score screen")
		await skip_overlay(main)
		if lv < 3:
			check(main.level_idx == lv + 1, "level %d loaded" % (lv + 2))
	check(main.state == "cutscene" and main._overlay is ComicCutscene and main._overlay.kind == "bomb_room", "bomb room cutscene after level 4")
	await skip_overlay(main)
	check(main._overlay is LevelOverlay and main._overlay.final, "final screen after the bomb room")
	await skip_overlay(main)
	await frames(5)
	check(main.state == "menu", "back to the menu (state=%s)" % main.state)
	# second run: let the bomb go off
	EventBus.request_start_game.emit()
	await frames(3)
	await skip_overlay(main)
	main.bomb_left = 0.05
	await frames(10)
	check(main._overlay is ComicCutscene and main._overlay.kind == "earth_blast", "the Earth blasts when the clock hits 0")
	await skip_overlay(main)
	await frames(5)
	check(main.state == "menu", "menu after the blast (state=%s)" % main.state)
	print("FAILS: %d" % fails)
	get_tree().quit()
