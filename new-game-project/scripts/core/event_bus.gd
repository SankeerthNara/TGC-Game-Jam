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
