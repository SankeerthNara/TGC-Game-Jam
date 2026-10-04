class_name EditionsDirector
extends Node
## Runs "Mirror Page: The Editions": the book opening, then the same story printed in three editions.
##   144p: two dark-room levels and the Ink Baron. Twist 1: the player raises the settings to 720p.
##   720p: a pixel-art brawler level and the Static Twins. Fake credits; the cursor moves to 2K by itself.
##   2k:   the library hall, the opera arena, the comms die, the Narrator unmasks; the final battle.
## The Narrator is the hero's friendly voice on comms until the very end.
## Scenes never leave an empty screen: a finished scene stays frozen until an ink page turn covers it.

var main: Node
var fx: EditionFX
var comms: CommsBox
var act := ""
var _stale: Node = null ## the finished scene, kept on screen until the next page turn covers it


func setup(m: Node) -> void:
	main = m
	add_to_group("editions_director")
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
		return "NARRATOR: There you are, hero! It's dark, I know. ARROW KEYS move, your torch lights the way. Walk to a glowing console and press Z to fix it. Fix them all and the door opens. M shows the map. I'll be right here on comms."
	return "NARRATOR: Careful. Two vampires in here: one is a friend, one works for the masked villain. Hold your light on one to catch him, then REVEAL or KILL. A revealed friend helps: stand at a console and press F."


# --- 144p ----------------------------------------------------------------------------------

## Both 144p levels are done: the Ink Baron (the first of the villain's lieutenants).
func after_144_levels() -> void:
	main._set_state("cutscene")
	comms.say("That door leads to the Ink Baron, one of the masked villain's lieutenants. Beat him and we're one step closer to your friends!", "narrator", 2.0)
	_later(3.0, func() -> void: _swap(_start_boss_144, "THE INK BARON"))


func _start_boss_144() -> void:
	main._set_state("boss")
	var b := BossFight.new()
	b.heroes = [0]
	b.relay = false
	b.max_hp = 6
	b.checkpoints = true
	b.boss_name = "THE INK BARON"
	b.fight_title = "THE INK BARON"
	b.win_text = "BARON BUSTED!"
	b.intro_lines = ["The Ink Baron blocks the way. Beat his choristers, then him.", "Power: V LIGHT BLADE, %s." % BossFight.POWER_TEXT_BY_KIND[0]]
	b.waves = [[[["lancer", "L", 0.0], ["lancer", "R", 0.6], ["bat", "AC", 3.5]], [["baron", "C", 0.0]]]]
	_launch(b)
	comms.say("Light him up, hero!", "narrator", 1.5)
	b.finished.connect(func(_result: String) -> void:
		_retire(b)
		_twist_one())


## Twist 1: the Narrator asks the player to raise the picture quality. The last frame of the fight
## stays on screen behind the window, so the player sees it sharpen.
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
			_later(2.4, func() -> void: _swap(start_720, "NEON STREET"))))


# --- 720p ----------------------------------------------------------------------------------

func start_720() -> void:
	act = "720p"
	main._set_state("boss")
	comms.say("New look, same mission. The Static Twins guard the line to the villain's tower. Their goons are on this street. Watch their eyes: when they glow RED, hit V and turn it around!", "narrator", 2.5)
	var g := BrawlerGame.new()
	g.stage = "street"
	_launch(g)
	g.finished.connect(func(_r: String) -> void:
		_retire(g)
		comms.say("Nice moves! The Twins are on the train. Hold on tight!", "narrator", 1.5)
		_later(1.8, func() -> void: _swap(_start_twins, "THE STATIC TWINS")))


func _start_twins() -> void:
	var g := BrawlerGame.new()
	g.stage = "train"
	_launch(g)
	comms.say("Two of them, one of you. They take turns: dodge the eye beams, counter the dashes!", "narrator", 2.0)
	g.finished.connect(func(_r: String) -> void:
		_retire(g)
		main._set_state("cutscene")
		_later(1.2, _twist_two))


## Twist 2: fake credits roll... freeze... and the cursor moves to 2K by itself.
func _twist_two() -> void:
	act = "twist2"
	comms.say("That's it... we did it! Roll the credits, hero!", "narrator", 1.5)
	var credits := FakeCredits.new()
	_swap(func() -> void:
		main._overlay = credits
		main._task_layer.add_child(credits))
	_later(9.0, func() -> void:
		credits.freeze()
		fx.glitch(0.7, 0.8)
		EventBus.sound_requested.emit("static")
		_later(1.0, func() -> void:
			var tw := SettingsTwist.new()
			tw.mode = "hijack"
			main.add_child(tw)
			tw.finished.connect(func(_c: String) -> void:
				_retire(credits)
				fx.sweep_to("2k", 2.0)
				_set_audio("2k")
				comms.say("...wait. Who clicked that? Never mind! Look how sharp everything is. Let's go, hero.", "narrator", 2.0)
				_later(2.6, func() -> void: _swap(start_2k, "THE LIBRARY")))))


# --- 2k ------------------------------------------------------------------------------------

func start_2k() -> void:
	act = "2k"
	main._set_state("boss")
	comms.say("The villain's tower. A library first, then his opera. Your friends are close, hero. I can feel it.", "narrator", 2.0)
	var b := _arena("hall")
	b.level_width = 3840.0
	b.arena_x = 3200.0
	b.platforms = [Rect2(620, 470, 220, 20), Rect2(980, 380, 200, 20), Rect2(1360, 470, 240, 20), Rect2(1800, 420, 220, 20), Rect2(2200, 330, 200, 20), Rect2(2540, 450, 240, 20)]
	b.roamers = [["lancer", Vector2(1100, 600)], ["bat", Vector2(1500, 260)], ["lancer", Vector2(2000, 600)], ["bat", Vector2(2400, 220)], ["lancer", Vector2(2700, 600)]]
	b.waves = [[[["lancer", "L", 0.0], ["lancer", "R", 0.4], ["bat", "AL", 2.0], ["bat", "AR", 3.5], ["lancer", "C", 5.0]]]]
	b.win_text = "THE HALL IS CLEAR!"
	b.fight_title = "THE LIBRARY"
	b.intro_lines = ["The deluxe edition. Light blade ready.", "X slash (+UP / +DOWN in the air)   C dash   V LIGHT BLADE   F heal"]
	_launch(b)
	b.finished.connect(func(_result: String) -> void:
		_retire(b)
		comms.say("Beautiful! Through those doors: his opera house. Stay sharp.", "narrator", 1.5)
		_later(1.8, func() -> void: _swap(_opera, "THE OPERA")))


func _opera() -> void:
	var b := _arena("opera")
	b.waves = [[[["lancer", "L", 0.0], ["lancer", "R", 0.3], ["bat", "AC", 3.0], ["lancer", "C", 6.0]],
		[["brute", "C", 0.0], ["bat", "AL", 3.0], ["bomb", "AR", 5.0], ["lancer", "L", 7.0], ["lancer", "R", 9.0]]]]
	b.win_text = "ENCORE!"
	b.fight_title = "THE OPERA"
	b.intro_lines = ["The masked villain's opera. His choir is waiting.", "Two waves, then... him."]
	_launch(b)
	comms.say("The masked villain is close. Clear his choir and he'll have to show himself!", "narrator", 2.0)
	b.finished.connect(func(_result: String) -> void:
		_retire(b)
		_reveal())


## The comms machine dies (the picture tears, the music drops out)... and the masked villain steps out.
func _reveal() -> void:
	main._set_state("cutscene")
	act = "reveal"
	comms.say("Hero, wait... something's wrong with the sig-", "narrator", 0.5)
	_later(2.0, func() -> void:
		comms.kill_signal()
		fx.glitch(0.9, 1.4))
	_later(5.0, func() -> void: fx.glitch(0.5, 0.4))
	_later(7.5, func() -> void:
		_free_stale()
		main._play_cutscene("reveal", func() -> void:
			act = "2k"
			_swap(_final_boss, "THE NARRATOR")))


func _final_boss() -> void:
	var b := _arena("dark")
	b.caged_heroes = true
	b.waves = [[[["narrator", "BALCONY", 0.0]]]]
	b.boss_name = "THE NARRATOR"
	b.fight_title = "THE NARRATOR"
	b.boss_hp_scale = 1.4
	b.narrator_line = "LET ME WRITE YOUR LAST PAGE!"
	b.win_text = ""
	b.intro_lines = ["The Narrator. The one who guided you all along.", "Free the three heroes. V LIGHT BLADE, F heal."]
	_launch(b)
	comms.say("I wrote every page of you, hero. Even this one.", "narrator_evil", 2.0)
	b.finished.connect(func(_result: String) -> void:
		_retire(b)
		_finale())


## The player drags the brightness to 100%: sunlight, the ending, the book closes.
func _finale() -> void:
	main._set_state("cutscene")
	comms.say("Reader... you wouldn't.", "narrator_evil", 1.0)
	var f := BrightnessFinale.new()
	main.add_child(f)
	f.finished.connect(func() -> void:
		_free_stale()
		main._play_cutscene("ending_editions", func() -> void: main._final_screen(true)))


func _arena(stage: String) -> BossFight:
	main._set_state("boss")
	var b := BossFight.new()
	b.stage = stage
	b.heroes = [0]
	b.relay = false
	b.max_hp = 6
	b.checkpoints = true
	b.friends_revealed = main.friends_revealed
	b.friends_killed = main.friends_killed
	b.bomb_left = -1.0
	return b


## Adds a configured scene to the screen.
func _launch(n: Node) -> void:
	main._overlay = n
	main._task_layer.add_child(n)


## A finished scene stays visible (frozen) instead of leaving an empty screen.
func _retire(n: Node) -> void:
	_free_stale()
	_stale = n
	if main._overlay == n:
		main._overlay = null


func _free_stale() -> void:
	if _stale != null and is_instance_valid(_stale):
		_stale.queue_free()
	_stale = null


## Turns the page: an ink wipe covers the screen, the old scene goes and `next` starts underneath.
func _swap(next: Callable, title := "") -> void:
	var w := EditionWipe.new()
	w.title = title
	main.add_child(w)
	w.covered.connect(func() -> void:
		_free_stale()
		next.call())


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
	MusicDirector.ensure_limiter() # always last on the master bus
