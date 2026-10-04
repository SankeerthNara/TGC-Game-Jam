class_name EditionWipe
extends CanvasLayer
## A comic page turn between scenes: an ink wedge sweeps across, the scene changes while the screen
## is covered (covered signal), then the wedge sweeps away. No black pops between fights.

signal covered
signal done

const DUR := 0.8
const INK := Color("0d0b10")
const GOLD := Color("ffd23f")

var title := "" ## optional text shown while covered
var _t := 0.0
var _fired := false
var _node: Control


func _ready() -> void:
	layer = 90 # under the edition filter, so the wipe looks like the current edition
	process_mode = Node.PROCESS_MODE_ALWAYS
	_node = Control.new()
	_node.size = Vector2(1280, 720)
	_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_node.draw.connect(_draw_wipe)
	add_child(_node)
	EventBus.sound_requested.emit("page_turn")


func _process(delta: float) -> void:
	_t += delta
	if not _fired and _t >= DUR * 0.5:
		_fired = true
		covered.emit()
	if _t >= DUR + (0.5 if title != "" else 0.0):
		done.emit()
		queue_free()
	_node.queue_redraw()


func _draw_wipe() -> void:
	var hold := 0.5 if title != "" else 0.0
	var k := _t / (DUR * 0.5)
	var x := 0.0
	if _t < DUR * 0.5:
		x = lerpf(-1700.0, 0.0, k * k * (3.0 - 2.0 * k)) # sweeping in
	elif _t < DUR * 0.5 + hold:
		x = 0.0
	else:
		var k2 := clampf((_t - DUR * 0.5 - hold) / (DUR * 0.5), 0.0, 1.0)
		x = lerpf(0.0, 1700.0, k2 * k2)
	var pts := PackedVector2Array([Vector2(x - 300, 0), Vector2(x + 1580, 0), Vector2(x + 1380, 720), Vector2(x - 500, 720)])
	_node.draw_colored_polygon(pts, INK)
	_node.draw_line(Vector2(x + 1580, 0), Vector2(x + 1380, 720), GOLD, 6.0)
	_node.draw_line(Vector2(x - 300, 0), Vector2(x - 500, 720), GOLD, 6.0)
	if title != "" and absf(x) < 200.0:
		ComicArt.shout(_node, title, Vector2(640 + x, 360), 72, GOLD, 12, -0.03)
