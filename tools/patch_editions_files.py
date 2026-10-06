import os
import shutil

notice_card_code = '''class_name NoticeCard
extends CanvasLayer
## A full-screen comic card that waits for the player: mode "start" tells testers to play on until
## the THE END card (credits roll and a boss fakes his death before it); mode "end" is that card, the true ending;
## mode "controls" tells the player combat controls before the 240p boss fight.
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
var _view: Control


func _ready() -> void:
	layer = 105 # above EditionFX (layer 95) so controls and text are rendered at crisp native 720p without shader blur
	process_mode = Node.PROCESS_MODE_ALWAYS
	_view = Control.new()
	_view.position = Vector2.ZERO
	_view.size = Vector2(1280, 720)
	_view.mouse_filter = Control.MOUSE_FILTER_STOP
	_view.focus_mode = Control.FOCUS_ALL
	_view.draw.connect(_draw_view)
	_view.gui_input.connect(_gui_input)
	add_child(_view)
	_view.grab_focus()
	if mode == "end":
		EventBus.sound_requested.emit("light_swell")


func _process(delta: float) -> void:
	_t += delta
	if _view != null and is_instance_valid(_view):
		_view.queue_redraw()


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
	if _closed or _t < (0.8 if mode in ["start", "controls"] else 2.0):
		return
	_closed = true
	EventBus.sound_requested.emit("page_turn")
	done.emit()
	queue_free()


func _center(text: String, y: float, font: Font, fs: int, col: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	_view.draw_string(font, Vector2(640 - w * 0.5, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


func _draw_view() -> void:
	var k := clampf(_t / 0.4, 0.0, 1.0)
	var size := Vector2(1280, 720)
	if mode == "controls":
		_view.draw_rect(Rect2(Vector2.ZERO, size), Color("0d0b10"))
		var card := Rect2(Vector2(190, 50), Vector2(900, 620))
		_view.draw_rect(Rect2(card.position + Vector2(10, 10), card.size), Color(0, 0, 0, 0.5))
		_view.draw_rect(card, PAPER)
		ComicArt.halftone(_view, size, Color(0, 0, 0, 0.05), 20.0, 3.0, Vector2(1, 1))
		_view.draw_rect(card, INK, false, 6.0)
		_view.draw_rect(Rect2(card.position, Vector2(card.size.x, 68)), GOLD)
		_center("COMBAT CONTROLS", card.position.y + 48, FONT_SHOUT, 46, INK)
		_center("These are your controls from now on.", card.position.y + 102, FONT_BODY, 24, Color("18151d"))
		var controls: Array = [
			["MOVE", "A / D  or  ARROWS", "Run left and right"],
			["JUMP", "Z  or  SPACE", "Jump / air leap"],
			["ATTACK", "J  or  X", "Slash combo (+Up / +Down in air)"],
			["DASH / ROLL", "K  or  C", "Quick dodge through attacks"],
			["PARRY", "L (Tap)", "Parry when enemy cane flashes GOLD or eyes turn RED"],
			["LIGHT BLADE", "L (Hold & Release)", "Radiant light blade blast across the arena"],
			["HEAL", "F", "Heal hearts (uses ink)"],
			["PAUSE", "P", "Pause / Resume game"],
		]
		var start_y := card.position.y + 130.0
		var row_h := 46.0
		for i in controls.size():
			var entry: Array = controls[i]
			var ry := start_y + i * row_h
			var rx := card.position.x + 36.0
			var rw := card.size.x - 72.0
			var bg_col := Color(0.95, 0.92, 0.84) if i % 2 == 0 else Color(0.98, 0.96, 0.90)
			_view.draw_rect(Rect2(Vector2(rx, ry), Vector2(rw, row_h - 6)), bg_col)
			_view.draw_rect(Rect2(Vector2(rx, ry), Vector2(rw, row_h - 6)), Color(0.1, 0.1, 0.1, 0.15), false, 1.0)
			var badge_rect := Rect2(Vector2(rx + 8, ry + 4), Vector2(170, row_h - 14))
			_view.draw_rect(badge_rect, INK)
			var action_text: String = entry[0]
			var at_sz := FONT_SHOUT.get_string_size(action_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
			_view.draw_string(FONT_SHOUT, Vector2(badge_rect.position.x + (badge_rect.size.x - at_sz) * 0.5, badge_rect.position.y + 22), action_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, GOLD)
			var keys_text: String = entry[1]
			_view.draw_string(FONT_BODY, Vector2(rx + 195, ry + 25), keys_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("0d0b12"))
			var desc_text: String = entry[2]
			_view.draw_string(FONT_BODY, Vector2(rx + 440, ry + 25), desc_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.3, 0.3, 0.35))
		if _t > 0.8 and int(_t * 2.0) % 2 == 0:
			_center("PRESS Z OR CLICK TO FIGHT", card.position.y + 590, FONT_SHOUT, 28, INK)
		return
	if mode == "end":
		_view.draw_rect(Rect2(Vector2.ZERO, size), Color("0d0b10"))
		ComicArt.burst(_view, size, Vector2(640, 330), Color(1, 0.85, 0.4, 0.0), Color(1, 0.85, 0.4, 0.18), 24, _t * 0.1)
		ComicArt.shout(_view, "THE END", Vector2(640, 280), 150, GOLD, 16, -0.03, lerpf(1.6, 1.0, k))
		_center("THE TRUE ENDING", 390, FONT_SHOUT, 40, PAPER)
		_center("You finished Glitched Out. Thank you for playing!", 450, FONT_BODY, 28, PAPER)
		_center("Story & design: Sankeerth Nara (team Game it)  -  TGC Game Jam", 500, FONT_BODY, 20, Color(1, 1, 1, 0.65))
		if _t > 2.0 and int(_t * 2.0) % 2 == 0:
			_center("PRESS Z OR CLICK TO SEE YOUR SCORE", 640, FONT_SHOUT, 26, GOLD)
		return
	_view.draw_rect(Rect2(Vector2.ZERO, size), Color("0d0b10"))
	var card := Rect2(Vector2(190, 120), Vector2(900, 480))
	_view.draw_rect(Rect2(card.position + Vector2(10, 10), card.size), Color(0, 0, 0, 0.5))
	_view.draw_rect(card, PAPER)
	ComicArt.halftone(_view, size, Color(0, 0, 0, 0.05), 20.0, 3.0, Vector2(1, 1))
	_view.draw_rect(card, INK, false, 6.0)
	_view.draw_rect(Rect2(card.position, Vector2(card.size.x, 70)), RED)
	_center("BEFORE YOU READ", card.position.y + 52, FONT_SHOUT, 48, PAPER)
	_center("Keep playing until you see the", 280, FONT_BODY, 32, INK)
	ComicArt.shout(_view, "THE END", Vector2(640, 345), 72, GOLD, 12, -0.03)
	_center("card. Only that card means the game is over.", 415, FONT_BODY, 32, INK)
	_center("Credits may roll and bosses may fall before then. Don't stop there!", 475, FONT_BODY, 24, RED)
	if _t > 0.8 and int(_t * 2.0) % 2 == 0:
		_center("PRESS Z OR CLICK TO START", 560, FONT_SHOUT, 28, INK)
'''

for base in ['D:/Infinium/wt-claude', 'D:/Infinium/TGC-Game-Jam']:
    target = os.path.join(base, 'new-game-project/scripts/editions/notice_card.gd')
    if os.path.exists(os.path.dirname(target)):
        with open(target, 'w', encoding='utf-8') as f:
            f.write(notice_card_code)
        print(f'Wrote {target}')
