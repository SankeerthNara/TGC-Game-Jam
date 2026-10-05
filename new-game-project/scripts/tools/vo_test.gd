extends Node
## The voice-over player with a generated clip (not part of the game): a page holds until its clip
## ends, the music dips, Z cuts the voice, VOICE OFF is silent, a missing file is silent, a comms line
## waits for its clip.

var fails := 0


func ok(c: bool, what: String) -> void:
	print(("PASS " if c else "FAIL ") + what)
	if not c:
		fails += 1


func tone(secs: float) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = 22050
	var n := int(secs * 22050)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		data.encode_s16(i * 2, int(sin(i * 0.06) * 3000.0))
	w.data = data
	return w


func key(k: Key, on: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.pressed = on
	Input.parse_input_event(ev)


func _ready() -> void:
	var main: Node = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(main)
	for i in 5:
		await get_tree().process_frame
	var vo := VoPlayer.get_vo(get_tree())
	ok(vo != null, "the voice-over player is in the game")
	# a 6 s clip for the first line of the book's first story page
	vo._map[VoPlayer._norm("book/1/0")] = "test_clip"
	vo._cache["test_clip"] = tone(6.0)
	vo._map[VoPlayer._norm("Can you hear me")] = "missing_file.mp3"
	EventBus.request_start_game.emit()
	for i in 5:
		await get_tree().process_frame
	var cs: ComicCutscene = main._overlay
	cs._page = 1
	cs._build_page()
	var t0 := Time.get_ticks_msec()
	var spoke := false
	var dipped := false
	while cs._page == 1 and Time.get_ticks_msec() - t0 < 15000:
		await get_tree().process_frame
		spoke = spoke or vo.busy()
		var md: Node = get_tree().get_first_node_in_group("music")
		dipped = dipped or (md != null and md._duck > 0.5)
	var held := (Time.get_ticks_msec() - t0) / 1000.0
	ok(spoke, "the caption's clip played")
	ok(held > 6.0, "the page held until the clip ended (%.1f s)" % held)
	ok(dipped, "the music dipped under the voice")
	# Z cuts the voice and turns the page
	cs._wipe = -1.0
	cs._page = 1
	cs._build_page()
	var w0 := Time.get_ticks_msec()
	while not vo.busy() and Time.get_ticks_msec() - w0 < 3000:
		await get_tree().process_frame
	cs._t = cs._page_end() + 0.1
	ok(vo.busy(), "voice playing again on the page")
	key(KEY_Z, true)
	await get_tree().process_frame
	key(KEY_Z, false)
	for i in 3:
		await get_tree().process_frame
	ok(not vo.busy() and cs._page == 2 or cs._wipe >= 0.0, "Z cuts the voice and turns the page")
	# VOICE OFF: silent
	vo.stop()
	vo.set_volume(0.0)
	vo.queue("x", "book/1/0")
	ok(not vo.busy(), "VOICE OFF: nothing plays")
	vo.set_volume(1.0)
	# a missing file is silent
	vo.queue("Can you hear me")
	ok(not vo.busy(), "a missing clip is silent")
	# comms: the line stays up while its clip plays
	vo._map[VoPlayer._norm("A test line on the comms.")] = "test_clip"
	main.director.comms.say("A test line on the comms.", "narrator", 0.2)
	await get_tree().process_frame
	var c0 := Time.get_ticks_msec()
	while main.director.comms.busy() and Time.get_ticks_msec() - c0 < 12000:
		await get_tree().process_frame
	ok((Time.get_ticks_msec() - c0) / 1000.0 > 5.5, "the comms line waited for its clip (%.1f s)" % ((Time.get_ticks_msec() - c0) / 1000.0))
	print("VO FAILS: ", fails)
	get_tree().quit()
