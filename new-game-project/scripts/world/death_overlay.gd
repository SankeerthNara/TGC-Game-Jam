class_name DeathOverlay
extends Control
## Comic-styled defeat screen when the hero runs out of hearts.
## Press Z / Enter / Space to respawn at the level checkpoint.

signal restart

const FONT_SHOUT := preload("res://assets/fonts/Bangers-Regular.ttf")
const FONT_BODY := preload("res://assets/fonts/ComicNeue-Bold.ttf")

const INK := Color("18151d")
const PAPER := Color("fff3d1")
const GOLD := Color("ffd23f")
const RED := Color("e63946")

var _t := 0.0
var message := "The dark won this round. Back to the checkpoint!"
var bomb := true ## remind the player that the bomb clock keeps running


func _ready() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _t > 0.6 and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_Z, KEY_ENTER, KEY_SPACE]:
		restart.emit()
		get_viewport().set_input_as_handled()


func _draw() -> void:
	var vp := get_viewport_rect().size
	var k := minf(_t / 0.5, 1.0)

	# Deep dramatic ink / blood red backdrop
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.12, 0.02, 0.04, 0.88 * k))

	# Comic halftone dots on background
	ComicArt.halftone(self, vp, Color(0.3, 0.05, 0.08, 0.35), 24.0, 4.5, Vector2(1, 1))

	var c := vp * 0.5

	# Dramatic comic panel zoom & slight tilt
	var tilt := -0.035 * (1.0 - k * 0.2)
	draw_set_transform(c, tilt, Vector2(k, k))

	# Comic panel box
	var pw := 720.0
	var ph := 320.0
	var prect := Rect2(-pw * 0.5, -ph * 0.5, pw, ph)

	# 3D Inked shadow
	draw_rect(Rect2(prect.position + Vector2(10, 10), prect.size), Color(0, 0, 0, 0.65))
	# Paper fill
	draw_rect(prect, PAPER)
	draw_rect(prect, INK, false, 8.0)

	# Red Alert Header Strip
	var h_rect := Rect2(prect.position, Vector2(pw, 90))
	draw_rect(h_rect, RED)
	draw_rect(h_rect, INK, false, 6.0)

	# Jagged comic burst behind "YOU DIED!"
	var burst_c := Vector2(0, -ph * 0.5 + 45)
	var b_pts := PackedVector2Array()
	for i in 16:
		var a := i / 16.0 * TAU + _t * 0.5
		var br: float = 120.0 if i % 2 == 0 else 85.0
		b_pts.append(burst_c + Vector2(cos(a) * 2.2, sin(a)) * (br * 0.35))
	b_pts.append(b_pts[0])
	draw_colored_polygon(b_pts, GOLD)
	draw_polyline(b_pts, INK, 2.5)

	# Header text
	var s1 := FONT_SHOUT.get_string_size("HERO DOWN!", HORIZONTAL_ALIGNMENT_LEFT, -1, 64)
	draw_string(FONT_SHOUT, Vector2(-s1.x * 0.5, -ph * 0.5 + 66), "HERO DOWN!", HORIZONTAL_ALIGNMENT_LEFT, -1, 64, PAPER)

	# Comic narration caption strip
	var cap_rect := Rect2(-pw * 0.5 + 40, -ph * 0.5 + 115, pw - 80, 72)
	draw_rect(cap_rect, Color(1, 0.98, 0.92))
	draw_rect(cap_rect, INK, false, 2.5)

	draw_string(FONT_SHOUT, cap_rect.position + Vector2(14, 24), "✦ NARRATOR ✦", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, RED)
	draw_string(FONT_BODY, cap_rect.position + Vector2(14, 52), message, HORIZONTAL_ALIGNMENT_LEFT, int(cap_rect.size.x - 28), 18, INK)

	# Subtitle reminder: bomb keeps ticking
	if bomb:
		draw_string(FONT_BODY, Vector2(-220, 75), "The bomb clock is still running! Hurry back!", HORIZONTAL_ALIGNMENT_CENTER, 440, 16, Color("6c757d"))

	# Blinking Respawn Prompt
	if _t > 0.6 and int(_t * 2.5) % 2 == 0:
		var prompt := "PRESS [Z] OR [SPACE] TO RESPAWN"
		var s3 := FONT_SHOUT.get_string_size(prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 32)
		draw_string(FONT_SHOUT, Vector2(-s3.x * 0.5, 115), prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, RED)

	draw_set_transform(Vector2.ZERO)
