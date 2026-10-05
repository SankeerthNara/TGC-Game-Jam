extends "res://scripts/tools/playtime_test.gd"
## The playtime bot plus random key mashing (pause, skip, escape, map...) through the whole game:
## it must still reach the final screen. Prints where it gets stuck (not part of the game).

const MASH := [KEY_P, KEY_ESCAPE, KEY_Z, KEY_ENTER, KEY_SPACE, KEY_M, KEY_TAB]
var _mash := 0.0
var _log := 0.0
var _last_label := ""
var _stuck := 0.0


func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # keep mashing (and unpausing) while the game is paused


func _process(delta: float) -> void:
	super._process(delta)
	if main == null or main.director == null:
		return
	_mash += delta
	if _mash > 0.5:
		_mash = 0.0
		var k: Key = MASH[randi() % MASH.size()]
		tap(k)
		press(k, false)
	# never stay paused for long (a player would unpause)
	if main.paused and randf() < 0.05:
		tap(KEY_P)
		press(KEY_P, false)
	var label := _label() + " / " + String(main.state)
	_stuck = 0.0 if label != _last_label else _stuck + delta
	_last_label = label
	_log += delta
	if _log > 30.0:
		_log = 0.0
		print("t=%.0f %s paused=%s" % [_total, label, main.paused])
	if _stuck > 240.0:
		print("STUCK at ", label, " paused=", main.paused)
		_report()
		get_tree().quit()
