class_name EditionFX
extends CanvasLayer
## The picture quality of the current "edition": one full-screen shader over the whole game.
##   "144p": 256x144, mushy, crushed colours, grain, scanlines (the cheap edition)
##   "720p": 480x270 crisp pixel art (the pixel edition)
##   "2k":   off, full resolution (the deluxe edition)
## glitch() tears the picture for a moment; sweep_to() animates a resolution change.

const SHADER := preload("res://scripts/editions/edition_fx.gdshader")
const PRESETS := {
	"144p": {"res": Vector2(256, 144), "soft": 0.7, "levels": 10.0, "scan": 0.35, "noise": 0.6},
	"720p": {"res": Vector2(480, 270), "soft": 0.0, "levels": 28.0, "scan": 0.12, "noise": 0.15},
	"2k": {"res": Vector2(1280, 720), "soft": 0.0, "levels": 256.0, "scan": 0.0, "noise": 0.0},
}

var edition := "2k"
var _rect: ColorRect
var _mat: ShaderMaterial
var _glitch := 0.0
var _glitch_t := 0.0
var _sweep := {} ## {from, to, t, dur}
var _t := 0.0


func _ready() -> void:
	layer = 95 # above the game and its HUD, below the fourth-wall overlays
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.position = Vector2.ZERO
	_rect.size = Vector2(1280, 720)
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_rect.material = _mat
	add_child(_rect)
	set_edition(edition)


func set_edition(e: String) -> void:
	edition = e
	_sweep = {}
	_apply(PRESETS[e])


func _apply(p: Dictionary) -> void:
	_mat.set_shader_parameter("res", p["res"])
	_mat.set_shader_parameter("soft", p["soft"])
	_mat.set_shader_parameter("levels", p["levels"])
	_mat.set_shader_parameter("scan", p["scan"])
	_mat.set_shader_parameter("noise", p["noise"])
	_rect.visible = edition != "2k" or _glitch > 0.0 or not _sweep.is_empty()


## Tears the picture for `secs` seconds.
func glitch(amount := 1.0, secs := 0.6) -> void:
	_glitch = maxf(_glitch, amount)
	_glitch_t = maxf(_glitch_t, secs)
	_rect.visible = true


## Animates the resolution from the current edition to `e` over `dur` seconds (with a glitch).
func sweep_to(e: String, dur := 1.6) -> void:
	_sweep = {"from": PRESETS[edition], "to": PRESETS[e], "t": 0.0, "dur": dur, "name": e}
	glitch(0.8, dur * 0.6)


func _process(delta: float) -> void:
	_t += delta
	_mat.set_shader_parameter("time", _t)
	if _glitch_t > 0.0:
		_glitch_t -= delta
		_mat.set_shader_parameter("glitch", _glitch * clampf(_glitch_t / 0.3, 0.0, 1.0))
		if _glitch_t <= 0.0:
			_glitch = 0.0
			_mat.set_shader_parameter("glitch", 0.0)
			_rect.visible = edition != "2k" or not _sweep.is_empty()
	if not _sweep.is_empty():
		_sweep["t"] = float(_sweep["t"]) + delta
		var k := clampf(float(_sweep["t"]) / float(_sweep["dur"]), 0.0, 1.0)
		var e := k * k * (3.0 - 2.0 * k)
		var a: Dictionary = _sweep["from"]
		var b: Dictionary = _sweep["to"]
		_mat.set_shader_parameter("res", (a["res"] as Vector2).lerp(b["res"], e))
		_mat.set_shader_parameter("soft", lerpf(a["soft"], b["soft"], e))
		_mat.set_shader_parameter("levels", lerpf(a["levels"], b["levels"], e))
		_mat.set_shader_parameter("scan", lerpf(a["scan"], b["scan"], e))
		_mat.set_shader_parameter("noise", lerpf(a["noise"], b["noise"], e))
		if k >= 1.0:
			set_edition(String(_sweep["name"]))
