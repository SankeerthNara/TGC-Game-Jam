extends Node
## Plays the book, reveal and ending cutscenes with the real voice clips and logs what plays when
## (not part of the game).

func _ready() -> void:
	add_child(VoPlayer.new())
	var layer := CanvasLayer.new()
	add_child(layer)
	for kind in ["book", "reveal", "ending_editions"]:
		var cs := ComicCutscene.new()
		cs.kind = kind
		layer.add_child(cs)
		var vo := VoPlayer.get_vo(get_tree())
		var last := ""
		var last_page := -1
		var t0 := Time.get_ticks_msec()
		var done := [false]
		cs.finished.connect(func() -> void: done[0] = true)
		while not done[0] and Time.get_ticks_msec() - t0 < 120000:
			await get_tree().process_frame
			var now := (Time.get_ticks_msec() - t0) / 1000.0
			if cs._page != last_page:
				last_page = cs._page
				print("%-16s %5.1f s  page %d" % [kind, now, cs._page])
			var f := vo.current_file()
			if f != last and f != "":
				var shown := []
				for b: Dictionary in cs._pages[cs._page].get("text", []):
					if cs._t >= float(b["at"]):
						shown.append(String(b["text"]).left(18))
				print("%-16s %5.1f s    voice %s   on screen: %s" % [kind, now, f, str(shown)])
			last = f
		print("%-16s %5.1f s  END" % [kind, (Time.get_ticks_msec() - t0) / 1000.0])
		cs.queue_free()
	get_tree().quit()
