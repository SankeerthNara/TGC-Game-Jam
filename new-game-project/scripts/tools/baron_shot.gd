extends Node
## The Ink Baron landing (2K and 240p) and the Twins tuning in, with the bosses' comms lines (not part of the game).

var _layer: CanvasLayer


func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _ready() -> void:
	var fx := EditionFX.new()
	add_child(fx)
	var comms := CommsBox.new()
	add_child(comms)
	_layer = CanvasLayer.new()
	_layer.layer = 18
	add_child(_layer)
	for ed in ["2k", "240p"]:
		fx.set_edition(ed)
		comms.clear()
		var b := BossFight.new()
		b.heroes = [0]
		b.relay = false
		b.bomb_left = -1.0
		b.fight_title = "THE INK BARON"
		b.boss_name = "THE INK BARON"
		b.waves = [[[["baron", "C", 0.0]]]]
		_layer.add_child(b)
		await frames(3)
		b._pt = 10.0
		for i in 600:
			await get_tree().process_frame
			if b._narrator != null and b._narrator.state != "enter" and b._t > 4.0:
				break
		await frames(45)
		get_viewport().get_texture().get_image().save_png("user://baron_%s.png" % ed)
		b.queue_free()
		await frames(2)
	fx.set_edition("720p")
	comms.clear()
	var g := BrawlerGame.new()
	g.stage = "train"
	_layer.add_child(g)
	for i in 400:
		await get_tree().process_frame
		if g._phase == "play":
			break
	await frames(20)
	get_viewport().get_texture().get_image().save_png("user://twins_taunt.png")
	get_tree().quit()
