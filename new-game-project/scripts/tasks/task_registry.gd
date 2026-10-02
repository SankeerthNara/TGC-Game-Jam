class_name TaskRegistry
extends RefCounted
## Maps a task type from data/world/station.json to its mini-game.
## "mirror" tasks are not here: they reuse the panel-and-mirror light puzzle pages.

static func create(type: String) -> TaskBase:
	match type:
		"wires":
			return WiresTask.new()
		"switches":
			return SwitchesTask.new()
		"simon":
			return SimonTask.new()
		"charge":
			return ChargeTask.new()
		"dial":
			return DialTask.new()
		"blots":
			return BlotsTask.new()
		"swipe":
			return SwipeTask.new()
	return null
