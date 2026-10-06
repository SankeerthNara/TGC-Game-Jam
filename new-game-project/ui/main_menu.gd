class_name MainMenu
extends Control
## Animated comic cover main menu for GLITCHED OUT:
## Features high-impact comic cover presentation, looming masked villain,
## glowing Light Blade hero, dynamic chromatic glitch title, comic book trade dress,
## cycling speech balloons, and rich comic buttons.

const FONT_TITLE := preload("res://assets/fonts/Bangers-Regular.ttf")
const FONT_BODY := preload("res://assets/fonts/ComicNeue-Bold.ttf")
const SFX_CLICK := preload("res://assets/audio/click.wav")

const INK := Color("18151d")
const PAPER := Color("fff9e6")
const GOLD := Color("ffd23f")
const RED := Color("e63946")
const CYAN := Color("2bb3c0")
const PURPLE := Color("8338ec")

var _help_modal: Control
var _credits_modal: Control
var _sfx_player: AudioStreamPlayer
var _time := 0.0

var _cover_tex: Texture2D
var _villain_tex: Texture2D
var _hero_tex: Texture2D
var _glow_tex: Texture2D

const HERO_NAMES := ["PULP", "NOIR", "NINJA", "SPACE"]
const HERO_COLORS := [Color("ffd23f"), Color("8d99ae"), Color("f77f00"), Color("ff70a6")]

const VILLAIN_LINES := [
	"Every story has a narrator... but who controls the ink?",
	"Three editions to survive. Beat my lieutenants if you can!",
	"Can you make it all the way from 240p to 2K, hero?",
	"The picture is already glitching. The ink drinks your world!",
]


func _ready() -> void:
	set_deferred("size", Vector2(1280, 720))
	custom_minimum_size = Vector2(1280, 720)

	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.stream = SFX_CLICK
	_sfx_player.bus = "Master"
	add_child(_sfx_player)

	# Load painted assets
	for cp in ["res://assets/art/cover_page.png", "res://assets/editions/book/book_cover.png"]:
		if ResourceLoader.exists(cp):
			_cover_tex = load(cp)
			break
	if ResourceLoader.exists("res://assets/editions/sprites/masked_villain.png"):
		_villain_tex = load("res://assets/editions/sprites/masked_villain.png")
	if ResourceLoader.exists("res://assets/editions/sprites/hero_blade_1.png"):
		_hero_tex = load("res://assets/editions/sprites/hero_blade_1.png")
	elif ResourceLoader.exists("res://assets/editions/portraits/hero.png"):
		_hero_tex = load("res://assets/editions/portraits/hero.png")
	if ResourceLoader.exists("res://assets/art/radial_glow.png"):
		_glow_tex = load("res://assets/art/radial_glow.png")

	# Buttons Container on the right side
	var btn_box := VBoxContainer.new()
	btn_box.position = Vector2(740, 425)
	btn_box.custom_minimum_size = Vector2(440, 240)
	btn_box.add_theme_constant_override("separation", 14)
	add_child(btn_box)

	# Main Start Button
	var btn_start := _create_button("START READING ▶", GOLD, 30)
	btn_start.custom_minimum_size = Vector2(440, 60)
	btn_start.pressed.connect(_on_start_pressed)
	btn_box.add_child(btn_start)

	# Secondary Action Buttons
	var h_actions := HBoxContainer.new()
	h_actions.add_theme_constant_override("separation", 14)
	btn_box.add_child(h_actions)

	var btn_help := _create_button("READER'S GUIDE", CYAN, 22)
	btn_help.custom_minimum_size = Vector2(213, 48)
	btn_help.pressed.connect(func() -> void: _help_modal.visible = true)
	h_actions.add_child(btn_help)

	var btn_credits := _create_button("CREDITS", Color("f4e8c1"), 22)
	btn_credits.custom_minimum_size = Vector2(213, 48)
	btn_credits.pressed.connect(func() -> void: _credits_modal.visible = true)
	h_actions.add_child(btn_credits)

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

	# Comic Halftone Background Texture
	ComicArt.halftone(self, sz, Color(0, 0, 0, 0.07), 24.0, 3.5, Vector2(1, 1))

	# Comic Outer Frame Border
	draw_rect(Rect2(0, 0, sz.x, sz.y), INK, false, 8.0)
	draw_rect(Rect2(6, 6, sz.x - 12, sz.y - 12), INK, false, 2.0)

	# 2. Comic Top Masthead / Issue Banner
	draw_rect(Rect2(8, 8, sz.x - 16, 34), INK)
	draw_string(FONT_TITLE, Vector2(24, 32), "★ INFINIUM COMICS GROUP • ISSUE #1 • SPECIAL COLLECTOR'S EDITION", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, GOLD)
	draw_string(FONT_TITLE, Vector2(sz.x * 0.5 - 110, 32), "TGC GAME JAM 2026 FEATURE SHOWCASE", HORIZONTAL_ALIGNMENT_CENTER, -1, 16, PAPER)
	draw_string(FONT_TITLE, Vector2(sz.x - 140, 32), "PRICE: 25¢", HORIZONTAL_ALIGNMENT_RIGHT, 120, 16, GOLD)

	# 3. Left Side: The Physical Comic Book Showcase
	var cover_rect := Rect2(Vector2(55, 65), Vector2(420, 560))
	# Dynamic hover float
	var float_y := sin(_time * 1.5) * 4.0
	cover_rect.position.y += float_y

	# Deep 3D Drop Shadow behind the book
	draw_rect(Rect2(cover_rect.position + Vector2(14, 14), cover_rect.size), Color(0, 0, 0, 0.45))
	draw_rect(Rect2(cover_rect.position + Vector2(7, 7), cover_rect.size), Color(0.1, 0.05, 0.15, 0.3))

	if _cover_tex != null:
		# Draw the high-res comic cover image
		draw_texture_rect(_cover_tex, cover_rect, false)
		# Comic book outer frame
		draw_rect(cover_rect, INK, false, 5.0)
		# Spine shadow on left edge
		draw_rect(Rect2(cover_rect.position, Vector2(12, cover_rect.size.y)), Color(0, 0, 0, 0.35))
		draw_line(Vector2(cover_rect.position.x + 12, cover_rect.position.y), Vector2(cover_rect.position.x + 12, cover_rect.position.y + cover_rect.size.y), Color(1, 1, 1, 0.25), 1.5)
	else:
		# Fallback stylized comic cover frame if texture loading
		draw_rect(cover_rect, Color("20102b"))
		draw_rect(cover_rect, INK, false, 5.0)

	# Collector Ribbon across bottom of the cover
	var rib_w := cover_rect.size.x
	var rib_h := 36.0
	var rib_pos := Vector2(cover_rect.position.x, cover_rect.position.y + cover_rect.size.y - rib_h)
	draw_rect(Rect2(rib_pos, Vector2(rib_w, rib_h)), INK)
	draw_line(rib_pos, rib_pos + Vector2(rib_w, 0), GOLD, 2.5)
	draw_string(FONT_TITLE, rib_pos + Vector2(0, 24), "✦ 3 EDITIONS: 240P ➔ 720P ➔ 2K ✦", HORIZONTAL_ALIGNMENT_CENTER, int(rib_w), 16, GOLD)

	# 4. Comics Code Authority Stamp (Top Left Corner of Cover)
	var stamp_rect := Rect2(cover_rect.position + Vector2(12, 12), Vector2(58, 68))
	draw_rect(stamp_rect, PAPER)
	draw_rect(stamp_rect, INK, false, 2.5)
	draw_string(FONT_TITLE, stamp_rect.position + Vector2(5, 20), "APPROVED", HORIZONTAL_ALIGNMENT_CENTER, 48, 11, INK)
	draw_string(FONT_BODY, stamp_rect.position + Vector2(5, 36), "BY THE", HORIZONTAL_ALIGNMENT_CENTER, 48, 9, INK)
	draw_string(FONT_TITLE, stamp_rect.position + Vector2(5, 52), "COMICS CODE", HORIZONTAL_ALIGNMENT_CENTER, 48, 9, RED)
	draw_string(FONT_TITLE, stamp_rect.position + Vector2(5, 64), "★", HORIZONTAL_ALIGNMENT_CENTER, 48, 10, GOLD)

	# 5. Center-Right: Towering "GLITCHED OUT" Title Logo
	var logo_center := Vector2(950, 140)
	_draw_glitched_title(logo_center)

	# Subtitle Ribbon
	var sub_w := 640.0
	var sub_h := 34.0
	var sub_pts := PackedVector2Array([
		Vector2(logo_center.x - sub_w * 0.5 - 15, logo_center.y + 40),
		Vector2(logo_center.x + sub_w * 0.5 + 15, logo_center.y + 40),
		Vector2(logo_center.x + sub_w * 0.5 - 5, logo_center.y + 40 + sub_h),
		Vector2(logo_center.x - sub_w * 0.5 - 25, logo_center.y + 40 + sub_h)
	])
	draw_colored_polygon(sub_pts, RED)
	draw_polyline(PackedVector2Array([sub_pts[0], sub_pts[1], sub_pts[2], sub_pts[3], sub_pts[0]]), INK, 3.0)
	draw_string(FONT_TITLE, Vector2(logo_center.x - sub_w * 0.5, logo_center.y + 64), "✦ A REALITY-WARPING COMIC BOOK ADVENTURE ✦", HORIZONTAL_ALIGNMENT_CENTER, int(sub_w), 20, PAPER)

	# 6. Feature Badges (Pills)
	var badge_y := logo_center.y + 88
	# Badge 1: 3 Editions in One
	var b1_rect := Rect2(Vector2(650, badge_y), Vector2(285, 30))
	draw_rect(Rect2(b1_rect.position + Vector2(2, 2), b1_rect.size), Color(0, 0, 0, 0.3))
	draw_rect(b1_rect, GOLD)
	draw_rect(b1_rect, INK, false, 2.5)
	draw_string(FONT_TITLE, b1_rect.position + Vector2(0, 21), "⚡ THREE GRAPHIC EDITIONS IN ONE", HORIZONTAL_ALIGNMENT_CENTER, int(b1_rect.size.x), 15, INK)

	# Badge 2: Real Voice Acting
	var b2_rect := Rect2(Vector2(955, badge_y), Vector2(245, 30))
	draw_rect(Rect2(b2_rect.position + Vector2(2, 2), b2_rect.size), Color(0, 0, 0, 0.3))
	draw_rect(b2_rect, CYAN)
	draw_rect(b2_rect, INK, false, 2.5)
	draw_string(FONT_TITLE, b2_rect.position + Vector2(0, 21), "🎙 FULL SPOKEN VOICE ACTING", HORIZONTAL_ALIGNMENT_CENTER, int(b2_rect.size.x), 15, INK)

	# 7. Masked Villain Speech Balloon
	var speech_c := Vector2(950, 310)
	var speech_w := 540.0
	var speech_h := 66.0
	var speech_rect := Rect2(Vector2(speech_c.x - speech_w * 0.5, speech_c.y - speech_h * 0.5), Vector2(speech_w, speech_h))

	# Speech shadow & body
	draw_rect(Rect2(speech_rect.position + Vector2(4, 4), speech_rect.size), Color(0, 0, 0, 0.3))
	draw_rect(speech_rect, PAPER)
	draw_rect(speech_rect, INK, false, 3.0)

	# Pointer tail
	var tail_pts := PackedVector2Array([
		Vector2(speech_rect.position.x + 80, speech_rect.position.y),
		Vector2(speech_rect.position.x + 40, speech_rect.position.y - 20),
		Vector2(speech_rect.position.x + 105, speech_rect.position.y)
	])
	draw_colored_polygon(tail_pts, PAPER)
	draw_polyline(tail_pts, INK, 3.0)

	# Current villain dialogue line
	var line_idx := int(_time / 4.5) % VILLAIN_LINES.size()
	var cur_line: String = VILLAIN_LINES[line_idx]
	# Speaker tag
	draw_rect(Rect2(Vector2(speech_rect.position.x + 14, speech_rect.position.y - 12), Vector2(110, 22)), INK)
	draw_string(FONT_TITLE, Vector2(speech_rect.position.x + 20, speech_rect.position.y + 4), "THE NARRATOR:", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, GOLD)
	# Quote text
	draw_string(FONT_BODY, Vector2(speech_rect.position.x + 20, speech_rect.position.y + 38), '"%s"' % cur_line, HORIZONTAL_ALIGNMENT_LEFT, int(speech_w - 40), 17, INK)

	# 8. Bottom Cheatsheet & Barcode Bar
	var bar_y := 675.0
	draw_line(Vector2(40, bar_y - 12), Vector2(sz.x - 40, bar_y - 12), Color(0, 0, 0, 0.15), 1.5)
	draw_string(FONT_BODY, Vector2(65, bar_y + 16), "CONTROLS: [WASD] Move   [SPACE / Z] Jump   [J] Attack   [K] Dash   [L] Parry / Light Blade   [ESC] Pause   [Hold Z] Skip", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.2, 0.2, 0.25))

	# Vintage Barcode (Bottom Right Corner)
	var bc_x := sz.x - 210.0
	var bc_y := bar_y - 8.0
	draw_rect(Rect2(Vector2(bc_x, bc_y), Vector2(170, 42)), PAPER)
	draw_rect(Rect2(Vector2(bc_x, bc_y), Vector2(170, 42)), INK, false, 2.0)
	var cur_bc_x := bc_x + 8.0
	for bw in [2, 3, 1, 4, 2, 1, 3, 5, 2, 4, 1, 3, 2, 5, 2, 3, 1, 4, 2]:
		draw_rect(Rect2(Vector2(cur_bc_x, bc_y + 4), Vector2(bw, 24)), INK)
		cur_bc_x += bw + 3.5
		if cur_bc_x >= bc_x + 160:
			break
	draw_string(FONT_BODY, Vector2(bc_x + 16, bc_y + 38), "0  71486 01926  4", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, INK)


func _draw_glitched_title(c: Vector2) -> void:
	var text := "GLITCHED OUT"
	var fs := 102
	var text_w := FONT_TITLE.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var p := c - Vector2(text_w * 0.5, -fs * 0.35)

	# Chromatic Glitch Spike every ~2.8s
	var glitch_phase := fmod(_time, 2.8)
	var glitching := glitch_phase < 0.18
	var glitch_offset := Vector2(randf_range(-6, 6), randf_range(-2, 2)) if glitching else Vector2.ZERO

	# 1. 3D Ink Extrusion Shadow
	for d in range(16, 0, -2):
		draw_string(FONT_TITLE, p + Vector2(d, d), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)

	# 2. Chromatic aberration offset
	if glitching:
		draw_string(FONT_TITLE, p + Vector2(-6, 1) + glitch_offset, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, RED)
		draw_string(FONT_TITLE, p + Vector2(6, -1) - glitch_offset, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, CYAN)
	else:
		draw_string(FONT_TITLE, p + Vector2(-2, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.9, 0.2, 0.2, 0.5))
		draw_string(FONT_TITLE, p + Vector2(2, -1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.2, 0.8, 0.9, 0.5))

	# 3. Main Vibrant Golden Face
	draw_string(FONT_TITLE, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, GOLD)

	# 4. Inner Shimmer Highlight
	draw_string(FONT_TITLE, p + Vector2(0, -2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs - 2, Color("fff6cc"))


func _create_button(text: String, bg_color: Color, font_size: int = 24) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_override("font", FONT_TITLE)
	btn.add_theme_font_size_override("font_size", font_size)

	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_width_bottom = 4
	sb.border_width_left = 4
	sb.border_width_right = 4
	sb.border_width_top = 4
	sb.border_color = INK
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(5, 5)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", sb)

	var sb_hover := sb.duplicate() as StyleBoxFlat
	sb_hover.bg_color = bg_color.lightened(0.2)
	sb_hover.shadow_offset = Vector2(7, 7)
	sb_hover.border_color = INK
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
	dim.color = Color(0, 0, 0, 0.75)
	_help_modal.add_child(dim)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(740, 520)
	panel.position = Vector2((1280 - 740) * 0.5, (720 - 520) * 0.5)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("fff9e6")
	sb.border_width_bottom = 5
	sb.border_width_left = 5
	sb.border_width_right = 5
	sb.border_width_top = 5
	sb.border_color = INK
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(8, 8)
	sb.content_margin_left = 32
	sb.content_margin_right = 32
	sb.content_margin_top = 24
	sb.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", sb)
	_help_modal.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "READER'S GUIDE • HOW TO PLAY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", FONT_TITLE)
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", INK)
	vbox.add_child(title)

	var guide_sections := [
		"1. THREE EDITIONS: Experience the same story across 240p retro station, 720p neon street brawler, and 2K gothic opera climax!",
		"2. 240P TORCH & TASKS: Move with WASD/Arrows. Your torch lights the dark. Press [Z] at consoles to solve puzzles. [M] toggles the map.",
		"3. VAMPIRES & REVEAL: Catch vampires in your light. Friendly allies help with tasks [F]; the Villain will strike you for 1 heart and teleport far away!",
		"4. COMBAT CONTROLS: [WASD] Move • [SPACE/Z] Jump • [J] Attack • [K] Dash/Roll • [F] Heal (uses ink) • [ESC] Pause.",
		"5. PARRY & LIGHT BLADE: Tap [L] when an enemy flashes GOLD or eyes turn RED to parry! Hold & release [L] for a devastating Light Blade blast!",
		"6. CUTSCENES: Advance dialogue with [Z] or [SPACE]. To skip any cutscene, simply Hold [Z]!",
	]

	for g in guide_sections:
		var lbl := Label.new()
		lbl.text = g
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_override("font", FONT_BODY)
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.add_theme_color_override("font_color", INK)
		vbox.add_child(lbl)

	var btn_close := _create_button("RETURN TO COVER ▶", GOLD, 22)
	btn_close.custom_minimum_size = Vector2(220, 44)
	btn_close.pressed.connect(func() -> void: _help_modal.visible = false)
	vbox.add_child(btn_close)


func _build_credits_modal() -> void:
	_credits_modal = Control.new()
	_credits_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	_credits_modal.visible = false
	add_child(_credits_modal)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.75)
	_credits_modal.add_child(dim)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 440)
	panel.position = Vector2((1280 - 620) * 0.5, (720 - 440) * 0.5)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("fff9e6")
	sb.border_width_bottom = 5
	sb.border_width_left = 5
	sb.border_width_right = 5
	sb.border_width_top = 5
	sb.border_color = INK
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(8, 8)
	sb.content_margin_left = 32
	sb.content_margin_right = 32
	sb.content_margin_top = 24
	sb.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", sb)
	_credits_modal.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "THE COMIC BULLPEN • CREDITS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", FONT_TITLE)
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", INK)
	vbox.add_child(title)

	var text := Label.new()
	text.text = "GLITCHED OUT\nCreated for TGC Game Jam 2026 (100 Hours)\n\nGame Design & Development: Sankeerth Nara\nGame Engine: Godot 4.7 (GL Compatibility)\nVoice Acting: Full Spoken Narrator & Lieutenants\nTypography: Bangers (SIL OFL) & Comic Neue (SIL OFL)\nAudio & Sound: Procedural & Synthesized Soundtrack\n\nComplete asset and attribution log available in CREDITS.md."
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_override("font", FONT_BODY)
	text.add_theme_font_size_override("font_size", 16)
	text.add_theme_color_override("font_color", INK)
	vbox.add_child(text)

	var btn_close := _create_button("BACK TO COVER", GOLD, 22)
	btn_close.custom_minimum_size = Vector2(180, 42)
	btn_close.pressed.connect(func() -> void: _credits_modal.visible = false)
	vbox.add_child(btn_close)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if _help_modal.visible:
				_help_modal.visible = false
				get_viewport().set_input_as_handled()
				return
			if _credits_modal.visible:
				_credits_modal.visible = false
				get_viewport().set_input_as_handled()
				return
		if not _help_modal.visible and not _credits_modal.visible:
			if event.keycode in [KEY_Z, KEY_SPACE, KEY_ENTER]:
				_on_start_pressed()
				get_viewport().set_input_as_handled()


func _on_start_pressed() -> void:
	var eb := get_node_or_null("/root/EventBus")
	if eb:
		eb.request_start_game.emit()
	queue_free()
