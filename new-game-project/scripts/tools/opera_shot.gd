extends Node
## The opera arena mid-fight, and the Narrator's flood and high phases (not part of the game).

var _keys := {}


func press(k: Key, on: bool) -> void:
	if _keys.get(k, false) == on:
		return
	_keys[k] = on
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.pressed = on
	Input.parse_input_event(ev)


func tap(k: Key) -> void:
	press(k, false)
	press(k, true)


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 18
	add_child(layer)
	var b := BossFight.new()
	b.stage = "opera"
	b.heroes = [0]
	b.relay = false
	b.bomb_left = -1.0
	b.max_hp = 6
	b.checkpoints = true
	b.chandeliers = [[Rect2(230, 360, 160, 14), 0.0], [Rect2(890, 360, 160, 14), 0.0], [Rect2(565, 220, 150, 14), 110.0]]
	b.waves = [[[["dancer", "AL", 0.0], ["dancer", "AR", 0.5], ["brute", "C", 1.0], ["bat", "AL", 1.5]]]]
	layer.add_child(b)
	for i in 5:
		await get_tree().process_frame
	b._pt = 10.0
	var n := 0
	for f in 900:
		ArenaBot.drive(b, press, tap)
		await get_tree().process_frame
		if f in [300, 420, 540]:
			get_viewport().get_texture().get_image().save_png("user://opera_%d.png" % n)
			n += 1
	b.queue_free()
	var nb := BossFight.new()
	nb.stage = "dark"
	nb.caged_heroes = true
	nb.heroes = [0]
	nb.relay = false
	nb.bomb_left = -1.0
	nb.max_hp = 6
	nb.checkpoints = true
	nb.chandeliers = [[Rect2(200, 400, 150, 14), 0.0], [Rect2(930, 400, 150, 14), 0.0], [Rect2(565, 310, 150, 14), 90.0]]
	nb.waves = [[[["narrator", "BALCONY", 0.0]]]]
	layer.add_child(nb)
	for i in 5:
		await get_tree().process_frame
	nb._pt = 10.0
	for f in 900:
		ArenaBot.drive(nb, press, tap)
		await get_tree().process_frame
		if nb._narrator != null and f == 200:
			nb._narrator.hp = nb._narrator.max_hp * 0.5
		if nb._narrator != null and f == 520:
			nb._narrator.hp = nb._narrator.max_hp * 0.25
		if f in [440, 800]:
			get_viewport().get_texture().get_image().save_png("user://narr_%d.png" % f)
	get_tree().quit()
