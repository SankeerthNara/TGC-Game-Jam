class_name StoryScenes
extends RefCounted
## The script of every story cutscene: pages, panel layout (fractions of the page), panel art keys,
## captions, speech bubbles and sound effects, each with the time it appears on its page.


static func pages(kind: String) -> Array:
	match kind:
		"opening":
			return _opening()
		"bomb_room":
			return _bomb_room()
		"earth_blast":
			return _earth_blast()
	return []


static func _p(key: String, x: float, y: float, w: float, h: float, at := 0.0, enter := "fade") -> Dictionary:
	return {"key": key, "rect": Rect2(x, y, w, h), "at": at, "enter": enter}


static func _cap(text: String, panel: int, at: float, where := "tl", width := 440.0) -> Dictionary:
	return {"type": "caption", "text": text, "panel": panel, "at": at, "at_pos": where, "width": width}


static func _say(text: String, panel: int, at: float, pos: Vector2, tail: Vector2, who := "", width := 300.0, shout := false) -> Dictionary:
	return {"type": "bubble", "text": text, "panel": panel, "at": at, "pos": pos, "tail": tail, "who": who, "width": width, "shout": shout}


static func _sfx(text: String, panel: int, at: float, pos: Vector2, size := 64, color := Color("ffd23f"), rot := -0.08) -> Dictionary:
	return {"text": text, "panel": panel, "at": at, "pos": pos, "size": size, "color": color, "rot": rot}


static func _opening() -> Array:
	return [
		{"panels": [
			_p("earth_peace", 0, 0, 1, 0.6, 0.0, "fade"),
			_p("hero_portrait_0", 0, 0.6, 0.25, 0.4, 1.4, "up"),
			_p("hero_portrait_1", 0.25, 0.6, 0.25, 0.4, 1.7, "up"),
			_p("hero_portrait_2", 0.5, 0.6, 0.25, 0.4, 2.0, "up"),
			_p("hero_portrait_3", 0.75, 0.6, 0.25, 0.4, 2.3, "up")],
		 "text": [
			_cap("Once upon a time, the Earth lived in peace...", 0, 0.3),
			_cap("...guarded by four superheroes.", 0, 2.6, "br", 360.0)],
		 "sfx": [
			_sfx("PULP HERO", 1, 1.6, Vector2(0.5, 0.9), 30, Color("ffd23f"), 0.0),
			_sfx("NOIR DETECTIVE", 2, 1.9, Vector2(0.5, 0.9), 30, Color("ffd23f"), 0.0),
			_sfx("NINJA", 3, 2.2, Vector2(0.5, 0.9), 30, Color("ffd23f"), 0.0),
			_sfx("SPACE HERO", 4, 2.5, Vector2(0.5, 0.9), 30, Color("ffd23f"), 0.0)],
		 "hold": 1.8},
		{"panels": [
			_p("villain_rise", 0, 0, 0.56, 1, 0.0, "left"),
			_p("earth_darkening", 0.56, 0, 0.44, 0.5, 1.6, "right"),
			_p("heroes_shock", 0.56, 0.5, 0.44, 0.5, 3.2, "pop")],
		 "text": [
			_cap("Until a masked villain came.", 0, 0.2, "tl", 330.0),
			_say("Peace? How BORING.", 0, 1.0, Vector2(0.62, 0.2), Vector2(0.5, 0.4), "narrator", 250.0),
			_cap("He covered the world in darkness.", 1, 2.0, "bl", 330.0)],
		 "sfx": [
			_sfx("HA HA HA!", 0, 0.8, Vector2(0.3, 0.55), 58, Color("c77dff"), -0.15),
			_sfx("SHHRRAAK!", 1, 2.2, Vector2(0.7, 0.2), 46, Color("c77dff"), 0.1),
			_sfx("?!", 2, 3.4, Vector2(0.5, 0.18), 70, Color("e63946"), 0.0)],
		 "hold": 1.6},
		{"panels": [
			_p("bomb_closeup", 0, 0, 1, 0.5, 0.0, "pop"),
			_p("door_locked", 0, 0.5, 0.45, 0.5, 1.8, "left"),
			_p("hero_ready", 0.45, 0.5, 0.55, 0.5, 3.4, "right")],
		 "text": [
			_say("And in 17 minutes... your precious Earth goes BOOM!", 0, 0.4, Vector2(0.2, 0.3), Vector2(0.05, 0.05), "narrator", 280.0),
			_cap("His bomb hides in a room sealed by four locks.", 1, 2.0, "tl", 300.0),
			_cap("One key waits in each hero's comic.", 1, 2.8, "bl", 300.0),
			_say("Then we find the keys. One comic at a time!", 2, 3.8, Vector2(0.75, 0.25), Vector2(0.52, 0.42), "hero", 270.0)],
		 "sfx": [
			_sfx("TICK... TICK...", 0, 0.9, Vector2(0.8, 0.75), 50, Color("ff4d4d"), 0.08)],
		 "hold": 2.0},
	]


static func _bomb_room() -> Array:
	return [
		{"panels": [_p("door_unlock", 0, 0, 1, 1, 0.0, "fade")],
		 "text": [_cap("Four keys. Four comics. The bomb room opens...", 0, 0.2, "tl", 420.0)],
		 "sfx": [
			_sfx("CLICK!", 0, 0.45, Vector2(0.28, 0.3), 46),
			_sfx("CLICK!", 0, 0.9, Vector2(0.72, 0.3), 46),
			_sfx("CLICK!", 0, 1.35, Vector2(0.28, 0.75), 46),
			_sfx("CLICK!", 0, 1.8, Vector2(0.72, 0.75), 46),
			_sfx("KRRRNNK!", 0, 2.2, Vector2(0.5, 0.92), 60, Color("ffb703"), 0.0)],
		 "hold": 1.0},
		{"panels": [
			_p("bomb_room_bomb", 0, 0, 0.5, 1, 0.0, "left"),
			_p("masked_closeup", 0.5, 0, 0.5, 0.5, 0.8, "right"),
			_p("unmask", 0.5, 0.5, 0.5, 0.5, 2.6, "pop")],
		 "text": [
			_say("So you made it. Clever little heroes.", 1, 1.2, Vector2(0.3, 0.2), Vector2(0.45, 0.35), "narrator", 250.0)],
		 "sfx": [_sfx("RIIIP!", 2, 3.3, Vector2(0.75, 0.25), 60, Color("e63946"), 0.12)],
		 "hold": 1.4},
		{"panels": [
			_p("narrator_reveal", 0, 0, 1, 0.48, 0.0, "pop"),
			_p("grab", 0, 0.48, 0.55, 0.52, 2.6, "left"),
			_p("caged", 0.55, 0.48, 0.45, 0.52, 4.0, "right")],
		 "text": [
			_say("...the NARRATOR?!", 0, 0.3, Vector2(0.15, 0.3), Vector2(0.02, 0.6), "hero", 220.0, true),
			_say("Surprised? I wrote every page of your little story.", 0, 1.0, Vector2(0.82, 0.3), Vector2(0.6, 0.45), "narrator", 280.0),
			_say("HELP!", 2, 4.5, Vector2(0.25, 0.18), Vector2(0.45, 0.35), "hero", 120.0, true),
			_say("Come and get him, heroes. The bomb is still ticking.", 1, 5.0, Vector2(0.7, 0.2), Vector2(0.88, 0.45), "narrator", 280.0),
			_cap("The first hero is captured!", 2, 4.2, "bl", 300.0)],
		 "sfx": [_sfx("GRAB!", 1, 3.0, Vector2(0.3, 0.82), 64, Color("e63946"), -0.12)],
		 "hold": 2.2},
	]


static func _earth_blast() -> Array:
	return [
		{"panels": [
			_p("bomb_zero", 0, 0, 1, 0.55, 0.0, "pop"),
			_p("heroes_too_late", 0, 0.55, 1, 0.45, 1.0, "up")],
		 "text": [_cap("The heroes ran for the bomb room...", 1, 1.3, "tl", 380.0)],
		 "sfx": [
			_sfx("BEEP!", 0, 0.2, Vector2(0.18, 0.3), 52, Color("ff4d4d"), -0.15),
			_sfx("BEEP!", 0, 0.7, Vector2(0.82, 0.3), 52, Color("ff4d4d"), 0.15),
			_sfx("BEEEEEP!", 0, 1.4, Vector2(0.5, 0.88), 60, Color("ff4d4d"), 0.0)],
		 "hold": 0.8},
		{"panels": [_p("boom", 0, 0, 1, 1, 0.0, "fade")],
		 "text": [_cap("...but they were too late. The Earth is gone.", 0, 2.4, "bl", 460.0)],
		 "sfx": [_sfx("KA-BOOOOM!", 0, 0.35, Vector2(0.5, 0.35), 140, Color("ffb703"), -0.06)],
		 "hold": 2.5},
	]
