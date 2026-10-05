extends "res://scripts/tools/playtime_test.gd"
## Pause menu checks in every act (not part of the game): RESTART in each fight must restart that fight
## (same kind of scene, a new one, same act); QUIT TO MENU in the opera must leave a clean menu (no
## filter, no comms, no scene behind it, no old timers firing) and a new run must play to the end.

var _done := {}
var _in := ""
var _in_t := 0.0
var _check := {}
var _quit_t := -1.0
var _quit_done := false
var _fails := 0


func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func ok(c: bool, what: String) -> void:
	print(("PASS " if c else "FAIL ") + what)
	if not c:
		_fails += 1


func _process(delta: float) -> void:
	if _quit_t >= 0.0:
		_quit_t += delta
		if _quit_t > 1.0 and _quit_t - delta <= 1.0:
			ok(main.state == "menu", "quit to menu: state is menu (%s)" % main.state)
			ok(main.director.fx.edition == "2k", "quit to menu: no edition filter (%s)" % main.director.fx.edition)
			ok(main._task_layer.get_child_count() == 0, "quit to menu: no scene left behind (%d)" % main._task_layer.get_child_count())
			ok(not main.director.comms.busy(), "quit to menu: the comms are quiet")
		if _quit_t > 12.0:
			ok(main.state == "menu" and main._task_layer.get_child_count() == 0, "12 s on the menu: no old timer started a scene (%s)" % main.state)
			_quit_t = -1.0
			EventBus.request_start_game.emit()
		return
	super._process(delta)
	if main == null or main.director == null:
		return
	var label := _label()
	if not label.begins_with("fight:") and not label.begins_with("brawler:"):
		_in = ""
		return
	if label != _in:
		_in = label
		_in_t = 0.0
	_in_t += delta
	if not _check.is_empty():
		if _in_t > 0.5:
			var ov: Variant = main._overlay
			ok(ov != null and ov != _check["old"] and ov.get_class() == _check["cls"] and main.director.act == _check["act"] and main.state == "boss",
				"RESTART in %s restarts that fight" % _check["label"])
			_check = {}
		return
	if not _done.has(label) and _in_t > 3.0 and main.state == "boss":
		_done[label] = true
		_check = {"old": main._overlay, "cls": main._overlay.get_class(), "act": main.director.act, "label": label}
		release_all()
		main._set_paused(true)
		EventBus.request_restart_level.emit()
		_in_t = 0.0
		return
	if not _quit_done and label == "fight: THE OPERA" and _done.has(label) and _in_t > 2.0:
		_quit_done = true
		release_all()
		main._set_paused(true)
		EventBus.request_quit_to_menu.emit()
		_quit_t = 0.0


func _report() -> void:
	super._report()
	print("MENU/RESTART FAILS: ", _fails)
