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
var state := "menu" ## menu | world | playing (a page puzzle) | paused | ended

var _caption: Label
var _info: Label


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("23232e"))
	world = World.new()
	add_child(world)
	world.door_entered.connect(_enter_puzzle)
	world.message.connect(func(t: String) -> void: EventBus.caption_changed.emit(t))
	world.gate_opened.connect(func(_g: String) -> void:
		EventBus.caption_changed.emit("NARRATOR: The ink-gate dissolves into light! New streets are open."))
	view = PageView.new()
	add_child(view)
	view.swap_requested.connect(_on_swap)
	view.toggle_requested.connect(_on_toggle)
	view.locked_panel_clicked.connect(_on_locked)
	EventBus.request_start_game.connect(_start_game)
	EventBus.request_restart_level.connect(func() -> void: if state == "playing": start_level(GameState.level_index); EventBus.level_restarted.emit())
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


func _set_state(s: String) -> void:
	state = s
	var in_puzzle := s == "playing" or s == "paused"
	view.visible = in_puzzle
	view.input_enabled = s == "playing" and not busy
	world.set_active(s == "world")
	EventBus.game_state_changed.emit(s)


func _to_menu() -> void:
	GameState.restart_game()
	busy = false
	_set_state("menu")
	if ResourceLoader.exists(MENU_SCENE):
		var layer := CanvasLayer.new()
		layer.layer = 20
		add_child(layer)
		layer.add_child((load(MENU_SCENE) as PackedScene).instantiate()) # frees itself on start
		EventBus.request_start_game.connect(layer.queue_free, CONNECT_ONE_SHOT)


func _start_game() -> void:
	GameState.restart_game()
	world.reset()
	_enter_world()
	EventBus.caption_changed.emit("NARRATOR: Gutter Town has gone dark! Walk with the ARROW KEYS, press Z or SPACE to talk. Find hidden items, trade them for keys at the shop, and open the PAGE doors.")


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


func _wait_playing() -> void:
	while state == "paused":
		await get_tree().process_frame


func _set_paused(paused: bool) -> void:
	if state == "playing" and paused:
		_set_state("paused")
	elif state == "paused" and not paused:
		_set_state("playing")


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
	if event.keycode == KEY_ESCAPE and (state == "playing" or state == "paused"):
		_set_paused(state == "playing")
	elif state != "playing" or busy:
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
