extends Node
## Global signal hub. Systems emit, UI/audio/VFX listen. Never call across owners directly.
## Signal contract is documented in docs/ARCHITECTURE.md; do not rename signals without updating it.

signal level_loaded(index: int, data: Dictionary)
signal panel_swapped(a: int, b: int)
signal panel_rejected(panel: int) ## tried to move a locked panel
signal mirror_toggled(cell: Vector2i)
signal move_count_changed(moves: int)
signal beam_updated(good_lit: int, good_total: int, bad_lit: int)
signal caption_changed(text: String) ## narrator caption (comic caption box)
signal twist_triggered(kind: String) ## "flip"
signal level_solved(index: int)
signal game_finished

## --- UI -> game requests (the UI emits these, main.gd acts on them) ---
signal request_start_game ## main menu "Play"
signal request_restart_level
signal request_undo
signal request_pause(paused: bool)
signal request_quit_to_menu
signal request_skip_level ## debug builds only

## --- game -> UI state notifications ---
signal game_state_changed(state: String) ## "menu", "playing", "paused", "ended"
signal level_restarted

## --- town events (for audio and effects) ---
signal item_collected(type: String) ## "ink", "gear" or "shard"
signal trade_made(key_id: String)
signal door_unlocked(puzzle_index: int)

## --- station tasks ---
signal task_started(task_id: String)
signal task_completed(task_id: String, done: int, total: int)
