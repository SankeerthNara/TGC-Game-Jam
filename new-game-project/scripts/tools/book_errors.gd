extends Node
## Draws the book panels for many moments in time to flush out drawing errors (not part of the game).

func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	for kind in ["book", "reveal", "ending_editions"]:
		var cs := ComicCutscene.new()
		cs.kind = kind
		layer.add_child(cs)
		await get_tree().process_frame
		cs.set_process(false)
		for page in StoryScenes.pages(kind).size():
			for k in 60:
				cs.show_at(page, k * 0.37)
				for p in cs._panels:
					p.t = k * 0.37 + page * 7.3
					p.queue_redraw()
				await get_tree().process_frame
		cs.queue_free()
	print("book panels drawn")
	get_tree().quit()
