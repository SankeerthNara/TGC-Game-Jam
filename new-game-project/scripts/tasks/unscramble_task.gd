class_name UnscrambleTask
extends TaskBase
## Comic lettering: put the scrambled letters back in order to spell the comic word.

const WORDS := ["COMIC", "PANEL", "CAPTION", "SIDEKICK", "SUPERHERO", "VILLAIN", "NARRATOR", "INKWELL", "GUTTER", "SPLASH", "BUBBLE", "LETTERER"]

var ROUNDS := 2
var _round := 0
var _deck: Array = []
var _word := ""
var _tiles: Array[String] = []
var _used: Array[bool] = []
var _typed := ""


func _begin() -> void:
	ROUNDS = 2 + (1 if difficulty >= 2 else 0)
	title = "UNSCRAMBLE THE WORD"
	hint = "Click the letters in the right order to spell the comic word."
	_deck = WORDS.duplicate()
	_deck.shuffle()
	_load()


func _load() -> void:
	_word = _deck[_round]
	_typed = ""
	_tiles.clear()
	_used.clear()
	for ch in _word:
		_tiles.append(ch)
		_used.append(false)
	var orig := _tiles.duplicate()
	while _tiles == orig:
		_tiles.shuffle()


func _tile(i: int) -> Rect2:
	var n := _tiles.size()
	var w := minf(70.0, (panel.size.x - 120.0) / n - 8.0)
	var total := n * (w + 8.0)
	return Rect2(Vector2(panel.get_center().x - total * 0.5 + i * (w + 8.0), panel.position.y + 330), Vector2(w, w))


func _gui_input(event: InputEvent) -> void:
	if _done:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in _tiles.size():
			if _tile(i).has_point(event.position) and not _used[i]:
				if _tiles[i] == _word[_typed.length()]:
					_used[i] = true
					_typed += _tiles[i]
					if _typed == _word:
						_round += 1
						if _round >= ROUNDS:
							succeed()
						else:
							flash("NICE!")
							_load()
				else:
					flash("NOT THAT LETTER!", 6.0)
				return


func _draw_task() -> void:
	_text("WORD %d / %d" % [_round + 1, ROUNDS], panel.position + Vector2(30, 112), 26, INK, FONT_SHOUT)
	var n := _word.length()
	var w := minf(70.0, (panel.size.x - 120.0) / n - 8.0)
	var total := n * (w + 8.0)
	for i in n:
		var r := Rect2(Vector2(panel.get_center().x - total * 0.5 + i * (w + 8.0), panel.position.y + 190), Vector2(w, w))
		draw_rect(r, Color("fffdf2"))
		draw_rect(r, INK, false, 3.0)
		if i < _typed.length():
			_text(_typed[i], r.position + Vector2(w * 0.28, w * 0.74), 46, GREEN, FONT_SHOUT)
	for i in _tiles.size():
		var r := _tile(i)
		draw_rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.3))
		draw_rect(r, Color("bdbdbd") if _used[i] else GOLD)
		draw_rect(r, INK, false, 3.0)
		if not _used[i]:
			_text(_tiles[i], r.position + Vector2(w * 0.28, w * 0.74), 46, INK, FONT_SHOUT)
