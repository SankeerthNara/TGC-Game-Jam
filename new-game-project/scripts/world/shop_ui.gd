class_name ShopUI
extends Control
## The trade shop menu: swap hidden items for keys. Arrow keys to choose, Z to trade, X to leave.

signal buy_requested(key_id: String)
signal closed

const FONT_SHOUT := preload("res://assets/fonts/Bangers-Regular.ttf")
const FONT_BODY := preload("res://assets/fonts/ComicNeue-Bold.ttf")
const INK := Color("18151d")
const PAPER := Color("fff3d1")
const GOLD := Color("ffd23f")

var stock: Array = [] ## [{id, name, cost, blurb}]
var inv := {}
var owned: Array = []
var used: Array = []
var sel := 0
var note := ""
var _t := 0.0


func _ready() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func open(new_stock: Array, new_inv: Dictionary, new_owned: Array, new_used: Array, greeting: String) -> void:
	stock = new_stock
	sel = clampi(sel, 0, maxi(stock.size() - 1, 0))
	update_state(new_inv, new_owned, new_used)
	note = greeting
	visible = true


func update_state(new_inv: Dictionary, new_owned: Array, new_used: Array) -> void:
	inv = new_inv
	owned = new_owned
	used = new_used
	queue_redraw()


func can_afford(cost: Dictionary) -> bool:
	for k: String in cost:
		if int(inv.get(k, 0)) < int(cost[k]):
			return false
	return true


func _process(delta: float) -> void:
	if visible:
		_t += delta
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k: int = event.keycode
	if k == KEY_UP or k == KEY_W:
		sel = (sel - 1 + stock.size()) % maxi(stock.size(), 1)
	elif k == KEY_DOWN or k == KEY_S:
		sel = (sel + 1) % maxi(stock.size(), 1)
	elif k in [KEY_Z, KEY_ENTER, KEY_SPACE, KEY_E]:
		if not stock.is_empty():
			buy_requested.emit(stock[sel]["id"])
	elif k in [KEY_X, KEY_ESCAPE, KEY_BACKSPACE]:
		visible = false
		closed.emit()
	else:
		return
	get_viewport().set_input_as_handled()
	queue_redraw()


func _text(s: String, pos: Vector2, size: int, col: Color, font: Font = FONT_BODY) -> void:
	draw_string(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


func _draw() -> void:
	if not visible:
		return
	var vp := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.6))
	var panel := Rect2(Vector2(150, 105), Vector2(980, 520))
	draw_rect(Rect2(panel.position + Vector2(8, 8), panel.size), Color(0, 0, 0, 0.5))
	draw_rect(panel, PAPER)
	draw_rect(panel, INK, false, 6.0)
	# header
	draw_rect(Rect2(panel.position, Vector2(panel.size.x, 62)), GOLD)
	draw_rect(Rect2(panel.position, Vector2(panel.size.x, 62)), INK, false, 6.0)
	_text("TRADE SHOP", panel.position + Vector2(24, 46), 46, INK, FONT_SHOUT)
	_text("Mr. Barter's Swap & Stock", panel.position + Vector2(300, 44), 22, INK)
	# stock rows
	var y0 := panel.position.y + 82.0
	for i in stock.size():
		var e: Dictionary = stock[i]
		var row := Rect2(Vector2(panel.position.x + 18, y0 + i * 60.0), Vector2(560, 54))
		var is_sel := i == sel
		draw_rect(row, GOLD if is_sel else Color(1, 1, 1, 0.55))
		draw_rect(row, INK, false, 3.0 if is_sel else 1.5)
		var key_id: String = e["id"]
		draw_circle(row.position + Vector2(30, 27), 22.0, INK)
		KeySymbols.draw_key(self, key_id, row.position + Vector2(30, 27), 15.0, GOLD, INK)
		_text(e["name"], row.position + Vector2(66, 36), 28, INK, FONT_SHOUT)
		var x := row.position.x + 280.0
		for type: String in e["cost"]:
			KeySymbols.draw_item(self, type, Vector2(x + 12, row.position.y + 27), 11.0, INK)
			_text("x%d" % int(e["cost"][type]), Vector2(x + 26, row.position.y + 34), 20, INK)
			x += 76.0
		var status := "BUY [Z]"
		var scol := Color("2d6a4f")
		if used.has(key_id):
			status = "USED"
			scol = Color("6c757d")
		elif owned.has(key_id):
			status = "OWNED"
			scol = Color("6c757d")
		elif not can_afford(e["cost"]):
			status = "NEED MORE"
			scol = Color("c1121f")
		elif not is_sel:
			status = "can afford"
		var sz := FONT_SHOUT.get_string_size(status, HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
		_text(status, Vector2(row.end.x - sz.x - 12, row.position.y + 34), 20, scol, FONT_SHOUT)
	if stock.is_empty():
		_text("Nothing in stock yet. Open the gates, explore, come back!", Vector2(panel.position.x + 30, y0 + 40), 24, INK)
	# right column: selected blurb + your items
	var rx := panel.position.x + 604.0
	_text("YOUR POCKETS", Vector2(rx, y0 + 18), 26, INK, FONT_SHOUT)
	var iy := y0 + 34.0
	for type: String in ["ink", "gear", "shard"]:
		KeySymbols.draw_item(self, type, Vector2(rx + 18, iy + 20), 14.0, INK)
		_text("%s  x%d" % [KeySymbols.ITEM_NAMES[type], int(inv.get(type, 0))], Vector2(rx + 46, iy + 28), 22, INK)
		iy += 40.0
	if not stock.is_empty():
		var e2: Dictionary = stock[sel]
		_text("THE KEY", Vector2(rx, iy + 24), 26, INK, FONT_SHOUT)
		draw_circle(Vector2(rx + 40, iy + 80), 34.0, INK)
		KeySymbols.draw_key(self, e2["id"], Vector2(rx + 40, iy + 80), 24.0, GOLD, INK)
		_blurb(e2["blurb"], Vector2(rx + 90, iy + 62), 250.0)
	# shopkeeper line + footer
	draw_rect(Rect2(Vector2(panel.position.x + 18, panel.end.y - 92), Vector2(panel.size.x - 36, 50)), Color(1, 1, 1, 0.7))
	draw_rect(Rect2(Vector2(panel.position.x + 18, panel.end.y - 92), Vector2(panel.size.x - 36, 50)), INK, false, 2.0)
	_blurb(note, Vector2(panel.position.x + 30, panel.end.y - 68), panel.size.x - 60.0)
	_text("UP/DOWN: choose     Z: trade     X: leave", Vector2(panel.position.x + 24, panel.end.y - 16), 20, Color("6c757d"))


func _blurb(text: String, pos: Vector2, width: float) -> void:
	var words := text.split(" ")
	var line := ""
	var y := pos.y
	for w in words:
		var test := (line + " " + w).strip_edges()
		if FONT_BODY.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x > width:
			_text(line, Vector2(pos.x, y), 19, INK)
			y += 22.0
			line = w
		else:
			line = test
	_text(line, Vector2(pos.x, y), 19, INK)
