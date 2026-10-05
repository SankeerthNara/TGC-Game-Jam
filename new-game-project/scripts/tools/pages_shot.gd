extends Node
## Renders every page of the given cutscenes (-- book reveal ...) to PNGs, at the given moments of
## each page (default: when the page is complete), for a visual check (not part of the game).
## -- at=0.3,1.0 renders each page at those fractions of its length instead.


func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var kinds: Array[String] = []
	var fracs: Array[float] = [1.0]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("at="):
			fracs.clear()
			for f in a.substr(3).split(","):
				fracs.append(float(f))
		else:
			kinds.append(a)
	for kind in kinds:
		var n := StoryScenes.pages(kind).size()
		for pg in n:
			for fi in fracs.size():
				var cs := ComicCutscene.new()
				cs.kind = kind
				layer.add_child(cs)
				await get_tree().process_frame
				cs.set_process(false)
				cs._page = pg
				cs._build_page()
				var end := cs._page_end() + float(cs._pages[pg].get("hold", 2.2))
				cs.show_at(pg, end * fracs[fi])
				cs._flash = 0.0
				cs._shake = 0.0
				for i in 3:
					await get_tree().process_frame
				get_viewport().get_texture().get_image().save_png("user://pg_%s_%d_%d.png" % [kind, pg, fi])
				cs.queue_free()
				await get_tree().process_frame
	print("done")
	get_tree().quit()
