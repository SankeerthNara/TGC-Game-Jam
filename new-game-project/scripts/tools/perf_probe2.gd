extends Node
## Frame rate of the menu and the 240p dark-room level inside the real game scene (not part of the game).

var main: Node


func _ready() -> void:
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(main)
	for i in 10:
		await get_tree().process_frame
	await measure("main menu")
	EventBus.request_start_game.emit()
	await measure("book (first page)")
	main._overlay.skip()
	for i in 2000:
		if main.state == "world":
			break
		await get_tree().process_frame
	await measure("240p level 1 (world)")
	main.world._foot += Vector2(300, 0)
	await measure("240p level 1 (moved)")
	get_tree().quit()


func measure(name: String) -> void:
	for i in 30:
		await get_tree().process_frame
	var n := 0
	var draws := 0.0
	var worst := 0.0
	var t0 := Time.get_ticks_msec()
	var last := Time.get_ticks_usec()
	while Time.get_ticks_msec() - t0 < 2500:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		worst = maxf(worst, (now - last) / 1000.0)
		last = now
		draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		n += 1
	print("%-26s frames/s %5.1f   worst frame %5.1f ms   draw calls %5.0f" % [name, n / 2.5, worst, draws / n])
