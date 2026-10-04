extends Node
## Screenshot of the main menu's credits panel (not part of the game).

func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var m: Node = (load("res://ui/main_menu.tscn") as PackedScene).instantiate()
	layer.add_child(m)
	for i in 10:
		await get_tree().process_frame
	m._credits_modal.visible = true
	for i in 5:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("user://menu_credits.png")
	get_tree().quit()
