extends Node
## Close-ups of the hero's parkour frames in the game (not part of the game).

const CROP := Vector2i(300, 300)
var _crops: Array[Image] = []


func key(k: Key, on: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.pressed = on
	Input.parse_input_event(ev)


func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func grab(b: BossFight) -> void:
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	var hp: Vector2 = b.hero_pos - Vector2(b._cam, b._cam_y)
	var r := Rect2i(Vector2i(clampi(int(hp.x) - 150, 0, 1280 - 300), clampi(int(hp.y) - 220, 0, 720 - 300)), CROP)
	_crops.append(img.get_region(r))
	print("shot: anim ", b._anim.anim, " key ", b._anim.key, " face ", b._face, " wall ", b._wall)


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 18
	add_child(layer)
	var b := BossFight.new()
	b.stage = "opera"
	b.heroes = [0]
	b.relay = false
	b.bomb_left = -1.0
	b.walls = [Rect2(800, 100, 60, 420)]
	b.waves = [[[["lancer", "L", 999.0]]]]
	layer.add_child(b)
	await frames(3)
	b._pt = 10.0
	await frames(110)
	b.hero_pos = Vector2(700, BossFight.FLOOR_Y)
	key(KEY_D, true)
	key(KEY_Z, true)
	await frames(8)
	key(KEY_Z, false)
	for i in 80:
		await get_tree().process_frame
		if b._sliding and b._anim.anim == "wallslide":
			break
	await frames(4)
	await grab(b) # wall slide
	key(KEY_Z, true)
	await frames(6)
	await grab(b) # wall jump
	key(KEY_Z, false)
	key(KEY_D, false)
	await frames(8)
	key(KEY_K, true)
	await frames(4)
	await grab(b) # air dash
	key(KEY_K, false)
	var e := ArenaEnemy.new("lancer", Vector2(640, BossFight.FLOOR_Y))
	e.state = "idle"
	e.hp = 99.0
	b._enemies.append(e)
	b.hero_pos = Vector2(640, 380)
	b._vel = Vector2(0, 200)
	b._ground = false
	key(KEY_S, true)
	key(KEY_J, true)
	for i in 40:
		await get_tree().process_frame
		if b._pogo_t > 0.0:
			break
	key(KEY_J, false)
	key(KEY_S, false)
	await frames(3)
	await grab(b) # pogo
	b.hero_pos = Vector2(420, 300)
	b._vel = Vector2.ZERO
	b._air_dash = true
	b._face = 1.0
	await frames(1)
	key(KEY_S, true)
	key(KEY_K, true)
	await frames(8)
	key(KEY_K, false)
	key(KEY_S, false)
	await grab(b) # dive
	var sheet := Image.create(300 * _crops.size(), 300, false, _crops[0].get_format())
	for i in _crops.size():
		sheet.blit_rect(_crops[i], Rect2i(Vector2i.ZERO, CROP), Vector2i(i * 300, 0))
	sheet.save_png("user://parkour_frames_ingame.png")
	get_tree().quit()
