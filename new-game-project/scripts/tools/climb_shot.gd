extends Node
## The library climb at several heights (not part of the game).

func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 18
	add_child(layer)
	var d := EditionsDirector.new()
	var b := BossFight.new()
	b.stage = "hall"
	b.heroes = [0]
	b.relay = false
	b.bomb_left = -1.0
	b.max_hp = 6
	b.checkpoints = true
	# the same layout as the game (copied from the director by calling it on a fake main)
	var src := FileAccess.get_file_as_string("res://scripts/editions/editions_director.gd")
	layer.add_child(b)
	_configure(b)
	for i in 5:
		await get_tree().process_frame
	b._pt = 10.0
	var spots := [Vector2(250, 600), Vector2(490, 200), Vector2(760, -360), Vector2(1180, -420), Vector2(620, -860), Vector2(1080, -1320)]
	for i in spots.size():
		b.hero_pos = spots[i]
		b._vel = Vector2.ZERO
		for k in 50:
			b._phase = "explore"
			b._exploring = true
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("user://climb_%d.png" % i)
	get_tree().quit()


func _configure(b: BossFight) -> void:
	b.level_width = 1280.0
	b.level_top = -1720.0
	b.walls = [Rect2(330, -360, 60, 820), Rect2(590, -360, 60, 820)]
	b.platforms = [Rect2(650, -360, 220, 20), Rect2(1110, -420, 140, 20), Rect2(480, -860, 280, 20), Rect2(840, -960, 170, 20), Rect2(110, -1080, 1060, 20), Rect2(640, -1200, 180, 20), Rect2(960, -1320, 230, 20)]
	b.steppers = [Vector2(990, -540), Vector2(800, -700)]
	b.book_columns = [[1020.0, 2.4], [430.0, 3.1]]
	b.encounters = [{"at": Rect2(-9999, 9999, 1, 1), "l": 110.0, "r": 1170.0, "floor": 600.0}, {"at": Rect2(0, -1200, 1280, 125), "l": 110.0, "r": 1170.0, "floor": -1080.0}]
	b.exit_rect = Rect2(1000, -1440, 150, 120)
	b.waves = [[[["lancer", "L", 99.0]], [["lancer", "L", 99.0]]]]
