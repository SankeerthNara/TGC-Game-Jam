extends Node
## The start notice and the THE END card (not part of the game).

func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	for m in ["start", "end"]:
		var c := NoticeCard.new()
		c.mode = m
		layer.add_child(c)
		for i in 5:
			await get_tree().process_frame
		c._t = 3.0
		c.queue_redraw()
		await get_tree().process_frame
		await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("user://card_%s.png" % m)
		c.queue_free()
	get_tree().quit()
