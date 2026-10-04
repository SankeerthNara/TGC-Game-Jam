extends Node
## Screenshots of the console tasks as they look in the 144p edition (not part of the game).

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
	var n := 0
	for t: Vector2i in main.world._task_at.keys():
		var task: Dictionary = main.world._task_at[t]
		if task.get("is_fix", false):
			continue
		main.world._console_cd = 0.0
		main.world._open_task(t)
		await frames(60)
		get_viewport().get_texture().get_image().save_png("user://t144_%d_%s.png" % [n, task["type"]])
		print("task ", n, " ", task["type"])
		if main._overlay != null and main._overlay.has_method("queue_free"):
			main._overlay.queue_free()
			main._overlay = null
		main._set_state("world")
		await frames(10)
		n += 1
		if n >= 3:
			break
	get_tree().quit()
