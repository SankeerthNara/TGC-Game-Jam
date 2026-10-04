extends Node
## Checks that a revealed friend does the tasks handed to him with F (not part of the game).

var fails := 0


func check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _ready() -> void:
	var main: Node = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(main)
	await frames(5)
	EventBus.request_start_game.emit()
	await frames(3)
	main._overlay.skip()
	await frames(3)
	main._level_complete()
	await frames(3)
	main._overlay.continue_pressed.emit()
	await frames(5)
	var w: World = main.world
	check(main.level_idx == 1 and w.vampires.list.size() == 2, "level 2 with two vampires")
	# no friend yet: F only explains
	w._assign_to_friend()
	check(w.assigned.is_empty(), "F does nothing without a friend")
	var fi := 0 if w.vampires.role_of(0) == "friend" else 1
	w.vampires.reveal_friend(fi)
	w.on_ally_revealed()
	# stand in front of the first task and press F
	var t0: Dictionary = w.tasks[0]
	w._foot = w.center_of(Vector2i(int(t0["x"]), int(t0["y"]) + 1))
	w._face = Vector2.UP
	w._assign_to_friend()
	check(w.assigned == [String(t0["id"])], "F assigns the task at the console")
	w._assign_to_friend()
	check(w.assigned.size() == 1, "the same task is not queued twice")
	var t1: Dictionary = w.tasks[1]
	w._foot = w.center_of(Vector2i(int(t1["x"]), int(t1["y"]) + 1))
	w._assign_to_friend()
	check(w.assigned.size() == 2, "a second task is queued")
	# let him work (fast-forward)
	Engine.time_scale = 10.0
	var waited := 0.0
	var saw_progress := false
	while not w.tasks_done.has(t1["id"]) and waited < 200.0:
		await get_tree().process_frame
		waited += get_process_delta_time()
		if w.vampires.work_progress() > 0.1:
			if not saw_progress:
				print("started working at %.1f, dist to hero tiles %.1f" % [waited, (w.vampires.list[fi]["pos"] as Vector2).distance_to(w._foot) / World.TILE])
			saw_progress = true
	Engine.time_scale = 1.0
	check(saw_progress, "the friend shows work progress")
	check(w.tasks_done.has(t0["id"]) and w.tasks_done.has(t1["id"]), "the friend finished both tasks (%.0f game seconds)" % waited)
	check(w.assigned.is_empty(), "his queue is empty afterwards")
	print("FAILS: %d" % fails)
	get_tree().quit()
