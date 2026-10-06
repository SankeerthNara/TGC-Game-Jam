extends Node
## Frames of the 2K library climb with the bot climbing (not part of the game).

var main: Node
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
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(main)
	for i in 5:
		await get_tree().process_frame
	EventBus.request_start_game.emit()
	for i in 10:
		await get_tree().process_frame
	if main._overlay is NoticeCard:
		main._overlay.skip()
	main.director.start_2k()
	var n := 0
	for f in 60 * 80:
		await get_tree().process_frame
		var ov: Variant = main._overlay
		if ov is ComicCutscene or ov is NoticeCard:
			ov.skip()
		if ov is BossFight:
			ArenaBot.drive(ov, press, tap)
			if f > 60 * 14 and f % 120 == 0 and n < 8:
				get_viewport().get_texture().get_image().save_png("user://climb_%d.png" % n)
				n += 1
	get_tree().quit()
