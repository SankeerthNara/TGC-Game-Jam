extends Node
## Renders frames of the comic story cutscenes to PNGs for a visual check (not part of the game).

const SHOTS := [["ending_sun", 0, 4.0], ["ending_sun", 1, 5.0], ["ending_lava", 0, 4.0], ["ending_lava", 1, 5.0]]


func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	for shot in SHOTS:
		var cs := ComicCutscene.new()
		cs.kind = shot[0]
		cs.bomb_left = 112.0
		layer.add_child(cs)
		await get_tree().process_frame
		cs.set_process(false)
		cs.show_at(shot[1], shot[2])
		await get_tree().process_frame
		await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("user://cc_%s_%d.png" % [shot[0], shot[1]])
		cs.queue_free()
		await get_tree().process_frame
	print("done")
	get_tree().quit()
