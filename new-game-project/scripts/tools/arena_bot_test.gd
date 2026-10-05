extends Node
## Plays the final battle with a crude bot (not part of the game): checks that every wave spawns and
## clears, the relay works and the fight ends, and prints timings. A bot is not a player.
## Screenshots are saved to user:// when run with a window.

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
	add_child(layer)
	var configs := [
		{"name": "ink baron (144p)", "stage": "opera", "waves": [[[["lancer", "L", 0.0], ["lancer", "R", 0.6], ["bat", "AC", 3.5]], [["baron", "C", 0.0]]]], "scale": 1.0},
		{"name": "opera (2k)", "stage": "opera", "chandeliers": [[Rect2(230, 360, 160, 14), 0.0], [Rect2(890, 360, 160, 14), 0.0], [Rect2(565, 220, 150, 14), 110.0]], "waves": [[[["lancer", "L", 0.0], ["lancer", "R", 0.4], ["bat", "AC", 2.5]], [["dancer", "AL", 0.0], ["dancer", "AR", 1.5]], [["brute", "C", 0.0], ["bat", "AL", 1.0], ["bat", "AR", 1.6], ["bat", "AC", 2.4]], [["brute", "L", 0.0], ["dancer", "AR", 1.5], ["lancer", "R", 3.0]]]], "scale": 1.0},
		{"name": "narrator (2k final)", "stage": "dark", "chandeliers": [[Rect2(200, 400, 150, 14), 0.0], [Rect2(930, 400, 150, 14), 0.0], [Rect2(565, 310, 150, 14), 90.0]], "waves": [[[["narrator", "BALCONY", 0.0]]]], "scale": 1.6},
	]
	var runs := configs.size()
	for run in runs:
		var b := BossFight.new()
		b.bomb_left = -1.0
		var cfgd: Dictionary = configs[run]
		b.stage = cfgd["stage"]
		if not cfgd.get("classic", false):
			b.heroes = [cfgd.get("hero", 0)]
			b.relay = false
			b.waves = cfgd["waves"]
			b.boss_hp_scale = cfgd["scale"]
			b.max_hp = 6
			b.checkpoints = true
			b.chandeliers = cfgd.get("chandeliers", [])
		layer.add_child(b)
		var result := [""]
		b.finished.connect(func(r: String) -> void: result[0] = r)
		var frames := 0
		var log_phase := ""
		var shots := 0
		var retries := 0
		var was_retry := false
		while result[0] == "" and frames < 60 * 600:
			await get_tree().process_frame
			frames += 1
			_drive(b)
			var ph := "%s r%d w%d" % [b._phase, b._round, b._wave]
			if ph != log_phase:
				log_phase = ph
			if b._phase == "retry" and not was_retry:
				retries += 1
			was_retry = b._phase == "retry"
			if DisplayServer.get_name() != "headless" and frames % 900 == 450 and shots < 8:
				get_viewport().get_texture().get_image().save_png("user://arena_%d.png" % shots)
				shots += 1
		for k in _keys.keys():
			press(k, false)
		print("run %d %s: %s after %.0f s, hero hp %d, retries %d" % [run, configs[run]["name"], result[0], b._t, b._hp, retries])
		b.queue_free()
		await get_tree().process_frame
	get_tree().quit()


func _drive(b: BossFight) -> void:
	ArenaBot.drive(b, press, tap)
