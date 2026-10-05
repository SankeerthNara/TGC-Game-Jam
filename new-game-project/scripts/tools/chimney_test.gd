extends Node
## Can a player climb the library chimney with plain wall jumps? A human-like input pattern:
## jump in, hold toward a wall, Z when sliding, hold toward the other wall, repeat (not part of the game).

func key(k: Key, on: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.pressed = on
	Input.parse_input_event(ev)


func _ready() -> void:
	var b := BossFight.new()
	b.stage = "hall"
	b.heroes = [0]
	b.relay = false
	b.bomb_left = -1.0
	b.level_top = -1720.0
	b.walls = [Rect2(330, -360, 60, 820), Rect2(590, -360, 60, 820)]
	b.platforms = [Rect2(650, -360, 220, 20)]
	b.encounters = [{"at": Rect2(-9999, 9999, 1, 1), "l": 110.0, "r": 1170.0, "floor": 600.0}]
	b.waves = [[[["lancer", "L", 999.0]]]]
	add_child(b)
	for i in 5:
		await get_tree().process_frame
	b._pt = 10.0
	for i in 60:
		await get_tree().process_frame
	b.hero_pos = Vector2(490, 600)
	var side := 1 # the wall we head for
	key(KEY_RIGHT, true)
	key(KEY_Z, true)
	var z_down := 0
	var best := 600.0
	for f in 600:
		await get_tree().process_frame
		best = minf(best, b.hero_pos.y)
		z_down += 1
		if z_down == 10:
			key(KEY_Z, false)
		if b._sliding and z_down > 10:
			# kick off and head for the other wall
			key(KEY_Z, true)
			z_down = 0
			key(KEY_RIGHT if side > 0 else KEY_LEFT, false)
			side = -side
			key(KEY_RIGHT if side > 0 else KEY_LEFT, true)
		if b.hero_pos.y <= -360.0 and b._ground:
			break
	key(KEY_LEFT, false)
	key(KEY_RIGHT, false)
	print("CHIMNEY: highest y %.0f, on top: %s (top of the walls at -360), %.1f s" % [best, b.hero_pos.y <= -360.0, b._t])
	get_tree().quit()
