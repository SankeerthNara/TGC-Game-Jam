extends Node
## Saves screenshots of the main screens for a visual review (not part of the game).

const OUT := "C:/Users/sanke/AppData/Local/Temp/t/tour_%s.png"


func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(OUT % name)


func _ready() -> void:
	var main: Node = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(main)
	await frames(30)
	shot("menu")
	EventBus.request_start_game.emit()
	await frames(5)
	main._overlay.skip()
	await frames(5)
	# walk around level 2 so vampires and more rooms show
	main._level_complete()
	await frames(3)
	main._overlay.continue_pressed.emit()
	await frames(90)
	shot("level2")
	var w: World = main.world
	w.hero.pos += Vector2(300, 0)
	await frames(60)
	shot("level2b")
	print("done")
	get_tree().quit()
