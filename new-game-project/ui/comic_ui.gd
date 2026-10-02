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
const SFX_MUSIC := preload("res://assets/audio/music_loop.wav")

const TEX_BURST_TWIST := preload("res://assets/art/comic_burst_twist.png")
const TEX_BURST_SOLVED := preload("res://assets/art/comic_burst_solved.png")

var _caption_label: Label
var _level_label: Label
var _moves_label: Label
var _status_label: Label
var _caption_box: PanelContainer
var _banner_rect: TextureRect
var _pause_modal: Control
var _hud_root: Control
var _info_box: Control
var _action_bar: Control
var _end_modal: Control

var _audio_players: Dictionary = {}
var _bgm: AudioStreamPlayer
var _audio_muted := false

var _current_level_idx := 0
var _current_level_name := "Page"


func _ready() -> void:
	layer = 10
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
	
	_bgm = AudioStreamPlayer.new()
	_bgm.stream = SFX_MUSIC
	_bgm.volume_db = -12.0
	add_child(_bgm)
	_bgm.finished.connect(func() -> void: _bgm.play())
	_bgm.play()


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


func _build_ui() -> void:
	# Main Root Control
	var root := Control.new()
	_hud_root = root
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# --- TOP BAR: Caption Box ---
	_caption_box = PanelContainer.new()
	_caption_box.position = Vector2(30, 20)
	_caption_box.custom_minimum_size = Vector2(860, 95)
	
	var box_style := StyleBoxFlat.new()
	box_style.bg_color = Color("fff9e6") # Pale vintage paper
	box_style.border_width_bottom = 4
	box_style.border_width_left = 4
	box_style.border_width_right = 4
	box_style.border_width_top = 4
	box_style.border_color = Color("18151d") # Ink black
	box_style.shadow_color = Color(0, 0, 0, 0.4)
	box_style.shadow_size = 4
	box_style.shadow_offset = Vector2(4, 4)
	box_style.content_margin_left = 16
	box_style.content_margin_right = 16
	box_style.content_margin_top = 10
	box_style.content_margin_bottom = 10
	_caption_box.add_theme_stylebox_override("panel", box_style)
	root.add_child(_caption_box)

	var caption_vbox := VBoxContainer.new()
	_caption_box.add_child(caption_vbox)

	var tag := Label.new()
	tag.text = "✦ NARRATION ✦"
	tag.add_theme_font_override("font", FONT_TITLE)
	tag.add_theme_font_size_override("font_size", 14)
	tag.add_theme_color_override("font_color", Color("e63946")) # Punch red tag
	caption_vbox.add_child(tag)

	_caption_label = Label.new()
	_caption_label.text = "Loading comic issue..."
	_caption_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption_label.add_theme_font_override("font", FONT_BODY)
	_caption_label.add_theme_font_size_override("font_size", 18)
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
	_pause_modal.visible = false
	parent.add_child(_pause_modal)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.65)
	_pause_modal.add_child(dim)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 320)
	panel.position = Vector2((1280 - 400) * 0.5, (720 - 320) * 0.5)
	
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
	_pause_modal.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", FONT_TITLE)
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color("18151d"))
	vbox.add_child(title)

	var btn_resume := _make_comic_button("RESUME")
	btn_resume.custom_minimum_size = Vector2(0, 44)
	btn_resume.pressed.connect(func() -> void: _request("request_pause", [false]))
	vbox.add_child(btn_resume)

	var btn_restart := _make_comic_button("RESTART LEVEL")
	btn_restart.custom_minimum_size = Vector2(0, 44)
	btn_restart.pressed.connect(func() -> void:
		_request("request_pause", [false])
		_request("request_restart_level"))
	vbox.add_child(btn_restart)

	var btn_mute := _make_comic_button("TOGGLE SOUND")
	btn_mute.custom_minimum_size = Vector2(0, 44)
	btn_mute.pressed.connect(func() -> void:
		_audio_muted = not _audio_muted
		_bgm.volume_db = -80.0 if _audio_muted else -12.0)
	vbox.add_child(btn_mute)


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
	var in_puzzle := state == "playing" or state == "paused"
	_info_box.visible = in_puzzle
	_action_bar.visible = in_puzzle
	_pause_modal.visible = state == "paused"
	_end_modal.visible = state == "ended"


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
	_caption_label.text = text


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
