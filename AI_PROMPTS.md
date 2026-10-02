# Starter Prompts

Paste each prompt into the matching IDE. Before pasting, make sure the worktrees from `AI_WORKFLOW.md` section 4 exist and each IDE has opened its own folder.

Replace `"Mirror Page", a comic-page light-routing puzzle where players drag panels and flip mirrors, and a narrator twists the rules (see docs/SCOPE.md)` with the one-paragraph game concept once it is decided. Until then, use the Phase 0 prompts as they are.

---

## Antigravity (AI Pro) - Phase 0 (Hours 0-12)

```
You are the content, UI and QA engineer on a 100-hour game jam team. The human is the designer. Read AI_WORKFLOW.md in the repo root first and follow it exactly.

Project: Godot 4.7, GDScript only, Compatibility renderer, exported to the Web and published on itch.io.
Themes: Comic, Twist, Light (all three must appear in the one game; first playthrough 15 min target, 20 max).
Rules that affect you: only free, open-source, CC0/CC BY or AI-generated assets; no paid assets; every asset must be logged in CREDITS.md (source link + license) or docs/AI_USAGE.md (tool + what it made + date).
You own: ui/, assets/, data/levels/, data/content/. Do not edit anything else. If you need a change elsewhere, add a task to docs/TASKS.md.

Phase 0 tasks (research only, do NOT write game code yet):
1. Research 8-10 visual references for a game that uses all three themes (comic-book look, a light-based mechanic, and a twist). Summarise each in 2 lines with what we could borrow. Save to docs/ART_REFERENCES.md.
2. Propose 3 distinct art directions with a colour palette (hex codes), font choices (open licence only, give the licence and link) and UI style for each.
3. List free CC0/CC BY sources for audio, fonts and textures that fit, with licence links.
4. Check the Godot web export size limits and give me a short asset budget (max texture size, audio format, total MB).
Output everything as markdown files under docs/. Keep each file short. Do not generate final assets yet.
```

## ChatGPT / Codex (Go) - Phase 0 (Hours 0-12)

```
You are the utility engineer on a 100-hour game jam team. The human is the designer. Read AI_WORKFLOW.md in the repo root first and follow it exactly.

Project: Godot 4.7, GDScript only, Compatibility renderer, Web export, hosted on itch.io.
Themes: Comic, Twist, Light (all three must appear in the one game; first playthrough 15 min target, 20 max).
You own: scripts/entities/, scripts/tools/, tests/, data/balance/, docs/, README.md, CREDITS.md, docs/AI_USAGE.md. Do not edit anything else. If you need a change elsewhere, add a task to docs/TASKS.md.
Your quota is small, so keep each task short and finish it fully before starting another.

Phase 0 tasks (documentation only, NO game code):
1. Create README.md with sections: game title placeholder, itch.io link placeholder, setup and run instructions (Godot 4.7), controls placeholder, team details (Sankeerth Nara, solo), license (MIT), credits link.
2. Create CREDITS.md with a table: Asset | Type | Author | Source link | License | Where used. Add one row for the Godot AI editor plugin (MIT, editor tooling only).
3. Create docs/AI_USAGE.md with a table: Date | Tool | What it produced | File(s). Add the three tools we use (Claude Code, Antigravity, ChatGPT/Codex) as the first rows.
4. Create docs/TASKS.md with the table format from AI_WORKFLOW.md section 5 and no tasks yet.
Commit with message "docs: add README, CREDITS, AI_USAGE, TASKS skeletons". Report what you created.
```

---

## Claude Code - Phase 0 (for reference; use it in this IDE)

```
Read AI_WORKFLOW.md. Fix the repo hygiene items in section 7, switch the renderer to Compatibility, then help me turn the themes Comic / Twist / Light into 3 game concepts that fit a 15-minute loop (20 minutes maximum) and use all three themes together. Draft docs/SCOPE.md and docs/ARCHITECTURE.md (event bus, entity interface, level data format) once I pick one.
```

---

## Phase 1 prompts (concept locked: "Mirror Page")

### Antigravity

```
WORKING FOLDER: open and edit ONLY D:\Infinium\wt-anti (branch anti/work). Never edit D:\Infinium\TGC-Game-Jam directly. First run: git merge main.
Read AI_WORKFLOW.md, docs/SCOPE.md, docs/ARCHITECTURE.md, docs/ART_DIRECTIONS.md and docs/TASKS.md.
Game: "Mirror Page", a comic-page light puzzle. Players drag comic panels to swap them and click mirrors to steer a beam onto star targets; a narrator twists the rules. It is a 2D puzzle, NOT a platformer, so ignore platformer/lantern ideas from the Phase 0 research.
Art direction: Direction 1 "Vintage Pulp & Ink" (newsprint paper, printer's black, lantern yellow beam, crimson for bad targets, violet for the twist inversion).
Your tasks in order (Owner = Antigravity in docs/TASKS.md): A2 comic UI in ui/ (main menu, HUD, caption box, pause, end screen) that only listens to EventBus signals and replaces the debug labels in scripts/core/main.gd (ask via TASKS.md if main.gd needs a hook, do not edit it); A3 art pass (textures in assets/, wired through PageView only if Claude agrees via TASKS.md); A4 audio (music loop, swap, mirror click, beam lit, twist sting); A5 levels 4-6 JSON in data/levels/ using the format in docs/ARCHITECTURE.md, rules "lying" (level 4), "bend" (level 5), "bend" + twist "flip" + locked_panels (level 6). Every level must pass: godot --headless --path new-game-project --script res://scripts/tools/level_check.gd (run --import once first). Use level_gen.gd to propose layouts, and write funny comic-narrator captions.
Rules: only free/CC0/CC BY/AI-generated assets; log third-party assets in CREDITS.md and AI-generated ones in docs/AI_USAGE.md. Keep the web build under the budget in docs/ASSET_BUDGET.md.
After each task: export Web (new-game-project/export_presets.cfg has a "Web" preset, output build/web), serve it and test in the browser with Playwright, report console errors, update docs/TASKS.md, commit with "ui:", "assets:" or "levels:" prefixes. Stop and report after each task.
```

### ChatGPT / Codex

```
WORKING FOLDER: open and edit ONLY D:\Infinium\wt-gpt (branch gpt/work). Never edit D:\Infinium\TGC-Game-Jam directly. First run: git merge main.
Read AI_WORKFLOW.md, docs/SCOPE.md, docs/ARCHITECTURE.md and docs/TASKS.md.
Game: "Mirror Page", a Godot 4.7 GDScript comic-page light puzzle (see docs/SCOPE.md). Logic lives in new-game-project/scripts/systems/page_model.gd and beam_solver.gd. Do NOT change these files or the interfaces; if you find a bug, add a task for Claude in docs/TASKS.md.
Your tasks, one at a time (Owner = ChatGPT in docs/TASKS.md): G2 headless unit tests in new-game-project/tests/ (runnable like scripts/tools/level_check.gd via: godot --headless --path new-game-project --script res://tests/run_tests.gd) covering reflection tables, the "lying" rule, the "bend" rule across panels, swap_panels incl. locked panels, toggle_mirror, status() with the twist flip, and solver edge cases (loops, out of bounds, wall, emitter blocking). G3 write data/balance/optimal_moves.json with the minimum move count per level from LevelSolver (twist levels: both stages), plus a tool script that regenerates it. Then update README.md controls (drag panel to swap, click mirror to flip, Z undo, R reset) and keep CREDITS.md and docs/AI_USAGE.md accurate.
Run the tests, commit with "tests:", "tools:" or "docs:" prefixes, mark tasks done, then stop and report. Keep each task small; your usage quota is limited.
```
