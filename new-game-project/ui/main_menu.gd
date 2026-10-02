class_name MainMenu
extends Control
## Main title screen for Mirror Page. Vintage comic book cover aesthetic.

const FONT_TITLE := preload("res://assets/fonts/Bangers-Regular.ttf")
const FONT_BODY := preload("res://assets/fonts/ComicNeue-Bold.ttf")
const SFX_CLICK := preload("res://assets/audio/click.wav")
const TEX_BURST := preload("res://assets/art/comic_burst_twist.png")
const TEX_HALFTONE := preload("res://assets/art/halftone_dot.png")

var _help_modal: Control
var _credits_modal: Control
var _click_player: AudioStreamPlayer


func _ready() -> void:
	_click_player = AudioStreamPlayer.new()
	_click_player.stream = SFX_CLICK
	add_child(_click_player)

	_build_menu()


func _play_click() -> void:
	_click_player.play()


func _build_menu() -> void:
	# Background
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("23232e")
	add_child(bg)

	# Comic cover parchment sheet
	var sheet := PanelContainer.new()
	sheet.custom_minimum_size = Vector2(800, 640)
	sheet.position = Vector2((1280 - 800) * 0.5, (720 - 640) * 0.5)
	
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("f4e8c1") # Aged newsprint
	sb.border_width_bottom = 6
	sb.border_width_left = 6
	sb.border_width_right = 6
	sb.border_width_top = 6
	sb.border_color = Color("18151d")
	sb.shadow_size = 12
	sb.shadow_offset = Vector2(8, 8)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.content_margin_left = 40
	sb.content_margin_right = 40
	sb.content_margin_top = 30
	sb.content_margin_bottom = 30
	sheet.add_theme_stylebox_override("panel", sb)
	add_child(sheet)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	sheet.add_child(vbox)

	# Top comic issue header banner
	var top_bar := HBoxContainer.new()
	vbox.add_child(top_bar)

	var issue_tag := Label.new()
	issue_tag.text = "ISSUE #1 • 100-HOUR JAM EDITION"
	issue_tag.add_theme_font_override("font", FONT_TITLE)
	issue_tag.add_theme_font_size_override("font_size", 16)
	issue_tag.add_theme_color_override("font_color", Color("e63946"))
	top_bar.add_child(issue_tag)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)

	var price_tag := Label.new()
	price_tag.text = "PRICE: FREE!"
	price_tag.add_theme_font_override("font", FONT_TITLE)
	price_tag.add_theme_font_size_override("font_size", 16)
	price_tag.add_theme_color_override("font_color", Color("18151d"))
	top_bar.add_child(price_tag)

	# Big Main Comic Title
	var title_lbl := Label.new()
	title_lbl.text = "MIRROR PAGE"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_override("font", FONT_TITLE)
	title_lbl.add_theme_font_size_override("font_size", 76)
	title_lbl.add_theme_color_override("font_color", Color("ffd034"))
	title_lbl.add_theme_color_override("font_shadow_color", Color("18151d"))
	title_lbl.add_theme_constant_override("shadow_offset_x", 5)
	title_lbl.add_theme_constant_override("shadow_offset_y", 5)
	vbox.add_child(title_lbl)

	# Subtitle
	var sub_lbl := Label.new()
	sub_lbl.text = "A COMIC-STRIP LIGHT-ROUTING MYSTERY"
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_override("font", FONT_TITLE)
	sub_lbl.add_theme_font_size_override("font_size", 22)
	sub_lbl.add_theme_color_override("font_color", Color("2bb3c0"))
	vbox.add_child(sub_lbl)

	# Story premise blurb
	var blurb := Label.new()
	blurb.text = "The story cannot advance in the dark! Rearrange panels, flip mirrors, and steer the beam across the gutters. But beware the narrator..."
	blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb.add_theme_font_override("font", FONT_BODY)
	blurb.add_theme_font_size_override("font_size", 16)
	blurb.add_theme_color_override("font_color", Color("18151d"))
	vbox.add_child(blurb)

	var btn_spacer := Control.new()
	btn_spacer.custom_minimum_size = Vector2(0, 15)
	vbox.add_child(btn_spacer)

	# Buttons
	var btn_start := _create_button("START READING", Color("ffd034"))
	btn_start.pressed.connect(_on_start_pressed)
	vbox.add_child(btn_start)

	var btn_help := _create_button("HOW TO PLAY", Color("2bb3c0"))
	btn_help.pressed.connect(func() -> void: _help_modal.visible = true)
	vbox.add_child(btn_help)

	var btn_credits := _create_button("CREDITS", Color("f4e8c1"))
	btn_credits.pressed.connect(func() -> void: _credits_modal.visible = true)
	vbox.add_child(btn_credits)

	# Modals
	_build_help_modal()
	_build_credits_modal()


func _create_button(text: String, bg_color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(320, 52)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_override("font", FONT_TITLE)
	btn.add_theme_font_size_override("font_size", 24)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_width_bottom = 4
	sb.border_width_left = 4
	sb.border_width_right = 4
	sb.border_width_top = 4
	sb.border_color = Color("18151d")
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(3, 3)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	btn.add_theme_stylebox_override("normal", sb)

	var sb_hover := sb.duplicate() as StyleBoxFlat
	sb_hover.bg_color = bg_color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", sb_hover)

	btn.add_theme_color_override("font_color", Color("18151d"))
	btn.add_theme_color_override("font_hover_color", Color("18151d"))
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
	sb.border_color = Color("18151d")
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
	title.add_theme_color_override("font_color", Color("18151d"))
	vbox.add_child(title)

	var rules := [
		"1. THE EMITTER (>) shines a beam of light across the page.",
		"2. DRAG PANELS: Left-click and drag any unlocked comic panel to swap positions.",
		"3. FLIP MIRRORS: Click rotatable mirrors (/ and \\) to redirect the beam 90 degrees.",
		"4. OBJECTIVE: Route the beam into all target stars (T) without hitting hazards (X).",
		"5. TWIST: Read the narrator's captions carefully! The rules will change under your feet!",
		"6. CONTROLS: [Z] Undo move, [R] Reset level, [ESC] Pause menu."
	]

	for r in rules:
		var lbl := Label.new()
		lbl.text = r
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_override("font", FONT_BODY)
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.add_theme_color_override("font_color", Color("18151d"))
		vbox.add_child(lbl)

	var btn_close := _create_button("GOT IT!", Color("ffd034"))
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
	sb.border_color = Color("18151d")
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
	title.add_theme_color_override("font_color", Color("18151d"))
	vbox.add_child(title)

	var text := Label.new()
	text.text = "MIRROR PAGE\nCreated for TGC Game Jam (100 Hours)\n\nDesigner & Team Lead: Sankeerth Nara\nEngine: Godot 4.7 (Compatibility Renderer)\nFonts: Bangers (SIL OFL), Comic Neue (SIL OFL)\nAudio: Procedural CC0 synthesized sounds\n\nFull attribution logged in CREDITS.md."
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_override("font", FONT_BODY)
	text.add_theme_font_size_override("font_size", 16)
	text.add_theme_color_override("font_color", Color("18151d"))
	vbox.add_child(text)

	var btn_close := _create_button("BACK", Color("ffd034"))
	btn_close.custom_minimum_size = Vector2(160, 42)
	btn_close.pressed.connect(func() -> void: _credits_modal.visible = false)
	vbox.add_child(btn_close)


func _on_start_pressed() -> void:
	var eb := get_node_or_null("/root/EventBus")
	if eb:
		eb.request_start_game.emit()
	queue_free()
