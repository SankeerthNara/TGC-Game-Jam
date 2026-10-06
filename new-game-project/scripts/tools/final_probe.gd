extends "res://scripts/tools/playtime_test.gd"
## Jumps straight to the Narrator fight and the finale with the playtime bot, printing the state (not part of the game).

var _jumped := false
var _tick := 0.0


func _ready() -> void:
	Engine.time_scale = 2.0
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
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
	main.director._final_boss()
	_jumped = true


func _process(delta: float) -> void:
	if not _jumped:
		return
	super._process(delta)
	_tick += delta
	if _tick > 5.0:
		_tick = 0.0
		var ov: Variant = main._overlay
		var s := "t=%.0f state=%s overlay=%s" % [_total, main.state, ov.get_class() if ov != null else "null"]
		if ov is BossFight:
			s += " phase=%s hp=%d proc=%s nar=%s" % [ov._phase, ov._hp, ov.is_processing(), str(ov._narrator.hp) if ov._narrator != null else "none"]
		for c in main.get_children():
			if c is BrightnessFinale:
				s += " FINALE value=%.2f done=%s t=%.1f" % [c._value, c._done, c._t]
		print(s)
