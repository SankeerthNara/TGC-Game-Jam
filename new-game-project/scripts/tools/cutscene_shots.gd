extends SceneTree
## Renders frames of the comic story cutscenes to PNGs for a visual check (not part of the game).

const SHOTS := [["opening", 0, 4.0], ["opening", 1, 4.5], ["opening", 2, 5.5], ["bomb_room", 0, 1.2], ["bomb_room", 1, 4.0], ["bomb_room", 2, 6.5], ["earth_blast", 0, 2.5], ["earth_blast", 1, 3.0]]


func _init() -> void:
	var layer := CanvasLayer.new()
	root.add_child(layer)
	for shot in SHOTS:
		var cs := ComicCutscene.new()
		cs.kind = shot[0]
		cs.bomb_left = 112.0
		layer.add_child(cs)
		await process_frame
		cs.set_process(false)
		cs.show_at(shot[1], shot[2])
		await process_frame
		await process_frame
		root.get_texture().get_image().save_png("user://cc_%s_%d.png" % [shot[0], shot[1]])
		cs.queue_free()
		await process_frame
	print("done")
	quit()
