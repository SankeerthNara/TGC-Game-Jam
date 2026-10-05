class_name EditionsDirector
extends Node
## Runs "Glitched Out": the book opening, then the same story printed in three editions.
##   240p: two dark-room levels and the Ink Baron. Twist 1: the player raises the settings to 720p.
##   720p: a pixel-art brawler level and the Static Twins. Fake credits; the cursor moves to 2K by itself.
##   2k:   the library hall, the opera arena, the comms die, the Narrator unmasks; the final battle.
## The Narrator is the hero's friendly voice on comms until the very end.
## Scenes never leave an empty screen: a finished scene stays frozen until an ink page turn covers it.

var main: Node
var fx: EditionFX
var comms: CommsBox
var act := ""
var _stale: Node = null ## the finished scene, kept on screen until the next page turn covers it
var _run := 0 ## goes up when a run ends (quit to menu): timers and page turns of the old run do nothing
var _current := Callable() ## starts the fight on screen again (pause menu: RESTART)


func setup(m: Node) -> void:
	main = m
	add_to_group("editions_director")
	fx = EditionFX.new()
	main.add_child(fx)
	comms = CommsBox.new()
	main.add_child(comms)


## 240p rooms: only the picture of the dark rooms is cheap. The filter sits just above the world, so
## the HUD, the consoles, the REVEAL / KILL choice and the score cards stay readable. Everywhere else
## (fights, cutscenes, page turns) it covers the whole screen.
const WORLD_STATES := ["world", "task", "choice", "dead", "levelend", "playing"]


func _process(_delta: float) -> void:
	if fx != null and main != null:
		fx.layer = 4 if act == "240p" and main.state in WORLD_STATES else 95


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
	fx.sweep_to("240p", 1.4)
	_later(1.6, func() -> void:
		act = "240p"
		_set_audio("240p")
		main._load_level(0))


## What the Narrator says when a 240p level starts (replaces the level's own intro).
func level_intro(i: int) -> String:
	if i == 0:
		return "NARRATOR: There you are, hero! It's dark, I know. WASD or the ARROW KEYS move, your torch lights the way. Walk to a glowing console and press Z to fix it. Fix them all and the door opens. M shows the map. I'll be right here on comms."
	return "NARRATOR: Careful. Two vampires in here: one is a friend, one works for the masked villain. Hold your light on one to catch him, then REVEAL or KILL. A revealed friend helps: stand at a console and press F."


# --- 240p ----------------------------------------------------------------------------------

## Both 240p levels are done: the Ink Baron (the first of the villain's lieutenants).
func after_240_levels() -> void:
	main._set_state("cutscene")
	comms.say("That door leads to the Ink Baron, one of the masked villain's lieutenants. Beat him and we're one step closer to your friends!", "narrator", 2.0)
	_later(3.0, func() -> void: _swap(_start_boss_240, "THE INK BARON"))


func _start_boss_240() -> void:
	_current = _start_boss_240
	main._set_state("boss")
	var b := BossFight.new()
	b.heroes = [0]
	b.relay = false
	b.max_hp = 6
	b.checkpoints = true
	b.boss_name = "THE INK BARON"
	b.fight_title = "THE INK BARON"
	b.win_text = "BARON BUSTED!"
	b.guards = false # the cheap edition: nobody guards yet (the library teaches the parry properly)
	b.intro_lines = ["The Ink Baron blocks the way. Beat his choristers, then him.", "L parry (tap as his cane flashes GOLD)   hold L: Light Blade"]
	b.waves = [[[["lancer", "L", 0.0], ["lancer", "R", 0.6], ["bat", "AC", 3.5]], [["baron", "C", 0.0]]]]
	_launch(b)
	comms.say("Light him up, hero! Z or SPACE jump, J attack, K dash, F heals. Tap L as his cane flashes GOLD to parry; hold L for your light blade.", "narrator", 2.5)
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
	_current = start_720
	act = "720p"
	main._set_state("boss")
	comms.say("New look, same mission. The Static Twins guard the line to the villain's tower. Their goons are on this street. Watch their eyes: when they glow RED, hit L and turn it around!", "narrator", 2.5)
	var g := BrawlerGame.new()
	g.stage = "street"
	_launch(g)
	g.finished.connect(func(_r: String) -> void:
		_retire(g)
		comms.say("Nice moves! The Twins are on the train. Hold on tight!", "narrator", 1.5)
		_later(1.8, func() -> void: _swap(_start_twins, "THE STATIC TWINS")))


func _start_twins() -> void:
	_current = _start_twins
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
	_current = start_2k
	act = "2k"
	main._set_state("boss")
	comms.say("The villain's tower. A library first, then his opera. Your friends are close, hero. I can feel it.", "narrator", 2.0)
	var b := _arena("hall")
	# the library is a climb: a locked fight on the ground floor, a bookshelf chimney to wall-jump up,
	# a gap to air-dash across, paper bats to pogo off, falling books, a locked fight in the upper
	# reading room, and the door to the opera at the top
	b.level_width = 1280.0
	b.level_top = -1720.0
	b.walls = [Rect2(330, -360, 60, 820), Rect2(590, -360, 60, 820)]
	b.platforms = [Rect2(650, -360, 220, 20), Rect2(1110, -420, 140, 20), Rect2(480, -860, 280, 20),
		Rect2(840, -960, 170, 20), Rect2(110, -1080, 1060, 20), Rect2(640, -1200, 180, 20), Rect2(960, -1320, 230, 20)]
	b.steppers = [Vector2(990, -540), Vector2(800, -700)]
	b.book_columns = [[1020.0, 2.4], [430.0, 3.1]]
	b.encounters = [{"at": Rect2(380, 300, 1000, 400), "l": 110.0, "r": 1170.0, "floor": 600.0},
		{"at": Rect2(0, -1200, 1280, 125), "l": 110.0, "r": 1170.0, "floor": -1080.0}]
	b.exit_rect = Rect2(1000, -1440, 150, 120)
	b.lamps.assign([Vector2(240, 380), Vector2(1040, 380), Vector2(760, -130), Vector2(220, -260), Vector2(1180, -640), Vector2(400, -1240), Vector2(1100, -1500)])
	b.route = [Vector2(490, 600), Vector2(620, -360), Vector2(850, -360), Vector2(1180, -420), Vector2(1010, -640), Vector2(820, -800), Vector2(620, -860), Vector2(925, -960), Vector2(640, -1080), Vector2(730, -1200), Vector2(1075, -1320)]
	b.tips = [
		{"at": Rect2(390, -360, 200, 830), "text": "WALL JUMP: HOLD TOWARD A WALL TO SLIDE, Z TO KICK OFF", "say": "Up the shelves, hero! Cling to a wall and kick off it with Z, side to side."},
		{"at": Rect2(650, -470, 230, 110), "text": "AIR DASH: K IN THE AIR (A WALL OR LANDING GIVES IT BACK)", "say": "Too far to jump. Jump, then dash with K in the air!"},
		{"at": Rect2(1100, -560, 180, 150), "text": "POGO: S + J IN THE AIR BOUNCES YOU OFF BATS AND BOOKS", "say": "Those paper bats are stepping stones. Slash down on them, S and J, and bounce!"},
		{"at": Rect2(380, -1000, 760, 150), "text": "DIVE STRIKE: S + K IN THE AIR", "say": "The reading room is full of them. Strike down from the air with S and K!"}]
	b.waves = [[
		[["lancer", "R", 0.0, {"trainee": true}], ["lancer", "L", 7.0]],
		[["lancer", "L", 0.0], ["bat", "AR", 1.0], ["lancer", "R", 2.0], ["bat", "AL", 4.0], ["lancer", "C", 5.5]]]]
	b.win_text = "TO THE OPERA!"
	b.fight_title = "THE LIBRARY"
	b.intro_lines = ["The deluxe edition: climb the library to the opera.", "Z on a wall: wall jump   K in the air: dash   S+J: pogo   S+K: dive"]
	_launch(b)
	b.finished.connect(func(_result: String) -> void:
		_retire(b)
		comms.say("Beautiful! Through those doors: his opera house. Stay sharp.", "narrator", 1.5)
		_later(1.8, func() -> void: _swap(_opera, "THE OPERA")))


func _opera() -> void:
	_current = _opera
	var b := _arena("opera")
	# a locked arena fought in the air: climbable side walls, the inkwell podium, two chandeliers and a
	# high one that swings; waves like the reference: lancers and bats -> aerial dancers -> a bat
	# swarm while the armoured brute charges -> a final mix
	b.chandeliers = [[Rect2(230, 360, 160, 14), 0.0], [Rect2(890, 360, 160, 14), 0.0], [Rect2(565, 220, 150, 14), 110.0]]
	b.waves = [[[["lancer", "L", 0.0], ["lancer", "R", 0.4], ["bat", "AC", 2.5]],
		[["dancer", "AL", 0.0], ["dancer", "AR", 1.5]],
		[["brute", "C", 0.0], ["bat", "AL", 1.0], ["bat", "AR", 1.6], ["bat", "AC", 2.4]],
		[["brute", "L", 0.0], ["dancer", "AR", 1.5], ["lancer", "R", 3.0]]]]
	b.win_text = "ENCORE!"
	b.fight_title = "THE OPERA"
	b.intro_lines = ["The masked villain's opera: fight it in the air.", "Walls, chandeliers, pogo (S+J), dive (S+K). The brute's front is armoured."]
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
	_current = _final_boss
	var b := _arena("dark")
	b.caged_heroes = true
	# a flat stage for a duel on foot, lit by a few lanterns
	b.lamps.assign([Vector2(150, 400), Vector2(470, 330), Vector2(810, 330), Vector2(1130, 400)])
	b.waves = [[[["narrator", "BALCONY", 0.0]]]]
	b.boss_name = "THE NARRATOR"
	b.fight_title = "THE NARRATOR"
	b.boss_hp_scale = 1.3
	b.narrator_line = "LET ME WRITE YOUR LAST PAGE!"
	b.win_text = ""
	b.intro_lines = ["The Narrator. The one who guided you all along.", "A duel: parry his gold lunges and dives, dodge the red quill and whirl."]
	_launch(b)
	comms.say("I wrote every page of you, hero. Even this one.", "narrator_evil", 2.0)
	b.finished.connect(func(_result: String) -> void:
		_retire(b)
		_finale(b.hero_pos - Vector2(b._cam, 70.0)))


## The player drags the brightness to 100%: sunlight, the ending, the book closes.
func _finale(hero := Vector2(640, 520)) -> void:
	main._set_state("cutscene")
	comms.say("Reader... you wouldn't.", "narrator_evil", 1.0)
	var f := BrightnessFinale.new()
	f.hero = hero
	main.add_child(f)
	f.finished.connect(func() -> void:
		_free_stale()
		main._play_cutscene("ending_editions", _the_end))


## The true ending: a THE END card (testers were told to play until they see it), then the score.
func _the_end() -> void:
	main._set_state("cutscene")
	comms.clear()
	var card := NoticeCard.new()
	card.mode = "end"
	main._overlay = card
	main._task_layer.add_child(card)
	card.done.connect(func() -> void:
		main._overlay = null
		main._final_screen(true))


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
	var run := _run
	var w := EditionWipe.new()
	w.title = title
	main.add_child(w)
	w.covered.connect(func() -> void:
		if run != _run:
			return
		_free_stale()
		next.call())


# --- helpers -------------------------------------------------------------------------------

func _later(secs: float, f: Callable) -> void:
	var run := _run
	var t := get_tree().create_timer(secs, false)
	t.timeout.connect(func() -> void:
		if run == _run:
			f.call())


## Quit to menu: everything of this run goes (its timers, the frozen scene, the overlays, the filter).
func reset() -> void:
	_run += 1
	act = ""
	_current = Callable()
	_free_stale()
	comms.clear()
	comms.dead = false
	fx.set_edition("2k")
	_set_audio("2k")
	for c in main.get_children():
		if c is EditionWipe or c is SettingsTwist or c is BrightnessFinale:
			c.queue_free()


## Pause menu RESTART during a fight: the same fight from its start. False if no fight is on.
func restart_fight() -> bool:
	if not _current.is_valid() or main.state != "boss":
		return false
	if main._overlay != null and is_instance_valid(main._overlay):
		main._overlay.queue_free()
	main._overlay = null
	_free_stale()
	comms.clear()
	_current.call()
	return true


## The cheap edition sounds cheap: muffled and crushed. The others sound clean.
func _set_audio(edition: String) -> void:
	var bus := AudioServer.get_bus_index("Master")
	while AudioServer.get_bus_effect_count(bus) > 0:
		AudioServer.remove_bus_effect(bus, 0)
	if edition == "240p":
		var lp := AudioEffectLowPassFilter.new()
		lp.cutoff_hz = 3600.0
		AudioServer.add_bus_effect(bus, lp)
		var crush := AudioEffectDistortion.new()
		crush.mode = AudioEffectDistortion.MODE_LOFI
		crush.drive = 0.25
		crush.post_gain = -3.0
		AudioServer.add_bus_effect(bus, crush)
	MusicDirector.ensure_limiter() # always last on the master bus
