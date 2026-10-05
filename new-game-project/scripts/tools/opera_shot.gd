extends Node
## The opera arena mid-fight: chandeliers, dancers, the brute (not part of the game).

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
	get_tree().quit()
