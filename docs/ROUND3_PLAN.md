# Round 3: visuals, mechanics and audio (2026-10-04)

## Honest audit of the current build

**Visuals**
- In a level the HUD covers about a third of the screen (caption box, timers, task box and list), so the play area is small.
- Floors are flat brown tiles, walls are plain, every room and every level looks the same. No comic look in the level itself (no ink lines, halftone or panel framing).
- You always play the same generic hero; the four heroes of the story never appear in their own levels.
- The short vampire cutscenes (detected, reveal, kill) are still the old flat style; the story cutscenes are now comic pages.
- Menu is a plain paper page; no transitions between levels; task windows are plain panels.

**Mechanics**
- The final boss fight (the climax promised in the proposal) does not exist: after the bomb room the run ends on a score screen.
- There is no pause menu during play and no way to mute (the old pause only worked in the removed mirror puzzles).
- No tutorial: the first minute drops the player into the dark with a caption.
- Task quality is uneven (the safe and the ink spill had real problems); nobody has reviewed all 25.
- The chases were only checked by a bot; the ball chase may be too hard.

**Audio**
- Only 6 old sound effects exist (from the mirror game). Tasks, sabotage, hearts, vampires, keys, chases and cutscenes are silent.
- The music is now adaptive (4 layers), but simple.

**Process**
- No outside player has played the game yet. Get 2 or 3 friends on a build as soon as the pause menu and boss exist; their notes beat any of our own tests.

## Who does what (one owner per file, no exceptions)

| Owner | Area | Files |
|---|---|---|
| **Claude Code** | Boss fight, pause/mute logic, hero per level and level themes, tutorial, in-level world art, vampire cutscenes as comic pages, wiring, merges, web build | `scripts/core/`, `scripts/systems/`, `scripts/story/`, `scripts/chase/`, `scripts/world/world.gd`, `vampires.gd`, `cutscene.gd`, `level_generator.gd`, `vampire_choice.gd`, new `scripts/boss/`, `tools/make_music.py`, `project.godot` |
| **Antigravity** | HUD redesign, pause menu UI, screen effects, level transitions, menu, score cards, browser QA | `ui/` (all), `scripts/world/task_hud.gd`, `level_overlay.gd`, `minimap.gd`, `death_overlay.gd`, new `assets/shaders/`, new `assets/art/` files, `assets/story/` |
| **Codex** | Sound effects + sound player, task quality pass, task tests | `scripts/tasks/` (all, including `task_base.gd`), new `scripts/audio/`, new `tools/make_sfx.py`, new `assets/audio/sfx_*.wav`, `tests/`, `docs/TASK_REVIEW.md` |
| **Human** | Playtests with friends, deadline, design calls, merges approval | |

Everyone: log your work in `docs/AI_USAGE.md` (one row) and any asset in `CREDITS.md`. Small commits. Never commit to `main` directly; Claude merges your branch.

---

## Prompt for Antigravity (paste as is)

```
You are working on "Mirror Page", a Godot 4.7 (GDScript, Compatibility renderer, web export) comic game for the TGC Game Jam. Read docs/ROUND3_PLAN.md, docs/SCOPE.md and AI_WORKFLOW.md first.

SETUP
- Work in D:/Infinium/wt-anti on branch anti/work. Commit any of your own pending work, then run `git merge main`. If a merge conflict is in a file you do not own (see below), take main's version (`git checkout --theirs <file>`).
- Godot: D:/GAMES/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe. After pulling run it with `--headless --path new-game-project --import` and make sure there are no script errors.

YOU OWN (edit only these): new-game-project/ui/ (all), scripts/world/task_hud.gd, scripts/world/level_overlay.gd, scripts/world/minimap.gd, scripts/world/death_overlay.gd, new files in assets/shaders/, assets/art/, assets/story/.
DO NOT EDIT: scripts/core/, scripts/world/world.gd, vampires.gd, level_generator.gd, scripts/story/, scripts/chase/, scripts/tasks/, project.godot. If you need a change there, write it in docs/TASKS.md for Claude.
You may READ and CALL scripts/story/comic_art.gd (ComicArt drawing helpers: heroes, narrator, bomb, halftone, bursts) to draw characters.

GOAL: the game must look like a polished comic. Do these in order, commit after each:
1. HUD redesign (task_hud.gd). Today the caption box, timers, task box and task list cover about a third of the screen. Make it compact and comic-styled: one slim top bar with hearts, the BOMB countdown with the 4 keys, level name and score; a small task progress bar; the task list collapsible with TAB (closed by default after the first 10 seconds of a level); the sabotage alert stays big and red when active. Keep every piece of information and every field other scripts read (world.*, list_open). The caption box is in ui/comic_ui.gd: make it smaller and auto-hide after a few seconds.
2. Pause menu UI. Claude is adding pause during play: main.gd will emit EventBus.game_state_changed("paused") when the player presses P or Esc with nothing open, and listens to EventBus.request_pause(false) to resume. Build the overlay in ui/comic_ui.gd: Resume, Controls (list all controls: arrows move, Z interact/skip, M map, F give task to friend, TAB task list, chase controls), Music on/off (get_tree().call_group("music", "set_muted", bool)), Sound effects on/off (get_tree().call_group("sfx", "set_muted", bool)), Quit to menu (EventBus.request_quit_to_menu).
3. Comic screen effects: a light full-screen shader (assets/shaders/) with subtle halftone shading in the dark areas, paper grain and an ink vignette; a short colour flash + shake when EventBus.sabotage_failed or player_died fires. Must stay fast in the web build. Add it from ui/comic_ui.gd as its own CanvasLayer under the HUD.
4. Level transitions: when EventBus.level_started(index, title) fires, play a 1.5 s comic panel-split transition with a title card: "LEVEL n", the level title and the hero of that level (1 THE PULP HERO, 2 THE NOIR DETECTIVE, 3 THE NINJA, 4 THE SPACE HERO; draw them with ComicArt.hero_bust).
5. Main menu (ui/main_menu.gd): turn it into an animated comic cover: big MIRROR PAGE logo, the masked villain (ComicArt.narrator with mask_off = 0) looming, the four hero busts, a ticking bomb showing 17:00, buttons in comic style. Keep the existing buttons and signals.
6. Score card (level_overlay.gd) and death screen (death_overlay.gd): comic page styling, rank badge animation, key icons.
7. Optional, only if the jam rules allow AI-generated art (ask Sankeerth first): generate story panels described in docs/STORY_ART.md and drop them into new-game-project/assets/story/<key>.png. Log them in docs/AI_USAGE.md.
8. Export the web build (preset "Web", output build/web) and run a Playwright smoke test in Chrome: menu -> start -> skip opening cutscene (Z) -> walk around 30 s. Report load size, FPS and any console errors in docs/TASKS.md.

RULES: 1280x720 base resolution; fonts are Bangers (titles) and Comic Neue (text) in assets/fonts; colours INK #18151d, PAPER #fff3d1, GOLD #ffd23f, RED #e63946. Everything drawn in code or from free/AI assets that are credited. Add one row to docs/AI_USAGE.md. Commit small and often on anti/work. When done, tell Sankeerth so Claude can merge.
```

---

## Prompt for Codex / ChatGPT (paste as is)

```
You are working on "Mirror Page", a Godot 4.7 (GDScript, Compatibility renderer, web export) comic game for the TGC Game Jam. Read docs/ROUND3_PLAN.md, docs/SOUNDS.md and AI_WORKFLOW.md first.

SETUP
- Work in D:/Infinium/wt-gpt on branch gpt/work. Commit any of your own pending work, then `git merge main`. If a conflict is in a file you do not own, take main's version.
- Godot: D:/GAMES/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe. Run `--headless --path new-game-project --import` after pulling; no script errors allowed.

YOU OWN (edit only these): new-game-project/scripts/tasks/ (all task mini-games, task_base.gd, task_registry.gd), new folder scripts/audio/, new tools/make_sfx.py, new files assets/audio/sfx_*.wav, new-game-project/tests/, docs/TASK_REVIEW.md, docs/SOUNDS.md.
DO NOT EDIT: scripts/core/ (main.gd, event_bus.gd), scripts/world/, scripts/story/, scripts/chase/, ui/, project.godot. Need a change there? Write it in docs/TASKS.md for Claude.

JOB 1: SOUND EFFECTS (the game is almost silent today)
- Write tools/make_sfx.py in the style of tools/make_music.py (numpy only, synthesised from scratch, 22050 Hz mono 16-bit WAV) that creates every sound listed in docs/SOUNDS.md as new-game-project/assets/audio/sfx_<name>.wav. Comic, punchy, short, similar loudness.
- Write scripts/audio/sfx_player.gd: `class_name SfxPlayer extends Node`. A pool of 8 AudioStreamPlayers. In _ready add itself to group "sfx", connect EventBus.sound_requested(name) and the existing signals in docs/SOUNDS.md (task_started -> task_open, sabotage_started -> sabotage_alarm, ...). Small random pitch variation (0.95 to 1.05), a per-sound volume table, `func set_muted(on: bool)`. Missing files must not crash (just skip).
- Do not edit main.gd: Claude will add `add_child(SfxPlayer.new())` when merging.

JOB 2: TASK QUALITY PASS (25 mini-games in scripts/tasks/, registered in task_registry.gd)
- Play/read every task. For each one check: the title and one-line hint explain it clearly; it works with the mouse (and the keys its hint mentions); it cannot soft-lock; text never spills outside the 800x520 panel; difficulty 0..3 really changes it; wrong moves call flash(...) and solving calls succeed(); Esc always leaves.
- Fix every bug you find (the safe task had wrong scoring and a hidden reset; the ink spill task was removed for being bad). Keep each task under about 30 seconds for a first-timer at difficulty 1.
- Write docs/TASK_REVIEW.md: a table of task, what the player does, problems found, what you fixed, fun rating 1-5, keep or cut. List the 3 to 5 weakest tasks with a suggested replacement idea. Do NOT delete tasks; Sankeerth decides.

JOB 3: TESTS
- tests/tasks_smoke_test.gd (+ a .tscn to run it): create every registered task at difficulty 0..3 inside a CanvasLayer, run it for 60 frames, check there are no errors and that it emits nothing unexpected. Print PASS/FAIL per task and a total. Run: godot --headless --path new-game-project res://tests/tasks_smoke_test.tscn

Commit small and often on gpt/work. Add rows to docs/AI_USAGE.md and CREDITS.md (sounds are CC0, made by tools/make_sfx.py). When done, tell Sankeerth so Claude can merge.
```

---

## Claude's list (in order)

1. Pause during play (P / Esc) and mute hooks; EventBus sound hooks for everything (done: `sound_requested`).
2. Final boss: relay duels in the bomb room with the bomb still ticking (at least 3:00), hero powers, sunlight and lava endings, closing cutscene.
3. Play as the level's hero, with a themed level each (palette, floor/wall art, props, room names): 1 pulp newsroom, 2 rainy noir precinct, 3 lantern dojo, 4 orbit station.
4. A 30-second tutorial at the start of level 1.
5. In-level art: inked walls and props, floor patterns, better vampires; vampire cutscenes as comic pages.
6. Merge Antigravity and Codex work, add SfxPlayer, web build, keep main playable at every step.
