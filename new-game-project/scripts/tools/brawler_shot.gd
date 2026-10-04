extends Node
## Screenshots of the 720p brawler through the edition filter (not part of the game).

func _ready() -> void:
	var fx := EditionFX.new()
	add_child(fx)
	fx.set_edition("720p")
	var layer := CanvasLayer.new()
	add_child(layer)
	for stage in ["street", "train"]:
		var g := BrawlerGame.new()
		g.stage = stage
		layer.add_child(g)
		await get_tree().process_frame
		g._phase = "play"
		if stage == "street":
			g._start_zone(1)
			g.hero_pos = Vector2(1700, BrawlerGame.GROUND)
			g._cam = 1280.0
			for p in g._pending:
				p["delay"] = 0.0
		for i in 50:
			await get_tree().process_frame
		g._atk_t = 0.2
		g._combo = 3
		for e in g._enemies:
			e.state = "windup"
			e.attack = "heavy"
			e.st = 0.3
		g.set_process(false)
		g.queue_redraw()
		for i in 3:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("user://brawl_%s.png" % stage)
		g.queue_free()
		await get_tree().process_frame
	get_tree().quit()
