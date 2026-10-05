# Visual polish plan: make the fights read like the reference fights

Owner: Claude (branch `claude/editions`, pushed to `editions`). If Claude runs out of credits, any
agent (Antigravity / Codex) can pick up the first task whose **Status** is not DONE. Each task lists
the files, the exact approach, and how to check it. Keep every change small and visual; do not change
gameplay numbers unless the task says so.

Repo: `D:\Infinium\wt-claude` (worktree of branch `claude/editions`). Godot 4.7.2 console:
`D:/GAMES/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe`.
Run tools from `new-game-project/`:

- flow test (must print `FAILS: 0`):
  `"$G" --headless --fixed-fps 60 --path . res://scripts/tools/editions_flow_test.tscn`
- fight bots (each must "win"):
  `"$G" --headless --fixed-fps 60 --path . res://scripts/tools/arena_bot_test.tscn`
- screenshots of the 2K fights, saved to `%APPDATA%/Godot/app_userdata/Glitched Out/duel_*.png`:
  `"$G" --resolution 1280x720 --fixed-fps 60 --path . res://scripts/tools/duel_shot.tscn`
  (add `-- scribe late` for the Ink Scribe).
- web export: `"$G" --headless --path . --export-release "Web"`, which writes to `../build/web/`.
- zip for testers: copy `build/web/*` into `D:\Infinium\TGC-Game-Jam\build\playtest\game\`, then
  zip the contents of `build\playtest\` as `build\GlitchedOut_vN.zip`.
- If new PNGs were added, run `"$G" --headless --import --path .` once first.

Commit each task on `claude/editions` (`git push -q origin claude/editions:editions`), add a line to
`docs/NIGHT_LOG.md`. Never merge to main or publish to itch.io (Sankeerth does that).

The gaps (from Sankeerth's comparison with the reference videos), worst first:
1. You can't easily see the fighters: in the reference, the fighters are bright against a dim,
   blurred background. Ours are dark on a sharp, saturated painting, under the darkness overlay,
   and the hero is about 20% smaller.
2. The background competes with the action (the reference blurs and hazes it).
3. The climb's ledges are hard to see.
4. The screen is cluttered (objective, title, wave counter, key hints, comms box over the play area).
5. Hits are smaller (the reference has big white slash arcs, white hit flashes, petal bursts).
6. Fewer enemies on screen at once (the reference has 3-6).

---

## T1. Soft backgrounds (blur, darken, desaturate, haze): Status: DONE
- Why: gaps 1 and 2.
- Approach: pre-process the 2K background pictures offline (no runtime shader, so the web build
  stays fast). Script `tools/soften_backgrounds.py` (Python + Pillow) reads
  `new-game-project/assets/editions/2k/{hall_far,arena_far,arena_dark}.jpg` and
  `{hall_mid,arena_mid}.png`. It writes `<name>_soft.jpg` / `<name>_soft.png` next to them: Gaussian
  blur (far: radius 4, mid: radius 2), saturation x0.55, brightness x0.7, then a 18% blend toward a
  haze colour (hall: #1d2b33, opera: #2a2238), alpha kept for PNGs.
- Code: `scripts/boss/boss_fight.gd`, in `_ready()` where `_bg` is filled. For each key, load
  `<key>_soft` when it exists, else the original. The cutscenes keep using the sharp originals.
- Check: duel_shot frames. The background is visibly softer and darker; the fighters stand out.

## T2. Fighters pop: rim light, own light, 20% bigger: Status: DONE
- Rim: `scripts/editions/sprites.gd` gets `static func draw_rim(ci, key, feet, height, dir, col,
  squash, rot, width)`. It draws the same texture 8 times, offset by `width` px in 8 directions, with
  an overbright modulate (`Color(col.r*6, col.g*6, col.b*6, col.a)`), which clamps to a solid
  silhouette in the Compatibility renderer, before the normal draw. Use it in:
  - `scripts/boss/arena_enemy.gd` `draw()`: cream rim `Color(1, 0.93, 0.8, 0.55)`, width 3;
  - `scripts/editions/hero_animator.gd` `draw()`: hero rim `Color(0.75, 1, 1, 0.6)`, width 3.
- Own light: `boss_fight.gd` `_update_lights()` adds a small light (radius 170, intensity 0.55) on
  every live enemy's center, so the darkness overlay never hides a fighter.
- Size: `scripts/boss/arena_art.gd` `HERO_SCALE` 1.35 -> 1.62 (+20%); `arena_enemy.gd` `SPRITE_H`
  values x1.2. Hitboxes are not changed (the art only).
- Check: duel_shot frames; the hero and the enemies are readable at a glance; feet still on the floor.

## T3. Lit ledges on the climb: Status: DONE
- Code: `boss_fight.gd` `_draw_hall_floor()` (the `platforms` loop) and `_draw_climb()` (the
  `walls` top edge). Each ledge gets a warm glow strip above it (`ArenaArt.TEX_GLOW`), a 5 px bright
  top edge `Color(1, 0.86, 0.55)`, a lighter body colour `#3b4a48`, and a small lantern light per
  ledge in `_update_lights()` (only when `level_top < 0`, at most 10 lights).
- Check: `scripts/tools/parkour_shot.tscn` or the climb in a playthrough. Every ledge is visible.

## T4. Less clutter: Status: DONE
- Key hints: the long "WASD move ... F heal" line (bottom of `_draw_hud()` and the explore block in
  `_draw()`) and the "L parry hold L..." line under the ink meter show only during the first fight of
  a run. Add `static var hints_seen := false` to BossFight; set it in `_exit_tree()` once a fight was
  played for more than 15 s. The pause menu still lists all controls.
- Wave counter: hide "WAVE n/m" when the fight has a single wave.
- Comms box: `scripts/editions/comms_box.gd` `_draw_box()`. During fights (when a BossFight or
  BrawlerGame overlay is up), draw it at the top centre, smaller (`Rect2(330, 10, 620, 96)`),
  not bottom-left.
- Check: duel_shot frames; the play area is clear and the top-left only shows health and ink.

## T5. Bigger hits: Status: DONE
- `arena_art.gd` `slash()`: radius 62/90 -> 92/130, thickness 16/26 -> 22/34, near-white.
- `boss_fight.gd` `_draw_hero()`: also draw the slash arc when painted attack frames exist (today it
  is skipped), at 0.85 alpha.
- On every hit (`_hit_enemy`), set the enemy's `whiteout` to 0.06 s (it exists in arena_enemy) and
  burst 8 cream "petal" paper flakes (`_fx` kind "paper").
- Check: duel_shot frames show big white arcs and white flashes.

Notes from doing T1-T5:
- The darkness overlay dropped from 0.62 to 0.5 (`_update_lights`), because the soft backgrounds are already darker.
- The comms box is 600 px wide at the top centre during 2K fights (`boss_fight` group), so it clears the fight title.
- Hints count game seconds across fights (`BossFight.hints_seen`) and hide after 40 s.
- Tools: `scripts/tools/climb_shot.tscn` (library climb frames). It starts the 2K act directly, so the
  frames still show the 240p filter; that's a tool artifact, not the game.

## T6. More on screen: Status: DONE (opera waves 4/4/5 with tighter delays; bot 45-51 s; full run 12.8 min)
- Opera waves (`scripts/editions/editions_director.gd` `_opera()`): wave 2 and 3 get one or two
  extra light enemies (bat, dancer), so 3-5 are on screen. Re-run arena_bot_test (the opera must
  still be won) and playtime_test (the total must stay 10-15 min).

## T7. Compare with the references again, then polish: Status: DONE (first pass)
- Done: getting hit is heavier (hit-stop 0.22 s, white ring, ink splash); kills burst with a white
  ring and paper; comic words only for brutes and bosses (the reference has no text pops); a small
  shake on every landed hit. `duel_shot.tscn -- opera` renders the opera crowd.
- Ideas for a next pass, if time allows: a short camera zoom-in on parries; dust/particle motes in
  the lamp light; brighter floor edge in the library hall.
- Watch the duel_shot frames next to the reference videos (Hollow Knight Soul Master / Hornet). Fix
  whatever still reads worse: camera framing, hit-stop, screen shake, enemy telegraph readability.

## T8. Zip: Status: TODO
- Export the web build, copy it into `build/playtest/game`, and zip as `GlitchedOut_v3.zip` (after
  T1-T6), then `GlitchedOut_v4.zip` (after T7).
