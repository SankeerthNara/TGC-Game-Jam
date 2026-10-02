extends Node
## Game flow: loads levels, applies player actions to the model, fires the narrator's twist.
## Contains a throwaway debug HUD; Antigravity's ui/ HUD replaces it by listening to EventBus.

var model: PageModel
var view: PageView
var level_data: Dictionary
var undo_stack: Array[Dictionary] = []
var busy := false

var _caption: Label
var _info: Label


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("23232e"))
	view = PageView.new()
	add_child(view)
	view.swap_requested.connect(_on_swap)
	view.toggle_requested.connect(_on_toggle)
	view.locked_panel_clicked.connect(_on_locked)
	_build_debug_hud()
	EventBus.caption_changed.connect(func(t: String) -> void: _caption.text = t)
	start_level(GameState.level_index)


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
	busy = false
	view.input_enabled = true
	view.set_model(model)
	EventBus.level_loaded.emit(index, level_data)
	EventBus.caption_changed.emit(level_data.get("caption_intro", ""))
	EventBus.move_count_changed.emit(0)
	_refresh()


func _push_undo() -> void:
	undo_stack.append(model.snapshot())


func _on_swap(a: int, b: int) -> void:
	if busy:
		return
	_push_undo()
	if model.swap_panels(a, b):
		EventBus.panel_swapped.emit(a, b)
		_refresh()
	else:
		undo_stack.pop_back()


func _on_toggle(cell: Vector2i) -> void:
	if busy:
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
	if not event.is_pressed() or busy:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_R):
		start_level(GameState.level_index)
	elif event is InputEventKey and event.keycode == KEY_Z and not undo_stack.is_empty():
		model.restore(undo_stack.pop_back())
		_refresh()
	elif OS.is_debug_build() and event is InputEventKey and event.keycode == KEY_N:
		_advance()


func _refresh() -> void:
	var tr := BeamSolver.trace(model)
	var st := model.status(tr)
	view.set_trace(tr)
	EventBus.move_count_changed.emit(model.moves)
	EventBus.beam_updated.emit(st["good_lit"], st["good_total"], st["bad_lit"])
	if st["solved"]:
		_on_solved()


func _on_solved() -> void:
	busy = true
	view.input_enabled = false
	if level_data.get("twist", "none") == "flip" and not model.flipped:
		await get_tree().create_timer(1.0).timeout
		model.flipped = true
		view.shake(18.0)
		EventBus.twist_triggered.emit("flip")
		EventBus.caption_changed.emit(level_data.get("caption_twist", "Plot twist!"))
		busy = false
		view.input_enabled = true
		_refresh()
		return
	EventBus.level_solved.emit(GameState.level_index)
	EventBus.caption_changed.emit(level_data.get("caption_solved", "Page complete."))
	await get_tree().create_timer(2.2).timeout
	_advance()


func _advance() -> void:
	if GameState.has_next():
		GameState.advance()
		start_level(GameState.level_index)
	else:
		EventBus.game_finished.emit()
		EventBus.caption_changed.emit("THE END. (Press R to play again)")
		GameState.restart_game()
