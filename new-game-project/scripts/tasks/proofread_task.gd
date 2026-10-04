class_name ProofreadTask
extends TaskBase
## College task: proofread the paragraph. Click every misspelled word.

const TEXTS := [
	{"text": "THE HERO FELL INTO A DARK CORIDOR AND LOST HIS TORCHE BUT A FRIEND SHONE A LITE AND THEY ESCAPED", "typos": [6, 10, 16]},
	{"text": "EVERY PANAL OF THE COMIC TELLS A STORY AND THE NARATOR READS EACH CAPTON OUT LOUD", "typos": [1, 10, 13]},
	{"text": "THE VILAIN CUT THE POWR SO THE STUDIO WENT DARK AND ONLY THE TORCH LIGHT REMANED", "typos": [1, 4, 15]},
	{"text": "A GOOD ASSIGMENT NEEDS CLEAR HEADINGS CAREFULL RESEARCH AND NO SPELING MISTAKES", "typos": [2, 6, 10]},
]

var _words: PackedStringArray = []
var _typos: Array = []
var _found: Array[int] = []
var _wrong: Array[int] = []
var _deck: Array = []
var _round := 0
var _rounds := 1


func _begin() -> void:
	title = "PROOFREAD THE PARAGRAPH"
	hint = "Click the three misspelled words on each page."
	_rounds = 1 + difficulty
	_deck = TEXTS.duplicate()
	_deck.shuffle()
	_round = 0
	_load_round()


func _load_round() -> void:
	var t: Dictionary = _deck[_round]
	_words = String(t["text"]).split(" ")
	_typos = t["typos"].duplicate()
	_found.clear()
	_wrong.clear()


func _word_rect(i: int) -> Rect2:
	# lay words out in lines
	var x := panel.position.x + 50.0
	var y := panel.position.y + 170.0
	var maxx := panel.end.x - 50.0
	for k in _words.size():
		var w := FONT_BODY.get_string_size(_words[k], HORIZONTAL_ALIGNMENT_LEFT, -1, 34).x + 18.0
		if x + w > maxx:
			x = panel.position.x + 50.0
			y += 64.0
		if k == i:
			return Rect2(Vector2(x, y - 34), Vector2(w, 46))
		x += w + 6.0
	return Rect2()


func _gui_input(event: InputEvent) -> void:
	if _done:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in _words.size():
			if _word_rect(i).has_point(event.position):
				if _typos.has(i):
					if not _found.has(i):
						_found.append(i)
						if _found.size() >= _typos.size():
							_round += 1
							if _round >= _rounds:
								succeed()
							else:
								flash("PAGE %d CLEAR!" % _round)
								_load_round()
				else:
					if not _wrong.has(i):
						_wrong.append(i)
					flash("THAT ONE IS FINE!", 6.0)
				return


func _draw_task() -> void:
	_text("PAGE %d / %d     FOUND %d / %d" % [mini(_round + 1, _rounds), _rounds, _found.size(), _typos.size()], panel.position + Vector2(30, 112), 26, INK, FONT_SHOUT)
	draw_rect(Rect2(panel.position + Vector2(30, 124), Vector2(panel.size.x - 60, 280)), Color("fffdf2"))
	draw_rect(Rect2(panel.position + Vector2(30, 124), Vector2(panel.size.x - 60, 280)), INK, false, 3.0)
	for i in _words.size():
		var r := _word_rect(i)
		if _found.has(i):
			draw_rect(r, Color(0.2, 0.8, 0.4, 0.45))
		elif _wrong.has(i):
			draw_rect(r, Color(1, 0.3, 0.3, 0.25))
		elif r.has_point(get_local_mouse_position()):
			draw_rect(r, Color(1, 0.85, 0.3, 0.35))
		_text(_words[i], r.position + Vector2(9, 34), 34, INK, FONT_BODY)
