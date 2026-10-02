extends Node
## Autoload. Owns level progression and loads level JSON from res://data/levels/.

var levels: Array[Dictionary] = []
var level_index := 0


func _ready() -> void:
	load_levels()


func load_levels() -> void:
	levels.clear()
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels/index.json"))
	for file: String in index["levels"]:
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels/" + file))
		if data is Dictionary:
			levels.append(data)
		else:
			push_error("Bad level file: " + file)


func current_level() -> Dictionary:
	return levels[level_index]


func has_next() -> bool:
	return level_index + 1 < levels.size()


func advance() -> void:
	level_index += 1


func restart_game() -> void:
	level_index = 0
