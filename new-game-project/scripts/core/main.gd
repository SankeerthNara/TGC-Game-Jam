extends Node
## Game flow: loads levels, applies player actions to the model, fires the narrator's twist.
## Contains a throwaway debug HUD; Antigravity's ui/ HUD replaces it by listening to EventBus.

var model: PageModel
const UI_SCENE := "res://ui/comic_ui.tscn"
const MENU_SCENE := "res://ui/main_menu.tscn"

var view: PageView
var world: World
var level_data: Dictionary
var undo_stack: Array[Dictionary] = []
var busy := false
var run_id := 0 ## bumps on every level start so stale timers do nothing
var decoy_revealed := false
var state := "menu" ## menu | cutscene | world | task | playing (a page puzzle) | choice | parkour | paused | levelend | ended | dead
var friends_killed := 0
var friends_revealed := 0
const BOSS_MIN_TIME := 180.0 ## the bomb has at least this much left when the boss fight starts
var active_task := ""
var run_seed := 0
var level_idx := 0
var level_time := 0.0
var total_time := 0.0
var level_splits: Array = []
var _overlay: Node
var _retrying := false
var score := ScoreKeeper.new()
var level_ease: Array[int] = [0, 0, 0, 0]
var _task_layer: CanvasLayer
var paused := false ## the whole game is frozen (P / Esc); the UI keeps running
## "Glitched Out" (144p -> 720p -> 2k). false = the classic game (roll back here).
const EDITIONS := true
var director: EditionsDirector = null
const PAUSABLE_STATES := ["world", "task", "parkour", "playing", "boss"]
const BOMB_SECONDS := 17 * 60.0 ## the masked villain's bomb: find the 4 keys and open the bomb room in time
const TICKING := ["world", "task", "playing", "parkour", "boss"] ## the bomb clock pauses in cutscenes, menus and score screens
var bomb_left := BOMB_SECONDS
var keys_found := 0

var _caption: Label
var _info: Label


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("23232e"))
	# main and the UI keep running while paused; the world, tasks and chases freeze
	process_mode = Node.PROCESS_MODE_ALWAYS
	world = World.new()
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	world.door_entered.connect(_enter_puzzle)
	world.task_requested.connect(_on_task_requested)
	world.sabotage_started.connect(_on_sabotage_started)
	world.sabotage_resolved.connect(func(def: Dictionary) -> void:
		score.on_fixed(def.get("big", false))
		EventBus.caption_changed.emit("NARRATOR: Crisis averted! %s is under control. Phew." % String(def["name"]).capitalize()))
	world.sabotage_failed.connect(func(def: Dictionary, left: int) -> void:
		score.on_failed(def.get("big", false))
		view.shake(14.0)
		EventBus.caption_changed.emit("NARRATOR: OUCH! %s hit you. %d heart%s left." % [String(def["name"]).capitalize(), left, "" if left == 1 else "s"]))
	world.player_died.connect(_on_player_died)
	world.vampire_caught.connect(_on_vampire_caught)
	world.tasks_all_done.connect(func() -> void:
		if state == "world":
			_level_complete())
	world.ally_helped.connect(func(what: String) -> void:
		EventBus.caption_changed.emit("NARRATOR: Your friend helped: %s!" % what))
	world.task_disrupted.connect(func(task_name: String) -> void:
		score.on_disrupted()
		view.shake(10.0)
		EventBus.caption_changed.emit("NARRATOR: Something tampered with \"%s\"! That task is undone. Do it again." % task_name))
	var music := MusicDirector.new()
	music.main = self
	add_child(music)
	if EDITIONS:
		director = EditionsDirector.new()
		add_child(director)
		director.setup(self)
	var sfx := SfxPlayer.new() # Codex's sound effects (listens to EventBus)
	sfx.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(sfx)
	_task_layer = CanvasLayer.new()
	_task_layer.process_mode = Node.PROCESS_MODE_PAUSABLE
	_task_layer.layer = 18
	add_child(_task_layer)
	world.message.connect(func(t: String) -> void: EventBus.caption_changed.emit(t))
	world.gate_opened.connect(func(_g: String) -> void:
		EventBus.caption_changed.emit("NARRATOR: The ink-gate dissolves into light! New streets are open."))
	view = PageView.new()
	view.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(view)
	view.swap_requested.connect(_on_swap)
	view.toggle_requested.connect(_on_toggle)
	view.locked_panel_clicked.connect(_on_locked)
	EventBus.request_start_game.connect(_start_game)
	set_process(true)
	EventBus.request_restart_level.connect(_restart_level)
	EventBus.request_undo.connect(_undo)
	EventBus.request_pause.connect(_set_paused)
	EventBus.request_quit_to_menu.connect(_to_menu)
	EventBus.request_skip_level.connect(func() -> void: if OS.is_debug_build() and state == "playing": _finish_puzzle())
	if ResourceLoader.exists(UI_SCENE):
		add_child((load(UI_SCENE) as PackedScene).instantiate()) # Antigravity's comic UI replaces the debug HUD
		_to_menu()
	else:
		_build_debug_hud()
		EventBus.caption_changed.connect(func(t: String) -> void: _caption.text = t)
		_start_game()
	if "boss" in OS.get_cmdline_user_args():
		# testing shortcut: `godot --path . -- boss` starts straight in the final battle
		EventBus.request_start_game.emit()
		_clear_overlay()
		for c in _task_layer.get_children():
			c.queue_free()
		bomb_left = 300.0
		_start_boss.call_deferred()


func _set_state(s: String) -> void:
	state = s
	var in_puzzle := s == "playing" or s == "paused"
	view.visible = in_puzzle
	view.input_enabled = s == "playing" and not busy
	world.set_active(s == "world" or s == "task" or s == "dead" or s == "levelend" or s == "choice")
	world.input_blocked = s == "task" or s == "dead" or s == "levelend" or s == "choice"
	world.clock_running = s == "world" or s == "task" or s == "playing"
	EventBus.game_state_changed.emit(s)


func _to_menu() -> void:
	if paused:
		paused = false
		get_tree().paused = false
	GameState.restart_game()
	busy = false
	if director != null:
		# the Editions: nothing of the abandoned run may keep running behind the menu
		director.reset()
		for c in _task_layer.get_children():
			c.queue_free()
		_overlay = null
		active_task = ""
	_set_state("menu")
	if ResourceLoader.exists(MENU_SCENE):
		var layer := CanvasLayer.new()
		layer.layer = 20
		add_child(layer)
		layer.add_child((load(MENU_SCENE) as PackedScene).instantiate()) # frees itself on start
		EventBus.request_start_game.connect(layer.queue_free, CONNECT_ONE_SHOT)


func _start_game() -> void:
	GameState.restart_game()
	run_seed = randi()
	level_splits.clear()
	total_time = 0.0
	score.new_run()
	friends_killed = 0
	friends_revealed = 0
	bomb_left = BOMB_SECONDS
	keys_found = 0
	world.bomb_left = bomb_left
	world.keys_found = 0
	for i in level_ease.size():
		level_ease[i] = 0
	_clear_overlay()
	if EDITIONS:
		bomb_left = -1.0 # no bomb clock in the editions
		world.bomb_left = -1.0
		# the cheap edition is a quick prologue: 3 and 4 tasks, kinder sabotage
		level_ease[0] = 1
		level_ease[1] = 2
		director.start()
		return
	_set_state("cutscene")
	EventBus.caption_changed.emit("NARRATOR: Once upon a time...")
	_play_cutscene("opening", func() -> void: _load_level(0))


## Builds level `i` (same layout every time for this run, so a respawn is the same map) and starts it.
func _load_level(i: int) -> void:
	level_idx = i
	if not _retrying:
		level_time = 0.0
	score.start_level(_retrying)
	_retrying = false
	var data := LevelGenerator.generate(i, run_seed, level_ease[clampi(i, 0, level_ease.size() - 1)])
	world.level_time = level_time
	world.level_index = i
	world.level_count = LevelGenerator.level_count()
	world.level_title = LevelGenerator.level_title(i)
	world.load_data(data)
	EventBus.level_started.emit(i, world.level_title)
	_enter_world()
	EventBus.caption_changed.emit(director.level_intro(i) if EDITIONS else world.intro)


func _process(delta: float) -> void:
	if paused:
		return
	if world.clock_running and (state == "world" or state == "task" or state == "playing"):
		level_time += delta
		total_time += delta
	world.level_time = level_time
	world.total_time = total_time
	world.score_total = score.live(level_idx, world.tasks_done.size())
	if not EDITIONS and state in TICKING and bomb_left > 0.0:
		bomb_left = maxf(0.0, bomb_left - delta)
		if bomb_left <= 0.0:
			_bomb_exploded()
	world.bomb_left = bomb_left
	if _overlay is BossFight:
		_overlay.bomb_left = bomb_left


## The 17 minutes ran out before the bomb room was opened: the Earth is blasted.
func _bomb_exploded() -> void:
	for c in _task_layer.get_children():
		c.queue_free()
	_overlay = null
	active_task = ""
	_set_state("ended")
	EventBus.sound_requested.emit("explosion")
	EventBus.caption_changed.emit("NARRATOR: Tick... tick... BOOM. The heroes were too late.")
	_play_cutscene("earth_blast", func() -> void:
		EventBus.game_finished.emit()
		EventBus.request_quit_to_menu.emit())


func _clear_overlay() -> void:
	if _overlay != null and is_instance_valid(_overlay):
		_overlay.queue_free()
	_overlay = null


func _enter_world() -> void:
	busy = false
	_set_state("world")


## The hero walked through a page door: switch from the town to that page's puzzle.
func _enter_puzzle(index: int) -> void:
	if state != "world":
		return
	_set_state("playing")
	start_level(index)


## Back to the town after finishing a page (or giving up on it with M).
func _finish_puzzle(solved := true) -> void:
	if world.station_mode:
		var id := active_task
		active_task = ""
		if solved:
			world.complete_task(id)
		_back_from_task(solved)
		return
	var idx := GameState.level_index
	if solved:
		world.mark_done(idx)
	else:
		world.leave_door(idx)
	if world.real_done() >= world.real_total():
		_set_state("ended")
		EventBus.game_finished.emit()
		EventBus.caption_changed.emit("THE END.")
		return
	_enter_world()
	if solved and not GameState.levels[idx].get("type", "puzzle") == "decoy":
		EventBus.caption_changed.emit("NARRATOR: The lights flicker back on! %d of %d real pages read." % [world.real_done(), world.real_total()])
	elif solved:
		EventBus.caption_changed.emit("NARRATOR: Wrong key, wrong door, wrong comic. Back to Gutter Town. The real page is still waiting; check the keyhole next time!")
	else:
		EventBus.caption_changed.emit("NARRATOR: Giving up on that page? It will wait for you.")


## The hero reached a task console. Mirror tasks reuse the light puzzle pages; the rest are mini-games.
func _on_task_requested(task_id: String, type: String, param: int) -> void:
	if state != "world":
		return
	active_task = task_id
	if type == "mirror":
		_set_state("playing")
		start_level(param)
		return
	var game := TaskRegistry.create(type)
	if game == null:
		active_task = ""
		return
	game.difficulty = clampi(level_idx - world.level_ease + world.fix_bonus(task_id), 0, 3)
	_set_state("task")
	_task_layer.add_child(game)
	game.finished.connect(func(success: bool) -> void: _on_task_finished(game, success))


func _on_task_finished(game: Node, success: bool) -> void:
	game.queue_free()
	var id := active_task
	active_task = ""
	if success:
		world.complete_task(id)
	_back_from_task(success)


func _back_from_task(success: bool) -> void:
	if world.all_tasks_done():
		_level_complete()
		return
	_enter_world()
	if success:
		EventBus.caption_changed.emit("NARRATOR: Task complete! %d of %d done. Keep going, hero." % [world.tasks_done.size(), world.tasks_total()])
	else:
		EventBus.caption_changed.emit("NARRATOR: Gave up on that one? It will still be here.")


## Plays one of the Among Us style cutscenes, then calls `then`.
func _play_cutscene(kind: String, then: Callable) -> void:
	var cs: Control = ComicCutscene.new() if kind in ComicCutscene.KINDS else CutScene.new()
	cs.kind = kind
	cs.bomb_left = bomb_left
	_overlay = cs
	_task_layer.add_child(cs)
	cs.finished.connect(func() -> void:
		_clear_overlay()
		then.call())


## The hero held a vampire in the torchlight: a cutscene, then reveal or kill?
## (If the other vampire is already known there is no real choice left.)
func _on_vampire_caught(i: int) -> void:
	if state != "world":
		return
	_set_state("choice")
	EventBus.sound_requested.emit("vampire_spotted")
	EventBus.caption_changed.emit("NARRATOR: A vampire! Hold him in the light...")
	_play_cutscene("detected", func() -> void:
		if world.vampires.other_resolved(i):
			_apply_vampire_choice(i, true)
			return
		var ov := VampireChoice.new()
		ov.role = world.vampires.role_of(i)
		_overlay = ov
		_task_layer.add_child(ov)
		ov.finished.connect(func(reveal: bool) -> void:
			_clear_overlay()
			_apply_vampire_choice(i, reveal)))


func _apply_vampire_choice(i: int, reveal: bool) -> void:
	var role := world.vampires.role_of(i)
	var kind := ("friend_revealed" if role == "friend" else "villain_revealed") if reveal else ("friend_killed" if role == "friend" else "villain_killed")
	EventBus.sound_requested.emit(("reveal_friend" if role == "friend" else "reveal_villain") if reveal else "kill")
	_play_cutscene(kind, func() -> void: _after_vampire_choice(i, reveal, role))


func _after_vampire_choice(i: int, reveal: bool, role: String) -> void:
	if reveal and role == "friend":
		world.vampires.reveal_friend(i)
		friends_revealed += 1
		world.on_ally_revealed()
		score.on_friend_revealed()
		_enter_world()
		var helps := ["points you to tasks", "points you to the nearest task", "points to tasks and buys you time on sabotage", "buys you time, fixes a sabotage and shields you once"]
		EventBus.caption_changed.emit("NARRATOR: A friend! He is not afraid of light now, and he %s. Stand at a task and press F: he will do it for you!" % helps[clampi(level_idx, 0, 3)])
	elif reveal:
		world.vampires.reveal_villain(i)
		_start_parkour(i)
	elif role == "friend":
		world.vampires.kill(i)
		friends_killed += 1
		score.on_friend_killed()
		world.hp = maxi(0, world.hp - 1)
		_enter_world()
		if world.hp <= 0:
			world.player_died.emit()
		else:
			EventBus.caption_changed.emit("NARRATOR: You killed your friend... He was on your side. You lose a heart.")
	else:
		world.vampires.kill(i)
		score.on_villain_killed()
		world.sab_plan.clear()
		_enter_world()
		EventBus.caption_changed.emit("NARRATOR: The villain is dead. No more sabotage. Efficient, if a little cold.")


## He is revealed and runs: the hero is teleported into a short parkour chase.
func _start_parkour(i: int) -> void:
	_set_state("parkour")
	# one chase per level, each harder: rolling ball (level 2), rooftop run (level 3), web swing (level 4)
	var g: ChaseBase = [BallChase, BallChase, RunChase, WebChase][clampi(level_idx, 0, 3)].new()
	g.difficulty = clampi(level_idx, 0, 3)
	_task_layer.add_child(g)
	EventBus.caption_changed.emit("NARRATOR: The villain bolts! Chase him down!")
	g.finished.connect(func(success: bool) -> void:
		g.queue_free()
		if success:
			world.vampires.defeat_villain(i)
			world.sab_plan.clear()
			world.hp = mini(world.max_health, world.hp + 1)
			score.on_villain_defeated()
			_enter_world()
			EventBus.caption_changed.emit("NARRATOR: Caught him! The sabotage is over and you recover a heart.")
		else:
			world.vampires.release(i)
			world.hp = maxi(0, world.hp - 1)
			_enter_world()
			if world.hp <= 0:
				world.player_died.emit()
			else:
				EventBus.caption_changed.emit("NARRATOR: He got away and you lost a heart. Catch him in the light again!"))


func _on_sabotage_started(def: Dictionary) -> void:
	var fix := world.active_fix()
	var cost := "%d hearts" % int(def.get("damage", 1)) if int(def.get("damage", 1)) > 1 else "a heart"
	EventBus.caption_changed.emit("NARRATOR: %s%s! %s Fix it in the %s within %d seconds or lose %s!" % ["BIG SABOTAGE! " if def.get("big", false) else "SABOTAGE! ", def["name"], def["line"], fix.get("room", "station"), int(def["seconds"]), cost])


func _on_player_died() -> void:
	score.on_death()
	for c in _task_layer.get_children():
		c.queue_free()
	active_task = ""
	_set_state("dead")
	var overlay := DeathOverlay.new()
	overlay.message = "Back to the checkpoint: the start of Level %d." % (level_idx + 1)
	var kept: Dictionary = world.tasks_done.duplicate()
	if EDITIONS:
		overlay.message = "Back to the start of Level %d. Your finished tasks stay finished." % (level_idx + 1)
		overlay.bomb = false
	overlay.restart.connect(func() -> void:
		overlay.queue_free()
		_retrying = true
		_load_level(level_idx)
		if EDITIONS:
			# failing should not cost the player their progress
			for id in kept:
				world.tasks_done[id] = true
			world.queue_redraw())
	_task_layer.add_child(overlay)
	EventBus.caption_changed.emit("NARRATOR: Out of hearts! Respawning at your checkpoint. Level %d starts again." % (level_idx + 1))


func _level_complete() -> void:
	level_splits.append(level_time)
	EventBus.level_completed.emit(level_idx, level_time)
	var last := level_idx >= (1 if EDITIONS else LevelGenerator.level_count() - 1)
	var big_flags: Array = []
	for sab in world.sabotage_defs.values():
		big_flags.append(sab.get("big", false))
	if not EDITIONS:
		keys_found = mini(keys_found + 1, LevelGenerator.level_count())
		EventBus.sound_requested.emit("key_get")
	world.keys_found = keys_found
	var result := score.finish_level(level_idx, world.tasks.size(), level_time, world.level_par, world.hp, world.max_health, big_flags)
	# the next level is kinder if this one took longer than par (the run should stay about the same length)
	if not last:
		var over := level_time / float(maxi(world.level_par, 1))
		level_ease[level_idx + 1] = maxi(level_ease[level_idx + 1], 2 if over > 1.5 else (1 if over > 1.0 else 0))
	_set_state("levelend")
	var ov := LevelOverlay.new()
	ov.title = "Level %d: %s" % [level_idx + 1, LevelGenerator.level_title(level_idx)]
	ov.level_time = level_time
	ov.total_time = total_time
	ov.splits = level_splits.duplicate()
	ov.par = world.level_par
	ov.to_bomb_room = last and not EDITIONS
	ov.keys_found = keys_found
	ov.key_total = 0 if EDITIONS else LevelGenerator.level_count()
	ov.bomb_left = bomb_left
	ov.lines = result["lines"]
	ov.score = result["score"]
	ov.rank = result["rank"]
	ov.total_score = score.total
	ov.level_scores = score.level_totals.duplicate()
	ov.level_ranks = score.level_ranks.duplicate()
	ov.overall_rank = score.overall_rank()
	if not last:
		ov.next_title = "Level %d" % (level_idx + 2)
		ov.easier_next = level_ease[level_idx + 1] > 0
	_overlay = ov
	_task_layer.add_child(ov)
	ov.continue_pressed.connect(func() -> void:
		_clear_overlay()
		if last and EDITIONS:
			director.after_144_levels()
		elif last:
			_open_bomb_room()
		else:
			_load_level(level_idx + 1))
	if EDITIONS:
		EventBus.caption_changed.emit("NARRATOR: Brilliant work, hero! Rank %s. On to the next one." % result["rank"])
	elif last:
		EventBus.caption_changed.emit("NARRATOR: All four keys! The bomb room... wait. Don't open that door.")
	else:
		EventBus.caption_changed.emit("NARRATOR: Level complete! Key %d of %d to the bomb room. Rank %s." % [keys_found, LevelGenerator.level_count(), result["rank"]])


## All four keys: the bomb room opens, the masked villain unmasks (it was the Narrator) and captures
## the level 1 hero. The boss fight (relay duels, bomb still ticking) is not built yet, so for now
## the run ends on the final score screen.
func _open_bomb_room() -> void:
	_set_state("cutscene")
	_play_cutscene("bomb_room", func() -> void:
		bomb_left = maxf(bomb_left, BOSS_MIN_TIME)
		_start_boss())


## The final boss: three relay duels against the Narrator, the bomb still ticking.
func _start_boss() -> void:
	_set_state("boss")
	EventBus.caption_changed.emit("NARRATOR: Three heroes left? I already wrote how this ends.")
	var boss := BossFight.new()
	boss.friends_revealed = friends_revealed
	boss.friends_killed = friends_killed
	boss.bomb_left = bomb_left
	_overlay = boss
	_task_layer.add_child(boss)
	boss.finished.connect(func(result: String) -> void:
		boss.queue_free()
		_overlay = null
		var won := result == "win"
		_set_state("cutscene")
		_play_cutscene("ending_sun" if won else "ending_lava", func() -> void: _final_screen(won)))


## The last score screen after either ending.
func _final_screen(won: bool) -> void:
	_set_state("ended")
	EventBus.caption_changed.emit("NARRATOR: The end. For now." if won else "NARRATOR: My story, my ending. Again?")
	var ov := LevelOverlay.new()
	ov.final = true
	ov.won = won
	ov.title = "The Earth is saved!" if won else "The Narrator wins..."
	ov.total_time = total_time
	ov.splits = level_splits.duplicate()
	ov.total_score = score.total
	ov.level_scores = score.level_totals.duplicate()
	ov.level_ranks = score.level_ranks.duplicate()
	ov.overall_rank = score.overall_rank()
	ov.keys_found = keys_found
	ov.key_total = LevelGenerator.level_count()
	ov.bomb_left = bomb_left
	_overlay = ov
	_task_layer.add_child(ov)
	ov.continue_pressed.connect(func() -> void:
		_clear_overlay()
		EventBus.game_finished.emit()
		EventBus.request_quit_to_menu.emit())


func _wait_playing() -> void:
	while paused:
		await get_tree().process_frame


## Pause menu "restart": back to the start of this level (the bomb keeps its time).
func _restart_level() -> void:
	if not paused and not state in PAUSABLE_STATES:
		return
	_set_paused(false)
	if director != null and state == "boss" and director.restart_fight():
		EventBus.level_restarted.emit()
		return # a fight restarts itself (the 144p rooms reload below)
	for c in _task_layer.get_children():
		c.queue_free()
	_overlay = null
	active_task = ""
	_retrying = true
	_load_level(level_idx)
	EventBus.level_restarted.emit()


## Freezes the game (world, tasks, chases, the bomb clock) and tells the UI to show the pause menu.
func _set_paused(on: bool) -> void:
	if on and not paused and state in PAUSABLE_STATES:
		paused = true
		get_tree().paused = true
		EventBus.game_state_changed.emit("paused")
	elif not on and paused:
		paused = false
		get_tree().paused = false
		EventBus.game_state_changed.emit(state)


func _undo() -> void:
	if state == "playing" and not busy and not undo_stack.is_empty():
		model.restore(undo_stack.pop_back())
		_refresh()


func _build_debug_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_caption = Label.new()
	_caption.position = Vector2(40, 30)
	_caption.custom_minimum_size = Vector2(1200, 0)
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.add_theme_font_size_override("font_size", 26)
	layer.add_child(_caption)
	_info = Label.new()
	_info.position = Vector2(40, 670)
	_info.add_theme_font_size_override("font_size", 18)
	layer.add_child(_info)
	EventBus.beam_updated.connect(_update_info)


func _update_info(good_lit: int, good_total: int, bad_lit: int) -> void:
	_info.text = "Level %d/%d  |  Moves %d  |  Lit %d/%d  |  Bad lit %d  |  Drag panels to swap, click mirrors to flip  |  R reset, Z undo" % [
		GameState.level_index + 1, GameState.levels.size(), model.moves, good_lit, good_total, bad_lit]


func start_level(index: int) -> void:
	GameState.level_index = index
	level_data = GameState.current_level()
	model = PageModel.from_data(level_data)
	undo_stack.clear()
	run_id += 1
	decoy_revealed = false
	busy = false
	view.input_enabled = state == "playing"
	view.visible = true
	view.set_model(model)
	EventBus.level_loaded.emit(index, level_data)
	EventBus.caption_changed.emit(level_data.get("caption_intro", ""))
	EventBus.move_count_changed.emit(0)
	_refresh()


func _push_undo() -> void:
	undo_stack.append(model.snapshot())


func _on_swap(a: int, b: int) -> void:
	if busy or state != "playing":
		return
	_push_undo()
	if model.swap_panels(a, b):
		EventBus.panel_swapped.emit(a, b)
		_refresh()
	else:
		undo_stack.pop_back()


func _on_toggle(cell: Vector2i) -> void:
	if busy or state != "playing":
		return
	_push_undo()
	if model.toggle_mirror(cell):
		EventBus.mirror_toggled.emit(cell)
		_refresh()
	else:
		undo_stack.pop_back()


func _on_locked(panel: int) -> void:
	view.shake(8.0)
	EventBus.panel_rejected.emit(panel)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or not event is InputEventKey:
		return
	# P pauses anywhere you play; Esc too, except inside a task (there Esc leaves the task)
	if event.keycode == KEY_P or (event.keycode == KEY_ESCAPE and (paused or state in ["world", "parkour"])):
		_set_paused(not paused)
		get_viewport().set_input_as_handled()
		return
	if paused or state != "playing" or busy:
		return
	elif event.keycode == KEY_M:
		_finish_puzzle(false)
	elif event.keycode == KEY_R:
		EventBus.request_restart_level.emit()
	elif event.keycode == KEY_Z:
		_undo()
	elif OS.is_debug_build() and event.keycode == KEY_N:
		_finish_puzzle()


func _refresh() -> void:
	var tr := BeamSolver.trace(model)
	var st := model.status(tr)
	view.set_trace(tr)
	EventBus.move_count_changed.emit(model.moves)
	EventBus.beam_updated.emit(st["good_lit"], st["good_total"], st["bad_lit"])
	if level_data.get("type", "puzzle") == "decoy":
		if not decoy_revealed and (st["solved"] or model.moves >= int(level_data.get("reveal_after_moves", 2))):
			_reveal_decoy()
		return
	if st["solved"]:
		_on_solved()


## A decoy page looks like a normal puzzle but belongs to some other comic.
## Once the player has played with it a little, the narrator admits the mistake.
func _reveal_decoy() -> void:
	decoy_revealed = true
	busy = true
	view.input_enabled = false
	var id := run_id
	await get_tree().create_timer(0.7).timeout
	await _wait_playing()
	if id != run_id or state != "playing":
		return
	view.shake(16.0)
	EventBus.twist_triggered.emit("wrong_page")
	EventBus.caption_changed.emit(level_data.get("caption_twist", "NARRATOR: Wrong page! Oops."))
	await get_tree().create_timer(4.0).timeout
	await _wait_playing()
	if id == run_id and state == "playing":
		_finish_puzzle()


func _on_solved() -> void:
	var id := run_id
	busy = true
	view.input_enabled = false
	if level_data.get("twist", "none") == "flip" and not model.flipped:
		await get_tree().create_timer(1.0).timeout
		if id != run_id:
			return
		model.flipped = true
		view.shake(18.0)
		EventBus.twist_triggered.emit("flip")
		EventBus.caption_changed.emit(level_data.get("caption_twist", "Plot twist!"))
		busy = false
		view.input_enabled = state == "playing"
		_refresh()
		return
	EventBus.level_solved.emit(GameState.level_index)
	EventBus.caption_changed.emit(level_data.get("caption_solved", "Page complete."))
	await get_tree().create_timer(2.2).timeout
	await _wait_playing()
	if id == run_id and state == "playing":
		_finish_puzzle()
