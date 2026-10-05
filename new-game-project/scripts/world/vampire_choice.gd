class_name VampireChoice
extends Control
## The big decision: you froze a vampire in your torchlight. REVEAL or KILL? Nobody knows if he is
## the friend or the villain. After the choice a short comic-panel suspense scene plays, then the result.

signal finished(reveal: bool)

const FONT_SHOUT := preload("res://assets/fonts/Bangers-Regular.ttf")
const FONT_BODY := preload("res://assets/fonts/ComicNeue-Bold.ttf")
const INK := Color("18151d")
const GOLD := Color("ffd23f")

var role := "friend"
var _stage := 0 ## 0 choosing, 1 suspense, 2 result
var _t := 0.0
var _reveal := true
var _sent := false


func _ready() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(delta: float) -> void:
	_t += delta
	if _stage == 1 and _t > 1.7:
		_stage = 2
		_t = 0.0
	elif _stage == 2 and _t > 2.2 and not _sent:
		_sent = true
		finished.emit(_reveal)
	queue_redraw()


func _choose(reveal: bool) -> void:
	if _stage != 0 or _t < 0.5:
		return
	_reveal = reveal
	_stage = 3
	if not _sent:
		_sent = true
		finished.emit(reveal)


func _btn(i: int) -> Rect2:
	return Rect2(Vector2(size.x * 0.5 - 330 + i * 350, 470), Vector2(310, 100))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in 2:
			if _btn(i).has_point(event.position):
				_choose(i == 0)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode in [KEY_Z, KEY_1, KEY_ENTER]:
		_choose(true)
	elif event.keycode in [KEY_J, KEY_2]:
		_choose(false)


func _vampire_face(c: Vector2, r: float, shake: float) -> void:
	var o := c + Vector2(sin(_t * 60.0) * shake, 0.0)
	draw_colored_polygon(PackedVector2Array([o + Vector2(-r * 1.5, r * 1.2), o + Vector2(-r * 0.7, -r * 0.4), o + Vector2(r * 0.7, -r * 0.4), o + Vector2(r * 1.5, r * 1.2)]), Color("1a1423"))
	draw_colored_polygon(PackedVector2Array([o + Vector2(-r * 0.5, r * 1.2), o + Vector2(0, -r * 0.2), o + Vector2(r * 0.5, r * 1.2)]), Color("a4161a"))
	draw_circle(o + Vector2(0, -r * 0.7), r * 1.0, INK)
	draw_circle(o + Vector2(0, -r * 0.7), r * 0.92, Color("e9e1f2"))
	draw_colored_polygon(PackedVector2Array([o + Vector2(-r * 0.92, -r * 0.85), o + Vector2(0, -r * 1.25), o + Vector2(r * 0.92, -r * 0.85), o + Vector2(r * 0.7, -r * 1.55), o + Vector2(-r * 0.7, -r * 1.55)]), Color("120d1a"))
	for side in [-1.0, 1.0]:
		draw_circle(o + Vector2(side * r * 0.38, -r * 0.62), r * 0.17, Color("ff2d2d"))
	draw_colored_polygon(PackedVector2Array([o + Vector2(-r * 0.3, -r * 0.2), o + Vector2(-r * 0.1, -r * 0.2), o + Vector2(-r * 0.2, r * 0.18)]), Color.WHITE)
	draw_colored_polygon(PackedVector2Array([o + Vector2(r * 0.3, -r * 0.2), o + Vector2(r * 0.1, -r * 0.2), o + Vector2(r * 0.2, r * 0.18)]), Color.WHITE)


func _centered(text: String, y: float, fs: int, col: Color, font: Font = FONT_SHOUT) -> void:
	var sz := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	draw_string(font, Vector2((size.x - sz.x) * 0.5, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


func _draw() -> void:
	var vp := size
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.04, 0.0, 0.1, 0.86))
	if _stage == 0:
		_vampire_face(Vector2(vp.x * 0.5, 230), 70.0, 0.0)
		_centered("YOU CAUGHT A VAMPIRE!", 380, 62, GOLD)
		_centered("Friend or villain? There is no way to tell. Choose.", 424, 26, Color("fff3d1"), FONT_BODY)
		var labels := ["REVEAL", "KILL"]
		var subs := ["[Z]  unmask him", "[J]  strike him down"]
		var cols := [Color("2dc653"), Color("e63946")]
		for i in 2:
			var b := _btn(i)
			draw_rect(Rect2(b.position + Vector2(6, 7), b.size), Color(0, 0, 0, 0.5))
			draw_rect(b, cols[i])
			draw_rect(b, INK, false, 6.0)
			var ls := FONT_SHOUT.get_string_size(labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 54)
			draw_string(FONT_SHOUT, b.position + Vector2((b.size.x - ls.x) * 0.5, 58), labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 54, INK)
			var ss := FONT_BODY.get_string_size(subs[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 22)
			draw_string(FONT_BODY, b.position + Vector2((b.size.x - ss.x) * 0.5, 88), subs[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, INK)
	elif _stage == 1:
		var words := ["...", "?!", "!!!"]
		var show := mini(int(_t / 0.5) + 1, 3)
		for i in show:
			var r := Rect2(Vector2(vp.x * 0.5 - 420 + i * 290, 190), Vector2(260, 300))
			var k := minf((_t - i * 0.5) / 0.15, 1.0)
			draw_set_transform(r.get_center(), (i - 1) * 0.05, Vector2(k, k))
			draw_rect(Rect2(-r.size * 0.5 + Vector2(6, 7), r.size), Color(0, 0, 0, 0.5))
			draw_rect(Rect2(-r.size * 0.5, r.size), Color("fff3d1"))
			draw_rect(Rect2(-r.size * 0.5, r.size), INK, false, 6.0)
			draw_set_transform(Vector2.ZERO)
			_vampire_face(r.get_center() + Vector2(0, 40), 40.0 + i * 8.0, 3.0 + i * 2.0)
			var ws := FONT_SHOUT.get_string_size(words[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 64)
			draw_string(FONT_SHOUT, r.position + Vector2((r.size.x - ws.x) * 0.5, 56), words[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 64, Color("e63946"))
		_centered("REVEALING..." if _reveal else "STRIKING...", 560, 40, GOLD)
	else:
		var head := ""
		var sub := ""
		var col := Color.WHITE
		if _reveal and role == "friend":
			head = "HE'S YOUR FRIEND!"
			sub = "He joins you now. Light no longer scares him."
			col = Color("2dc653")
		elif _reveal:
			head = "IT'S THE VILLAIN!"
			sub = "He bolts! Chase him down. Get ready to run and jump!"
			col = Color("e63946")
		elif role == "friend":
			head = "OH NO... HE WAS YOUR FRIEND."
			sub = "You will carry this. You lose a heart."
			col = Color("8d99ae")
		else:
			head = "THE VILLAIN IS DEAD!"
			sub = "That was quick. The sabotage stops."
			col = Color("ffd23f")
		var k := minf(_t / 0.2, 1.0)
		draw_set_transform(vp * 0.5, -0.03, Vector2(k, k))
		draw_rect(Rect2(-380, -90, 760, 180), Color("fff3d1"))
		draw_rect(Rect2(-380, -90, 760, 180), INK, false, 8.0)
		var hs := FONT_SHOUT.get_string_size(head, HORIZONTAL_ALIGNMENT_LEFT, -1, 64)
		draw_string(FONT_SHOUT, Vector2(-hs.x * 0.5, -10), head, HORIZONTAL_ALIGNMENT_LEFT, -1, 64, col.darkened(0.25) if col.get_luminance() > 0.6 else col)
		var sbs := FONT_BODY.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 26)
		draw_string(FONT_BODY, Vector2(-sbs.x * 0.5, 50), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, INK)
		draw_set_transform(Vector2.ZERO)
