extends SceneTree
## Renders frames of the story cutscenes to PNGs for a visual check (not part of the game).

const SHOTS := [["opening", 1.5], ["opening", 5.5], ["opening", 9.0], ["bomb_room", 1.5], ["bomb_room", 3.0], ["bomb_room", 5.0], ["bomb_room", 8.0], ["earth_blast", 0.8], ["earth_blast", 2.3], ["earth_blast", 4.5]]


func _init() -> void:
	var layer := CanvasLayer.new()
	root.add_child(layer)
	for shot in SHOTS:
		var cs := CutScene.new()
		cs.kind = shot[0]
		cs.bomb_left = 112.0
		layer.add_child(cs)
		await process_frame
		cs.set_process(false)
		cs._t = shot[1]
		cs.queue_redraw()
		await process_frame
		await process_frame
		root.get_texture().get_image().save_png("C:/Users/sanke/AppData/Local/Temp/t/cs_%s_%d.png" % [shot[0], int(shot[1] * 10)])
		cs.queue_free()
		await process_frame
	print("done")
	quit()
