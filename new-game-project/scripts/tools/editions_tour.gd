extends Node
## Screenshots of the editions flow for a visual check (not part of the game).

func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png("user://ed_%s.png" % name)


func _ready() -> void:
	var main: Node = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(main)
	await frames(5)
	EventBus.request_start_game.emit()
	await frames(3)
	main._overlay.show_at(1, 4.0)
	await frames(4)
	shot("book")
	main._overlay.skip()
	await get_tree().create_timer(3.0).timeout
	shot("144_level")
	main._level_complete()
	await frames(3)
	main._overlay.continue_pressed.emit()
	await frames(5)
	main._level_complete()
	await frames(3)
	main._overlay.continue_pressed.emit()
	await get_tree().create_timer(9.5).timeout
	shot("144_boss")
	main._overlay.finished.emit("win")
	await get_tree().create_timer(9.5).timeout
	shot("twist1")
	for n in get_tree().root.find_children("*", "Label", true, false):
		if "Brilliant" in (n as Label).text:
			print("LABEL: ", n.get_path(), " visible ", (n as Label).is_visible_in_tree())
	var tw: Node = null
	for c in main.get_children():
		if c is SettingsTwist:
			tw = c
	tw._pick(2)
	await get_tree().create_timer(4.5).timeout
	shot("720_card")
	get_tree().quit()
