# Hand-off prompt for Antigravity (or Codex): finish the reference-fight polish

Paste everything below the line into Antigravity. Claude ran low on credits on 2026-10-06; this lists
what is done and what is left. Check the **Status** of each task first: Claude may have finished
some after writing this.

---

You are finishing "Glitched Out" (Godot 4.7.2, web export), TGC Game Jam, team "Game it". Work in the
git worktree `D:\Infinium\wt-claude` on branch `claude/editions`. Push with
`git push -q origin claude/editions:editions`. Never merge to main, never publish to itch.io, never
delete branches or rewrite history. After each task: run the flow test, commit, and add a line to
`docs/NIGHT_LOG.md`.

Godot console: `D:/GAMES/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe` (call it G).
From `new-game-project/`:
- flow test (must print `FAILS: 0`): `G --headless --fixed-fps 60 --path . res://scripts/tools/editions_flow_test.tscn`
- fight bots (each must win): `G --headless --fixed-fps 60 --path . res://scripts/tools/arena_bot_test.tscn`
- 720p bots: `.../brawler_bot_test.tscn`
- run length (target 10-15 min): `.../playtime_test.tscn`
- screenshots: `G --resolution 1280x720 --fixed-fps 60 --path . res://scripts/tools/duel_shot.tscn`
  (args: none = the Narrator, `-- scribe`, `-- scribe late`, `-- opera`). The output goes to
  `%APPDATA%/Godot/app_userdata/Glitched Out/duel_*.png`. Look at the frames after every visual change.
- web build: `G --headless --path . --export-release "Web"` (output: `../build/web`). Then copy
  `build/web/*` to `D:\Infinium\TGC-Game-Jam\build\playtest\game\` and zip the contents of
  `build\playtest\` as `D:\Infinium\TGC-Game-Jam\build\GlitchedOut_vN.zip` (the next free N).

The goal (Sankeerth): the two 2K boss fights replicate the reference videos' mechanics, fight
sequence and presentation in our theme:
- the Ink Scribe (library boss) = Hollow Knight's Soul Master;
- the Narrator (final boss) = Hollow Knight's Hornet (Greenpath).

Already done: the Scribe's teleports, homing orbs, charge, slam with shockwaves, fake death,
floor break into the archive, and faster phase 2 with orb rings and double slams. The Narrator's
lunge, thread throw, leap and dive, whirl, hop away, stagger, and faster phase 2. Painted frames for
both, soft backgrounds, rim-lit fighters, lit ledges, big white hits, the darkness and light
overlay, and the library's staircase (no forced wall climb). See `docs/VISUAL_POLISH_PLAN.md` and
`docs/NIGHT_LOG.md` sections 14-19.

## Tasks

### H1. Boss title like Hollow Knight: Status: DONE (the Twins already had a title card)
When a boss fight starts, show a non-blocking title over the play area (the fight runs underneath):
a small line above, a big name below, fading in for 0.5 s, holding 2 s, fading out over 1 s.
- Ink Scribe: "Archivist of the Masked One" / "THE INK SCRIBE"
- Narrator: "The Storyteller" / "THE NARRATOR"
- Static Twins (720p): "Two Bodies, One Signal" / "THE STATIC TWINS"

Code: `scripts/boss/boss_fight.gd` (`_draw()` after `_draw_hud()`; a `boss_title`/`boss_sub` pair
set by `scripts/editions/editions_director.gd` in `_scribe()` / `_final_boss()`), and
`scripts/editions/brawler_game.gd` for the Twins.

### H2. Soul Master stun (Ink Scribe): Status: DONE
Like the Soul Master, a run of hits (12% of his max health since the last stun) knocks him out of
the air: he drops to the floor and lies stunned for 1.6 s (free hits), then teleports away. Code:
`scripts/boss/arena_enemy.gd`, the `_scribe()` state machine (add a state "stunned"; count damage in
`take_hit` or in `boss_fight.gd` `_hit_enemy` for kind "scribe"). Not during fake_death, laugh or
crash. Draw with the `boss_scribe_fall_2` frame.

### H3. Hornet's defeat (Narrator): Status: DONE
At 0 health, before the ending cutscene, play a short defeat beat: a white flash, slow motion for
0.6 s, then he kneels (`narrator_stagger_2` frame, tilted) for 1.2 s. See `_finale` in
`editions_director.gd` and where BossFight emits `finished`.

### H4. Bot stalls on the library staircase: Status: TODO (test tooling only)
`scripts/tools/arena_bot.gd` `_climb()` needs an assist on two steps of the new staircase in
`start_2k()` (`editions_director.gd`). Make the bot jump while moving toward the next ledge, so
`climb_bot_test.tscn` runs with 0-1 assists. This doesn't affect players.

### H5. Final check and zip: Status: DONE once (v6, 13.7 min); repeat after any new change
Run the flow test, the arena bots, the brawler bots and the playtime test (10-15 min). Export, zip
the next version, add a NIGHT_LOG entry with the results.

## More ideas (not started; only if there is time before the 12 pm feature freeze)

### H6. Hornet's repositioning hops (Narrator): Status: TODO
Hornet often hops to a new spot between attacks. In `arena_enemy.gd` `_narrator()`, in "idle", when
the cooldown ends and the hero is mid-range, sometimes (25%) pick a short hop toward or away from the
hero (`_go("jump")`, `vel = Vector2(±420, -700)`, `target = Vector2(0, 0)`). On landing, go to
"recover". Keep `target.x` 1 / 2 for the dive / whirl as now.

### H7. 720p readability like the 2K fights: Status: TODO
The 720p brawler (`scripts/editions/brawler_game.gd`, `brawl_enemy.gd`) didn't get the rim light or
the softer backgrounds. In `brawl_enemy.gd` `draw()`, call `Sprites.draw_rim(...)` before the
`Sprites.draw(...)` of the painted/pixel sprite (cream rim, width 2). Check with
`scripts/tools/twins_shot.tscn` (720p frames).

Latest zip: `D:\Infinium\TGC-Game-Jam\build\GlitchedOut_v6.zip` (everything up to H5).
