# AI Workflow Division

Team: Sankeerth Nara (solo). Event: TGC Game Jam, 100 hours. Themes: **Comic / Twist / Light**.
All three themes (**Comic, Twist, Light**) must appear in the one game, not just one of them.
Engine: **Godot 4.7, GDScript only**, exported to the **Web (HTML5)** and published on itch.io.

Three AI IDEs work at the same time. They share one repo and one rule: **each IDE only edits the files it owns.**

| IDE | Role | One-line job |
|---|---|---|
| **Claude Code** (Claude Pro) | Architect and core engineer | Design, core gameplay code, hard bugs, review, integration |
| **Antigravity** (AI Pro) | Content, UI and QA | UI/UX, art/audio assets, level content, browser playtests, itch.io page |
| **ChatGPT / Codex** (Go) | Utility worker | Isolated small features, tests, data tables, docs, credits |

The human (Sankeerth) decides the design, merges branches and approves anything outward-facing.
Core design and direction must be the human's own work, so write the design decisions in `docs/DESIGN_LOG.md` in your own words.

---

## 1. Hard rules (competition)

1. No game code before Hour 0. Commit history is audited, so commit small and often.
2. Hour 12: the scope and idea lock. After that there are no premise pivots, and the game is judged against `docs/SCOPE.md`.
3. All game code is written within the 100 hours. No game templates or prebuilt system logic. Small generic snippets are allowed.
4. Only free, open-source, CC0/CC BY or AI-generated assets. Every third-party asset goes in `CREDITS.md` with a source link and license.
5. Every AI tool use is disclosed. Log it in `docs/AI_USAGE.md` (tool, what it produced, date).
6. Final build must run in the browser and have one complete, stable loop of **15 minutes target, 20 minutes hard maximum** (average first playthrough). The rules ask for 10-15 minutes and ignore anything past 20, so a 15-minute design is safest.
7. `README.md` must have the itch.io link, setup/run instructions, controls and team details.

## 2. Technical constraints (decided now so nobody breaks the web build)

- **Renderer must be Compatibility**, not Forward Plus. Godot 4 web export only works with Compatibility. The project currently says Forward Plus, so switching it is the first task for Claude.
- **GDScript only.** Godot 4 C# projects cannot export to the web.
- **No threads, no GDExtension, no native plugins** in game code (limited web support).
- Keep audio as `.ogg` or `.wav` and textures small. Check the build size early.
- Test the **web export** at least every 12 hours, not only at the end. Antigravity owns this check.
- The `godot_ai` addon and the `godot-ai/` folder are **editor tooling**, not part of the game. `godot-ai/` must not be committed to the game repo (see section 7).

## 3. Ownership map

One owner per folder. Anyone who needs a change in another owner's folder writes a request in `docs/TASKS.md` instead of editing it directly. `.tscn` and `.tres` files are the main merge-conflict risk, so **one scene file has one owner**.

```
new-game-project/            (Godot project root; rename later if wanted)
  project.godot              CLAUDE only
  scripts/core/              CLAUDE   game loop, state machine, autoloads, event bus
  scripts/systems/           CLAUDE   mechanics for the theme (light/twist/comic systems)
  scenes/main/, scenes/levels/logic  CLAUDE   scene structure and wiring
  ui/                        ANTIGRAVITY  menus, HUD, pause, settings, comic-style panels, transitions
  assets/art, assets/audio, assets/fonts  ANTIGRAVITY  all generated/sourced assets
  data/levels/, data/content/ ANTIGRAVITY  level layouts, dialogue, comic panel text (data only)
  scripts/entities/          CHATGPT  enemies/items/props following a CLAUDE-defined interface
  scripts/tools/, tests/     CHATGPT  helpers, test scenes, unit tests
  data/balance/              CHATGPT  tuning tables
  docs/, README.md, CREDITS.md, docs/AI_USAGE.md   CHATGPT  (human approves)
  docs/SCOPE.md, docs/DESIGN_LOG.md, AI_WORKFLOW.md  HUMAN + CLAUDE
```

## 4. Git workflow

- `main` is always playable. Only the human merges into it.
- One long-lived branch per IDE and one **git worktree** per IDE so they never share a working directory:

```bash
git worktree add ../wt-claude   -b claude/work
git worktree add ../wt-anti     -b anti/work
git worktree add ../wt-gpt      -b gpt/work
```

- Short tasks branch off the IDE's branch. Merge into `main` at least every 3-4 hours, then each IDE runs `git merge main` before its next task.
- Commit message style: `area: what changed`. Examples: `core: add light beam state`, `ui: comic speech bubble`.
- Never force-push. Never rewrite history. Never backdate commits.
- Only one editor session may drive one Godot editor through the MCP plugin at a time. Each worktree opens its own Godot editor instance, so two IDEs are never connected to the same one.

## 5. Task board

`docs/TASKS.md` is the single source of truth. Format:

```
| ID | Owner | Task | Status (todo/doing/done/blocked) | Depends on | Notes |
```

Rules:
- An IDE picks only tasks with its own name as owner.
- Mark `doing` before starting and `done` in the same commit that finishes the task.
- If an IDE hits its usage limit, it writes `HANDOFF:` in the notes with what is finished and what is left, so another IDE can pick it up.
- Cross-owner needs go in as a new task with a `Depends on` link.

## 6. Interface contracts

Claude defines these first and records them in `docs/ARCHITECTURE.md`. The other two IDEs build against them and do not invent their own:
- the event bus (signal names and payloads)
- the entity base class (what enemies/items must implement)
- the level data format (what Antigravity writes and Claude loads)
- the UI hooks (which signals the HUD listens to)

## 7. Repo hygiene (do before the first game commit)

- `godot-ai/` is a separate cloned repository and is now in `.gitignore`. Leave it out of the game repo.
- Add the `godot_ai` addon to `CREDITS.md` as editor tooling, or leave `addons/godot_ai` out of the repo.
- `.godot/` stays git-ignored.
- Put the exported web build in `build/web/` and add it to `.gitignore`. Upload it to itch.io, do not commit it.

## 8. Limit management

| IDE | Spend it on | Do not spend it on |
|---|---|---|
| Claude (tightest, best reasoning) | Architecture, core loop, hard bugs, reviews, the Hour 12 scope doc | Boilerplate, repetitive content, long asset-generation loops |
| Antigravity | UI, asset generation, browser-driven playtests, itch.io page copy | Core architecture decisions |
| ChatGPT Go (smallest agent quota) | Small, fully specified, isolated tasks | Large refactors, anything touching many files |

When one IDE is out of quota: stop its tasks, write the handoff note, move the task to the IDE with the most quota left, and do not wait.

## 9. Timeline (100 hours; Hour 0 = event start)

| Hours | Phase | Claude | Antigravity | ChatGPT |
|---|---|---|---|---|
| 0-12 | Concept lock | Turn the theme into 2-3 concepts, draft `docs/SCOPE.md` and `docs/ARCHITECTURE.md` | Reference and art-direction research (comic style, light mechanics) | Draft README, CREDITS and AI_USAGE skeletons |
| 12 | **Submit scope + repo** | Final review of scope | - | - |
| 12-30 | Vertical slice | Core loop, theme mechanic, scene wiring | Main menu, HUD, first art pass, placeholder audio | Entity base implementations, test scenes |
| 30-60 | Content | Systems, progression, difficulty | Levels, comic panels, SFX/music, visuals | Enemies/items, balance tables, tests |
| 60-85 | Polish | Bug fixing, performance, game-feel | Full web playtests, UI polish, tutorial | Regression tests, docs, credits audit |
| 85 | **Feature freeze** | Stability only | Final art/audio fixes | Docs only |
| 85-100 | Ship | Final integration and fixes | Web export, itch.io page, screenshots | README, CREDITS final check |
| 100 | **Code freeze** | - | - | - |

Target: a submitted itch.io build at Hour 96 or earlier, leaving the last hours as a safety margin.

## 10. Daily routine for each IDE

1. Read `AI_WORKFLOW.md`, `docs/ARCHITECTURE.md` and `docs/TASKS.md`.
2. Pick one task you own and mark it `doing`.
3. Work only in your owned folders.
4. Run the project (or the web export if you are Antigravity) and confirm nothing broke.
5. Commit, mark the task `done`, log any AI-generated asset in `docs/AI_USAGE.md`.
6. Tell the human, who merges.
