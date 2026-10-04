extends Node
## Instantiates every registered task at all four difficulties and lets each process 60 frames.
## Run: godot --headless --path new-game-project res://tests/tasks_smoke_test.tscn

var _passed := 0
var _failed := 0
var _failures: Array[String] = []


func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	await _check_sfx()
	for task_type in TaskRegistry.types():
		for difficulty in 4:
			await _check_task(layer, task_type, difficulty)
	print("TASK SMOKE: %d passed, %d failed (%d cases)" % [_passed, _failed, _passed + _failed])
	for failure in _failures:
		push_error(failure)
	get_tree().quit(1 if _failed > 0 else 0)


func _check_sfx() -> void:
	var player := SfxPlayer.new()
	add_child(player)
	await get_tree().process_frame
	var sound_count := 0
	for file in DirAccess.get_files_at("res://assets/audio"):
		if not file.begins_with("sfx_") or not file.ends_with(".wav"):
			continue
		var sound_name := file.trim_prefix("sfx_").trim_suffix(".wav")
		if player._stream_for(sound_name) == null:
			_fail("SFX %s could not load" % sound_name)
		else:
			player.play(sound_name)
			sound_count += 1
	if sound_count < 25:
		_fail("only %d sound effects loaded" % sound_count)
	if player._stream_for("smoke_missing_sound") != null:
		_fail("a missing SFX unexpectedly loaded")
	player.play("smoke_missing_sound")
	player.set_muted(true)
	EventBus.task_started.emit("smoke_task")
	EventBus.sabotage_started.emit("smoke", 5.0)
	EventBus.sabotage_resolved.emit("smoke")
	EventBus.sabotage_failed.emit("smoke", 2)
	EventBus.player_died.emit()
	EventBus.item_collected.emit("ink")
	EventBus.trade_made.emit("coffee")
	EventBus.door_unlocked.emit(0)
	EventBus.sound_requested.emit("task_success")
	for pooled_player in player._players:
		if not is_equal_approx(pooled_player.volume_db, -80.0):
			_fail("muted SFX pool contains an audible player")
	player.set_muted(false)
	print("SFX SMOKE: %d effects loaded, missing-file handling and EventBus hooks PASS" % sound_count)


func _check_task(layer: CanvasLayer, task_type: String, level: int) -> void:
	var task := TaskRegistry.create(task_type)
	if task == null:
		_fail("%s d%d: registry returned null" % [task_type, level])
		return
	task.difficulty = level
	var completion_count := [0]
	var exit_success := [true]
	task.finished.connect(func(success: bool) -> void:
		completion_count[0] += 1
		exit_success[0] = success
	)
	layer.add_child(task)
	for _frame in 60:
		await get_tree().process_frame
	var issues: Array[String] = []
	if task.title.strip_edges().is_empty():
		issues.append("empty title")
	if task.hint.strip_edges().is_empty():
		issues.append("empty instruction")
	var title_size := 44
	while title_size > 24 and task.FONT_SHOUT.get_string_size(task.title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x > task.panel.size.x - 205.0:
		title_size -= 1
	if task.FONT_SHOUT.get_string_size(task.title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x > task.panel.size.x - 205.0:
		issues.append("title cannot fit beside Esc hint")
	var hint_size := 20
	while hint_size > 12 and task.FONT_BODY.get_string_size(task.hint, HORIZONTAL_ALIGNMENT_LEFT, -1, hint_size).x > task.panel.size.x - 48.0:
		hint_size -= 1
	if task.FONT_BODY.get_string_size(task.hint, HORIZONTAL_ALIGNMENT_LEFT, -1, hint_size).x > task.panel.size.x - 48.0:
		issues.append("hint wider than task panel")
	if completion_count[0] != 0:
		issues.append("finished without player input")
	if task.difficulty != level:
		issues.append("difficulty was not retained")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	task._input(escape)
	if completion_count[0] != 1 or exit_success[0]:
		issues.append("Escape did not leave exactly once as an unfinished task")
	if issues.is_empty():
		_passed += 1
		print("PASS %s d%d" % [task_type, level])
	else:
		_fail("%s d%d: %s" % [task_type, level, ", ".join(issues)])
	task.queue_free()
	await get_tree().process_frame


func _fail(message: String) -> void:
	_failed += 1
	_failures.append(message)
	print("FAIL " + message)
