extends Node
## Frames around a perfect parry + riposte and a critical strike, played by the arena bot against
## library lancers (for GIFs; not part of the game).

const CROP := Vector2i(560, 360)
var _keys := {}
var _ring: Array[Image] = []
var _clips := {} ## name -> frames
var _after := {} ## name -> frames still to record


func press(k: Key, on: bool) -> void:
	if _keys.get(k, false) == on:
		return
	_keys[k] = on
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.pressed = on
	Input.parse_input_event(ev)


func tap(k: Key) -> void:
	press(k, false)
	press(k, true)


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 18
	add_child(layer)
	var b := BossFight.new()
	b.stage = "hall"
	b.heroes = [0]
	b.relay = false
	b.bomb_left = -1.0
	b.max_hp = 6
	b.checkpoints = true
	b.waves = [[[["lancer", "R", 0.0], ["brute", "L", 4.0]]]]
	layer.add_child(b)
	for i in 5:
		await get_tree().process_frame
	b._pt = 10.0
	var last_p := 0
	var last_c := 0
	var f := 0
	while f < 60 * 60 and (not _clips.has("parry") or not _clips.has("critical") or not _after.is_empty()):
		ArenaBot.drive(b, press, tap)
		await get_tree().process_frame
		f += 1
		if f % 2 != 0:
			continue
		var img := get_viewport().get_texture().get_image()
		var hp: Vector2 = b.hero_pos - Vector2(b._cam, 0)
		var r := Rect2i(Vector2i(clampi(int(hp.x) - CROP.x / 2, 0, 1280 - CROP.x), clampi(int(hp.y) - CROP.y + 60, 0, 720 - CROP.y)), CROP)
		var crop := img.get_region(r)
		_ring.append(crop)
		if _ring.size() > 14:
			_ring.pop_front()
		for name in _after.keys():
			(_clips[name] as Array).append(crop)
			_after[name] = int(_after[name]) - 1
			if int(_after[name]) <= 0:
				_after.erase(name)
		if b.parries > last_p and not _clips.has("parry"):
			_clips["parry"] = _ring.duplicate()
			_after["parry"] = 40
		if b.criticals > last_c and not _clips.has("critical"):
			_clips["critical"] = _ring.duplicate()
			_after["critical"] = 36
		last_p = b.parries
		last_c = b.criticals
	for name in _clips:
		var frames: Array = _clips[name]
		for i in frames.size():
			(frames[i] as Image).save_png("user://pg_%s_%03d.png" % [name, i])
		print(name, " ", frames.size())
	get_tree().quit()
