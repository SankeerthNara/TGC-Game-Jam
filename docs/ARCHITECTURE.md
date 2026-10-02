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
| `twist_triggered(kind)` | Narrator twist happens (`"flip"`). Play the big dramatic effect. |
| `level_solved(index)` | Level finished. |
| `game_finished` | Last level done. |

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
3. Generator example (prints the `cells` rows):
```bash
godot --headless --path new-game-project --script res://scripts/tools/level_gen.gd -- seed=7 cols=3 rows=2 pw=3 ph=3 walls=5 mirrors=3 min=4 max=7 count=3 rule=bend
```
First run in a fresh checkout needs `godot --headless --path new-game-project --import` once.

## Web export checklist
- Compatibility renderer only, GDScript only.
- The export preset must include `*.json` (levels are not imported resources).
- Test with a real browser build, not only the editor.
