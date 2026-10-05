extends Node
## Consecutive frames of the hero starting a run, running, skidding into a turn and jumping, in the
## 2K arena and the 720p brawler (for GIFs; not part of the game).

const CROP := Vector2i(360, 300)


func key(k: Key, on: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.pressed = on
	Input.parse_input_event(ev)


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 18
	add_child(layer)
	var fx := EditionFX.new()
	add_child(fx)
	for stage in ["2k", "720p"]:
		fx.set_edition(stage)
		var scene: Node
		if stage == "2k":
			var b := BossFight.new()
			b.heroes = [0]
			b.relay = false
			b.bomb_left = -1.0
			b.waves = [[[["lancer", "L", 999.0]]]]
			scene = b
		else:
			var g := BrawlerGame.new()
			g.stage = "street"
			scene = g
		layer.add_child(scene)
		for i in 5:
			await get_tree().process_frame
		if scene is BossFight:
			scene._pt = 10.0
			for i in 130:
				await get_tree().process_frame
			scene.hero_pos.x = 300.0
		else:
			scene._phase = "play"
			scene._counters = 1
			scene.hero_pos.x = 300.0
		var n := 0
		for f in 150:
			match f:
				5: key(KEY_D, true)
				70: key(KEY_D, false)
				71: key(KEY_A, true)
				95: key(KEY_A, false)
				96: key(KEY_SPACE, true)
				104: key(KEY_SPACE, false)
			await get_tree().process_frame
			if f % 2 == 0:
				var img := get_viewport().get_texture().get_image()
				var hp: Vector2 = scene.hero_pos - Vector2(scene._cam, 0)
				var r := Rect2i(Vector2i(clampi(int(hp.x) - CROP.x / 2, 0, 1280 - CROP.x), clampi(int(hp.y) - CROP.y + 40, 0, 720 - CROP.y)), CROP)
				img.get_region(r).save_png("user://gif_%s_%03d.png" % [stage, n])
				n += 1
		scene.queue_free()
		for i in 5:
			await get_tree().process_frame
	get_tree().quit()
