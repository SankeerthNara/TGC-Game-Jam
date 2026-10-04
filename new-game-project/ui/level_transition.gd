class_name LevelTransition
extends CanvasLayer
## 1.5s Comic Panel-Split level transition title card.

const FONT_TITLE := preload("res://assets/fonts/Bangers-Regular.ttf")
const FONT_BODY := preload("res://assets/fonts/ComicNeue-Bold.ttf")

const INK := Color("18151d")
const PAPER := Color("fff3d1")
const GOLD := Color("ffd23f")
const RED := Color("e63946")

var level_index := 0
var level_title := ""

var _time := 0.0
var _split := 0.0
var _scale_card := 1.25

var _top_panel: Control
var _bottom_panel: Control
var _top_drawer: Control
var _bottom_drawer: Control

const HERO_NAMES := [
	"THE PULP HERO",
	"THE NOIR DETECTIVE",
	"THE NINJA",
	"THE SPACE HERO"
]

const HERO_SUBTITLES := [
	"DEFENDER OF THE METROPOLIS",
	"SHADOWS IN THE RAINY PRECINCT",
	"BLADE OF THE LANTERN DOJO",
	"GUARDIAN OF THE ORBIT STATION"
]


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Top half
	_top_panel = Control.new()
	_top_panel.position = Vector2(0, 0)
	_top_panel.size = Vector2(1280, 360)
	_top_panel.clip_contents = true
	add_child(_top_panel)

	_top_drawer = Control.new()
	_top_drawer.position = Vector2.ZERO
	_top_drawer.size = Vector2(1280, 720)
	_top_drawer.draw.connect(_draw_card.bind(_top_drawer))
	_top_panel.add_child(_top_drawer)

	# Bottom half
	_bottom_panel = Control.new()
	_bottom_panel.position = Vector2(0, 360)
	_bottom_panel.size = Vector2(1280, 360)
	_bottom_panel.clip_contents = true
	add_child(_bottom_panel)

	_bottom_drawer = Control.new()
	_bottom_drawer.position = Vector2(0, -360)
	_bottom_drawer.size = Vector2(1280, 720)
	_bottom_drawer.draw.connect(_draw_card.bind(_bottom_drawer))
	_bottom_panel.add_child(_bottom_drawer)

	# Animate: 1.5s total
	# 0.0 -> 0.25: Slam in
	var tw := create_tween()
	tw.tween_property(self, "_scale_card", 1.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# 0.25 -> 1.05: Hold
	tw.tween_interval(0.8)
	# 1.05 -> 1.50: Split open
	tw.tween_property(self, "_split", 1.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)


func _process(delta: float) -> void:
	_time += delta
	_top_panel.position.y = -_split * 380.0
	_bottom_panel.position.y = 360.0 + _split * 380.0
	_top_drawer.queue_redraw()
	_bottom_drawer.queue_redraw()


func _draw_card(ci: Control) -> void:
	var sz := Vector2(1280, 720)
	var center := sz * 0.5

	# Card background with comic burst rays
	ComicArt.burst(ci, sz, center, Color("ffd034"), Color("ffea85"), 22, _time * 0.1)
	ComicArt.halftone(ci, sz, Color(0, 0, 0, 0.12), 20.0, 4.0, Vector2(1, 1))

	# Thick comic border around viewport
	ci.draw_rect(Rect2(0, 0, sz.x, sz.y), INK, false, 8.0)

	# Center banner panel
	var card_rect := Rect2(Vector2(120, 110), Vector2(1040, 500))
	ci.draw_rect(Rect2(card_rect.position + Vector2(8, 8), card_rect.size), Color(0, 0, 0, 0.5))
	ci.draw_rect(card_rect, PAPER)
	ci.draw_rect(card_rect, INK, false, 6.0)

	# Hero Bust Portrait Frame (Left side)
	var portrait_center := Vector2(340, 360)
	var frame_r := 130.0
	ComicArt.disc(ci, portrait_center, frame_r + 6.0, INK, 0.0)
	ComicArt.disc(ci, portrait_center, frame_r, Color("ffe066"), 0.0)
	
	ComicArt.disc(ci, portrait_center, frame_r, Color(0, 0, 0, 0), 5.0)

	# Draw Hero Bust
	var kind := clampi(level_index, 0, 3)
	ComicArt.hero_bust(ci, kind, portrait_center, 1.45, "determined", _time)

	# Right side text block
	var text_x := 530.0

	# Tag
	var tag_rect := Rect2(Vector2(text_x, 175), Vector2(180, 30))
	ci.draw_rect(tag_rect, RED)
	ci.draw_rect(tag_rect, INK, false, 2.5)
	ci.draw_string(FONT_TITLE, Vector2(text_x + 14, 196), "✦ ISSUE MISSION ✦", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, PAPER)

	# LEVEL N
	var lvl_str := "LEVEL %d" % (level_index + 1)
	ComicArt.shout(ci, lvl_str, Vector2(text_x + 150, 260), 62, GOLD, 10, -0.03, _scale_card)

	# Level Hero Title
	var h_title: String = HERO_NAMES[kind] if level_title.strip_edges().is_empty() else level_title.to_upper()
	ci.draw_string(FONT_TITLE, Vector2(text_x, 340), h_title, HORIZONTAL_ALIGNMENT_LEFT, 500, 38, INK)

	# Subtitle / Mission Tagline
	var subtitle: String = HERO_SUBTITLES[kind]
	ci.draw_string(FONT_BODY, Vector2(text_x, 385), subtitle, HORIZONTAL_ALIGNMENT_LEFT, 500, 18, Color("4a4555"))

	# Comic badge: "GO!" / "ACTION!"
	var badge_pos := Vector2(text_x + 360, 440)
	var badge_pts := PackedVector2Array([
		badge_pos + Vector2(-50, -22),
		badge_pos + Vector2(50, -22),
		badge_pos + Vector2(65, 22),
		badge_pos + Vector2(-35, 22)
	])
	ComicArt.poly(ci, badge_pts, RED, 3.5)
	ci.draw_string(FONT_TITLE, badge_pos + Vector2(-28, 9), "ACTION!", HORIZONTAL_ALIGNMENT_CENTER, 60, 20, PAPER)

	# Center cut line separator (gives comic split seam hint)
	if _split == 0.0:
		ci.draw_line(Vector2(0, 360), Vector2(1280, 360), INK, 4.0)
