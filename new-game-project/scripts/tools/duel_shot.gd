extends Node
## Frames of the Narrator duel, played by the bot (not part of the game).

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
	b.stage = "dark"
	b.caged_heroes = true
	b.heroes = [0]
	b.relay = false
	b.bomb_left = -1.0
	b.max_hp = 6
	b.checkpoints = true
	b.boss_hp_scale = 1.3
	b.lamps.assign([Vector2(150, 400), Vector2(470, 330), Vector2(810, 330), Vector2(1130, 400)])
	b.waves = [[[["narrator", "BALCONY", 0.0]]]]
	layer.add_child(b)
	for i in 5:
		await get_tree().process_frame
	b._pt = 10.0
	var n := 0
	var last := ""
	for f in 2400:
		ArenaBot.drive(b, press, tap)
		await get_tree().process_frame
		var st: String = b._narrator.state if b._narrator != null else ""
		if st != last and st in ["lunge", "throw", "airdash_wind", "whirl", "stagger", "airdash"] and n < 8:
			for i in 6:
				await get_tree().process_frame
			get_viewport().get_texture().get_image().save_png("user://duel_%d.png" % n)
			n += 1
		last = st
	get_tree().quit()
