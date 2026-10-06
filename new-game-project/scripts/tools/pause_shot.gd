extends Node
## The pause screen and the library's intro card, for a layout check (not part of the game).

var main: Node


func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(main)
	await frames(5)
	EventBus.request_start_game.emit()
	await frames(30)
	main._overlay.skip()
	await frames(150)
	main.director.act = "2k"
	main.director.fx.set_edition("2k")
	main.director.start_2k()
	await frames(40)
	get_viewport().get_texture().get_image().save_png("user://card_library.png")
	main._set_paused(true)
	await frames(10)
	get_viewport().get_texture().get_image().save_png("user://pause_screen.png")
	get_tree().quit()
