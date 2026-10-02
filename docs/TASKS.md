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
