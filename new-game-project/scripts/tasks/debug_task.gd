class_name DebugTask
extends TaskBase
## College task: each snippet has one buggy line. Click it. Three rounds.

const SNIPPETS := [
	{"lines": ["# add up the numbers 1 to 10", "total = 0", "for i in range(1, 10):", "    total = total + i", "print(total)"], "bug": 2},
	{"lines": ["# pass if the score is at least 40", "score = 52", "if score = 40:", "    print('pass')", "else:", "    print('fail')"], "bug": 2},
	{"lines": ["# count down from 5 to 1", "n = 5", "while n > 0:", "    print(n)", "    n = n + 1"], "bug": 4},
	{"lines": ["# average of a list", "xs = [4, 8, 6]", "avg = sum(xs) / len(xs) + 1", "print(avg)"], "bug": 2},
	{"lines": ["# find the biggest number", "best = 0", "for x in [3, 9, 4]:", "    if x < best:", "        best = x", "print(best)"], "bug": 3},
	{"lines": ["# say hello three times", "word = 'hello'", "print(word * 2)"], "bug": 2},
	{"lines": ["# is the number even?", "n = 14", "if n % 2 == 1:", "    print('even')"], "bug": 2},
]
const ROUNDS := 3

var _round := 0
var _deck: Array = []
var _cur: Dictionary = {}
var _wrong := -1
var _wrong_t := 0.0


func _begin() -> void:
	title = "DEBUG THE ASSIGNMENT"
	hint = "One line in each program is wrong. Click the bug!"
	_deck = SNIPPETS.duplicate()
	_deck.shuffle()
	_cur = _deck[0]


func _line_rect(i: int) -> Rect2:
	return Rect2(Vector2(panel.position.x + 70, panel.position.y + 135 + i * 46), Vector2(panel.size.x - 140, 42))


func _update(delta: float) -> void:
	_wrong_t = maxf(0.0, _wrong_t - delta)
	if _wrong_t <= 0.0:
		_wrong = -1


func _gui_input(event: InputEvent) -> void:
	if _done:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var lines: Array = _cur["lines"]
		for i in lines.size():
			if i > 0 and _line_rect(i).has_point(event.position):
				if i == _cur["bug"]:
					_round += 1
					if _round >= ROUNDS:
						succeed()
					else:
						flash("BUG SQUASHED!")
						_cur = _deck[_round]
				else:
					_wrong = i
					_wrong_t = 0.6
					flash("COMPILER SAYS NO", 8.0)


func _draw_task() -> void:
	_text("PROGRAM %d / %d" % [_round + 1, ROUNDS], panel.position + Vector2(30, 112), 26, INK, FONT_SHOUT)
	var lines: Array = _cur["lines"]
	draw_rect(Rect2(panel.position + Vector2(50, 122), Vector2(panel.size.x - 100, lines.size() * 46 + 22)), Color("1e1e2e"))
	for i in lines.size():
		var r := _line_rect(i)
		var is_comment: bool = i == 0
		if i == _wrong:
			draw_rect(r, Color(1, 0.2, 0.2, 0.4))
		elif not is_comment and r.has_point(get_local_mouse_position()):
			draw_rect(r, Color(1, 1, 1, 0.12))
		_text("%d" % (i + 1), r.position + Vector2(8, 30), 22, Color("6c7086"))
		_text(lines[i], r.position + Vector2(50, 30), 26, Color("7f8c8d") if is_comment else Color("a6e3a1"), FONT_BODY)
