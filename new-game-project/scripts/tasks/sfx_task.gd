class_name SfxTask
extends TaskBase
## Comic lettering: type each sound effect before it fades. Six words.

const WORDS := ["POW", "ZAP", "BAM", "WHAM", "BZZT", "SPLAT", "KABOOM", "WHOOSH", "THUD", "SNAP", "KRAK", "ZOOM"]
const NEED := 6
const TIME_PER := 6.0

var _queue: Array[String] = []
var _word := ""
var _typed := 0
var _left := TIME_PER
var _count := 0


func _begin() -> void:
	title = "LETTER THE SOUND EFFECTS"
	hint = "Type the word you see. A wrong letter restarts the word. Be quick!"
	var w := WORDS.duplicate()
	w.shuffle()
	for i in NEED + 3:
		_queue.append(w[i])
	_next()


func _next() -> void:
	_word = _queue.pop_front()
	_typed = 0
	_left = TIME_PER


func _unhandled_input(event: InputEvent) -> void:
	if _done or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var ch := String.chr(event.unicode).to_upper() if event.unicode > 0 else ""
	if ch == "" or ch == " ":
		return
	if ch == _word[_typed]:
		_typed += 1
		if _typed >= _word.length():
			_count += 1
			if _count >= NEED:
				succeed()
			else:
				_next()
	else:
		_typed = 0
		flash("OOPS!", 6.0)


func _update(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		flash("TOO SLOW!", 8.0)
		if _queue.is_empty():
			_queue.append(WORDS[randi() % WORDS.size()])
		_next()


func _draw_task() -> void:
	_centered("LETTERED %d / %d" % [_count, NEED], panel.position.y + 112, 28, INK, FONT_SHOUT)
	var c := panel.get_center() + Vector2(0, 20)
	var sc := 1.0 + sin(_t * 8.0) * 0.03
	draw_set_transform(c, -0.06, Vector2(sc, sc))
	var pts := PackedVector2Array()
	for k in 24:
		var a := k * TAU / 24.0
		var r := 190.0 if k % 2 == 0 else 150.0
		pts.append(Vector2(cos(a) * r * 1.35, sin(a) * r * 0.62))
	draw_colored_polygon(pts, Color("ffd23f"))
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, INK, 6.0)
	var fs := 110
	var full := FONT_SHOUT.get_string_size(_word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var typed_part := _word.substr(0, _typed)
	var x := -full.x * 0.5
	draw_string(FONT_SHOUT, Vector2(x, 38), _word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(INK.r, INK.g, INK.b, 0.35))
	draw_string(FONT_SHOUT, Vector2(x, 38), typed_part, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("e63946"))
	draw_set_transform(Vector2.ZERO)
	var bar := Rect2(Vector2(panel.position.x + 120, panel.end.y - 70), Vector2(panel.size.x - 240, 22))
	draw_rect(bar, INK)
	draw_rect(Rect2(bar.position + Vector2(3, 3), Vector2((bar.size.x - 6) * clampf(_left / TIME_PER, 0.0, 1.0), bar.size.y - 6)), RED if _left < 2.0 else Color("2dc653"))
