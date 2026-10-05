extends Node
## The hero turns to the enemy he attacks (not part of the game).

func _ready() -> void:
	var fails := 0
	var b := BossFight.new()
	b.heroes = [0]
	b.relay = false
	b.bomb_left = -1.0
	b.waves = [[[["lancer", "L", 999.0]]]]
	add_child(b)
	await get_tree().process_frame
	var e := ArenaEnemy.new("lancer", b.hero_pos + Vector2(-150, 0))
	e.state = "idle"
	b._enemies.append(e)
	b._face = 1.0
	b._atk_cd = 0.0
	b._start_attack()
	print("2K: enemy behind, X -> face ", b._face, " (want -1)")
	if b._face != -1.0:
		fails += 1
	b.queue_free()
	var g := BrawlerGame.new()
	g.stage = "street"
	add_child(g)
	await get_tree().process_frame
	var t := BrawlEnemy.new("thug", g.hero_pos + Vector2(-120, 0))
	t.state = "idle"
	g._enemies.append(t)
	g._face = 1.0
	g._start_attack()
	print("720p: enemy behind, X -> face ", g._face, " (want -1)")
	if g._face != -1.0:
		fails += 1
	print("FACE FAILS: ", fails)
	get_tree().quit()
