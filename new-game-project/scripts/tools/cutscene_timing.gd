extends Node
## Times the story cutscenes page by page with their voice-over played in game time (as a player who
## never presses Z would see them). For each page: its length, when its last text is complete
## (page_end), and how long the voice ran past it. Not part of the game.

const KINDS := ["book", "reveal", "ending_editions"]


func _ready() -> void:
	var vo := VoPlayer.new()
	add_child(vo)
	var layer := CanvasLayer.new()
	add_child(layer)
	for kind: String in KINDS:
		var cs := ComicCutscene.new()
		cs.kind = kind
		var done := [false]
		cs.finished.connect(func() -> void: done[0] = true)
		layer.add_child(cs)
		var page := -1
		var page_t := 0.0
		var vo_end := 0.0
		var total := 0.0
		var line := ""
		while not done[0] and total < 300.0:
			await get_tree().process_frame
			var dt := get_process_delta_time()
			total += dt
			if vo._player.playing and vo._player.stream != null:
				var at := vo.position() + dt
				if at >= vo._player.stream.get_length():
					vo._player.stop()
				else:
					vo._player.seek(at)
			if cs._page != page:
				if page >= 0:
					print(line % page_t)
				page = cs._page
				page_t = 0.0
			page_t += dt
			if vo.busy():
				vo_end = cs._t
			line = "  %s page %d: %%.1f s (text done %.1f, voice until %.1f, hold %.1f)" % [kind, page, cs._page_end(), vo_end, float(cs._pages[page].get("hold", 2.2))]
		print(line % page_t)
		print("%s TOTAL %.1f s" % [kind, total])
		vo.stop()
		if is_instance_valid(cs):
			cs.queue_free()
		await get_tree().process_frame
	get_tree().quit()
