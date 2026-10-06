extends Node
## Before/after captures of the hero's movement (not part of the game): a scripted run, stop, turn,
## jump, landing and three attacks in the 2K arena and the 720p brawler, saved as contact sheets
## (crops around the hero). Pass the label with `-- before` or `-- after`.

const SCRIPT := [[0, KEY_RIGHT, true], [40, KEY_RIGHT, false], [56, KEY_LEFT, true], [80, KEY_LEFT, false],
	[80, KEY_Z, true], [92, KEY_Z, false], [140, KEY_J, true], [142, KEY_J, false], [158, KEY_J, true],
	[160, KEY_J, false], [176, KEY_J, true], [178, KEY_J, false]]
const SHOTS := [30, 44, 50, 60, 66, 74, 88, 104, 124, 146, 164, 184]
const CROP := Vector2(320, 300)

var label := "before"


func key(k: Key, on: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.pressed = on
	Input.parse_input_event(ev)


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		label = a
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
			b.stage = "opera"
			b.heroes = [0]
			b.relay = false
			b.bomb_left = -1.0
			b.waves = [[[["lancer", "L", 999.0]]]]
			b.hero_pos = Vector2(420, BossFight.FLOOR_Y)
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
		else:
			scene._phase = "play"
			scene._counters = 1
			scene.hero_pos.x = 420.0
		var crops: Array[Image] = []
		for f in 200:
			for s: Array in SCRIPT:
				if int(s[0]) == f:
					key(s[1], s[2])
			if f in SHOTS:
				await get_tree().process_frame
				var img := get_viewport().get_texture().get_image()
				var hp: Vector2 = scene.hero_pos - Vector2(scene._cam, 0)
				var r := Rect2i(Vector2i(clampi(int(hp.x - CROP.x * 0.5), 0, 1280 - int(CROP.x)), clampi(int(hp.y - CROP.y + 40), 0, 720 - int(CROP.y))), Vector2i(CROP))
				crops.append(img.get_region(r))
			else:
				await get_tree().process_frame
		var sheet := Image.create(int(CROP.x) * 6, int(CROP.y) * 2, false, crops[0].get_format())
		for i in crops.size():
			sheet.blit_rect(crops[i], Rect2i(Vector2i.ZERO, Vector2i(CROP)), Vector2i((i % 6) * int(CROP.x), (i / 6) * int(CROP.y)))
		sheet.save_png("user://hero_%s_%s.png" % [stage, label])
		scene.queue_free()
		for i in 5:
			await get_tree().process_frame
	get_tree().quit()
