extends Node
## Frames of the Static Twins fight (720p), played by the brawler bot (not part of the game).

const Bot := preload("res://scripts/tools/brawler_bot_test.gd")
var _bot: Node


func _ready() -> void:
	_bot = Bot.new()
	var fx := EditionFX.new()
	add_child(fx)
	fx.set_edition("720p")
	var layer := CanvasLayer.new()
	add_child(layer)
	var g := BrawlerGame.new()
	g.stage = "train"
	layer.add_child(g)
	var n := 0
	var seen := {}
	for f in 60 * 120:
		await get_tree().process_frame
		_bot._drive(g)
		var tag := ""
		for e in g._enemies:
			if e.state in ["hop_in", "dive_wind", "stagger"] or (e.state == "windup" and e.attack in ["xdash", "orbs"]):
				tag = e.state + e.attack
		if g._tunnel_k >= 1.0 and not seen.has("tunnel"):
			tag = "tunnel"
		if g._orbs.size() > 0 and not seen.has("orbsfly"):
			tag = "orbsfly"
		for e in g._enemies:
			if e.berserk and not seen.has("berserk") and e.state == "windup":
				tag = "berserk"
		if tag != "" and not seen.has(tag) and n < 10:
			seen[tag] = true
			for i in 4:
				await get_tree().process_frame
			get_viewport().get_texture().get_image().save_png("user://twins_%d.png" % n)
			print(n, " ", tag)
			n += 1
		if g._phase == "won":
			break
	get_tree().quit()
