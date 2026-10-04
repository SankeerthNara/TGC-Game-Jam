extends Node
## Still frames of the 2k stages for a visual check (not part of the game).

func cfg(b: BossFight, stage: String) -> void:
	b.stage = stage
	b.heroes = [0]
	b.relay = false
	b.bomb_left = -1.0
	if stage == "hall":
		b.level_width = 3840.0
		b.arena_x = 3200.0
		b.platforms = [Rect2(620, 470, 220, 20), Rect2(980, 380, 200, 20), Rect2(1360, 470, 240, 20)]
		b.roamers = [["lancer", Vector2(1100, 600)], ["bat", Vector2(900, 300)]]
	if stage == "dark":
		b.caged_heroes = true


func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	for stage in ["hall", "opera", "dark"]:
		var b := BossFight.new()
		cfg(b, stage)
		layer.add_child(b)
		await get_tree().process_frame
		b._phase = "explore" if stage == "hall" else "wave"
		b._pt = 10.0
		b._gate = 0.0 if stage == "hall" else 1.0
		b.hero_pos = Vector2(820, 600) if stage == "hall" else Vector2(560, 600)
		b._cam = 300.0 if stage == "hall" else 0.0
		b._ink = 6
		b._atk_t = 0.16
		if stage == "opera":
			for spec in [["lancer", Vector2(700, 600)], ["bat", Vector2(860, 300)], ["brute", Vector2(980, 600)]]:
				var e := ArenaEnemy.new(spec[0], spec[1])
				e.state = "idle" if not e.flying() else "hover"
				b._enemies.append(e)
		if stage == "dark":
			var n := ArenaEnemy.new("narrator", Vector2(1150, 480))
			n.state = "dash"
			n.st = 0.3
			n.target = Vector2(560, 560)
			n.hp = 70.0
			n.max_hp = 100.0
			b._enemies.append(n)
			b._narrator = n
		b.set_process(false)
		b._t = 3.0
		b.queue_redraw()
		for i in 3:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("user://stage_%s.png" % stage)
		b.queue_free()
		await get_tree().process_frame
	get_tree().quit()
