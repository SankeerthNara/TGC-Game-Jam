extends Node
## Screenshots of every part of the editions flow, in order, for a visual check (not part of the game).

var main: Node


func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func wait(secs: float) -> void:
	await get_tree().create_timer(secs).timeout


func shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png("user://ed_%s.png" % name)


func until(f: Callable) -> void:
	for i in 3000:
		if f.call():
			return
		await get_tree().process_frame


func twist() -> SettingsTwist:
	for c in main.get_children():
		if c is SettingsTwist:
			return c
	return null


func _ready() -> void:
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(main)
	await frames(5)
	EventBus.request_start_game.emit()
	await wait(3.0)
	shot("01_book")
	main._overlay.skip()
	await wait(5.0)
	shot("02_144_level")
	main._level_complete()
	await frames(3)
	main._overlay.continue_pressed.emit()
	await frames(5)
	main._level_complete()
	await frames(3)
	main._overlay.continue_pressed.emit()
	await until(func() -> bool: return main.state == "boss")
	await wait(6.0)
	shot("03_144_baron")
	main._overlay.finished.emit("win")
	await until(func() -> bool: return twist() != null)
	await wait(1.0)
	shot("04_twist1")
	twist()._pick(2)
	await until(func() -> bool: return main._overlay is BrawlerGame)
	await wait(5.0)
	shot("05_720_street")
	main._overlay.finished.emit("win")
	await until(func() -> bool: return main._overlay is BrawlerGame and main._overlay.stage == "train")
	await wait(5.0)
	shot("06_720_twins")
	main._overlay.finished.emit("win")
	await until(func() -> bool: return twist() != null)
	await wait(2.0)
	shot("07_twist2")
	await until(func() -> bool: return main._overlay is BossFight)
	await wait(5.0)
	shot("08_2k_hall")
	main._overlay.finished.emit("win")
	await until(func() -> bool: return main._overlay is BossFight and main._overlay.stage == "opera")
	await wait(6.0)
	shot("09_2k_opera")
	main._overlay.finished.emit("win")
	await until(func() -> bool: return main._overlay is ComicCutscene and main._overlay.kind == "reveal")
	main._overlay.show_at(1, 7.0)
	await wait(0.5)
	shot("10_reveal")
	main._overlay.skip()
	await until(func() -> bool: return main._overlay is BossFight and main._overlay.stage == "dark")
	await wait(6.0)
	shot("11_narrator")
	main._overlay.finished.emit("win")
	await wait(2.5)
	shot("12_finale")
	for c in main.get_children():
		if c is BrightnessFinale:
			c._value = 1.0
	await until(func() -> bool: return main._overlay is ComicCutscene and main._overlay.kind == "ending_editions")
	main._overlay.show_at(0, 6.0)
	await wait(0.5)
	shot("13_ending")
	get_tree().quit()
