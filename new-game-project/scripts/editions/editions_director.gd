class_name EditionsDirector
extends Node
## Runs "Mirror Page: The Editions": the book opening, then the same story printed in three editions.
##   144p: two dark-room levels and the Ink Baron. Twist 1: the player raises the settings to 720p.
##   720p: a pixel-art brawler level and the Static Twins. Fake credits; the cursor moves to 2K by itself.
##   2k:   the library hall, the opera arena, the comms die, the Narrator unmasks; the final battle.
## The Narrator is the hero's friendly voice on comms until the very end.

var main: Node
var fx: EditionFX
var comms: CommsBox
var act := ""


func setup(m: Node) -> void:
	main = m
	fx = EditionFX.new()
	main.add_child(fx)
	comms = CommsBox.new()
	main.add_child(comms)


# --- the book ------------------------------------------------------------------------------

func start() -> void:
	act = "book"
	fx.set_edition("2k")
	_set_audio("2k")
	comms.clear()
	comms.dead = false
	main._set_state("cutscene")
	main._play_cutscene("book", _after_book)


func _after_book() -> void:
	# the light drains: the picture falls apart into the cheap edition
	EventBus.sound_requested.emit("glitch")
	fx.sweep_to("144p", 1.4)
	_later(1.6, func() -> void:
		act = "144p"
		_set_audio("144p")
		main._load_level(0))


## What the Narrator says when a 144p level starts (replaces the level's own intro).
func level_intro(i: int) -> String:
	if i == 0:
		return "NARRATOR: There you are, hero! It's dark, I know. Use your torch, finish the tasks and the next door opens. I'll be right here on comms."
	return "NARRATOR: Careful. Two vampires in here: one is a friend, one works for the masked villain. Hold your light on them... and choose wisely."


# --- 144p ----------------------------------------------------------------------------------

## Both 144p levels are done: the Ink Baron (the first of the villain's lieutenants).
func after_144_levels() -> void:
	main._set_state("cutscene")
	comms.say("That door leads to the Ink Baron, one of the masked villain's lieutenants. Beat him and we're one step closer to your friends!", "narrator", 2.0)
	_later(3.5, func() -> void: _start_boss_144())


func _start_boss_144() -> void:
	main._set_state("boss")
	var b := BossFight.new()
	b.heroes = [0]
	b.relay = false
	b.boss_name = "THE INK BARON"
	b.win_text = "BARON BUSTED!"
	b.intro_lines = ["The Ink Baron blocks the way. Beat his choristers, then him.", "Power: V LIGHT BLADE, %s." % BossFight.POWER_TEXT_BY_KIND[0]]
	b.waves = [[[["lancer", "L", 0.0], ["lancer", "R", 0.6], ["bat", "AC", 3.5]], [["baron", "C", 0.0]]]]
	main._overlay = b
	main._task_layer.add_child(b)
	comms.say("Light him up, hero!", "narrator", 1.5)
	b.finished.connect(func(result: String) -> void:
		b.queue_free()
		main._overlay = null
		if result == "win":
			_twist_one()
		else:
			comms.say("Up you get, hero! Again!", "narrator", 1.5)
			_later(1.5, _start_boss_144))


## Twist 1: the Narrator asks the player to raise the picture quality.
func _twist_one() -> void:
	main._set_state("cutscene")
	act = "twist1"
	comms.say("You did it! But hero... I can barely see you. This picture is dreadful!", "narrator", 1.2)
	_later(4.2, func() -> void: comms.say("Reader - yes, YOU, holding the controls. Raise the settings! Please!", "narrator", 2.5))
	_later(8.0, func() -> void:
		var tw := SettingsTwist.new()
		tw.mode = "player"
		main.add_child(tw)
		tw.finished.connect(func(_c: String) -> void:
			fx.sweep_to("720p", 1.8)
			_set_audio("720p")
			comms.say("WOW. Look at you! Now THAT is a hero.", "narrator", 2.0)
			_later(2.4, start_720)))


# --- 720p ----------------------------------------------------------------------------------

func start_720() -> void:
	act = "720p"
	main._set_state("boss")
	comms.say("New look, same mission. The Static Twins guard the line to the villain's tower. Their goons are on this street. Watch their eyes: when they glow RED, hit V and turn it around!", "narrator", 2.5)
	var g := BrawlerGame.new()
	g.stage = "street"
	main._overlay = g
	main._task_layer.add_child(g)
	g.finished.connect(func(_r: String) -> void:
		g.queue_free()
		main._overlay = null
		comms.say("Nice moves! The Twins are on the train. Hold on tight!", "narrator", 1.5)
		_later(2.5, _start_twins))


func _start_twins() -> void:
	var g := BrawlerGame.new()
	g.stage = "train"
	main._overlay = g
	main._task_layer.add_child(g)
	comms.say("Two of them, one of you. They take turns: dodge the eye beams, counter the dashes!", "narrator", 2.0)
	g.finished.connect(func(_r: String) -> void:
		g.queue_free()
		main._overlay = null
		main._set_state("cutscene")
		_twist_two())


## Twist 2: fake credits, then the cursor moves to 2K by itself.
func _twist_two() -> void:
	act = "twist2"
	comms.say("That's it... we did it! Roll the credits, hero!", "narrator", 1.5)
	_later(3.0, func() -> void:
		var tw := SettingsTwist.new()
		tw.mode = "hijack"
		main.add_child(tw)
		tw.finished.connect(func(_c: String) -> void:
			fx.sweep_to("2k", 2.0)
			_set_audio("2k")
			comms.say("...wait. Who clicked that? Never mind! Look how sharp everything is. Let's go, hero.", "narrator", 2.0)
			_later(2.6, start_2k)))


# --- 2k ------------------------------------------------------------------------------------

func start_2k() -> void:
	act = "2k"
	main._set_state("cutscene")
	var card := EditionCard.new()
	card.title = "2K EDITION"
	card.lines = ["The library hall and the opera arena are being built.", "Press Z for the final battle."]
	main._task_layer.add_child(card)
	card.done.connect(func() -> void:
		card.queue_free()
		main._start_boss())


# --- helpers -------------------------------------------------------------------------------

func _later(secs: float, f: Callable) -> void:
	var t := get_tree().create_timer(secs, false)
	t.timeout.connect(f)


## The cheap edition sounds cheap: muffled and crushed. The others sound clean.
func _set_audio(edition: String) -> void:
	var bus := AudioServer.get_bus_index("Master")
	while AudioServer.get_bus_effect_count(bus) > 0:
		AudioServer.remove_bus_effect(bus, 0)
	if edition == "144p":
		var lp := AudioEffectLowPassFilter.new()
		lp.cutoff_hz = 2600.0
		AudioServer.add_bus_effect(bus, lp)
		var crush := AudioEffectDistortion.new()
		crush.mode = AudioEffectDistortion.MODE_LOFI
		crush.drive = 0.35
		crush.post_gain = -3.0
		AudioServer.add_bus_effect(bus, crush)
