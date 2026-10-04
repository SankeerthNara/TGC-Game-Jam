extends Node
## Measures CPU time per frame and draw calls in each Editions scene (not part of the game).
## Run with a window (not headless) so the renderer is real.

var _layer: CanvasLayer
var _fx: EditionFX


func _ready() -> void:
	_fx = EditionFX.new()
	add_child(_fx)
	_layer = CanvasLayer.new()
	_layer.layer = 18
	add_child(_layer)
	await get_tree().process_frame
	# the book (story pages with drawn panels)
	_fx.set_edition("2k")
	var cs := ComicCutscene.new()
	cs.kind = "book"
	_layer.add_child(cs)
	await get_tree().process_frame
	cs.show_at(2, 4.0)
	await measure("book page (2k)")
	cs.queue_free()
	# 720p brawler street
	_fx.set_edition("720p")
	var g := BrawlerGame.new()
	g.stage = "street"
	_layer.add_child(g)
	await get_tree().process_frame
	g._phase = "play"
	g._start_zone(1)
	for p in g._pending:
		p["delay"] = 0.0
	g.hero_pos = Vector2(1700, BrawlerGame.GROUND)
	await measure("brawler street (720p)")
	g.queue_free()
	# 2k fights
	_fx.set_edition("2k")
	for stage in ["hall", "opera", "dark"]:
		var b := BossFight.new()
		b.stage = stage
		b.heroes = [0]
		b.relay = false
		b.bomb_left = -1.0
		if stage == "hall":
			b.level_width = 3840.0
			b.arena_x = 3200.0
			b.platforms = [Rect2(620, 470, 220, 20), Rect2(980, 380, 200, 20)]
			b.roamers = [["lancer", Vector2(1100, 600)], ["bat", Vector2(900, 300)]]
		elif stage == "opera":
			b.waves = [[[["lancer", "L", 0.0], ["lancer", "R", 0.0], ["bat", "AC", 0.0], ["brute", "C", 0.0]]]]
		else:
			b.caged_heroes = true
			b.waves = [[[["narrator", "BALCONY", 0.0]]]]
		_layer.add_child(b)
		await get_tree().process_frame
		b._pt = 10.0 # skip the intro card
		await measure("fight %s (2k)" % stage)
		b.queue_free()
	# the 144p filter over a busy fight
	_fx.set_edition("144p")
	var b2 := BossFight.new()
	b2.heroes = [0]
	b2.relay = false
	b2.bomb_left = -1.0
	b2.waves = [[[["lancer", "L", 0.0], ["lancer", "R", 0.0], ["baron", "C", 0.0]]]]
	_layer.add_child(b2)
	await get_tree().process_frame
	b2._pt = 10.0
	await measure("Ink Baron fight (144p)")
	get_tree().quit()


func measure(name: String) -> void:
	for i in 30:
		await get_tree().process_frame
	var n := 0
	var cpu := 0.0
	var cpu_max := 0.0
	var draws := 0.0
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 2500:
		await get_tree().process_frame
		var c := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		cpu += c
		cpu_max = maxf(cpu_max, c)
		draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		n += 1
	print("%-26s frames/s %5.1f   (process %5.2f ms avg, %5.2f max)   draw calls %5.0f" % [name, n / 2.5, cpu / n, cpu_max, draws / n])
