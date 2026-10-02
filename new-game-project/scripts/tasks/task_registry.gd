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
		"panels":
			return PanelsTask.new()
		"bubbles":
			return BubblesTask.new()
		"sfx":
			return SfxTask.new()
		"debug":
			return DebugTask.new()
		"logic":
			return LogicTask.new()
		"sort":
			return SortTask.new()
		"dots":
			return DotsTask.new()
		"whack":
			return WhackTask.new()
		"memory":
			return MemoryTask.new()
		"unscramble":
			return UnscrambleTask.new()
		"math":
			return MathTask.new()
		"inkmix":
			return InkMixTask.new()
		"rain":
			return RainTask.new()
		"needle":
			return NeedleTask.new()
		"proofread":
			return ProofreadTask.new()
		"lightsout":
			return LightsOutTask.new()
		"pipes":
			return PipesTask.new()
		"slide":
			return SlideTask.new()
		"safe":
			return SafeTask.new()
	return null
