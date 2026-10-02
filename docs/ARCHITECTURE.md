# Architecture

Godot 4.7, GDScript, Compatibility renderer. Godot project root is `new-game-project/`.

## Layers
| Layer | Files | Rule |
|---|---|---|
| Model (pure logic, no scene access) | `scripts/systems/page_model.gd`, `beam_solver.gd` | Testable headless. Never `get_node`, never draws. |
| View | `scripts/systems/page_view.gd` | Draws the model and turns mouse input into signals. Placeholder art, restyle freely. |
| Flow | `scripts/core/main.gd`, `game_state.gd` | Applies actions to the model, runs the twist, loads levels. |
| Events | `scripts/core/event_bus.gd` (autoload `EventBus`) | UI, audio and VFX only listen here. |
| Data | `data/levels/*.json`, `data/levels/index.json` | Level files. Add a file name to `index.json` to add a level. |
| Tools | `scripts/tools/level_solver.gd`, `level_check.gd`, `level_gen.gd` | Headless validators and generator. |

## Levels (generated at run time)
`scripts/world/level_generator.gd` builds each level: 8 rooms at random positions, joined by a spanning tree plus loops of corridors, consoles against room walls, risky tasks with far-away fix consoles, sabotage timers from real walking distance, and furniture. `LEVELS` there defines each level's tasks and risky count. `main.gd` runs the flow: `_load_level(i)`, level timers, level-complete overlay (checkpoint), death -> respawn at the level start. `TaskBase.difficulty` (0-3) scales each mini-game.

## The station (data format) and tasks
`data/world/station.json` (built by a generator script) is the default map: `rows`, `rooms` (name, rect, floor colour), `tasks` (id, tile, type, name, room, param), `intro`. Map characters: `#` wall, `.` floor, `K` task console, `c` crate, `t` table, `p` plant, `b` bookshelf, `@` start.
**Sabotage and health:** tasks marked `triggers` (shown with a red warning triangle and "RISKY" in the checklist) start a countdown from `sabotages` in the JSON when completed. A `fixes` console (marked `F`) becomes active for that sabotage; finishing its mini-game in time resolves it, otherwise the hero loses `damage` hearts (3 max). At 0 hearts the death screen appears and the run restarts. Events: `sabotage_started`, `sabotage_resolved`, `sabotage_failed`, `player_died`.
**Movement:** station mode uses free movement: any mix of arrow keys or WASD works, opposing keys cancel, two perpendicular keys go diagonal at the same speed.
Task mini-games live in `scripts/tasks/`: `task_base.gd` (overlay base class: panel, title, success burst, Esc to leave) and one script per type (`wires`, `switches`, `simon`, `charge`, `dial`, `blots`, `swipe`, plus comic tasks `panels` (order a comic story), `bubbles` (fill speech bubbles), `sfx` (type sound effects) and college tasks `debug` (find the bug), `logic` (logic gates), `sort` (shelve books)) registered in `task_registry.gd`. A `mirror` task launches light-puzzle page level `param`. To add a task: write a `TaskBase` subclass, register it, add a `K` tile and a `tasks` entry.
`TaskHUD` (progress bar and checklist) and `MiniMap` (M or Tab) are drawn by the World UI layer. Events: `task_started(id)`, `task_completed(id, done, total)`.

## The town (older overworld, still in the code)
`scripts/world/world.gd` (class `World`) is the seamless top-down town, driven by `data/world/town.json`.

| File | Job |
|---|---|
| `world.gd` | Grid walking (arrow keys), camera, collisions, items, keys, doors, gates, torch and lights, drawing |
| `shop_ui.gd` | The trade shop menu (Up/Down, Z to trade, X to leave) |
| `inventory_hud.gd` | Bottom-left strip with items and keys |
| `key_symbols.gd` | Vector icons for keys, keyholes and items (no image assets) |
| `glint_layer.gd` | Item glints and fireflies drawn above the darkness |
| `hero_actor.gd` (in `scripts/systems/`) | The hero: walking, moods, torch |

`town.json` keys: `rows` (ASCII map), `doors` (page index -> label and key shape), `keys` (shop stock, costs, blurbs, district), `items` (hidden item positions), `gates` (pages needed per ink-gate), `decoys` (page indexes that are wrong-comic pages), `signs`, `npc_lines`.
Map characters: `.` path, `,` hedge (solid), `T` tree (solid), `#` building, `1`-`8` page doors (door n opens puzzle level n-1), `S` shop door, `G` `H` `I` ink-gates, `N` narrator, `s` sign, `l` lamp, `o` brazier, `@` start.

Game states: `menu`, `world` (the town), `playing` (a page puzzle), `paused`, `ended`. A door only opens with the matching key; decoy keys open decoy pages, which never count toward progress.

## EventBus signals (the contract)
| Signal | When |
|---|---|
| `level_loaded(index, data)` | A level starts. `data` is the level JSON dictionary. |
| `panel_swapped(a, b)` | Two panels were swapped. |
| `panel_rejected(panel)` | Player tried to move a locked panel. |
| `mirror_toggled(cell)` | A mirror was flipped. |
| `move_count_changed(moves)` | After any action, undo or reset. |
| `beam_updated(good_lit, good_total, bad_lit)` | Beam retraced. |
| `caption_changed(text)` | New narrator caption to show in a comic caption box. |
| `twist_triggered(kind)` | Narrator twist happens: `"flip"` (goal swap) or `"wrong_page"` (decoy reveal). Play the big dramatic effect. |
| `level_solved(index)` | Level finished. |
| `game_finished` | Last level done. |

Town events (audio and effects can listen): `item_collected(type)`, `trade_made(key_id)`, `door_unlocked(puzzle_index)`.

UI -> game requests (UI emits, `main.gd` acts):

| Signal | Effect |
|---|---|
| `request_start_game` | Start from level 1 (state becomes `playing`) |
| `request_restart_level` | Reload the current level |
| `request_undo` | Undo the last move |
| `request_pause(paused)` | Pause or resume (also Esc key) |
| `request_quit_to_menu` | Back to the menu |
| `request_skip_level` | Debug builds only |

Game -> UI: `game_state_changed(state)` with `"menu"`, `"playing"`, `"paused"` or `"ended"`, and `level_restarted`.

**UI hook:** if `res://ui/ui_root.tscn` exists, `main.gd` instantiates it and starts in the `menu` state (the UI must emit `request_start_game`). Without it, a debug HUD is used and the game auto-starts. The UI scene should use a `CanvasLayer`, so it draws over the page.

UI/VFX/audio use only these signals and never read the model directly.

## Level JSON format
```json
{
  "name": "Page One",
  "panel_size": [3, 3],
  "layout": [3, 1],
  "rule": "normal",
  "twist": "none",
  "locked_panels": [],
  "caption_intro": "...", "caption_twist": "...", "caption_solved": "...",
  "cells": ["row string", "..."]
}
```
- `panel_size`: cells per panel (w, h). `layout`: panels across, panels down.
- `rule`: `normal`, `lying` or `bend`. `twist`: `none` or `flip`.
- `locked_panels`: optional panel indexes (row-major) that cannot move.
- `type`: `puzzle` (default) or `decoy`. A decoy page reveals "wrong page" after `reveal_after_moves` moves (default 2) or when solved, emits `twist_triggered("wrong_page")` and moves on.
- `skin`: optional page look: `romance`, `cooking` (see `PageView.SKINS`).
- `cells`: `layout[1]*panel_size[1]` rows, each `layout[0]*panel_size[0]` characters.

Cell characters: `.` empty, `#` wall, `/` and `\` mirror the player can flip, `a` and `b` fixed mirrors (`/` and `\`), `>` `v` `<` `^` emitter, `T` good target, `X` bad target (must not be lit in a normal level).
A backslash must be written `\\` inside JSON.

## Rules (set per level)
- `normal`: mirrors reflect as drawn.
- `lying`: every mirror reflects the opposite way.
- `bend`: a beam entering a different panel turns 90 degrees clockwise on the first cell it enters.
- Twist `flip`: after the first solve, `T` and `X` swap meaning and the level must be solved again.

## Authoring a level
1. Write it (or use `level_gen.gd`) and add the file name to `index.json`.
2. Run the validator. It must report `OK` and a sensible minimum move count (about 2-8):
```bash
godot --headless --path new-game-project --script res://scripts/tools/level_check.gd
```
3. Regenerate the hint move counts for every level in `index.json`. Flip-twist levels also get `twist_optimal_moves`:
```bash
godot --headless --path new-game-project --script res://scripts/tools/update_hints.gd
```
4. Generator example (prints the `cells` rows):
```bash
godot --headless --path new-game-project --script res://scripts/tools/level_gen.gd -- seed=7 cols=3 rows=2 pw=3 ph=3 walls=5 mirrors=3 min=4 max=7 count=3 rule=bend
```
First run in a fresh checkout needs `godot --headless --path new-game-project --import` once.

## Web export checklist
- Compatibility renderer only, GDScript only.
- The export preset must include `*.json` (levels are not imported resources).
- Test with a real browser build, not only the editor.
