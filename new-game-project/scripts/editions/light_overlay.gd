class_name LightOverlay
extends ColorRect
## Darkness with pools of light, over a fight scene (2K arenas and the 720p brawler). The scene calls
## set_lights() every frame with screen positions: [Vector2 pos, radius, intensity].

const SHADER := preload("res://scripts/editions/light_overlay.gdshader")
const MAX := 24

var darkness := 0.55
var _mat: ShaderMaterial


func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color.WHITE
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	material = _mat
	_mat.set_shader_parameter("darkness", darkness)


## lights: Array of [Vector2 screen pos, float radius, float intensity]
func set_lights(lights: Array, dark := -1.0) -> void:
	var arr := PackedVector4Array()
	for l: Array in lights:
		if arr.size() >= MAX:
			break
		var p: Vector2 = l[0]
		arr.append(Vector4(p.x, p.y, float(l[1]), float(l[2])))
	while arr.size() < MAX:
		arr.append(Vector4.ZERO)
	_mat.set_shader_parameter("lights", arr)
	_mat.set_shader_parameter("count", mini(lights.size(), MAX))
	if dark >= 0.0:
		_mat.set_shader_parameter("darkness", dark)


func set_hud_bands(top: float, bottom: float) -> void:
	_mat.set_shader_parameter("hud_top", top)
	_mat.set_shader_parameter("hud_bottom", bottom)
