extends Node
## Freezes the big story moments at chosen instants and saves PNGs (not part of the game):
## the book dive, the unmasking, the closing book, the Twins' entrance, the solar flare.

var _layer: CanvasLayer


func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func shot(name: String) -> void:
	await frames(2)
	get_viewport().get_texture().get_image().save_png("user://mo_%s.png" % name)


func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 18
	add_child(_layer)
	await frames(2)
	# the book: the cover, then the dive into the comic
	var cs := ComicCutscene.new()
	cs.kind = "book"
	_layer.add_child(cs)
	await frames(1)
	cs.set_process(false)
	cs.show_at(0, 1.1)
	await shot("book_cover_gleam")
	for k: float in [0.25, 0.45, 0.6, 0.7]:
		cs._dive = ComicCutscene.DIVE * k
		cs._animate_panels()
		cs._top.queue_redraw()
		await shot("book_dive_%d" % int(k * 100))
	cs._dive = -1.0
	cs.show_at(1, 0.15)
	cs._flash = 0.8
	cs._top.queue_redraw()
	await shot("book_page1_flash")
	cs.queue_free()
	# the unmasking: the RIIIP! hit
	cs = ComicCutscene.new()
	cs.kind = "reveal"
	_layer.add_child(cs)
	await frames(1)
	cs.set_process(false)
	cs.show_at(1, 1.0)
	cs._flash = 0.5
	cs._punch[0] = 0.8
	cs._animate_panels()
	cs.position = Vector2(9, -6)
	cs._top.queue_redraw()
	await shot("reveal_rip")
	cs.position = Vector2.ZERO
	cs._flash = 0.0
	cs.show_at(1, 5.2)
	await shot("reveal_trap")
	cs.queue_free()
	# the book closes
	cs = ComicCutscene.new()
	cs.kind = "ending_editions"
	_layer.add_child(cs)
	await frames(1)
	cs.set_process(false)
	cs.show_at(2, 0.5)
	cs._flash = 0.0 # the page's opening flash fired in the one processed frame
	cs._top.queue_redraw()
	await shot("end_pullback")
	cs.show_at(2, 2.2)
	await shot("end_book")
	cs.queue_free()
	# the Twins tune in
	var fx := EditionFX.new()
	add_child(fx)
	fx.set_edition("720p")
	var g := BrawlerGame.new()
	g.stage = "train"
	_layer.add_child(g)
	await frames(1)
	g.set_process(false)
	for at: float in [0.25, 1.2, 1.75, 2.4]:
		g._phase = "intro"
		if at > 1.6 and g._pt < 1.6:
			g._pt = 1.6 - 0.01
			g._train_intro(0.0)
			g._pt = 1.6
			g._train_intro(0.01)
			g._update_fx(at - 1.6)
		g._pt = at
		g._t = at
		g.queue_redraw()
		await shot("twins_%d" % int(at * 100))
	g.queue_free()
	fx.set_edition("2k")
	# the solar flare over the Narrator's stage
	var b := BossFight.new()
	b.stage = "dark"
	b.caged_heroes = true
	b.heroes = [0]
	b.relay = false
	b.bomb_left = -1.0
	b.waves = [[[["lancer", "L", 99.0]]]]
	_layer.add_child(b)
	await frames(3)
	b._pt = 10.0
	b.hero_pos = Vector2(420, BossFight.FLOOR_Y)
	await frames(20)
	b.set_process(false)
	var f := BrightnessFinale.new()
	f.hero = b.hero_pos - Vector2(b._cam, 70.0)
	add_child(f)
	await frames(1)
	f.set_process(false)
	f._t = 3.0
	f._value = 0.6
	for i in 40:
		f._update_ink(0.05)
	f._node.queue_redraw()
	await shot("finale_60")
	f._done = true
	f._burst()
	for at: float in [0.35, 1.1]:
		f._t = at
		f._update_ink(0.1)
		f._node.queue_redraw()
		await shot("finale_flare_%d" % int(at * 100))
	print("done")
	get_tree().quit()
