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

## Phase 1 prompts (use after the concept is locked at Hour 12)

### Antigravity

```
Read AI_WORKFLOW.md, docs/SCOPE.md and docs/ARCHITECTURE.md. Concept: "Mirror Page", a comic-page light-routing puzzle where players drag panels and flip mirrors, and a narrator twists the rules (see docs/SCOPE.md).
Build, in your owned folders only: (1) a main menu, pause menu and HUD in ui/ that listen to the signals in docs/ARCHITECTURE.md, (2) the first art pass and placeholder audio in assets/, (3) the first level data file in data/levels/ using the agreed format.
Log every generated asset in docs/AI_USAGE.md and every third-party asset in CREDITS.md.
After each task, export for Web, run it in the browser with Playwright, report console errors and the build size, then update docs/TASKS.md. Commit to your branch with "ui:" or "assets:" prefixes.
```

### ChatGPT / Codex

```
Read AI_WORKFLOW.md, docs/SCOPE.md and docs/ARCHITECTURE.md. Concept: "Mirror Page", a comic-page light-routing puzzle where players drag panels and flip mirrors, and a narrator twists the rules (see docs/SCOPE.md).
Take ONE task at a time from docs/TASKS.md where Owner = ChatGPT. Implement it in scripts/entities/, scripts/tools/, tests/ or data/balance/ against the interfaces in docs/ARCHITECTURE.md. Do not change the interfaces. If one is missing something, add a task for Claude instead.
Finish, run the project to confirm nothing is broken, mark the task done, commit with an "entities:", "tools:" or "tests:" prefix, then stop and report.
```
