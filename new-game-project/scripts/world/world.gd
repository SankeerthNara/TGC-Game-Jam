class_name World
extends Node2D
## The seamless top-down comic town ("Gutter Town"). The hero walks it with the arrow keys,
## Pokemon style, carrying a torch. The town is dark: hidden items are traded at the shop for
## keys, and keys open the page doors. Cheap lookalike keys open the wrong doors.
## Rules and puzzles live elsewhere; this node handles walking, items, keys, drawing and lights.

signal door_entered(puzzle_index: int)
signal message(text: String)
signal gate_opened(gate_char: String)

const TEX_PAPER := preload("res://assets/art/paper_texture.png")
const TEX_HALFTONE := preload("res://assets/art/halftone_dot.png")
const TEX_GLOW := preload("res://assets/art/radial_glow.png")
const FONT_SHOUT := preload("res://assets/fonts/Bangers-Regular.ttf")

const TILE := 64.0
const INK := Color("18151d")
const PAPER := Color("fff3d1")
const GRASS := Color("5f8f4e")
const BUSH := Color("3f7a3a")
const GOLD := Color("ffd23f")
const DARKNESS := Color(0.17, 0.15, 0.3)
const HOUSE_COLORS := [Color("e76f51"), Color("2a9d8f"), Color("e9c46a"), Color("9b5de5"), Color("4cc9f0"), Color("f28482"), Color("84a59d"), Color("b5838d")]
const SOLID_CHARS := ",T#NslGHIo"
const KEEPER_LINES := [
	"Welcome, welcome! Mr. Barter's Swap & Stock. Bring me odds and ends, I will hand you keys.",
	"Mind the keyholes, friend. Some of my keys are a LITTLE bit different from what is on the door.",
	"Ink, gears, shards: I take them all. No refunds, ever."]

var rows: Array[String] = []
var cols := 0
var count_rows := 0
var decoys: Array = []
var gates: Dictionary = {}
var signs: Dictionary = {}
var npc_lines: Array = []
var door_info: Dictionary = {} ## puzzle index -> {label, key}
var key_defs: Array = [] ## shop stock definitions
var items: Array = [] ## [{x, y, type, taken}]

var hero := HeroActor.new()
var tile := Vector2i.ZERO
var facing := Vector2i.DOWN
var done := {} ## puzzle index -> true
var inv := {"ink": 0, "gear": 0, "shard": 0}
var keys_owned: Array = []
var keys_used: Array = []
var active := false

var _start := Vector2i.ZERO
var _shop_tile := Vector2i(-99, -99)
var _doors := {} ## Vector2i -> puzzle index
var _door_block := {} ## building tile -> puzzle index (for colouring)
var _lamps: Array[Vector2i] = []
var _braziers: Array[Vector2i] = []
var _lights := {} ## Vector2i -> PointLight2D (lamps and braziers)
var _door_lights := {}
var _hero_light: PointLight2D
var _cam: Camera2D
var _mod: CanvasModulate
var _glints: GlintLayer
var _ui: CanvasLayer
var _shop: ShopUI
var _inv_hud: InventoryHUD
var _pending_door := -1
var _pending_shop := false
var _shop_open := false
var _shop_visits := 0
var _npc_i := 0
var _time := 0.0
var _bump_cd := 0.0
var _flash := 0.0
var _mood_timer := 0.0
var _pops: Array[Dictionary] = []


func _ready() -> void:
	hero.glow = TEX_GLOW
	_cam = Camera2D.new()
	_cam.position_smoothing_enabled = true
	_cam.position_smoothing_speed = 7.0
	add_child(_cam)
	_mod = CanvasModulate.new()
	_mod.color = DARKNESS
	add_child(_mod)
	_hero_light = _make_light(2.3, Color("ffb85c"), 1.25)
	add_child(_hero_light)
	_glints = GlintLayer.new()
	_glints.world = self
	add_child(_glints)
	_ui = CanvasLayer.new()
	_ui.layer = 6
	add_child(_ui)
	_inv_hud = InventoryHUD.new()
	_ui.add_child(_inv_hud)
	_shop = ShopUI.new()
	_shop.buy_requested.connect(_buy)
	_shop.closed.connect(_close_shop)
	var shop_layer := CanvasLayer.new()
	shop_layer.layer = 15
	add_child(shop_layer)
	shop_layer.add_child(_shop)
	load_map("res://data/world/town.json")
	set_active(false)


func load_map(path: String) -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	rows.clear()
	for r: String in data["rows"]:
		rows.append(r)
	count_rows = rows.size()
	cols = rows[0].length()
	decoys = data.get("decoys", [])
	gates = data.get("gates", {})
	npc_lines = data.get("npc_lines", [])
	key_defs = data.get("keys", [])
	door_info.clear()
	for k: String in data.get("doors", {}):
		door_info[int(k)] = data["doors"][k]
	items.clear()
	for it: Dictionary in data.get("items", []):
		items.append({"x": int(it["x"]), "y": int(it["y"]), "type": it["type"], "taken": false})
	signs.clear()
	for k: String in data.get("signs", {}):
		var xy := k.split(",")
		signs[Vector2i(int(xy[0]), int(xy[1]))] = data["signs"][k]
	_doors.clear()
	_door_block.clear()
	_lamps.clear()
	_braziers.clear()
	for y in count_rows:
		for x in cols:
			var ch := rows[y][x]
			if ch == "@":
				_start = Vector2i(x, y)
			elif ch == "l":
				_lamps.append(Vector2i(x, y))
			elif ch == "o":
				_braziers.append(Vector2i(x, y))
			elif ch == "S":
				_shop_tile = Vector2i(x, y)
				for by in range(y - 2, y + 1):
					for bx in range(x - 2, x + 3):
						_door_block[Vector2i(bx, by)] = 7
			elif ch.is_valid_int():
				var idx := int(ch) - 1
				_doors[Vector2i(x, y)] = idx
				for by in range(y - 2, y + 1):
					for bx in range(x - 2, x + 3):
						_door_block[Vector2i(bx, by)] = idx
	for l in _lights.values():
		(l as Node).queue_free()
	_lights.clear()
	for t in _lamps:
		var light := _make_light(2.6, Color("ffd9a0"), 0.0)
		light.position = _center(t) + Vector2(0, -TILE * 0.35)
		add_child(light)
		_lights[t] = light
	for t in _braziers:
		var light := _make_light(2.1, Color("ff9a3c"), 0.0)
		light.position = _center(t) + Vector2(0, -TILE * 0.2)
		add_child(light)
		_lights[t] = light
	_cam.limit_left = 0
	_cam.limit_top = 0
	_cam.limit_right = int(cols * TILE)
	_cam.limit_bottom = int(count_rows * TILE)
	reset()


func _make_light(scale_f: float, color: Color, energy: float) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = TEX_GLOW
	l.texture_scale = scale_f
	l.color = color
	l.energy = energy
	return l


func reset() -> void:
	done.clear()
	for l in _door_lights.values():
		(l as Node).queue_free()
	_door_lights.clear()
	inv = {"ink": 0, "gear": 0, "shard": 0}
	keys_owned.clear()
	keys_used.clear()
	for it: Dictionary in items:
		it["taken"] = false
	_pops.clear()
	_shop_open = false
	_pending_shop = false
	_shop_visits = 0
	_shop.visible = false
	tile = _start
	facing = Vector2i.DOWN
	_pending_door = -1
	_npc_i = 0
	hero.reset()
	hero.snap(_stand_pos(tile), _stand_pos(tile) + Vector2(0, TILE))
	_sync_hud()
	_refresh_lights()
	queue_redraw()


func set_active(on: bool) -> void:
	active = on
	visible = on
	_cam.enabled = on
	_mod.visible = on
	_ui.visible = on
	if on:
		_cam.make_current()
		_cam.position = hero.pos
		_cam.reset_smoothing()
		RenderingServer.set_default_clear_color(Color("0b0818"))
		_refresh_lights()


func _sync_hud() -> void:
	_inv_hud.update_state(inv, keys_owned)


# --- map queries --------------------------------------------------------------

func _center(t: Vector2i) -> Vector2:
	return Vector2(t.x + 0.5, t.y + 0.5) * TILE


func _stand_pos(t: Vector2i) -> Vector2:
	return _center(t) + Vector2(0, -TILE * 0.2)


func _at(t: Vector2i) -> String:
	if t.x < 0 or t.y < 0 or t.x >= cols or t.y >= count_rows:
		return "T"
	return rows[t.y][t.x]


func total_done() -> int:
	return done.size()


## Pages that count for progress: decoy pages (wrong comics) do not.
func real_done() -> int:
	var n := 0
	for idx: int in done:
		if not decoys.has(idx):
			n += 1
	return n


func real_total() -> int:
	return _doors.size() - decoys.size()


func gate_open(ch: String) -> bool:
	return real_done() >= int(gates.get(ch, 999))


func _zone_of(t: Vector2i) -> int:
	if t.y >= 15:
		return 0 if t.x < 21 else 1
	return 2 if t.x >= 21 else 3


func _zone_index_open(z: int) -> bool:
	match z:
		0:
			return true
		1:
			return gate_open("G")
		2:
			return gate_open("G") and gate_open("H")
		_:
			return gate_open("G") and gate_open("H") and gate_open("I")


func _zone_open(t: Vector2i) -> bool:
	return _zone_index_open(_zone_of(t))


func is_solid(t: Vector2i) -> bool:
	var ch := _at(t)
	if ch in ["G", "H", "I"]:
		return not gate_open(ch)
	if _doors.has(t) and done.has(_doors[t]):
		return true
	return SOLID_CHARS.contains(ch)


func _is_building(t: Vector2i) -> bool:
	var ch := _at(t)
	return ch == "#" or ch == "S" or ch.is_valid_int()


func key_name_for_door(idx: int) -> String:
	return String(door_info.get(idx, {}).get("key", "?")).to_upper()


# --- progress -----------------------------------------------------------------

## Called when a puzzle finishes. Lights its door and may open a gate.
func mark_done(puzzle_index: int) -> void:
	var before: Array[String] = []
	for g: String in gates:
		if gate_open(g):
			before.append(g)
	done[puzzle_index] = true
	for t: Vector2i in _doors:
		if _doors[t] == puzzle_index:
			var l := _make_light(4.8, Color("ffd9a0") if not decoys.has(puzzle_index) else Color("ff9ec0"), 0.8)
			l.position = _center(t) + Vector2(0, TILE * 0.2)
			add_child(l)
			_door_lights[puzzle_index] = l
			hero.snap(_stand_pos(t + Vector2i.DOWN), _center(t))
			tile = t + Vector2i.DOWN
	for g: String in gates:
		if gate_open(g) and not before.has(g):
			_flash = 1.0
			gate_opened.emit(g)
	hero.mood = HeroActor.Mood.CONFUSED if decoys.has(puzzle_index) else HeroActor.Mood.HAPPY
	_mood_timer = 4.0
	_refresh_lights()
	queue_redraw()


## Gave up on a page: put the hero back on the street in front of its door.
func leave_door(puzzle_index: int) -> void:
	for t: Vector2i in _doors:
		if _doors[t] == puzzle_index:
			tile = t + Vector2i.DOWN
			hero.snap(_stand_pos(tile), _center(t))
	_pending_door = -1


func _refresh_lights() -> void:
	for t: Vector2i in _lights:
		(_lights[t] as PointLight2D).energy = 1.0 if _zone_open(t) else 0.0


# --- items, keys, shop -----------------------------------------------------------

func _item_at(t: Vector2i) -> int:
	for i in items.size():
		if not items[i]["taken"] and items[i]["x"] == t.x and items[i]["y"] == t.y:
			return i
	return -1


func _collect(i: int) -> void:
	var it: Dictionary = items[i]
	it["taken"] = true
	var type: String = it["type"]
	inv[type] = int(inv[type]) + 1
	_pop("+1 " + String(KeySymbols.ITEM_NAMES[type]), _center(tile) + Vector2(0, -TILE * 1.1), KeySymbols.ITEM_COLORS[type])
	EventBus.item_collected.emit(type)
	_sync_hud()


func _pop(text: String, pos: Vector2, color: Color) -> void:
	_pops.append({"text": text, "pos": pos, "t": 0.0, "color": color})


func _try_unlock(idx: int) -> bool:
	var kid: String = door_info.get(idx, {}).get("key", "")
	if kid != "" and keys_owned.has(kid):
		keys_owned.erase(kid)
		keys_used.append(kid)
		_sync_hud()
		EventBus.door_unlocked.emit(idx)
		return true
	return false


func _door_locked_msg(idx: int) -> void:
	message.emit("NARRATOR: Locked! The keyhole is shaped like a %s. Keys are sold at the shop." % key_name_for_door(idx))


func _open_shop() -> void:
	_shop_open = true
	_shop_visits += 1
	var stock: Array = []
	for e: Dictionary in key_defs:
		if _zone_index_open(int(e.get("zone", 0))):
			stock.append(e)
	_shop.open(stock, inv, keys_owned, keys_used, KEEPER_LINES[(_shop_visits - 1) % KEEPER_LINES.size()])


func _close_shop() -> void:
	_shop_open = false
	tile = _shop_tile + Vector2i.DOWN
	hero.snap(_stand_pos(tile), _center(_shop_tile))
	message.emit("NARRATOR: Keys in pocket? Find the door with the same keyhole shape.")


func _buy(key_id: String) -> void:
	var def: Dictionary = {}
	for e: Dictionary in key_defs:
		if e["id"] == key_id:
			def = e
	if def.is_empty():
		return
	if keys_owned.has(key_id) or keys_used.has(key_id):
		_shop.note = "You already bought that one! One of each, friend."
	elif not _shop.can_afford(def["cost"]):
		_shop.note = "Ha! Come back with more stuff. Hidden items glint in the dark."
	else:
		for type: String in def["cost"]:
			inv[type] = int(inv[type]) - int(def["cost"][type])
		keys_owned.append(key_id)
		var is_decoy := false
		for idx: int in decoys:
			if door_info.get(idx, {}).get("key", "") == key_id:
				is_decoy = true
		_shop.note = "Pleasure doing business! No refunds." if is_decoy else "A fine key! Treat it well."
		EventBus.trade_made.emit(key_id)
		_sync_hud()
	_shop.update_state(inv, keys_owned, keys_used)


# --- input & movement -----------------------------------------------------------

func _read_dir() -> Vector2i:
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		return Vector2i.LEFT
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		return Vector2i.RIGHT
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		return Vector2i.UP
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		return Vector2i.DOWN
	return Vector2i.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if not active or _shop_open or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode in [KEY_Z, KEY_ENTER, KEY_SPACE, KEY_E]:
		_interact(tile + facing)


func _interact(t: Vector2i) -> void:
	var ch := _at(t)
	if ch == "N":
		if not npc_lines.is_empty():
			message.emit(npc_lines[_npc_i % npc_lines.size()])
			_npc_i += 1
	elif signs.has(t):
		message.emit(signs[t])
	elif ch in ["G", "H", "I"] and not gate_open(ch):
		_gate_hint(ch)
	elif _doors.has(t):
		_bump_door(t)
	elif ch == "S":
		_pending_shop = true
	elif ch == "l" or ch == "o":
		message.emit("NARRATOR: Lamps and braziers wake up once their part of town has its light back.")


func _gate_hint(ch: String) -> void:
	var need := int(gates[ch])
	message.emit("NARRATOR: The ink-gate won't budge. It needs %d finished pages, and you have %d." % [need, real_done()])


func _bump_door(t: Vector2i) -> void:
	var idx: int = _doors[t]
	if done.has(idx):
		message.emit("NARRATOR: You already read that page.")
	else:
		_door_locked_msg(idx)


func _process(delta: float) -> void:
	_time += delta
	if not active:
		return
	_bump_cd = maxf(0.0, _bump_cd - delta)
	_flash = maxf(0.0, _flash - delta * 1.5)
	for p in _pops:
		p["t"] += delta
	_pops = _pops.filter(func(p: Dictionary) -> bool: return p["t"] < 1.2)
	if _mood_timer > 0.0:
		_mood_timer -= delta
		if _mood_timer <= 0.0:
			hero.mood = HeroActor.Mood.THINK
	if _shop_open:
		hero.update(delta, TILE * 1.15)
		_update_torch()
		queue_redraw()
		return
	if not hero.is_moving():
		if _pending_door >= 0:
			var idx := _pending_door
			_pending_door = -1
			door_entered.emit(idx)
			return
		if _pending_shop:
			_pending_shop = false
			_open_shop()
			return
		var d := _read_dir()
		if d != Vector2i.ZERO:
			facing = d
			_try_step(d)
	hero.update(delta, TILE * 1.15)
	_update_torch()
	queue_redraw()


func _try_step(d: Vector2i) -> void:
	var nxt := tile + d
	var ch := _at(nxt)
	if _doors.has(nxt):
		var idx: int = _doors[nxt]
		if not done.has(idx) and _try_unlock(idx):
			_move_to(nxt, d)
			_pending_door = idx
		elif _bump_cd <= 0.0:
			_bump_cd = 1.2
			_bump_door(nxt)
	elif ch == "S":
		_move_to(nxt, d)
		_pending_shop = true
	elif not is_solid(nxt):
		_move_to(nxt, d)
		var i := _item_at(tile)
		if i >= 0:
			_collect(i)
	elif _bump_cd <= 0.0:
		_bump_cd = 1.2
		if ch in ["G", "H", "I"]:
			_gate_hint(ch)


func _move_to(t: Vector2i, d: Vector2i) -> void:
	tile = t
	hero.set_target(_stand_pos(tile), _stand_pos(tile) + Vector2(d) * TILE * 2.0)


func _update_torch() -> void:
	var s := TILE * 1.15
	_hero_light.position = hero.pos + hero.torch_offset(s)
	_hero_light.energy = 1.2 + sin(_time * 17.0) * 0.08 + sin(_time * 29.0) * 0.05
	_cam.position = hero.pos


# --- drawing --------------------------------------------------------------------

func _h(x: int, y: int) -> float:
	return fposmod(sin(x * 12.9898 + y * 78.233) * 43758.5453, 1.0)


func _draw() -> void:
	if rows.is_empty():
		return
	var vp := get_viewport_rect().size
	var cc := _cam.get_screen_center_position() if _cam.is_current() else hero.pos
	var x0 := maxi(int((cc.x - vp.x * 0.5) / TILE) - 1, 0)
	var y0 := maxi(int((cc.y - vp.y * 0.5) / TILE) - 2, 0)
	var x1 := mini(int((cc.x + vp.x * 0.5) / TILE) + 2, cols - 1)
	var y1 := mini(int((cc.y + vp.y * 0.5) / TILE) + 2, count_rows - 1)
	var view := Rect2(Vector2(x0, y0) * TILE, Vector2(x1 - x0 + 1, y1 - y0 + 1) * TILE)

	draw_texture_rect(TEX_PAPER, view, true, PAPER)
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var ch := rows[y][x]
			if ch == "," or ch == "T":
				draw_rect(Rect2(Vector2(x, y) * TILE, Vector2(TILE, TILE)), GRASS)
	draw_texture_rect(TEX_HALFTONE, view, true, Color(0.1, 0.1, 0.2, 0.1))
	# path dots
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			if rows[y][x] in ".@" and _h(x, y) > 0.7:
				draw_circle(Vector2(x + _h(y, x), y + _h(x * 3, y)) * TILE, 3.0, Color(0.1, 0.1, 0.2, 0.18))

	_draw_items(x0, y0, x1, y1)
	var hero_row := clampi(int(floor((hero.pos.y + TILE * 0.2) / TILE)), 0, count_rows - 1)
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			_draw_tile(x, y)
		if y == hero_row:
			_draw_hero()
	if hero_row < y0 or hero_row > y1:
		_draw_hero()
	_draw_pops()
	if _flash > 0.0:
		draw_rect(view, Color(1, 0.95, 0.7, _flash * 0.5))


func _draw_items(x0: int, y0: int, x1: int, y1: int) -> void:
	for it: Dictionary in items:
		if it["taken"] or it["x"] < x0 or it["x"] > x1 or it["y"] < y0 or it["y"] > y1:
			continue
		var c := _center(Vector2i(it["x"], it["y"])) + Vector2(0, sin(_time * 3.0 + it["x"]) * 3.0)
		draw_circle(c + Vector2(0, TILE * 0.28), TILE * 0.16, Color(0, 0, 0, 0.25))
		KeySymbols.draw_item(self, it["type"], c, TILE * 0.2, INK)


func _draw_pops() -> void:
	for p in _pops:
		var t: float = p["t"]
		var a := clampf(1.0 - maxf(0.0, t - 0.8) / 0.4, 0.0, 1.0)
		var pos: Vector2 = (p["pos"] as Vector2) + Vector2(0, -36.0 * t)
		var text: String = p["text"]
		var sz := FONT_SHOUT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 30)
		var c: Color = p["color"]
		draw_string_outline(FONT_SHOUT, pos + Vector2(-sz.x * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, 9, Color(INK.r, INK.g, INK.b, a))
		draw_string(FONT_SHOUT, pos + Vector2(-sz.x * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(c.r, c.g, c.b, a))


func _draw_hero() -> void:
	var s := TILE * 1.15
	hero.villain = false
	hero.draw(self, s, INK, PAPER, FONT_SHOUT, Vector2.ZERO)


func _draw_tile(x: int, y: int) -> void:
	var t := Vector2i(x, y)
	var ch := rows[y][x]
	var r := Rect2(Vector2(x, y) * TILE, Vector2(TILE, TILE))
	match ch:
		",":
			_draw_bush(r, x, y)
		"T":
			_draw_tree(r, x, y)
		"#":
			_draw_house(r, t)
		"G", "H", "I":
			if not gate_open(ch):
				_draw_gate(r, ch)
		"N":
			_draw_npc(r)
		"s":
			_draw_sign(r)
		"l":
			_draw_lamp(r, t)
		"o":
			_draw_brazier(r, t)
		"S":
			_draw_shop_door(r, t)
		_:
			if ch.is_valid_int():
				_draw_door(r, t, int(ch) - 1)


func _draw_bush(r: Rect2, x: int, y: int) -> void:
	var c := r.get_center() + Vector2(_h(x, y) - 0.5, _h(y, x) - 0.5) * TILE * 0.2
	for off in [Vector2(-0.18, 0.05), Vector2(0.18, 0.08), Vector2(0.0, -0.12)]:
		draw_circle(c + off * TILE, TILE * 0.3, INK)
	for off in [Vector2(-0.18, 0.05), Vector2(0.18, 0.08), Vector2(0.0, -0.12)]:
		draw_circle(c + off * TILE, TILE * 0.26, BUSH)
	draw_circle(c + Vector2(-0.06, -0.18) * TILE, TILE * 0.06, Color(1, 1, 1, 0.3))


func _draw_tree(r: Rect2, x: int, y: int) -> void:
	var base := r.position + Vector2(TILE * 0.5, TILE * 0.9)
	draw_rect(Rect2(base + Vector2(-TILE * 0.07, -TILE * 0.35), Vector2(TILE * 0.14, TILE * 0.35)), INK)
	var c := r.position + Vector2(TILE * 0.5, TILE * 0.32)
	var sway := sin(_time * 1.5 + x) * 2.0
	draw_circle(c + Vector2(sway, 0), TILE * 0.52, INK)
	draw_circle(c + Vector2(sway, 0), TILE * 0.47, Color("3d9a45"))
	draw_circle(c + Vector2(sway - TILE * 0.14, -TILE * 0.14), TILE * 0.12, Color(1, 1, 1, 0.25))
	if _h(x, y) > 0.6:
		draw_circle(c + Vector2(TILE * 0.2, TILE * 0.1), TILE * 0.05, Color("e63946"))


func _house_color(t: Vector2i) -> Color:
	return HOUSE_COLORS[int(_door_block.get(t, 0)) % HOUSE_COLORS.size()]


func _draw_house(r: Rect2, t: Vector2i) -> void:
	var col := _house_color(t)
	draw_rect(r, col)
	var up := _is_building(t + Vector2i.UP)
	var down := _is_building(t + Vector2i.DOWN)
	var left := _is_building(t + Vector2i.LEFT)
	var right := _is_building(t + Vector2i.RIGHT)
	if not up:
		draw_rect(Rect2(r.position + Vector2(-4, 0), Vector2(TILE + 8, TILE * 0.9)), col.darkened(0.35))
		for k in 4:
			draw_line(r.position + Vector2(k * TILE * 0.25 + 4, 4), r.position + Vector2(k * TILE * 0.25 + 4, TILE * 0.85), col.darkened(0.55), 2.0)
	elif up and down:
		var win := Rect2(r.position + Vector2(TILE * 0.28, TILE * 0.22), Vector2(TILE * 0.44, TILE * 0.5))
		draw_rect(win, INK)
		draw_rect(win.grow(-4), Color("ffe9a8") if _zone_open(t) else Color("7a6f9a"))
		draw_line(win.get_center() - Vector2(0, win.size.y * 0.5 - 4), win.get_center() + Vector2(0, win.size.y * 0.5 - 4), INK, 2.5)
	if not up:
		draw_line(r.position + Vector2(-4, 0), r.position + Vector2(TILE + 4, 0), INK, 5.0)
	if not left:
		draw_line(r.position, r.position + Vector2(0, TILE), INK, 5.0)
	if not right:
		draw_line(r.position + Vector2(TILE, 0), r.position + Vector2(TILE, TILE), INK, 5.0)
	if not down:
		draw_line(r.position + Vector2(0, TILE), r.position + Vector2(TILE, TILE), INK, 5.0)


func _draw_door(r: Rect2, t: Vector2i, idx: int) -> void:
	var col := _house_color(t)
	draw_rect(r, col)
	var info: Dictionary = door_info.get(idx, {})
	var is_done := done.has(idx)
	var is_decoy := decoys.has(idx)
	var arch := Rect2(r.position + Vector2(TILE * 0.14, TILE * 0.08), Vector2(TILE * 0.72, TILE * 0.92))
	draw_rect(arch, INK)
	var pulse := 0.6 + 0.4 * sin(_time * 3.0)
	var cx := arch.get_center()
	if is_done:
		draw_rect(arch.grow(-5), Color("ff9ec0") if is_decoy else GOLD)
		if is_decoy:
			draw_line(cx + Vector2(-12, -12), cx + Vector2(12, 12), INK, 6.0)
			draw_line(cx + Vector2(-12, 12), cx + Vector2(12, -12), INK, 6.0)
		else:
			draw_circle(cx, 11.0, Color("fffbe6"))
	else:
		draw_rect(arch.grow(-5), Color(0.25, 0.2, 0.32))
		draw_circle(cx + Vector2(0, -2), TILE * 0.27, Color(GOLD.r, GOLD.g, GOLD.b, 0.25 + 0.25 * pulse))
		KeySymbols.draw_key(self, info.get("key", ""), cx + Vector2(0, -2), TILE * 0.2, GOLD, Color(0.25, 0.2, 0.32))
		draw_texture_rect(TEX_GLOW, Rect2(r.get_center() - Vector2(TILE, TILE) * 0.9, Vector2(TILE, TILE) * 1.8), false, Color(1, 0.85, 0.4, 0.3 * pulse))
	draw_line(r.position + Vector2(0, TILE), r.position + Vector2(TILE, TILE), INK, 5.0)
	# number plate on the wall above the door
	var plate := Rect2(r.position + Vector2(TILE * 0.05, -TILE * 0.78), Vector2(TILE * 0.9, TILE * 0.5))
	draw_rect(Rect2(plate.position + Vector2(3, 3), plate.size), Color(0, 0, 0, 0.35))
	draw_rect(plate, Color("ff9ec0") if (is_done and is_decoy) else Color("fff3d1"))
	draw_rect(plate, INK, false, 3.0)
	var label: String = "WRONG" if (is_done and is_decoy) else String(info.get("label", "PAGE %d" % (idx + 1)))
	var fs := 15 if label == "WRONG" else 17
	var sz := FONT_SHOUT.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	draw_string(FONT_SHOUT, plate.get_center() + Vector2(-sz.x * 0.5, fs * 0.33), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)


func _draw_shop_door(r: Rect2, t: Vector2i) -> void:
	var col := _house_color(t)
	draw_rect(r, col)
	var arch := Rect2(r.position + Vector2(TILE * 0.14, TILE * 0.08), Vector2(TILE * 0.72, TILE * 0.92))
	draw_rect(arch, INK)
	draw_rect(arch.grow(-5), Color("ffe9a8") if _zone_open(t) else Color("7a6f9a"))
	for k in 5:
		var aw := Rect2(r.position + Vector2(-TILE * 1.2 + k * TILE * 0.48, -TILE * 0.18), Vector2(TILE * 0.48, TILE * 0.28))
		draw_rect(aw, Color("e63946") if k % 2 == 0 else Color("fff3d1"))
	draw_rect(Rect2(r.position + Vector2(-TILE * 1.2, -TILE * 0.18), Vector2(TILE * 2.4, TILE * 0.28)), INK, false, 3.0)
	var plate := Rect2(r.position + Vector2(-TILE * 0.75, -TILE * 0.78), Vector2(TILE * 2.5, TILE * 0.5))
	draw_rect(plate, Color("fff3d1"))
	draw_rect(plate, INK, false, 3.0)
	var label := "TRADE SHOP"
	var sz := FONT_SHOUT.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 24)
	draw_string(FONT_SHOUT, plate.get_center() + Vector2(-sz.x * 0.5, 8), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, INK)
	draw_line(r.position + Vector2(0, TILE), r.position + Vector2(TILE, TILE), INK, 5.0)


func _draw_brazier(r: Rect2, t: Vector2i) -> void:
	var c := r.get_center() + Vector2(0, TILE * 0.12)
	var on := _zone_open(t)
	draw_rect(Rect2(c + Vector2(-TILE * 0.1, 0.0), Vector2(TILE * 0.2, TILE * 0.3)), INK)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-TILE * 0.26, -TILE * 0.1), c + Vector2(TILE * 0.26, -TILE * 0.1), c + Vector2(TILE * 0.14, TILE * 0.08), c + Vector2(-TILE * 0.14, TILE * 0.08)]), INK)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-TILE * 0.22, -TILE * 0.09), c + Vector2(TILE * 0.22, -TILE * 0.09), c + Vector2(TILE * 0.12, TILE * 0.05), c + Vector2(-TILE * 0.12, TILE * 0.05)]), Color("6c757d"))
	if on:
		var fl := sin(_time * 14.0 + t.x) * 0.08 + sin(_time * 23.0 + t.y) * 0.05
		var tip := c + Vector2(fl * TILE * 0.5, -TILE * (0.55 + fl))
		draw_colored_polygon(PackedVector2Array([c + Vector2(-TILE * 0.2, -TILE * 0.08), tip, c + Vector2(TILE * 0.2, -TILE * 0.08)]), INK)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-TILE * 0.16, -TILE * 0.1), tip + Vector2(0, TILE * 0.03), c + Vector2(TILE * 0.16, -TILE * 0.1)]), Color("ff8c1a"))
		draw_colored_polygon(PackedVector2Array([c + Vector2(-TILE * 0.08, -TILE * 0.1), c + Vector2(0, -TILE * 0.32), c + Vector2(TILE * 0.08, -TILE * 0.1)]), Color("ffe066"))


func _draw_gate(r: Rect2, ch: String) -> void:
	draw_rect(r, INK)
	for k in range(-2, 6):
		draw_line(r.position + Vector2(k * TILE * 0.28, TILE), r.position + Vector2(k * TILE * 0.28 + TILE * 0.7, 0), Color("3b3358"), 4.0)
	draw_rect(r, INK, false, 3.0)
	var need := str(int(gates[ch]))
	var c := r.get_center()
	draw_rect(Rect2(c + Vector2(-16, -14), Vector2(32, 28)), GOLD)
	draw_rect(Rect2(c + Vector2(-16, -14), Vector2(32, 28)), INK, false, 3.0)
	var sz := FONT_SHOUT.get_string_size(need, HORIZONTAL_ALIGNMENT_LEFT, -1, 24)
	draw_string(FONT_SHOUT, c + Vector2(-sz.x * 0.5, 8), need, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, INK)


func _draw_npc(r: Rect2) -> void:
	var c := r.get_center() + Vector2(0, sin(_time * 3.0) * 3.0 - 6.0)
	draw_rect(Rect2(c + Vector2(-TILE * 0.4 + 3, -TILE * 0.3 + 4), Vector2(TILE * 0.8, TILE * 0.55)), Color(0, 0, 0, 0.3))
	var body := Rect2(c + Vector2(-TILE * 0.4, -TILE * 0.3), Vector2(TILE * 0.8, TILE * 0.55))
	draw_rect(body, Color("fff9e6"))
	draw_rect(body, INK, false, 4.0)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-0.12, 0.24) * TILE, c + Vector2(0.1, 0.24) * TILE, c + Vector2(-0.2, 0.46) * TILE]), INK)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-0.1, 0.24) * TILE, c + Vector2(0.06, 0.24) * TILE, c + Vector2(-0.17, 0.4) * TILE]), Color("fff9e6"))
	for sx in [-1.0, 1.0]:
		draw_circle(c + Vector2(sx * 0.14, -0.08) * TILE, 5.5, INK)
		draw_circle(c + Vector2(sx * 0.14, -0.08) * TILE + Vector2(sin(_time) * 1.5, 0), 2.0, Color.WHITE)
	draw_arc(c + Vector2(0, 0.06) * TILE, TILE * 0.1, 0.2, PI - 0.2, 8, INK, 3.0)
	if _npc_i == 0:
		var f := 26
		draw_string_outline(FONT_SHOUT, c + Vector2(-6, -TILE * 0.45), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, f, 8, INK)
		draw_string(FONT_SHOUT, c + Vector2(-6, -TILE * 0.45), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, f, GOLD)


func _draw_sign(r: Rect2) -> void:
	var c := r.get_center()
	draw_rect(Rect2(c + Vector2(-3, 0), Vector2(6, TILE * 0.4)), INK)
	var board := Rect2(c + Vector2(-TILE * 0.32, -TILE * 0.32), Vector2(TILE * 0.64, TILE * 0.4))
	draw_rect(board, Color("c08457"))
	draw_rect(board, INK, false, 3.5)
	for k in 2:
		draw_line(board.position + Vector2(8, 10 + k * 10), board.position + Vector2(board.size.x - 8, 10 + k * 10), INK, 2.0)


func _draw_lamp(r: Rect2, t: Vector2i) -> void:
	var c := r.get_center()
	var on := _zone_open(t)
	draw_rect(Rect2(c + Vector2(-3, -TILE * 0.2), Vector2(6, TILE * 0.6)), INK)
	draw_circle(c + Vector2(0, -TILE * 0.3), TILE * 0.17, INK)
	draw_circle(c + Vector2(0, -TILE * 0.3), TILE * 0.12, Color("ffe08a") if on else Color("5a5470"))
	if on:
		draw_texture_rect(TEX_GLOW, Rect2(c + Vector2(-TILE, -TILE * 1.3), Vector2(TILE, TILE) * 2.0), false, Color(1, 0.9, 0.5, 0.35))
