extends Node
## Renders still frames of the final battle for a visual check (not part of the game).

func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var b := BossFight.new()
	b.bomb_left = 612.0
	layer.add_child(b)
	await get_tree().process_frame
	b._phase = "wave"
	b._gate = 1.0
	b._round = 1
	b.hero_pos = Vector2(560, 600)
	b._face = 1.0
	b._atk_t = 0.16
	b._ink = 6
	for spec in [["lancer", Vector2(700, 600)], ["lancer", Vector2(300, 600)], ["bat", Vector2(820, 300)], ["brute", Vector2(960, 600)], ["bomb", Vector2(420, 380)]]:
		var e := ArenaEnemy.new(spec[0], spec[1])
		e.state = "idle" if not e.flying() else "hover"
		b._enemies.append(e)
	b._enemies[0].flash = 0.8
	b._enemies[3].state = "windup"
	b._fx.append({"kind": "spark", "pos": Vector2(680, 540), "t": 0.05, "life": 0.25, "size": 1.2})
	b._corpses.append({"x": 200.0, "kind": "lancer", "dir": 1.0})
	b._corpses.append({"x": 1040.0, "kind": "brute", "dir": -1.0})
	b.set_process(false)
	b._t = 3.0
	b.queue_redraw()
	for i in 3:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("user://arena_still_0.png")
	# round 3 with the Narrator
	b._round = 2
	b._enemies.clear()
	var n := ArenaEnemy.new("narrator", Vector2(760, 330))
	n.state = "hover"
	n.hp = 40.0
	n.max_hp = 60.0
	b._enemies.append(n)
	b._narrator = n
	b._atk_t = 0.0
	b.hero_pos = Vector2(500, 505)
	b._waves.append({"x": 300.0, "dir": 1.0, "life": 2.0})
	b._drops.append({"x": 900.0, "y": 300.0, "warn": 0.0})
	b._drops.append({"x": 650.0, "y": -40.0, "warn": 0.4})
	b._beams.append({"from": Vector2(500, 459), "to": Vector2(1300, 459), "t": 0.25})
	b.queue_redraw()
	for i in 3:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("user://arena_still_1.png")
	b._phase = "round_intro"
	b._pt = 1.0
	b.queue_redraw()
	for i in 3:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("user://arena_still_2.png")
	get_tree().quit()
