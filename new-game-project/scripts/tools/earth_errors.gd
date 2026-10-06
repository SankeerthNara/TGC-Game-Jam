extends Node
## Draws the book's Earth panel at 4000 moments, 0.01 s apart, to catch drawing errors (not part of the game).

func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var cs := ComicCutscene.new()
	cs.kind = "book"
	layer.add_child(cs)
	await get_tree().process_frame
	cs.set_process(false)
	cs.show_at(1, 5.0)
	var p: ComicPanel = cs._panels[0]
	p.set_process(false)
	for k in 4000:
		p.t = k * 0.01
		p.queue_redraw()
		await get_tree().process_frame
	print("earth drawn")
	get_tree().quit()
