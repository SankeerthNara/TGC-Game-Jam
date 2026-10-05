class_name FakeCredits
extends Control
## The fake ending of the 720p edition: "THE END", then credits rolling... until they freeze and
## glitch (the Narrator takes the mouse). The director calls freeze() when the hijack begins.

const FONT_SHOUT := preload("res://assets/fonts/Bangers-Regular.ttf")
const FONT_BODY := preload("res://assets/fonts/ComicNeue-Bold.ttf")
const LINES := [
	["GLITCHED OUT", ""],
	["THE HERO", "you"],
	["THE NARRATOR", "the Narrator"],
	["THE INK BARON", "defeated"],
	["THE STATIC TWINS", "defeated"],
	["THE MASKED VILLAIN", "...still out there?"],
	["THE THREE CAPTURED HEROES", "...still captured?"],
	["THANK YOU FOR PLAYING", ""],
]

var _t := 0.0
var _frozen := false
var _freeze_t := 0.0


func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func freeze() -> void:
	_frozen = true
	_freeze_t = _t


func _process(delta: float) -> void:
	if not _frozen:
		var before := int(_t * 2.0)
		_t += delta
		if int(_t * 2.0) != before and _t > 2.0:
			EventBus.sound_requested.emit("typewriter")
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("07060a"))
	var k := clampf(_t / 1.2, 0.0, 1.0)
	ComicArt.shout(self, "THE END", Vector2(640, 220 - maxf(0.0, _t - 2.0) * 50.0), int(110 * k) + 1, Color("ffd23f"), 14, -0.03)
	var scroll := maxf(0.0, _t - 2.0) * 60.0
	for i in LINES.size():
		var y := 520.0 + i * 90.0 - scroll
		if y < -40.0 or y > 760.0:
			continue
		var role := String(LINES[i][0])
		var who := String(LINES[i][1])
		var w := FONT_SHOUT.get_string_size(role, HORIZONTAL_ALIGNMENT_LEFT, -1, 34).x
		draw_string(FONT_SHOUT, Vector2(640 - w * 0.5, y), role, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("fff3d1"))
		if who != "":
			var w2 := FONT_BODY.get_string_size(who, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
			draw_string(FONT_BODY, Vector2(640 - w2 * 0.5, y + 32), who, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("8d99ae"))
	if _frozen and int((_t + Time.get_ticks_msec() / 1000.0) * 8.0) % 3 == 0:
		# the credits stutter: something else is in control now
		draw_rect(Rect2(0, 300 + randf() * 200.0, 1280, 18), Color(1, 0.2, 0.3, 0.25))
