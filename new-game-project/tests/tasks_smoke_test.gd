extends Node
## Instantiates every registered task at all four difficulties and lets each process 60 frames.
## Run: godot --headless --path new-game-project res://tests/tasks_smoke_test.tscn

var _passed := 0
var _failed := 0
var _failures: Array[String] = []

const EXPECTED_SFX := [
	"task_success", "task_mistake", "vampire_spotted", "reveal_friend", "reveal_villain",
	"kill", "key_get", "explosion", "friend_assigned", "friend_done", "page_turn",
	"comic_pop", "key_click", "chase_jump", "chase_bounce", "chase_fall",
	"chase_checkpoint", "chase_hit", "chase_vault", "chase_slide", "chase_win",
	"chase_lose", "web_attach", "web_shoot", "web_hit", "task_open",
	"sabotage_alarm", "sabotage_fixed", "heart_lost", "death", "item_collected",
	"trade_made", "door_unlocked", "punch", "punch_heavy", "kick", "counter_flash",
	"counter_hit", "enemy_grunt", "glitch", "static", "comms_beep", "comms_dead",
	"resolution_change", "cursor_click", "typewriter", "credits_whoosh", "light_swell",
	"slash", "hit", "hero_hurt", "hero_jump", "dash", "heal", "power_deduction",
	"power_dash", "power_prism", "power_solar", "wave_start", "enemy_spawn",
	"enemy_windup", "shockwave", "bomb_fuse", "narrator_attack", "hero_ko",
]


func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	await _check_synthwave()
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
	var actual_names: Dictionary = {}
	for file in DirAccess.get_files_at("res://assets/audio"):
		if not file.begins_with("sfx_") or not file.ends_with(".wav"):
			continue
		actual_names[file.trim_prefix("sfx_").trim_suffix(".wav")] = true
	for sound_name in EXPECTED_SFX:
		if not actual_names.has(sound_name):
			_fail("missing generated SFX file: %s" % sound_name)
		if player._stream_for(sound_name) == null:
			_fail("SFX %s could not load" % sound_name)
		elif not player.VOLUME_DB.has(sound_name):
			_fail("SFX %s has no per-sound mix level" % sound_name)
		else:
			player.play(sound_name)
	if actual_names.size() != EXPECTED_SFX.size():
		_fail("expected %d effect files; found %d" % [EXPECTED_SFX.size(), actual_names.size()])
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
	print("SFX SMOKE: %d documented effects loaded, mixed, and muted; missing-file handling and EventBus hooks PASS" % EXPECTED_SFX.size())


func _check_synthwave() -> void:
	var layer_names := ["pad", "bass", "drums", "lead"]
	var expected_length := -1.0
	for layer_name in layer_names:
		var path := "res://assets/audio/music_synth_%s.wav" % layer_name
		var stream := load(path) as AudioStreamWAV
		if stream == null:
			_fail("could not load synthwave layer %s" % layer_name)
			continue
		if stream.mix_rate != 22050 or stream.stereo:
			_fail("synthwave layer %s is not 22050 Hz mono" % layer_name)
		if expected_length < 0.0:
			expected_length = stream.get_length()
		elif absf(stream.get_length() - expected_length) > 1.0 / 22050.0:
			_fail("synthwave layer %s is not sample-synced" % layer_name)
		var import_path := path + ".import"
		var import_file := FileAccess.open(import_path, FileAccess.READ)
		if import_file == null or not import_file.get_as_text().contains("edit/loop_mode=2"):
			_fail("synthwave layer %s is not set to loop" % layer_name)
	print("SYNTHWAVE SMOKE: four 22050 Hz mono layers share a loop length and loop import setting")


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
