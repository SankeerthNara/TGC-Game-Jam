import os

vampires_addition = '''func reveal_villain(i: int) -> void:
	list[i]["revealed"] = true


## Teleports the villain far away from the hero and returns him to active patrol.
func teleport_far(i: int) -> void:
	var v: Dictionary = list[i]
	v["revealed"] = true
	v["state"] = "patrol"
	v["mode"] = "patrol"
	v["light"] = 0.0
	v["thaw"] = 0.0
	v["path"] = []
	v["repath"] = 0.0
	var hero_tile := world.tile
	var candidates: Array[Vector2i] = []
	for r: Dictionary in world.rooms:
		var center := Vector2i(int(r["x"]) + int(r["w"]) / 2, int(r["y"]) + int(r["h"]) / 2)
		var tile := world.find_free_tile(center)
		candidates.append(tile)
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.distance_to(hero_tile) > b.distance_to(hero_tile))
	var pick_tile: Vector2i = candidates[0] if not candidates.is_empty() else hero_tile
	if candidates.size() >= 3:
		pick_tile = candidates[randi() % mini(3, candidates.size())]
	v["pos"] = world.center_of(pick_tile)
'''

for base in ['D:/Infinium/wt-claude', 'D:/Infinium/TGC-Game-Jam']:
    target = os.path.join(base, 'new-game-project/scripts/world/vampires.gd')
    if os.path.exists(target):
        with open(target, 'r', encoding='utf-8') as f:
            content = f.read()
        old_part = '''func reveal_villain(i: int) -> void:
	list[i]["revealed"] = true'''
        if old_part in content and 'func teleport_far' not in content:
            content = content.replace(old_part, vampires_addition)
            with open(target, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f'Updated {target}')

# Update main.gd
for base in ['D:/Infinium/wt-claude', 'D:/Infinium/TGC-Game-Jam']:
    target = os.path.join(base, 'new-game-project/scripts/core/main.gd')
    if os.path.exists(target):
        with open(target, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Update _on_vampire_caught
        old_caught = '''func _on_vampire_caught(i: int) -> void:
	EventBus.sound_requested.emit("vampire_spotted")
	EventBus.caption_changed.emit("NARRATOR: A vampire! Hold him in the light...")
	if world.vampires.other_resolved(i):
		_apply_vampire_choice(i, true)
		return'''
        new_caught = '''func _on_vampire_caught(i: int) -> void:
	EventBus.sound_requested.emit("vampire_spotted")
	EventBus.caption_changed.emit("NARRATOR: A vampire! Hold him in the light...")
	if world.vampires.other_resolved(i) and world.vampires.role_of(i) == "friend":
		_apply_vampire_choice(i, true)
		return'''
        if old_caught in content:
            content = content.replace(old_caught, new_caught)

        # Update _after_vampire_choice
        old_after = '''	elif reveal:
		world.vampires.reveal_villain(i)
		_start_parkour(i)'''
        new_after = '''	elif reveal:
		world.vampires.reveal_villain(i)
		world.vampires.teleport_far(i)
		world.hp = maxi(0, world.hp - 1)
		view.shake(14.0)
		EventBus.sound_requested.emit("hurt")
		_enter_world()
		if world.hp <= 0:
			world.player_died.emit()
		else:
			EventBus.caption_changed.emit("NARRATOR: The villain! He struck you, stole a heart, and vanished into the shadows!")'''
        if old_after in content:
            content = content.replace(old_after, new_after)

        with open(target, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f'Updated {target}')
