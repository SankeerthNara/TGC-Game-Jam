extends Node
## Frames of the bot playing the library climb, the opera arena and the Narrator's flood phase, for
## GIFs (not part of the game). Every 3rd frame, half size.

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


func grab(name: String, n: int) -> void:
	var img := get_viewport().get_texture().get_image()
	img.resize(640, 360)
	img.save_png("user://bg_%s_%03d.png" % [name, n])


func _ready() -> void:
	var main: Node = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(main)
	for i in 5:
		await get_tree().process_frame
	EventBus.request_start_game.emit()
	for i in 10:
		await get_tree().process_frame
	main._overlay.skip()
	for i in 200:
		await get_tree().process_frame
	main.director.act = "2k"
	main.director.fx.set_edition("2k")
	main.director.comms.clear()
	main.director.start_2k()
	var b: BossFight = main._overlay
	# the climb: from the end of the first fight up to the reading room
	var n := 0
	var f := 0
	while f < 60 * 120 and n < 200:
		ArenaBot.drive(b, press, tap)
		await get_tree().process_frame
		f += 1
		var wp: int = b.get_meta("bot_wp", 0)
		if b._phase == "explore" and wp >= 1 and wp <= 7 and f % 3 == 0:
			grab("climb", n)
			n += 1
	for k in _keys.keys():
		press(k, false)
	# the opera and the flood
	for which in ["opera", "flood"]:
		main.director._free_stale()
		if main._overlay != null:
			main._overlay.queue_free()
		await get_tree().process_frame
		if which == "opera":
			main.director._opera()
		else:
			main.director._final_boss()
		b = main._overlay
		main.director.comms.clear()
		n = 0
		f = 0
		while f < 60 * 40 and n < 170:
			ArenaBot.drive(b, press, tap)
			await get_tree().process_frame
			f += 1
			if which == "flood" and b._narrator != null and b._narrator.hp > b._narrator.max_hp * 0.6:
				b._narrator.hp = b._narrator.max_hp * 0.6
			if b._phase == "wave" and f % 3 == 0 and (which == "opera" and b._wave >= 1 or which == "flood" and b._flood > 0.3):
				grab(which, n)
				n += 1
		for k in _keys.keys():
			press(k, false)
	get_tree().quit()
