class_name MainMenu
extends Control
## Animated comic cover main menu for Glitched Out:
## Big logo, looming masked villain, 4 hero busts, a "NOW IN 240p" badge, comic buttons.

const FONT_TITLE := preload("res://assets/fonts/Bangers-Regular.ttf")
const FONT_BODY := preload("res://assets/fonts/ComicNeue-Bold.ttf")
const SFX_CLICK := preload("res://assets/audio/click.wav")

const INK := Color("18151d")
const PAPER := Color("fff3d1")
const GOLD := Color("ffd23f")
const RED := Color("e63946")

const TEX_GLOW := preload("res://assets/art/radial_glow.png")
var _help_modal: Control
var _credits_modal: Control
var _sfx_player: AudioStreamPlayer
var _time := 0.0

const HERO_NAMES := ["PULP", "NOIR", "NINJA", "SPACE"]


func _ready() -> void:
	custom_minimum_size = Vector2(1280, 720)
	
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.stream = SFX_CLICK
	_sfx_player.bus = "Master"
	add_child(_sfx_player)

	# Buttons Container on the right
	var btn_box := VBoxContainer.new()
	btn_box.position = Vector2(860, 420)
	btn_box.custom_minimum_size = Vector2(340, 240)
	btn_box.add_theme_constant_override("separation", 14)
	add_child(btn_box)

	# Buttons
	var btn_start := _create_button("START READING ▶", GOLD)
	btn_start.custom_minimum_size = Vector2(340, 54)
	btn_start.add_theme_font_size_override("font_size", 26)
	btn_start.pressed.connect(_on_start_pressed)
	btn_box.add_child(btn_start)

	var btn_help := _create_button("HOW TO PLAY", Color("2bb3c0"))
	btn_help.custom_minimum_size = Vector2(340, 46)
	btn_help.add_theme_font_size_override("font_size", 20)
	btn_help.pressed.connect(func() -> void: _help_modal.visible = true)
	btn_box.add_child(btn_help)

	var btn_credits := _create_button("CREDITS", Color("f4e8c1"))
	btn_credits.custom_minimum_size = Vector2(340, 46)
	btn_credits.add_theme_font_size_override("font_size", 20)
	btn_credits.pressed.connect(func() -> void: _credits_modal.visible = true)
	btn_box.add_child(btn_credits)

	# Modals
	_build_help_modal()
	_build_credits_modal()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _play_click() -> void:
	if _sfx_player:
		_sfx_player.play()


func _draw() -> void:
	var sz := get_viewport_rect().size

	# 1. Base Vintage Comic Paper
	draw_rect(Rect2(Vector2.ZERO, sz), Color("fbf3db"))

	# Comic Halftone Background
	ComicArt.halftone(self, sz, Color(0, 0, 0, 0.08), 24.0, 3.5, Vector2(1, 1))

	# Comic Outer Frame Border
	draw_rect(Rect2(0, 0, sz.x, sz.y), INK, false, 8.0)

	# 2. Comic Top Masthead / Issue Banner
	draw_rect(Rect2(8, 8, sz.x - 16, 32), INK)
	draw_string(FONT_TITLE, Vector2(24, 30), "ISSUE #1 • SPECIAL EDITION", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, GOLD)
	draw_string(FONT_TITLE, Vector2(sz.x * 0.5 - 120, 30), "TGC GAME JAM 100-HOUR SHOWCASE", HORIZONTAL_ALIGNMENT_CENTER, -1, 16, PAPER)
	draw_string(FONT_TITLE, Vector2(sz.x - 140, 30), "PRICE: 25¢", HORIZONTAL_ALIGNMENT_RIGHT, 120, 16, GOLD)

	# Comics Code Authority Stamp (Top Left)
	var stamp_rect := Rect2(Vector2(32, 54), Vector2(56, 68))
	draw_rect(stamp_rect, PAPER)
	draw_rect(stamp_rect, INK, false, 2.5)
	draw_string(FONT_TITLE, Vector2(36, 72), "APPROVED", HORIZONTAL_ALIGNMENT_CENTER, 48, 11, INK)
	draw_string(FONT_BODY, Vector2(36, 92), "BY THE", HORIZONTAL_ALIGNMENT_CENTER, 48, 10, INK)
	draw_string(FONT_TITLE, Vector2(36, 112), "COMICS CODE", HORIZONTAL_ALIGNMENT_CENTER, 48, 10, RED)

	# 3. Looming Masked Villain (centre background): the painted villain in a purple glow
	var villain_y := 275.0 + sin(_time * 1.8) * 6.0
	var villain_pos := Vector2(680, villain_y)
	ComicArt.burst(self, sz, Vector2(700, 330), Color(0.55, 0.3, 0.75, 0.0), Color(0.55, 0.3, 0.75, 0.14), 20, _time * 0.05)
	draw_texture_rect(TEX_GLOW, Rect2(Vector2(700, 380) - Vector2(330, 330), Vector2(660, 660)), false, Color(0.45, 0.1, 0.6, 0.45))
	if not Sprites.draw(self, "masked_villain", Vector2(705, 712 + sin(_time * 1.8) * 5.0), 600.0, -1.0, Color(0.92, 0.85, 1.0)):
		ComicArt.disc(self, villain_pos, 160.0, Color(0.18, 0.04, 0.22, 0.35), 0.0)
		ComicArt.narrator(self, villain_pos, 1.75, 0.0, "grin", _time)

	# Villain speech / whisper bubble
	var speech_c := Vector2(990, 262) + Vector2(0, sin(_time * 1.8) * 5.0)
	var speech_rect := Rect2(speech_c - Vector2(100, 24), Vector2(200, 48))
	draw_rect(Rect2(speech_rect.position + Vector2(3, 3), speech_rect.size), Color(0, 0, 0, 0.35))
	draw_rect(speech_rect, PAPER)
	draw_rect(speech_rect, INK, false, 2.5)
	var tail := PackedVector2Array([speech_c + Vector2(-100, -10), speech_c + Vector2(-136, -16), speech_c + Vector2(-100, 8)])
	draw_colored_polygon(tail, PAPER)
	draw_polyline(tail, INK, 2.5)
	draw_string(FONT_TITLE, speech_c + Vector2(-90, 7), "THE LIGHT IS MINE...", HORIZONTAL_ALIGNMENT_CENTER, 180, 16, RED)

	# 4. Big GLITCHED OUT Logo
	var logo_pos := Vector2(460, 130)
	# the title glitches now and then: cyan and magenta ghosts jump apart for a moment
	var burst := fposmod(_time, 3.2) < 0.18
	var split := (10.0 + 6.0 * sin(_time * 90.0)) if burst else 3.0
	var lw := FONT_TITLE.get_string_size("GLITCHED OUT", HORIZONTAL_ALIGNMENT_LEFT, -1, 82).x
	var base := logo_pos + Vector2(-lw * 0.5, 82 * 0.33)
	draw_string(FONT_TITLE, base + Vector2(-split, 0), "GLITCHED OUT", HORIZONTAL_ALIGNMENT_LEFT, -1, 82, Color(0.2, 1.0, 1.0, 0.8))
	draw_string(FONT_TITLE, base + Vector2(split, 2), "GLITCHED OUT", HORIZONTAL_ALIGNMENT_LEFT, -1, 82, Color(1.0, 0.2, 0.6, 0.8))
	ComicArt.shout(self, "GLITCHED OUT", logo_pos + (Vector2(randf_range(-4, 4), 0) if burst else Vector2.ZERO), 82, GOLD, 14, -0.02, 1.0)

	# Subtitle ribbon
	var sub_pts := PackedVector2Array([
		Vector2(140, 172),
		Vector2(780, 172),
		Vector2(770, 206),
		Vector2(130, 206)
	])
	draw_colored_polygon(sub_pts, RED)
	draw_polyline(PackedVector2Array([sub_pts[0], sub_pts[1], sub_pts[2], sub_pts[3], sub_pts[0]]), INK, 3.0)
	draw_string(FONT_TITLE, Vector2(150, 196), "✦ THE EDITIONS: ONE STORY, THREE RESOLUTIONS ✦", HORIZONTAL_ALIGNMENT_CENTER, 610, 20, PAPER)

	# 5. A "NOW IN 240p" badge (the editions joke, upper right)
	var bomb_pos := Vector2(1040, 240)
	
	# Comic burst tag over bomb
	var bomb_badge_pos := bomb_pos + Vector2(0, -78)
	var b_pts := PackedVector2Array()
	for k in 12:
		var a := k / 12.0 * TAU
		var r: float = 46.0 if k % 2 == 0 else 32.0
		b_pts.append(bomb_badge_pos + Vector2(cos(a) * r * 1.5, sin(a) * r))
	b_pts.append(b_pts[0])
	draw_colored_polygon(b_pts, GOLD)
	draw_polyline(b_pts, INK, 2.5)
	draw_string(FONT_TITLE, bomb_badge_pos + Vector2(-60, 6), "NOW IN 240p!", HORIZONTAL_ALIGNMENT_CENTER, 120, 14, INK)

	# 6. The pulp hero in the foreground, light blade ready (the four busts if the art is missing)
	draw_texture_rect(TEX_GLOW, Rect2(Vector2(250, 520) - Vector2(260, 260), Vector2(520, 520)), false, Color(1, 0.85, 0.45, 0.55))
	if Sprites.draw(self, "hero_idle", Vector2(250, 716), 470.0, 1.0, Color.WHITE, 1.0 + sin(_time * 2.2) * 0.008):
		var tag := Rect2(Vector2(96, 252), Vector2(300, 30))
		draw_rect(Rect2(tag.position + Vector2(3, 3), tag.size), Color(0, 0, 0, 0.3))
		draw_rect(tag, RED)
		draw_rect(tag, INK, false, 2.0)
		draw_string(FONT_TITLE, tag.position + Vector2(0, 21), "THE LAST HERO STANDING!", HORIZONTAL_ALIGNMENT_CENTER, tag.size.x, 18, PAPER)
		return
	var h_panel := Rect2(Vector2(40, 465), Vector2(740, 215))
	draw_rect(Rect2(h_panel.position + Vector2(4, 4), h_panel.size), Color(0, 0, 0, 0.25))
	draw_rect(h_panel, Color(1, 0.98, 0.93, 0.95))
	draw_rect(h_panel, INK, false, 4.0)
	var h_tag := Rect2(h_panel.position + Vector2(16, -15), Vector2(240, 28))
	draw_rect(h_tag, RED)
	draw_rect(h_tag, INK, false, 2.0)
	draw_string(FONT_TITLE, h_tag.position + Vector2(12, 19), "✦ 4 SUPERHEROES MUST UNITE! ✦", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, PAPER)
	for i in 4:
		var hc := Vector2(130.0 + i * 170.0, 565)
		ComicArt.disc(self, hc, 56.0, INK, 0.0)
		ComicArt.disc(self, hc, 52.0, Color("ffe680"), 0.0)
		ComicArt.hero_bust(self, i, hc, 0.72, "determined", _time)
		var pill_rect := Rect2(Vector2(hc.x - 48, hc.y + 54), Vector2(96, 22))
		draw_rect(pill_rect, INK)
		draw_string(FONT_TITLE, Vector2(hc.x - 46, hc.y + 70), HERO_NAMES[i], HORIZONTAL_ALIGNMENT_CENTER, 92, 14, GOLD)


func _create_button(text: String, bg_color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_override("font", FONT_TITLE)
	
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_width_bottom = 4
	sb.border_width_left = 4
	sb.border_width_right = 4
	sb.border_width_top = 4
	sb.border_color = INK
	sb.shadow_size = 5
	sb.shadow_offset = Vector2(4, 4)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	btn.add_theme_stylebox_override("normal", sb)

	var sb_hover := sb.duplicate() as StyleBoxFlat
	sb_hover.bg_color = bg_color.lightened(0.2)
	sb_hover.shadow_offset = Vector2(6, 6)
	btn.add_theme_stylebox_override("hover", sb_hover)

	btn.add_theme_color_override("font_color", INK)
	btn.add_theme_color_override("font_hover_color", INK)
	btn.pressed.connect(_play_click)
	return btn


func _build_help_modal() -> void:
	_help_modal = Control.new()
	_help_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	_help_modal.visible = false
	add_child(_help_modal)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.7)
	_help_modal.add_child(dim)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 480)
	panel.position = Vector2((1280 - 620) * 0.5, (720 - 480) * 0.5)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("fff9e6")
	sb.border_width_bottom = 5
	sb.border_width_left = 5
	sb.border_width_right = 5
	sb.border_width_top = 5
	sb.border_color = INK
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(6, 6)
	sb.content_margin_left = 30
	sb.content_margin_right = 30
	sb.content_margin_top = 25
	sb.content_margin_bottom = 25
	panel.add_theme_stylebox_override("panel", sb)
	_help_modal.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "HOW TO READ & PLAY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", FONT_TITLE)
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", INK)
	vbox.add_child(title)

	var rules := [
		"1. THE STORY: a masked villain drained the light. Without light, the world loses its detail.",
		"2. YOUR GUIDE: the Narrator talks to you on your comms machine. Listen to him.",
		"3. FIRST EDITION: WASD or the arrows move, your torch lights the dark. [Z] at a console starts a task, [ESC] leaves it. Fix sabotage in time. Vampires: REVEAL or KILL?",
		"4. LATER EDITIONS: [J] attack, [Z]/[SPACE] jump (on a wall: wall jump), [K] dash / roll, [S]+[J] in the air: pogo, [S]+[K]: dive, [L] PARRY a gold flash (hold L: Light Blade; 720p: COUNTER on red eyes), [F] heal.",
		"5. [P] pauses. [M] shows the map in the first edition.",
		"6. Sometimes the story needs YOU, the reader. Keep your mouse close.",
	]

	for r in rules:
		var lbl := Label.new()
		lbl.text = r
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_override("font", FONT_BODY)
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.add_theme_color_override("font_color", INK)
		vbox.add_child(lbl)

	var btn_close := _create_button("GOT IT!", GOLD)
	btn_close.custom_minimum_size = Vector2(160, 42)
	btn_close.pressed.connect(func() -> void: _help_modal.visible = false)
	vbox.add_child(btn_close)


func _build_credits_modal() -> void:
	_credits_modal = Control.new()
	_credits_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	_credits_modal.visible = false
	add_child(_credits_modal)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.7)
	_credits_modal.add_child(dim)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 400)
	panel.position = Vector2((1280 - 560) * 0.5, (720 - 400) * 0.5)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("fff9e6")
	sb.border_width_bottom = 5
	sb.border_width_left = 5
	sb.border_width_right = 5
	sb.border_width_top = 5
	sb.border_color = INK
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(6, 6)
	sb.content_margin_left = 30
	sb.content_margin_right = 30
	sb.content_margin_top = 25
	sb.content_margin_bottom = 25
	panel.add_theme_stylebox_override("panel", sb)
	_credits_modal.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "CREDITS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", FONT_TITLE)
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", INK)
	vbox.add_child(title)

	var text := Label.new()
	text.text = "GLITCHED OUT\nCreated for TGC Game Jam (100 Hours)\n\nStory, design & team lead: Sankeerth Nara (team Game it)\nEngine: Godot 4.7 (Compatibility Renderer)\nFonts: Bangers, Comic Neue (SIL OFL)\nArt: drawn in code + AI-generated backgrounds and sprites (Antigravity)\nMusic & sounds: synthesised by our own scripts (CC0)\nAI tools used (disclosed): Claude Code, Antigravity, ChatGPT/Codex\n\nFull attribution: CREDITS.md and docs/AI_USAGE.md."
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_override("font", FONT_BODY)
	text.add_theme_font_size_override("font_size", 16)
	text.add_theme_color_override("font_color", INK)
	vbox.add_child(text)

	var btn_close := _create_button("BACK", GOLD)
	btn_close.custom_minimum_size = Vector2(160, 42)
	btn_close.pressed.connect(func() -> void: _credits_modal.visible = false)
	vbox.add_child(btn_close)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_Z, KEY_SPACE, KEY_ENTER]:
			_on_start_pressed()
			get_viewport().set_input_as_handled()


func _on_start_pressed() -> void:
	var eb := get_node_or_null("/root/EventBus")
	if eb:
		eb.request_start_game.emit()
	queue_free()
