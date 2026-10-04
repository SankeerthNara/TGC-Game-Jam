class_name ComicUI
extends CanvasLayer
## Comic UI for Mirror Page: HUD, Narrator Caption Box, Audio triggers, Pause Menu and Level Clear / Twist banners.
## Listens strictly to EventBus signals as specified in docs/ARCHITECTURE.md.

const FONT_TITLE := preload("res://assets/fonts/Bangers-Regular.ttf")
const FONT_BODY := preload("res://assets/fonts/ComicNeue-Bold.ttf")

const SFX_CLICK := preload("res://assets/audio/click.wav")
const SFX_SWAP := preload("res://assets/audio/swap.wav")
const SFX_MIRROR := preload("res://assets/audio/mirror.wav")
const SFX_LIT := preload("res://assets/audio/lit.wav")
const SFX_BUZZ := preload("res://assets/audio/buzz.wav")
const SFX_TWIST := preload("res://assets/audio/twist.wav")

const TEX_BURST_TWIST := preload("res://assets/art/comic_burst_twist.png")
const TEX_BURST_SOLVED := preload("res://assets/art/comic_burst_solved.png")
const SHADER_COMIC_SCREEN := preload("res://assets/shaders/comic_screen.gdshader")
const LEVEL_TRANSITION_SCENE := preload("res://ui/level_transition.gd")

var _caption_label: Label
var _level_label: Label
var _moves_label: Label
var _status_label: Label
var _caption_box: PanelContainer
var _caption_tween: Tween
var _banner_rect: TextureRect
var _pause_modal: Control
var _hud_root: Control
var _info_box: Control
var _action_bar: Control
var _end_modal: Control
var _fx_layer: CanvasLayer
var _fx_mat: ShaderMaterial

var _audio_players: Dictionary = {}
var _bgm: AudioStreamPlayer
var _audio_muted := false
var _music_muted := false
var _sfx_muted := false

var _current_level_idx := 0
var _current_level_name := "Page"


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_screen_fx()
	_setup_audio()
	_build_ui()
	_connect_event_bus()


func _setup_audio() -> void:
	for key in ["click", "swap", "mirror", "lit", "buzz", "twist"]:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_audio_players[key] = p
	
	_audio_players["click"].stream = SFX_CLICK
	_audio_players["swap"].stream = SFX_SWAP
	_audio_players["mirror"].stream = SFX_MIRROR
	_audio_players["lit"].stream = SFX_LIT
	_audio_players["buzz"].stream = SFX_BUZZ
	_audio_players["twist"].stream = SFX_TWIST
	
	# the music is played by MusicDirector (adaptive layers, scripts/core/music_director.gd)


func play_sfx(key: String) -> void:
	if _audio_muted or not _audio_players.has(key):
		return
	_audio_players[key].play()


var _eb: Node
var _gs: Node


func _get_event_bus() -> Node:
	if not _eb:
		_eb = get_node_or_null("/root/EventBus")
	return _eb


func _get_game_state() -> Node:
	if not _gs:
		_gs = get_node_or_null("/root/GameState")
	return _gs


func _connect_event_bus() -> void:
	var eb := _get_event_bus()
	if not eb:
		return
	eb.level_loaded.connect(_on_level_loaded)
	eb.caption_changed.connect(_on_caption_changed)
	eb.move_count_changed.connect(_on_move_count_changed)
	eb.beam_updated.connect(_on_beam_updated)
	eb.twist_triggered.connect(_on_twist_triggered)
	eb.level_solved.connect(_on_level_solved)
	eb.game_finished.connect(_on_game_finished)
	eb.panel_rejected.connect(_on_panel_rejected)
	eb.panel_swapped.connect(_on_panel_swapped)
	eb.mirror_toggled.connect(_on_mirror_toggled)
	eb.game_state_changed.connect(_on_game_state_changed)
	eb.sabotage_failed.connect(_on_sabotage_failed)
	eb.player_died.connect(_on_player_died)
	eb.level_started.connect(_on_level_started)


func _build_ui() -> void:
	# Main Root Control
	var root := Control.new()
	_hud_root = root
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# --- CAPTION BOX: Compact comic narration banner at bottom-center ---
	_caption_box = PanelContainer.new()
	_caption_box.position = Vector2((1280 - 640) * 0.5, 650)
	_caption_box.custom_minimum_size = Vector2(640, 50)
	_caption_box.visible = false
	
	var box_style := StyleBoxFlat.new()
	box_style.bg_color = Color("fff9e6") # Pale vintage paper
	box_style.border_width_bottom = 3
	box_style.border_width_left = 3
	box_style.border_width_right = 3
	box_style.border_width_top = 3
	box_style.border_color = Color("18151d") # Ink black
	box_style.shadow_color = Color(0, 0, 0, 0.35)
	box_style.shadow_size = 3
	box_style.shadow_offset = Vector2(3, 3)
	box_style.content_margin_left = 12
	box_style.content_margin_right = 12
	box_style.content_margin_top = 4
	box_style.content_margin_bottom = 4
	_caption_box.add_theme_stylebox_override("panel", box_style)
	root.add_child(_caption_box)

	var caption_vbox := VBoxContainer.new()
	caption_vbox.add_theme_constant_override("separation", 2)
	_caption_box.add_child(caption_vbox)

	var tag := Label.new()
	tag.text = "✦ NARRATION ✦"
	tag.add_theme_font_override("font", FONT_TITLE)
	tag.add_theme_font_size_override("font_size", 12)
	tag.add_theme_color_override("font_color", Color("e63946"))
	caption_vbox.add_child(tag)

	_caption_label = Label.new()
	_caption_label.text = ""
	_caption_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption_label.add_theme_font_override("font", FONT_BODY)
	_caption_label.add_theme_font_size_override("font_size", 15)
	_caption_label.add_theme_color_override("font_color", Color("18151d"))
	caption_vbox.add_child(_caption_label)

	# --- TOP RIGHT: Level Info Card ---
	var info_box := PanelContainer.new()
	_info_box = info_box
	info_box.position = Vector2(910, 20)
	info_box.custom_minimum_size = Vector2(340, 95)
	var info_style := StyleBoxFlat.new()
	info_style.bg_color = Color("2bb3c0") # Comic cyan
	info_style.border_width_bottom = 4
	info_style.border_width_left = 4
	info_style.border_width_right = 4
	info_style.border_width_top = 4
	info_style.border_color = Color("18151d")
	info_style.shadow_color = Color(0, 0, 0, 0.4)
	info_style.shadow_size = 4
	info_style.shadow_offset = Vector2(4, 4)
	info_style.content_margin_left = 14
	info_style.content_margin_right = 14
	info_style.content_margin_top = 8
	info_style.content_margin_bottom = 8
	info_box.add_theme_stylebox_override("panel", info_style)
	root.add_child(info_box)

	var info_vbox := VBoxContainer.new()
	info_box.add_child(info_vbox)

	_level_label = Label.new()
	_level_label.text = "PAGE 1/4"
	_level_label.add_theme_font_override("font", FONT_TITLE)
	_level_label.add_theme_font_size_override("font_size", 22)
	_level_label.add_theme_color_override("font_color", Color("18151d"))
	info_vbox.add_child(_level_label)

	var stats_hbox := HBoxContainer.new()
	info_vbox.add_child(stats_hbox)

	_moves_label = Label.new()
	_moves_label.text = "MOVES: 0"
	_moves_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_moves_label.add_theme_font_override("font", FONT_BODY)
	_moves_label.add_theme_font_size_override("font_size", 16)
	_moves_label.add_theme_color_override("font_color", Color("18151d"))
	stats_hbox.add_child(_moves_label)

	_status_label = Label.new()
	_status_label.text = "STARS: 0/1"
	_status_label.add_theme_font_override("font", FONT_BODY)
	_status_label.add_theme_font_size_override("font_size", 16)
	_status_label.add_theme_color_override("font_color", Color("18151d"))
	stats_hbox.add_child(_status_label)

	# --- BOTTOM ACTION BAR ---
	var bar := HBoxContainer.new()
	_action_bar = bar
	bar.position = Vector2(30, 665)
	bar.custom_minimum_size = Vector2(1220, 45)
	root.add_child(bar)

	var hint := Label.new()
	hint.text = "💡 DRAG PANELS TO SWAP  •  CLICK MIRRORS TO FLIP  •  M: BACK TO MAP"
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.add_theme_font_override("font", FONT_BODY)
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color("f4e8c1"))
	bar.add_child(hint)

	var btn_undo := _make_comic_button("UNDO [Z]")
	btn_undo.pressed.connect(_on_undo_pressed)
	bar.add_child(btn_undo)

	var btn_reset := _make_comic_button("RESET [R]")
	btn_reset.pressed.connect(_on_reset_pressed)
	bar.add_child(btn_reset)

	var btn_pause := _make_comic_button("PAUSE [ESC]")
	btn_pause.pressed.connect(func() -> void: _request("request_pause", [true]))
	bar.add_child(btn_pause)

	# --- CENTER COMIC BURST BANNER ---
	_banner_rect = TextureRect.new()
	_banner_rect.texture = TEX_BURST_TWIST
	_banner_rect.custom_minimum_size = Vector2(240, 240)
	_banner_rect.position = Vector2((1280 - 240) * 0.5, (720 - 240) * 0.5 - 30)
	_banner_rect.pivot_offset = Vector2(120, 120)
	_banner_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_rect.visible = false
	root.add_child(_banner_rect)

	# --- MODALS ---
	_build_pause_modal(root)
	_build_end_modal(root)


func _make_comic_button(title: String) -> Button:
	var btn := Button.new()
	btn.text = title
	btn.custom_minimum_size = Vector2(120, 38)
	btn.add_theme_font_override("font", FONT_TITLE)
	btn.add_theme_font_size_override("font_size", 16)
	
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("ffd034") # Warm gold
	sb.border_width_bottom = 3
	sb.border_width_left = 3
	sb.border_width_right = 3
	sb.border_width_top = 3
	sb.border_color = Color("18151d")
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 2
	sb.shadow_offset = Vector2(2, 2)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	btn.add_theme_stylebox_override("normal", sb)

	var sb_hover := sb.duplicate() as StyleBoxFlat
	sb_hover.bg_color = Color("ffe170")
	btn.add_theme_stylebox_override("hover", sb_hover)

	btn.add_theme_color_override("font_color", Color("18151d"))
	btn.add_theme_color_override("font_hover_color", Color("18151d"))
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(func() -> void: play_sfx("click"))
	return btn


func _build_pause_modal(parent: Control) -> void:
	_pause_modal = Control.new()
	_pause_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_modal.process_mode = Node.PROCESS_MODE_ALWAYS
	_pause_modal.visible = false
	parent.add_child(_pause_modal)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.7)
	_pause_modal.add_child(dim)

	# Main container: side-by-side menu and controls in comic book spread style
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 24)
	hbox.position = Vector2((1280 - 780) * 0.5, (720 - 460) * 0.5)
	hbox.custom_minimum_size = Vector2(780, 460)
	_pause_modal.add_child(hbox)

	# --- LEFT PANEL: Menu Buttons ---
	var menu_panel := PanelContainer.new()
	menu_panel.custom_minimum_size = Vector2(340, 460)
	var sb_menu := StyleBoxFlat.new()
	sb_menu.bg_color = Color("fff9e6")
	sb_menu.border_width_bottom = 4
	sb_menu.border_width_left = 4
	sb_menu.border_width_right = 4
	sb_menu.border_width_top = 4
	sb_menu.border_color = Color("18151d")
	sb_menu.shadow_size = 6
	sb_menu.shadow_offset = Vector2(5, 5)
	sb_menu.content_margin_left = 24
	sb_menu.content_margin_right = 24
	sb_menu.content_margin_top = 20
	sb_menu.content_margin_bottom = 20
	menu_panel.add_theme_stylebox_override("panel", sb_menu)
	hbox.add_child(menu_panel)

	var menu_vbox := VBoxContainer.new()
	menu_vbox.add_theme_constant_override("separation", 12)
	menu_panel.add_child(menu_vbox)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", FONT_TITLE)
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color("18151d"))
	menu_vbox.add_child(title)

	var sub := Label.new()
	sub.text = "ISSUE FROZEN IN TIME"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_override("font", FONT_BODY)
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color("6c757d"))
	menu_vbox.add_child(sub)

	var btn_resume := _make_comic_button("RESUME")
	btn_resume.custom_minimum_size = Vector2(0, 42)
	btn_resume.pressed.connect(func() -> void: _request("request_pause", [false]))
	menu_vbox.add_child(btn_resume)

	var btn_music := _make_comic_button("MUSIC: ON")
	btn_music.custom_minimum_size = Vector2(0, 42)
	btn_music.pressed.connect(func() -> void:
		_music_muted = not _music_muted
		get_tree().call_group("music", "set_muted", _music_muted)
		btn_music.text = "MUSIC: %s" % ("OFF" if _music_muted else "ON"))
	menu_vbox.add_child(btn_music)

	var btn_sfx := _make_comic_button("SFX: ON")
	btn_sfx.custom_minimum_size = Vector2(0, 42)
	btn_sfx.pressed.connect(func() -> void:
		_sfx_muted = not _sfx_muted
		get_tree().call_group("sfx", "set_muted", _sfx_muted)
		_audio_muted = _sfx_muted
		btn_sfx.text = "SFX: %s" % ("OFF" if _sfx_muted else "ON"))
	menu_vbox.add_child(btn_sfx)

	var btn_restart := _make_comic_button("RESTART LEVEL")
	btn_restart.custom_minimum_size = Vector2(0, 42)
	btn_restart.pressed.connect(func() -> void:
		_request("request_pause", [false])
		_request("request_restart_level"))
	menu_vbox.add_child(btn_restart)

	var btn_quit := _make_comic_button("QUIT TO MENU")
	btn_quit.custom_minimum_size = Vector2(0, 42)
	var sb_quit := btn_quit.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	sb_quit.bg_color = Color("e63946")
	btn_quit.add_theme_stylebox_override("normal", sb_quit)
	btn_quit.add_theme_color_override("font_color", Color("fff3d1"))
	btn_quit.pressed.connect(func() -> void:
		_request("request_pause", [false])
		_request("request_quit_to_menu"))
	menu_vbox.add_child(btn_quit)

	# --- RIGHT PANEL: Controls Guide ---
	var ctrl_panel := PanelContainer.new()
	ctrl_panel.custom_minimum_size = Vector2(410, 460)
	var sb_ctrl := StyleBoxFlat.new()
	sb_ctrl.bg_color = Color("fff3d1")
	sb_ctrl.border_width_bottom = 4
	sb_ctrl.border_width_left = 4
	sb_ctrl.border_width_right = 4
	sb_ctrl.border_width_top = 4
	sb_ctrl.border_color = Color("18151d")
	sb_ctrl.shadow_size = 6
	sb_ctrl.shadow_offset = Vector2(5, 5)
	sb_ctrl.content_margin_left = 22
	sb_ctrl.content_margin_right = 22
	sb_ctrl.content_margin_top = 18
	sb_ctrl.content_margin_bottom = 18
	ctrl_panel.add_theme_stylebox_override("panel", sb_ctrl)
	hbox.add_child(ctrl_panel)

	var ctrl_vbox := VBoxContainer.new()
	ctrl_vbox.add_theme_constant_override("separation", 6)
	ctrl_panel.add_child(ctrl_vbox)

	var ctrl_title := Label.new()
	ctrl_title.text = "✦ HERO CONTROLS ✦"
	ctrl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ctrl_title.add_theme_font_override("font", FONT_TITLE)
	ctrl_title.add_theme_font_size_override("font_size", 24)
	ctrl_title.add_theme_color_override("font_color", Color("e63946"))
	ctrl_vbox.add_child(ctrl_title)

	var entries: Array[Array] = [
		["ARROWS / WASD", "Move hero"],
		["Z / SPACE / ENTER", "Interact / Action / Skip"],
		["M", "Toggle minimap"],
		["F", "Give task to friend ally"],
		["TAB", "Toggle task checklist"],
		["P / ESC", "Pause / Resume game"]
	]

	for entry in entries:
		var row := HBoxContainer.new()
		var key_lbl := Label.new()
		key_lbl.text = entry[0]
		key_lbl.custom_minimum_size = Vector2(170, 0)
		key_lbl.add_theme_font_override("font", FONT_TITLE)
		key_lbl.add_theme_font_size_override("font_size", 14)
		key_lbl.add_theme_color_override("font_color", Color("18151d"))
		row.add_child(key_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = entry[1]
		desc_lbl.add_theme_font_override("font", FONT_BODY)
		desc_lbl.add_theme_font_size_override("font_size", 13)
		desc_lbl.add_theme_color_override("font_color", Color("33303c"))
		row.add_child(desc_lbl)
		ctrl_vbox.add_child(row)

	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 10)
	ctrl_vbox.add_child(sep)

	var chase_title := Label.new()
	chase_title.text = "CHASE CONTROLS"
	chase_title.add_theme_font_override("font", FONT_TITLE)
	chase_title.add_theme_font_size_override("font_size", 16)
	chase_title.add_theme_color_override("font_color", Color("18151d"))
	ctrl_vbox.add_child(chase_title)

	var chase_entries: Array[Array] = [
		["LEVEL 2 ROLL", "Arrows lean/roll, Space jump"],
		["LEVEL 3 RUN", "Up jump, Down slide"],
		["LEVEL 4 SWING", "Space swing, Shift reel, X web"]
	]

	for entry in chase_entries:
		var row := HBoxContainer.new()
		var key_lbl := Label.new()
		key_lbl.text = entry[0]
		key_lbl.custom_minimum_size = Vector2(140, 0)
		key_lbl.add_theme_font_override("font", FONT_TITLE)
		key_lbl.add_theme_font_size_override("font_size", 13)
		key_lbl.add_theme_color_override("font_color", Color("ffd034").darkened(0.2))
		row.add_child(key_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = entry[1]
		desc_lbl.add_theme_font_override("font", FONT_BODY)
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.add_theme_color_override("font_color", Color("33303c"))
		row.add_child(desc_lbl)
		ctrl_vbox.add_child(row)


func _build_end_modal(parent: Control) -> void:
	_end_modal = Control.new()
	_end_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	_end_modal.visible = false
	parent.add_child(_end_modal)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.75)
	_end_modal.add_child(dim)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 360)
	panel.position = Vector2((1280 - 500) * 0.5, (720 - 360) * 0.5)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("ffd034")
	sb.border_width_bottom = 6
	sb.border_width_left = 6
	sb.border_width_right = 6
	sb.border_width_top = 6
	sb.border_color = Color("18151d")
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(8, 8)
	sb.content_margin_left = 30
	sb.content_margin_right = 30
	sb.content_margin_top = 30
	sb.content_margin_bottom = 30
	panel.add_theme_stylebox_override("panel", sb)
	_end_modal.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "TO BE CONTINUED..."
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", FONT_TITLE)
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color("18151d"))
	vbox.add_child(title)

	var msg := Label.new()
	msg.text = "You mastered the page, outsmarted the mirrors, and survived the narrator's twists!\n\nIssue #1 Complete."
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.add_theme_font_override("font", FONT_BODY)
	msg.add_theme_font_size_override("font_size", 18)
	msg.add_theme_color_override("font_color", Color("18151d"))
	vbox.add_child(msg)

	var btn_again := _make_comic_button("READ AGAIN")
	btn_again.custom_minimum_size = Vector2(0, 48)
	btn_again.pressed.connect(func() -> void:
		_request("request_quit_to_menu"))
	vbox.add_child(btn_again)


## Emits one of EventBus's request_* signals (the game's main.gd acts on it).
func _request(signal_name: String, args: Array = []) -> void:
	var eb := _get_event_bus()
	if eb:
		eb.callv("emit_signal", [signal_name] + args)


func _on_undo_pressed() -> void:
	_request("request_undo")


func _on_reset_pressed() -> void:
	_request("request_restart_level")


func _on_game_state_changed(state: String) -> void:
	_hud_root.visible = state != "menu"
	if _fx_layer:
		_fx_layer.visible = state != "menu"
	var in_puzzle := state == "playing"
	_info_box.visible = in_puzzle
	_action_bar.visible = in_puzzle
	_pause_modal.visible = state == "paused"
	_end_modal.visible = false # the run's end screens are drawn by main (bomb room, Earth blast)


# --- EventBus Listeners ---

func _on_level_loaded(index: int, data: Dictionary) -> void:
	_current_level_idx = index
	_current_level_name = data.get("name", "Page %d" % (index + 1))
	var total_levels: int = _get_game_state().levels.size() if _get_game_state() else 4
	_level_label.text = "PAGE %d/%d: %s" % [index + 1, total_levels, _current_level_name.to_upper()]
	_moves_label.text = "MOVES: 0"
	_status_label.text = "GOALS: 0"
	_banner_rect.visible = false


func _on_caption_changed(text: String) -> void:
	if get_tree().get_first_node_in_group("comms") != null and text.begins_with("NARRATOR:"):
		return # the editions show the Narrator on the comms box instead
	var clean := text.strip_edges()
	if clean.is_empty():
		_caption_box.visible = false
		return
	_caption_label.text = clean
	_caption_box.visible = true
	_caption_box.modulate = Color(1, 1, 1, 1)
	if _caption_tween and _caption_tween.is_valid():
		_caption_tween.kill()
	var duration := clampf(3.5 + clean.length() * 0.03, 3.5, 7.0)
	_caption_tween = create_tween()
	_caption_tween.tween_interval(duration)
	_caption_tween.tween_property(_caption_box, "modulate:a", 0.0, 0.4)
	_caption_tween.tween_callback(func() -> void: _caption_box.visible = false)


func _on_move_count_changed(moves: int) -> void:
	_moves_label.text = "MOVES: %d" % moves


func _on_beam_updated(good_lit: int, good_total: int, bad_lit: int) -> void:
	if bad_lit > 0:
		_status_label.text = "GOALS: %d/%d  ⚠ DO NOT LIGHT: %d" % [good_lit, good_total, bad_lit]
	else:
		_status_label.text = "GOALS: %d/%d" % [good_lit, good_total]


func _on_panel_swapped(_a: int, _b: int) -> void:
	play_sfx("swap")


func _on_mirror_toggled(_cell: Vector2i) -> void:
	play_sfx("mirror")


func _on_panel_rejected(_panel: int) -> void:
	play_sfx("buzz")


func _on_twist_triggered(_kind: String) -> void:
	play_sfx("twist")
	_show_banner(TEX_BURST_TWIST, 1.8)


func _on_level_solved(_index: int) -> void:
	play_sfx("lit")
	_show_banner(TEX_BURST_SOLVED, 1.5)


func _on_game_finished() -> void:
	pass # the "ended" game state shows the end modal


func _show_banner(tex: Texture2D, duration: float) -> void:
	_banner_rect.texture = tex
	_banner_rect.visible = true
	_banner_rect.scale = Vector2(0.2, 0.2)
	var tw := create_tween()
	tw.tween_property(_banner_rect, "scale", Vector2(1.15, 1.15), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_banner_rect, "scale", Vector2(1.0, 1.0), 0.1)
	tw.tween_interval(duration)
	tw.tween_property(_banner_rect, "scale", Vector2.ZERO, 0.2)
	tw.tween_callback(func() -> void: _banner_rect.visible = false)

func _setup_screen_fx() -> void:
	_fx_layer = CanvasLayer.new()
	_fx_layer.layer = 8
	_fx_layer.visible = false
	add_child(_fx_layer)

	var fx_rect := ColorRect.new()
	fx_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fx_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx_mat = ShaderMaterial.new()
	_fx_mat.shader = SHADER_COMIC_SCREEN
	fx_rect.material = _fx_mat
	_fx_layer.add_child(fx_rect)


func _screen_flash_and_shake(color: Color, duration: float, intensity: float) -> void:
	if not _fx_mat:
		return
	_fx_mat.set_shader_parameter("flash_color", color)
	_fx_mat.set_shader_parameter("flash_amount", 1.0)
	
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void:
		if _fx_mat:
			_fx_mat.set_shader_parameter("flash_amount", v),
		1.0, 0.0, duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var shake_tw := create_tween()
	var steps := 8
	var step_time := duration / float(steps)
	for i in steps:
		var decay := 1.0 - float(i) / float(steps)
		var ox := (randf() * 2.0 - 1.0) * intensity * decay * 0.015
		var oy := (randf() * 2.0 - 1.0) * intensity * decay * 0.015
		shake_tw.tween_method(func(offset: Vector2) -> void:
			if _fx_mat:
				_fx_mat.set_shader_parameter("shake_offset", offset),
			Vector2(ox, oy), Vector2.ZERO, step_time
		)
	shake_tw.tween_callback(func() -> void:
		if _fx_mat:
			_fx_mat.set_shader_parameter("shake_offset", Vector2.ZERO)
	)


func _on_sabotage_failed(_name: String, _hp_left: int) -> void:
	_screen_flash_and_shake(Color("e63946"), 0.45, 1.2)


func _on_player_died() -> void:
	_screen_flash_and_shake(Color("18151d"), 0.65, 1.8)

func _on_level_started(index: int, title: String) -> void:
	var trans = LEVEL_TRANSITION_SCENE.new()
	trans.level_index = index
	trans.level_title = title
	add_child(trans)
