class_name NoticeCard
extends Control
## A full-screen comic card that waits for the player: mode "start" tells testers to play on until
## the THE END card (the story has false endings); mode "end" is that card, the true ending.
## Z / Enter / Space / click (after a moment) closes it and emits `done`.

signal done

const FONT_SHOUT := preload("res://assets/fonts/Bangers-Regular.ttf")
const FONT_BODY := preload("res://assets/fonts/ComicNeue-Bold.ttf")
const INK := Color("18151d")
const PAPER := Color("fff3d1")
const GOLD := Color("ffd23f")
const RED := Color("e63946")

var mode := "start"
var _t := 0.0
var _closed := false


func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	grab_focus()
	if mode == "end":
		EventBus.sound_requested.emit("light_swell")


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_Z, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		get_viewport().set_input_as_handled()
		_close()


## Closes at once (the test tools: like the book's skip(), it also skips the cutscene that follows).
func skip() -> void:
	_t = 99.0
	var tree := get_tree()
	_close()
	for n in tree.root.get_children() if tree != null else []:
		if "_overlay" in n and n._overlay is ComicCutscene:
			n._overlay.skip()


func _close() -> void:
	if _closed or _t < (0.8 if mode == "start" else 2.0):
		return
	_closed = true
	EventBus.sound_requested.emit("page_turn")
	done.emit()
	queue_free()


func _center(text: String, y: float, font: Font, fs: int, col: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, Vector2(640 - w * 0.5, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


func _draw() -> void:
	var k := clampf(_t / 0.4, 0.0, 1.0)
	if mode == "end":
		draw_rect(Rect2(Vector2.ZERO, size), Color("0d0b10"))
		ComicArt.burst(self, size, Vector2(640, 330), Color(1, 0.85, 0.4, 0.0), Color(1, 0.85, 0.4, 0.18), 24, _t * 0.1)
		ComicArt.shout(self, "THE END", Vector2(640, 280), 150, GOLD, 16, -0.03, lerpf(1.6, 1.0, k))
		_center("THE TRUE ENDING", 390, FONT_SHOUT, 40, PAPER)
		_center("You finished Glitched Out. Thank you for playing!", 450, FONT_BODY, 28, PAPER)
		_center("Story & design: Sankeerth Nara (team Game it)  -  TGC Game Jam", 500, FONT_BODY, 20, Color(1, 1, 1, 0.65))
		if _t > 2.0 and int(_t * 2.0) % 2 == 0:
			_center("PRESS Z OR CLICK TO SEE YOUR SCORE", 640, FONT_SHOUT, 26, GOLD)
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("0d0b10"))
	var card := Rect2(Vector2(190, 120), Vector2(900, 480))
	draw_rect(Rect2(card.position + Vector2(10, 10), card.size), Color(0, 0, 0, 0.5))
	draw_rect(card, PAPER)
	ComicArt.halftone(self, size, Color(0, 0, 0, 0.05), 20.0, 3.0, Vector2(1, 1))
	draw_rect(card, INK, false, 6.0)
	draw_rect(Rect2(card.position, Vector2(card.size.x, 70)), RED)
	_center("BEFORE YOU READ", card.position.y + 52, FONT_SHOUT, 48, PAPER)
	_center("Keep playing until you see the", 280, FONT_BODY, 32, INK)
	ComicArt.shout(self, "THE END", Vector2(640, 345), 72, GOLD, 12, -0.03)
	_center("card. Only that card means the game is over.", 415, FONT_BODY, 32, INK)
	_center("The story has a few FALSE ENDINGS along the way. Don't stop at them!", 475, FONT_BODY, 24, RED)
	if _t > 0.8 and int(_t * 2.0) % 2 == 0:
		_center("PRESS Z OR CLICK TO START", 560, FONT_SHOUT, 28, INK)
