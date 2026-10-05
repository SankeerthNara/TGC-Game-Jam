extends Node
## The first dark room in 144p and without the filter, for a readability check (not part of the game).

var main: Node


func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _ready() -> void:
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(main)
	await frames(5)
	EventBus.request_start_game.emit()
	await frames(30)
	main._overlay.skip()
	for i in 2000:
		if main.state == "world":
			break
		await get_tree().process_frame
	await frames(150)
	main.director.comms.clear()
	await frames(5)
	get_viewport().get_texture().get_image().save_png("user://w144_on.png")
	main.director.fx.set_edition("2k")
	await frames(5)
	get_viewport().get_texture().get_image().save_png("user://w144_off.png")
	get_tree().quit()
