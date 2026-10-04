class_name MainMenu
extends Control
## Animated comic cover main menu for Mirror Page:
## Big logo, looming masked villain, 4 hero busts, ticking 17:00 bomb, comic buttons.

const FONT_TITLE := preload("res://assets/fonts/Bangers-Regular.ttf")
const FONT_BODY := preload("res://assets/fonts/ComicNeue-Bold.ttf")
const SFX_CLICK := preload("res://assets/audio/click.wav")

const INK := Color("18151d")
const PAPER := Color("fff3d1")
const GOLD := Color("ffd23f")
const RED := Color("e63946")

var _help_modal: Control
var _credits_modal: Control
var _sfx_player: AudioStreamPlayer
var _time := 0.0

const HERO_NAMES := ["PULP", "NOIR", "NINJA", "SPACE"]


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
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
	var sz := size

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

	# 3. Looming Masked Villain (Center-Top background)
	var villain_y := 275.0 + sin(_time * 1.8) * 6.0
	var villain_pos := Vector2(680, villain_y)
	
	# Ominous aura burst behind villain
	ComicArt.burst(self, Vector2(400, 300), villain_pos, Color(0.2, 0.05, 0.25, 0.35), Color(0.05, 0.02, 0.08, 0.0), 16, _time * 0.15)
	# Draw Masked Villain: mask_off = 0.0 (masked!), mood = "grin"
	ComicArt.narrator(self, villain_pos, 1.75, 0.0, "grin", _time)

	# Villain speech / whisper bubble
	var speech_c := villain_pos + Vector2(170, -70)
	var speech_rect := Rect2(speech_c - Vector2(100, 24), Vector2(200, 48))
	draw_rect(Rect2(speech_rect.position + Vector2(3, 3), speech_rect.size), Color(0, 0, 0, 0.35))
	draw_rect(speech_rect, PAPER)
	draw_rect(speech_rect, INK, false, 2.5)
	draw_colored_polygon(PackedVector2Array([speech_c + Vector2(-60, 24), speech_c + Vector2(-75, 38), speech_c + Vector2(-45, 24)]), PAPER)
	draw_polyline(PackedVector2Array([speech_c + Vector2(-60, 24), speech_c + Vector2(-75, 38), speech_c + Vector2(-45, 24)]), INK, 2.5)
	draw_string(FONT_TITLE, speech_c + Vector2(-90, 7), "THE CLOCK IS TICKING...", HORIZONTAL_ALIGNMENT_CENTER, 180, 16, RED)

	# 4. Big MIRROR PAGE Logo
	var logo_pos := Vector2(460, 130)
	ComicArt.shout(self, "MIRROR PAGE", logo_pos, 82, GOLD, 14, -0.02, 1.0)

	# Subtitle ribbon
	var sub_pts := PackedVector2Array([
		Vector2(140, 172),
		Vector2(780, 172),
		Vector2(770, 206),
		Vector2(130, 206)
	])
	draw_colored_polygon(sub_pts, RED)
	draw_polyline(PackedVector2Array([sub_pts[0], sub_pts[1], sub_pts[2], sub_pts[3], sub_pts[0]]), INK, 3.0)
	draw_string(FONT_TITLE, Vector2(150, 196), "✦ A DARK COMIC RACE AGAINST THE BOMB! ✦", HORIZONTAL_ALIGNMENT_CENTER, 610, 20, PAPER)

	# 5. Ticking Bomb (Upper-Right) showing 17:00
	var bomb_pos := Vector2(1040, 240)
	var bomb_urgent := (int(_time * 3.0) % 2 == 0)
	ComicArt.bomb(self, bomb_pos, 54.0, 1020.0, _time, bomb_urgent)
	
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
	draw_string(FONT_TITLE, bomb_badge_pos + Vector2(-60, 6), "17:00 ZERO HOUR!", HORIZONTAL_ALIGNMENT_CENTER, 120, 14, INK)

	# 6. Four Hero Busts (Bottom-Left Spread)
	var h_panel := Rect2(Vector2(40, 465), Vector2(740, 215))
	draw_rect(Rect2(h_panel.position + Vector2(4, 4), h_panel.size), Color(0, 0, 0, 0.25))
	draw_rect(h_panel, Color(1, 0.98, 0.93, 0.95))
	draw_rect(h_panel, INK, false, 4.0)

	# Hero panel banner tag
	var h_tag := Rect2(h_panel.position + Vector2(16, -15), Vector2(240, 28))
	draw_rect(h_tag, RED)
	draw_rect(h_tag, INK, false, 2.0)
	draw_string(FONT_TITLE, h_tag.position + Vector2(12, 19), "✦ 4 SUPERHEROES MUST UNITE! ✦", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, PAPER)

	var h_start_x := 130.0
	var h_spacing := 170.0
	for i in 4:
		var hc := Vector2(h_start_x + i * h_spacing, 565)

		# Portrait circle framing
		var circle_r := 52.0
		ComicArt.disc(self, hc, circle_r + 4.0, INK, 0.0)
		ComicArt.disc(self, hc, circle_r, Color("ffe680"), 0.0)
		ComicArt.burst(self, Vector2(circle_r * 2, circle_r * 2), hc, Color("ffe680"), Color("fff5b8"), 10, _time * 0.2)
		ComicArt.disc(self, hc, circle_r, Color(0, 0, 0, 0), 3.5)

		# Hero bust
		ComicArt.hero_bust(self, i, hc, 0.72, "determined", _time)

		# Name label pill
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
		"1. THE BOMB: 17 minutes on the clock for the whole run. Finish a level to win a key; 4 keys open the bomb room.",
		"2. MOVE with arrows / WASD. It is dark: only your torch lights the way. [M] opens the map.",
		"3. TASKS: walk to a console and press [Z]. Finish every task to fill the progress bar. [ESC] leaves a task.",
		"4. SABOTAGE: the villain breaks things. Run to the fix console before the timer ends or lose hearts.",
		"5. VAMPIRES: hold your torch on one, then REVEAL or KILL. One is your friend, one is the villain. Pure chance!",
		"6. Out of hearts? Back to the start of the level, but the bomb keeps its time.",
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
	text.text = "MIRROR PAGE\nCreated for TGC Game Jam (100 Hours)\n\nDesigner & Team Lead: Sankeerth Nara\nEngine: Godot 4.7 (Compatibility Renderer)\nFonts: Bangers (SIL OFL), Comic Neue (SIL OFL)\nAudio: Procedural CC0 synthesized sounds\n\nFull attribution logged in CREDITS.md."
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


func _on_start_pressed() -> void:
	var eb := get_node_or_null("/root/EventBus")
	if eb:
		eb.request_start_game.emit()
	queue_free()
