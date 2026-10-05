extends Node
## Frame-set detection of HeroAnimator with fake sets put in the sprite cache (not part of the game):
## the agreed names (hero_run_1..12, hero_jump_1..6 arc, upslash, runstart, turn, land, px punch1..3...)
## are found and counted, the jump arc follows vertical speed, transitions play once, attacks follow
## their progress, and missing sets fall back to today's frames.

var fails := 0


func ok(c: bool, what: String) -> void:
	print(("PASS " if c else "FAIL ") + what)
	if not c:
		fails += 1


func fake(prefix: String, set_name: String, n: int) -> void:
	var tex: Texture2D = Sprites.get_tex("hero_idle")
	for i in range(1, n + 1):
		Sprites._cache["%s_%s_%d" % [prefix, set_name, i]] = tex


func _ready() -> void:
	fake("hero", "run", 12)
	fake("hero", "jump", 6)
	fake("hero", "upslash", 3)
	fake("hero", "runstart", 3)
	fake("hero", "turn", 3)
	fake("hero", "land", 2)
	fake("px_hero", "punch2", 3)
	var b := BossFight.new()
	var a: HeroAnimator = b._anim
	ok(a.frames("run").size() == 12, "2K run: 12 frames found (%d)" % a.frames("run").size())
	ok(a.frames("attack_up").size() == 3 and a.frames("attack_up")[0] == "hero_upslash_1", "2K attack_up uses hero_upslash_1..3")
	ok(a.frames("idle").size() == 6 and a.frames("attack1").size() == 3 and a.frames("attack3").size() == 4, "2K delivered sets: idle 6, attack1 3, attack3 4")
	ok(a.frames("blade").size() == 4 and a.frames("ko").size() == 3 and a.frames("attack_down")[0] == "hero_downslash_1", "2K blade 4, ko 3, attack_down uses hero_downslash")
	var none := HeroAnimator.new("no_such_prefix", {"idle": ["hero_idle"], "run": ["hero_run1", "hero_run2"]})
	ok(none.frames("idle") == ["hero_idle"] and none.frames("run") == ["hero_run1", "hero_run2"], "a missing set falls back to the single frames")
	ok(HeroAnimator.swing_frame(3, 0.05) == 0 and HeroAnimator.swing_frame(3, 0.3) == 1 and HeroAnimator.swing_frame(3, 0.8) == 2, "3-frame swing: wind-up, strike in the hit window, recovery")
	ok(HeroAnimator.swing_frame(4, 0.1) == 1 and HeroAnimator.swing_frame(4, 0.4) == 2 and HeroAnimator.swing_frame(4, 0.9) == 3, "4-frame swing: strike frame through the hit window")
	# the jump arc by vertical speed
	var seen := []
	for vy in [-880.0, -600.0, -300.0, 0.0, 400.0, 900.0]:
		a.update(0.1 if vy > -880.0 else 0.001, "jump" if vy < 0.0 else "fall", Vector2(0, vy), 1.0, 360.0, false)
		seen.append(a.key)
	ok(seen == ["hero_jump_1", "hero_jump_2", "hero_jump_3", "hero_jump_4", "hero_jump_5", "hero_jump_6"], "jump arc follows vertical speed: %s" % str(seen))
	# landing plays the land set once, then idle
	a.landed(800.0)
	a.update(0.016, "idle", Vector2.ZERO, 1.0, 360.0, true)
	ok(a.key.begins_with("hero_land_"), "landing plays hero_land (%s)" % a.key)
	for i in 20:
		a.update(0.016, "idle", Vector2.ZERO, 1.0, 360.0, true)
	ok(a.key.begins_with("hero_idle_"), "then back to the idle loop (%s)" % a.key)
	# starting to run plays runstart once, then the run cycle
	a.update(0.016, "run", Vector2(200, 0), 1.0, 360.0, true)
	ok(a.key.begins_with("hero_runstart_"), "run start plays hero_runstart (%s)" % a.key)
	for i in 20:
		a.update(0.016, "run", Vector2(360, 0), 1.0, 360.0, true)
	ok(a.key.begins_with("hero_run_"), "then the run cycle (%s)" % a.key)
	# turning plays the turn set
	a.update(0.016, "run", Vector2(-100, 0), -1.0, 360.0, true)
	ok(a.key.begins_with("hero_turn_"), "turning plays hero_turn (%s)" % a.key)
	# an attack follows its progress: frame 3 of 3 at the end of the swing
	a.start_attack(1)
	a.attack = 0.9
	a.update(0.016, "attack_up", Vector2.ZERO, -1.0, 360.0, true)
	ok(a.key == "hero_upslash_3", "attack frames follow the swing (%s)" % a.key)
	# 720p names
	var g := BrawlerGame.new()
	var p: HeroAnimator = g._anim
	ok(p.frames("run").size() == 10, "720p run: all 10 frames in the loop (%d)" % p.frames("run").size())
	ok(p.frames("attack2").size() == 3 and p.frames("attack2")[0] == "px_hero_punch2_1", "720p attack2 uses px_hero_punch2_1..3")
	ok(p.frames("attack1").size() == 3 and p.frames("attack3").size() == 4 and p.frames("attack1")[0] == "px_hero_punch1_1", "720p punches 3/3/4 via px_hero_punch1..3")
	ok(p.frames("roll").size() == 4 and p.frames("counter").size() == 3 and p.frames("idle").size() == 4, "720p roll 4, counter 3, idle 4")
	b.free()
	g.free()
	print("ANIM SET FAILS: ", fails)
	get_tree().quit()
