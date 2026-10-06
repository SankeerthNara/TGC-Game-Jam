extends Node
## Frames of the Narrator duel or the Ink Scribe fight (-- scribe), played by the bot (not part of the game).

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
	var scribe := "scribe" in OS.get_cmdline_user_args()
	var b := BossFight.new()
	b.stage = "hall" if scribe else "dark"
	b.caged_heroes = not scribe
	b.heroes = [0]
	b.relay = false
	b.bomb_left = -1.0
	b.max_hp = 6
	b.checkpoints = true
	b.boss_hp_scale = 1.3
	b.lamps.assign([Vector2(150, 400), Vector2(470, 330), Vector2(810, 330), Vector2(1130, 400)])
	b.waves = [[[["scribe", Vector2(640, 300), 0.0]]]] if scribe else [[[["narrator", "BALCONY", 0.0]]]]
	b.boss_name = "THE INK SCRIBE" if scribe else "THE NARRATOR"
	b.boss_sub = "Archivist of the Masked One" if scribe else "The Storyteller"
	if "opera" in OS.get_cmdline_user_args():
		b.stage = "opera"
		b.caged_heroes = false
		b.waves = [[[["lancer", "L", 0.0], ["lancer", "R", 0.4], ["bat", "AC", 1.2], ["bat", "AL", 1.8]], [["brute", "C", 0.0], ["dancer", "AL", 0.6], ["bat", "AR", 1.0], ["bat", "AC", 1.6]]]]
		layer.add_child(b)
		for f in 60 * 30:
			ArenaBot.drive(b, press, tap)
			await get_tree().process_frame
			if f % 150 == 149:
				get_viewport().get_texture().get_image().save_png("user://duel_%d.png" % (f / 150))
		get_tree().quit()
		return
	layer.add_child(b)
	for i in 5:
		await get_tree().process_frame
	b._pt = 10.0
	var late := "late" in OS.get_cmdline_user_args()
	var n := 0
	var last := ""
	for i in 110:
		ArenaBot.drive(b, press, tap)
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("user://title.png")
	for f in 2400:
		ArenaBot.drive(b, press, tap)
		if late and b._narrator != null and b._narrator.hp > b._narrator.max_hp * 0.6:
			b._narrator.hp = b._narrator.max_hp * 0.53 # straight to the fake death
			late = false
		await get_tree().process_frame
		var st: String = b._narrator.state if b._narrator != null else ""
		if st != last and st in ["lunge", "throw", "airdash_wind", "whirl", "stagger", "airdash", "cast_wind", "charge", "slam", "fake_death", "laugh", "hover", "stunned"] and n < 10 and (not scribe or st != "hover" or b._floor_broken):
			for i in 6:
				await get_tree().process_frame
			get_viewport().get_texture().get_image().save_png("user://duel_%d.png" % n)
			n += 1
		last = st
		if b._phase == "won" and not scribe:
			for k in 4:
				for i in 25:
					await get_tree().process_frame
				get_viewport().get_texture().get_image().save_png("user://won_%d.png" % k)
			break
	get_tree().quit()
