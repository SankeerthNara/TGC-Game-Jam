# Task Board

Statuses: todo / doing / done / blocked. Pick only tasks with your own name as Owner.

| ID | Owner | Task | Status | Depends on | Notes |
|---|---|---|---|---|---|
| C1 | Claude | Core: page model, beam solver, view, flow, 3 levels, validator | done | - | Playable placeholder build |
| C2 | Claude | Locked panels, final-level logic, polish of rules 4-6 | done | C1 | |
| C3 | Claude | Web export preset (Compatibility, include `*.json`) | done | C1 | |
| C4 | Claude | Verify EventBus contract works for UI/audio | done | C1 | comic_ui.tscn and main_menu.tscn wired into main.gd through request_* signals and game_state_changed; verified by rendered frames |
| A1 | Antigravity | Phase 0 research: art direction, palette, fonts, audio sources | done | - | Chosen direction: Vintage Pulp & Ink (docs/ART_DIRECTIONS.md). Research mentions platformer ideas; our game is a panel/mirror puzzle |
| A2 | Antigravity | Comic UI in `ui/`: menu, HUD, caption box, pause, end screen (listen to EventBus) | done | A1, C1 | Built `ui/comic_ui.*` and `ui/main_menu.*` with EventBus listeners |
| A3 | Antigravity | Art pass: panel paper, ink walls, mirrors, emitter, targets, beam glow, comic SFX words (POW, ZAP) | done | A1 | Created textures in `assets/art/` and open fonts in `assets/fonts/` |
| A4 | Antigravity | Audio: music loop, swap, mirror click, beam lit, twist sting (CC0 or AI generated, logged) | done | A1 | Generated procedural CC0 audio in `assets/audio/` |
| A5 | Antigravity | Author levels 4-6 JSON with `level_gen.gd` and `level_check.gd`, plus captions | done | C1 | All 6 levels complete and verified with `level_check.gd` (Level 5 bend, Level 6 bend+flip+locked) |
| A6 | Antigravity | Web export and Playwright playtest every few hours; report errors and size | done | C3 | Playwright automated test verified: 0 console errors, 454 KB PCK, screenshot captured |
| G1 | ChatGPT | README, CREDITS, AI_USAGE skeletons | done | - | |
| G2 | ChatGPT | Unit tests for BeamSolver and PageModel (reflection tables, bend rule, swap, status) in `tests/` | done | C1 | Headless script runnable like level_check |
| G3 | ChatGPT | Per-level optimal move counts from `level_check.gd` into `data/balance/` for a hint system | done | C1 | |
| G3b | ChatGPT | Add hint-data generator for indexed levels; document its command and README controls | done | G3 | `update_hints.gd` regenerates all indexed levels, including twist counts |
| C5 | Claude | Town overworld: walking, torch, lights, items, shop, keys, wrong-key decoy pages | done | C1 | `scripts/world/`, `data/world/town.json` |
| A7 | Antigravity | Town art and sound: shop and item sounds on `item_collected`, `trade_made`, `door_unlocked`; footsteps; town music; tweak house and tree art in `scripts/world/world.gd` drawing helpers only if Claude agrees via this board | todo | C5 | |
| G4 | ChatGPT | Headless town tests: every door reachable once gates open, items reachable, item and key budget is affordable, decoy keys open decoy pages (`tests/world_test.gd`) | todo | C5 | |
| C6 | Claude | Station mode: huge dark map, torch-only lighting, 15 tasks with progress bar, minimap, 7 mini-games | done | C5 | `scripts/tasks/`, `data/world/station.json` |
| A8 | Antigravity | Task art/sound: sounds for task start, success, fail (hook `task_started`, `task_completed`), station ambience, wall/floor/prop art polish via `World` draw helpers (ask on this board) | todo | C6 | |
| G5 | ChatGPT | Headless tests: every task console reachable, tasks list matches map, TaskRegistry covers every type in station.json | todo | C6 | |
| C7 | Claude | Sabotage timers and hearts, death and restart, free 8-direction movement, 6 comic/college mini-games, 18 tasks and 6 emergency fixes | done | C6 | |
| C8 | Claude | Levels: 4 generated levels of 8 random rooms, rising difficulty, checkpoints and respawn, level and total timers, split summary | done | C7 | `level_generator.gd`, `level_overlay.gd` |
| C9 | Claude | Remove unused town code (shop, items, keys, decoy pages) | todo | C8 | one clean-up commit first |
| C12 | Claude | Narrator system: portrait, bubbles, event-driven lines | todo | C9 | lines written by the developer |
| A9 | Antigravity | Four hero and villain looks, level themes (palette, props, fonts), boss and vampire art, fight music and SFX | todo | C12 | original characters only |
| G6 | ChatGPT | Headless tests for the choice outcomes, ally behaviour, fight states and respawn | todo | C10 | |
| C13 | Claude | Par times (2/3/4/5 min), 4/6/8/10 tasks, hidden risky tasks, sabotage counts 1/2/2/2 with big sabotages, task-undo disruption in level 4 | done | C8 | tune from timed playtests |
| C14 | Claude | Adaptive difficulty (easier next level after going over par) and the score system with ranks and breakdown | done | C13 | `score_keeper.gd`, `level_overlay.gd` |
| C10 | Claude | Vampires (patrol, flee from light, freeze), Reveal/Kill choice, four outcomes, villain starts sabotage himself, friend ally with growing help | done | C9 | `vampires.gd`, `vampire_choice.gd` |
| C11 | Claude | Parkour chase minigame; 13 new task types so no task repeats in a run | done | C10 | `parkour_game.gd`, `scripts/tasks/` |
| C12b | Claude | Cutscene system for detect/reveal/kill; level 1 warm-up (no vampires or sabotage) | done | C11 | `cutscene.gd` |
| C15 | Claude | Final boss: three relay duels (hero 2, 3, 4) vs the Narrator in the bomb room, bomb still ticking (at least 3:00 left guaranteed), sunlight and lava ending cutscenes | todo | C18 | at least 3 minutes in all |
| C16 | Claude | Hero special powers for the final duels (Deduction, Light Dash, Prism Cannon / Solar Flare); scripted knock-outs for heroes 2 and 3 | todo | C15 | |
| C17 | Claude | Opening cutscene (peaceful Earth, four heroes, masked villain, bomb) and mirrored closing cutscene | opening done (simple), closing todo | C12b | `cutscene.gd` |
| C18 | Claude | 17:00 bomb clock for the whole run, one key per level, bomb room cutscene (unmask: it is the Narrator; he captures the level 1 hero), Earth blast ending | done | C12b | `main.gd`, `cutscene.gd`, `task_hud.gd`, `tools/bomb_flow_test.tscn` |
| C19 | Claude | Instantiate `SfxPlayer` in the main game and verify task, sabotage, damage, death, and requested-sound playback end to end | todo | - | Add `add_child(SfxPlayer.new())` in `main.gd`; implementation and sound files are ready in `scripts/audio/` and `assets/audio/` |
| C20 | Claude | Route the 720p edition into the synced `music_synth_*` layers with a clean crossfade | todo | - | Four same-length looping assets are ready in `assets/audio/`; wire them from `scripts/core/music_director.gd` (outside Codex audio ownership) |
| A10 | Antigravity | Round 3 HUD redesign: compact comic top masthead (hearts, 17:00 bomb, 4 keys, level name, par/time, score), mini task bar, collapsible checklist (TAB), auto-hiding caption box | done | C18 | `task_hud.gd`, `ui/comic_ui.gd` |
| A11 | Antigravity | Round 3 Pause menu UI: comic spread modal with Resume, full Controls guide, Music on/off, SFX on/off, Restart level, Quit to menu | done | A10 | `ui/comic_ui.gd` |
| A12 | Antigravity | Round 3 Comic screen effects: full-screen shader with dark-area halftone dots, paper grain, ink vignette, color flash & shake on sabotage fail / death | done | A11 | `assets/shaders/comic_screen.gdshader`, `ui/comic_ui.gd` |
| A13 | Antigravity | Round 3 Level transitions: 1.5s comic panel-split transition with title card ("LEVEL n", level title, hero bust) | done | A12 | `ui/level_transition.gd`, `ui/comic_ui.gd` |
| A14 | Antigravity | Round 3 Main menu comic cover: big MIRROR PAGE 3D logo, looming masked villain, 4 hero busts, ticking 17:00 bomb, comic buttons | done | A13 | `ui/main_menu.gd` |
| A15 | Antigravity | Round 3 Score card & death overlays: comic page styling, animated rank badge with starburst, 4 bomb key icons | done | A14 | `level_overlay.gd`, `death_overlay.gd` |
| A16 | Antigravity | Round 3 Web export & Playwright smoke test: Chrome headless 30s walk, 0 console errors, 0 page errors, 1.51 MB PCK (39.48 MB total), 73.6 avg FPS (55.6 sustained) | done | A15 | `build/web/`, `tests/smoke_test_round3.py` |
