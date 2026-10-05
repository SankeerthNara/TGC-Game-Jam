extends "res://scripts/tools/playtime_test.gd"
## Targeted edge cases (not part of the game):
##  1. pause right as the street fight ends and the page turn to the Twins begins; unpause later
##  2. the hero takes a lethal hit on the same frame the Ink Baron takes his killing blow
## The game must still reach the final screen.

var _paused_once := false
var _pause_t := -1.0
var _clash_done := false


func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	super._process(delta)
	if main == null or main.director == null:
		return
	var ov: Variant = main._overlay
	# 2: Ink Baron down to his last hit, hero on one heart: both blows land on the same frame
	if not _clash_done and ov is BossFight and ov.fight_title == "THE INK BARON" and ov._narrator != null and ov._phase == "wave":
		_clash_done = true
		var b: BossFight = ov
		b._narrator.hp = 0.5
		b._hp = 1
		b._invuln = 0.0
		b._hit_enemy(b._narrator, 5.0, false) # the hero's blow lands first in a frame (as in the game)
		b._hurt(b.hero_pos.x + 30.0)
		print("EDGE clash done: hero hp=", b._hp, " phase=", b._phase)
	# 1: pause the moment the street is cleared
	if not _paused_once and ov is BrawlerGame and ov.stage == "street" and ov._phase == "won":
		_paused_once = true
		tap(KEY_P)
		press(KEY_P, false)
		_pause_t = 0.0
		print("EDGE paused at the street's end: paused=", main.paused, " state=", main.state)
	if _pause_t >= 0.0:
		_pause_t += delta
		if _pause_t > 6.0:
			_pause_t = -1.0
			if main.paused:
				tap(KEY_P)
				press(KEY_P, false)
			print("EDGE unpaused: overlay=", _label(), " state=", main.state, " paused=", main.paused)
