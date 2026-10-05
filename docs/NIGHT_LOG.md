# Night log (Editions build, while Sankeerth sleeps)

Rules for the night: work only on `claude/editions` (pushed to `origin/editions`); never merge to
`main`, publish to itch.io, delete branches or rewrite history. Decisions are logged here.

## 2026-10-05

- Merged Antigravity's sprites (pulp hero frames, Narrator, masked villain, lancer, bat, brute, Ink Baron).
  Note: the status message said "all art delivered", but `book/` and `portraits/` are still empty and the
  720p pixel sprites (`px_*`) do not exist. Decision: keep the code-drawn fallbacks for those (the game
  already uses them automatically); nothing blocks on them.
- The masked villain sprite now conducts from the balcony spot on the painted opera stage (his face stays
  hidden until the reveal).
- Main menu text updated for the Editions (no bomb): subtitle, "NOW IN 144p!" badge, How to Play rules.
- Tests: editions flow test 0 fails; task smoke test 100/100.
- Hall fix: when the library hall's doors lock, roamers left outside stay outside (they used to be
  clamped into the locked fight and pile in).
- Balance (decision): a test bot lost the wave fights in about 30 s even with other heroes, so for the
  Editions the hero has 6 hearts and **dying restarts only the current wave** (full health) instead of
  the whole fight. Bot results after: Ink Baron win (2 retries), opera win, Narrator win. A bot is not a
  player; Sankeerth / friends must still play them.
- Web build re-exported (index.pck 20.4 MB, engine wasm 39.5 MB): loads in the browser, menu and book
  render, the edition shader works, no console errors. A full browser playthrough was not possible here
  (the preview pane is hidden, so the browser throttles the game); the desktop build plays end to end
  in the automated flow test.
- Menu: the villain's bubble now says "THE LIGHT IS MINE..." (no clock in the Editions).
- Full visual tour of every part (book → 144p → twist 1 → 720p street/twins → twist 2 → 2k hall/opera →
  reveal → Narrator → finale → ending). Fixes: the Narrator boss floated behind the curtain valance
  (now lower, in front of the cracked mask); his entry line in the Editions is "LET ME WRITE YOUR LAST PAGE!".
- README rewritten for the Editions (story, controls per edition, AI use).
- Story panels now use the same sprites as gameplay (masked villain rising, the unmask crossfade, the Narrator reveal, the hero escaping and on comms), framed so faces stay in view.
- 720p: no pixel sprites were delivered, so the brawler draws the painted hero frames; the 720p filter
  turns them into pixel art (looks right next to the pixel backgrounds).

## For Sankeerth in the morning
1. Play the whole Editions run once (about 16-18 minutes) from `D:\Infinium\wt-claude` (branch
   `claude/editions`, pushed as `origin/editions`). Note anything that feels wrong.
2. Decide: merge `editions` into `main` (I did not; rollback = keep `main` as the classic game).
3. Still missing art (code fallbacks are used, nothing is broken): book panels, comms portraits, 720p
   pixel sprites for the goons and the Twins.
4. Feature freeze Tuesday 12 pm; web build `build/web/` exports cleanly (20 MB pck).
- Merged Antigravity's next delivery: book panels (7), comms portraits (5), 720p pixel sprites (hero,
  thug, gunner, both Twins), key art. They replace the drawn placeholders automatically.
- Wired for the coming art (falls back if missing): pixel hero frames `px_hero_run1/run2/punch/kick/roll/hurt`
  in the brawler; pixel comms portraits `px_narrator_friendly/evil` in the 720p comms box.
- Pixel sprites drawn a bit bigger (hero 180 px, goons 170, Twins 230). Flow test 0 fails.

## 2026-10-05, after 3:20 am (polish pass)
- Transitions: no more empty/black screens between scenes. A finished fight stays frozen on screen
  until an ink page turn (`EditionWipe`, with a title card like "THE STATIC TWINS") covers it and the
  next scene starts underneath. The twist windows now appear over the frozen fight, so the player sees
  the 144p frame sharpen into 720p (and the credits sharpen into 2K).
- Twist 2: real fake credits ("THE END", the cast rolling with typewriter ticks, "THE MASKED VILLAIN
  ...still out there?") that freeze and glitch before the cursor is hijacked.
- The comms dying: the picture tears twice and the music drops out completely until the reveal page.
- Game feel: attack input is buffered in the brawler and the 2k fights (press X during a swing and the
  next hit follows); each brawler punch steps forward; knocked-out goons fly back, spin and fade
  instead of vanishing; landing and running kick up dust; the painted hero bobs and leans when running,
  leans into attacks and squashes on landing.
- Balance (decision): the brawler bot beat the Static Twins in 18 s, too short for a boss, so each Twin
  has 40 HP (was 26) and a counter does 3 to them (was 4). Bot now: street 47 s, Twins 33 s, no deaths.
  New tool: `scripts/tools/brawler_bot_test.tscn`.
- Telegraphs: the Narrator's dash shows a red lane across the stage and his slam a target ring on the floor; the Ink Baron's cane sweep shows the shockwave path and a "!" before every attack.
- Score cards in the Editions no longer mention bomb keys or a bomb clock ("Checkpoint saved. The Narrator is proud of you.").
- Each Editions fight shows its own title on the intro card and HUD (THE INK BARON / THE LIBRARY / THE OPERA / THE NARRATOR) instead of the relay "ROUND 1: THE PULP HERO".
- Big moments: a counter now bursts speed lines; during the brightness finale the Narrator begs over the comms as the slider rises (45%, 70%, 90%).
- Web: the window stretch aspect was "expand", so in a browser window that is not 16:9 the game drew in one corner with an uncovered band (the edition filter only covers 1280x720). Now "keep" (letterbox): the game always fits. Re-exported and checked in the browser (no console errors).

## Second pass (playtime, clarity, moments, audio, web)
- **Playtime measured** (`scripts/tools/playtime_test.tscn`: bots play every fight, cutscenes auto-advance
  with no skipping, windows clicked after 3 s of reading, the 144p task levels counted at par):
  book 20 s, Ink Baron 59 s, twist 1 16 s, street 46 s, Twins 24 s, twist 2 19 s, library 51 s,
  opera 35 s, reveal 24 s, Narrator 125 s (3 retries), ending 16 s, 144p levels 300 s (par).
  **Total 12.6 min with bots.** Bots fight much faster than first-time players (estimate x1.5-2 for the
  fights), so a real first playthrough was likely 16-20 min, too close to the 20-minute cut-off with the
  ending at the very end.
- Decisions to keep a first playthrough around 15-17 min: the 144p levels have 3 and 5 tasks (was 4 and 6)
  and kinder sabotage timers; the Narrator has a bit less health (x1.4, was x1.6) and **a retry keeps most
  of the damage done to a boss** (Ink Baron, Narrator) instead of healing him fully.
- First-time clarity: the 144p level intros now say the controls (arrows, Z at a glowing console, M map;
  vampires: hold the light, REVEAL or KILL, F gives a task to the friend); the comms box splits long lines
  into pages (lines used to be cut off after 3 rows, e.g. the 720p counter tip); the library shows its
  objective ("REACH THE END OF THE LIBRARY") and the controls while exploring; the street shows
  "BEAT THE GOONS (n left)" / "KEEP GOING >>".
- Failing is gentler: dying in a 144p level keeps the tasks already finished (it used to reset the level).
- Moments: the brass brute and the Ink Baron crash down from above (fast drop, shake, dust ring, "THE INK BARON!"); the Narrator arrives with a white flash, shake and a sting; the killing blow on a boss gets a long hit-stop, white flash and a burst of paper and light.
- Audio mix: measured every WAV (sound effects peak at -2.2 dB, music layers at -3 to -9 dB, no file
  clips). But up to four music layers plus effects could sum past 0 dB, so a hard limiter (ceiling -1 dB)
  now sits last on the master bus in every edition (after the 144p lo-fi effects). The music dips by
  about 4 dB while the Narrator speaks on the comms and comes back when he stops.
- Tests: the friend-task test now waits for the Editions' first level before running (it was finishing
  level 1 before the book's glitch had loaded it, so the level reloaded mid-test). It passes again.
- Performance (`scripts/tools/perf_probe.tscn`, desktop, real renderer): every fight and the brawler ran
  at the 180 fps cap, but the story pages only managed **33 fps with 2,723 draw calls**: every halftone
  dot was drawn one by one, every frame. In a browser (GDScript and WebGL are slower) that would have
  been about 10-15 fps during cutscenes. The halftone is now a tiled dot texture on a few soft-faded
  quads: same look, **28 draw calls, 180 fps**. It speeds up every screen that uses halftone (cutscenes,
  score cards, menus, the code-drawn stages).
- Performance inside the real game scene (`scripts/tools/perf_probe2.tscn`): main menu 180 fps (241 draw
  calls), book 180 fps (29), 144p level 1 180 fps (227 / 126 after walking). Web build re-exported
  (index.pck 20.9 MB, wasm 39.5 MB) and loaded in the browser with no console errors.
- The in-game Credits now disclose the AI art and the AI tools used (Claude Code, Antigravity,
  ChatGPT/Codex) and point to CREDITS.md and docs/AI_USAGE.md (jam rule: AI use must be disclosed).
  Checked that the longer text still fits the panel (`scripts/tools/menu_shot.tscn`).

## Moments, round two
- **Book opening**: the camera settles on the closed comic (a gleam slides over the cover, dust drifts
  in the lamp light). On Z or after the hold it pushes in until the cover fills the screen, the cover
  (drawn with the real cover art) swings open on its spine, two pages flick past and the page fills with
  light, which fades into the first story page. Replaces the plain ink wipe on that one page.
- **The unmasking**: the reveal pages now have camera moments: KZZZT! shakes, the RIIIP! hits with a
  big shake, white flash, zoom punch on the panel and the villain sting; the Narrator's reveal panel
  lands with a shockwave. His lines type out slowly ("This is the perfect ending...", "You fell into my
  trap perfectly.") so they land.
- **The Static Twins**: the hero drops onto the train roof (thud, dust), the Twins tune in out of
  static (flickering cyan and magenta bars, then a flash, shake and a burst of pixels), and the title
  snaps together from cyan and magenta ghosts with "TWO BODIES. ONE SIGNAL." Neon Street's card says
  what to do ("CLEAR THE STREET OF THE VILLAIN'S GOONS"). Bots: street 48 s, Twins 25 s, no deaths.
- **Solar flare**: the beaten Narrator kneels across the stage as a fading ink figure, shedding ink
  drops faster as the brightness rises; at 100% sun rays burst out of the hero, a shock ring rolls out,
  "SOLAR FLARE!", the stage shakes, he bursts into ink and the page burns white into the ending. The
  beams now meet the hero where the fight ended (they aimed at the screen centre before).
- Bug fixed: dragging the brightness slider fast queued all three of the Narrator's pleas, and they
  kept playing over the ending pages. Each plea now cuts off the last, and the comms clear at 100%.
- **The book closes**: the last page starts zoomed into the comic and pulls back onto the closed book;
  THE END lands with a thud and a shake.
- Layout: the boss health bars (Ink Baron, Narrator, Static Twins) moved to the bottom right; the comms
  box (bottom left) used to cover their names and half the bar whenever the Narrator spoke in a fight.
- New tool: `scripts/tools/moments_shots.tscn` freezes each of these moments for screenshots.

## Antigravity's new character art (merged 77a41de)
- Merged anti/work: painted 2K hero frames (idle, run, jump, attack, dash, hurt), the Narrator (unmasked,
  ink swirling from his quill) and the masked villain, new comms portraits, true pixel-art hero frames
  for 720p (run, punch, kick, roll, hurt) and pixel Narrator portraits, plus reference sheets.
- Fixed a cutout artefact before use: white background trapped inside the silhouettes (between an arm
  and the body, inside the Narrator's ink swirl) stayed opaque, so the Narrator carried big white blobs
  and the hero white patches at the hip. New `tools/fix_enclosed_white.py` makes those pockets
  transparent (white in a dark ink ring = trapped background; white in a bright glow = the light blade,
  kept; the face is protected so the eyes, teeth and monocle stay). Applied to the 7 hero frames and
  the Narrator (the masked villain was clean).
- Checked in every scene (tour screenshots): 144p arena, 720p street and train, library, opera, the
  Narrator fight and the finale. Bots unchanged: Ink Baron 35 s, opera 55 s, Narrator 55 s.

## 144p readability (found while checking the new art)
- In 144p the whole screen was filtered to 256x144, so the comms box, the task list and the console
  tasks were unreadable (the speech-bubble task could not be played at all, and the Narrator's very
  first instructions, the controls, could not be read). Decision: in the dark rooms the filter now sits
  just above the world (the rooms stay mushy and colour-crushed; the HUD, consoles, REVEAL/KILL choice
  and score cards are crisp). In fights, cutscenes and page turns it still covers the whole screen. The
  comms box sits above the filter in every edition, and the Ink Baron's opening line now gives the
  controls (his intro card is 144p). The comms line waits while a console task is open (it used to
  cover the task's instructions) and continues when the task closes.

## The book's panels, composed from the painted art
- The book opening's story panels (op_peace, op_heroes, op_villain, op_capture, op_escape, op_comms)
  were flat placeholder shapes (a smiley Earth, triangle heroes), the weakest visuals in the game and
  the first thing a judge sees after the menu. New `scripts/story/book_panels.gd` composes them from
  the painted sprites and portraits plus drawn light and ink: a lit Earth (drifting continents and
  clouds, night side, atmosphere) circled by the four heroes' light trails; the painted pulp hero with
  his team in round insets; the masked villain (painted) pulling streams of light out of the sky into
  his quill while the city below breaks into ever bigger pixel blocks ("the world began to lose its
  detail"); the three heroes in hanging ink cages under spotlights, ink dripping; the hero dashing
  through a crack of light with ink grabbing at him; the hero (painted portrait) listening to the comms
  machine with the friendly Narrator's face on its screen and his voice on the wave line.
- The reveal reuses them (the comms machine with static and NO SIGNAL, the caged heroes) and the ending
  gets new ones: the painted hero's slash gathering the freed heroes' light, the painted Narrator
  fading from the feet up with ink rising off him, the four heroes, and a sunlit Earth.
- New keys (bk_*), so if painted book panels arrive later as op_*.png they can be compared and swapped.

## Menu, medallions, web size
- Main menu restaged as a comic cover with the painted art: the masked villain looms in a purple glow
  behind the logo ("THE LIGHT IS MINE..."), the painted pulp hero stands in the foreground under
  "THE LAST HERO STANDING!" (the four flat busts and the code-drawn villain face are the fallback if
  the sprites are missing).
- The fight HUD medallion and the comms box show the painted portraits, clipped to a disc.
- Fixed a faint line above sprites: the halftone turns on texture repeat for the canvas item it draws
  on, so a sprite drawn on the same item had its bottom row (the boots) wrap around to its top edge.
  Sprites now sample half a texel inside their edges.
- Web download halved: the 2K background layers are imported as lossy WebP at quality 0.85 (no visible
  change; 15.4 MB -> 2.7 MB) and Antigravity's reference sheets and preview composites are excluded
  from the game (`.gdignore` + export filter). index.pck 20.9 MB -> about 10 MB with all the new art.
  Web build re-exported and loaded in the browser: no console errors.
- The masked villain conducting from the opera balcony showed only his legs with the new, taller art
  (the curtain valance hides anything above y 140). He now floats lower, fully visible, in his spotlight.
- Asked the watchdog to relay the next art request to Antigravity: the four 2K enemies (lancer, bat,
  brute, Ink Baron) are still the old flat sprites and are now the biggest style clash.

## Bug: the final fight could never end (fixed)
- The full playtime test hung in the Narrator fight for an hour. Probe (`scripts/tools/final_probe.tscn`,
  jumps straight to the fight with the bot): in 2 of 4 runs the Narrator's health went below zero and
  kept falling (to -19,000) while the fight never ended. Cause: the Light Blade (V) is fired from input
  events, which still run during hit-stop. A Light Blade landing on the already-beaten Narrator hit him
  again and restarted the hit-stop, so the update that removes him and declares the win never ran.
  A player mashing V at the killing blow could soft-lock the last fight of the game.
- Fix: an enemy that is already beaten cannot be hit again. Probe: 6 of 6 runs finish (37-66 s).
  Flow test 0 fails; bots: Ink Baron 32 s, opera 49 s, Narrator 63 s, street 62 s, Twins 27 s.
- Playtime re-measured after the fix: the whole game runs end to end, 11.2 min with bots (book 21 s,
  Ink Baron 36 s, street 46 s, Twins 24 s, library 42 s, opera 43 s, reveal 18 s, Narrator 57 s, ending
  17 s, 144p levels 5 min at par). A first-time human: roughly 14-18 min.
- Toward the 10-15 min target (watchdog): my human estimate was 14-18 min, so the 144p level 2 now
  has 4 tasks with kinder sabotage timers (ease 2, was 5 tasks) and the Narrator has x1.3 health (was
  x1.4). Expected first playthrough about 13-16 min. Flow test 0 fails.

## Soft-lock hunt (watchdog)
- New `scripts/tools/chaos_test.tscn`: the playtime bot plays everything while random keys are mashed
  every half second (P pause, Esc, Z, Enter, Space, M map, Tab) through cutscenes, page turns, twists,
  fights and the finale; it reports STUCK if one screen lasts 4 minutes. Two runs: both reached the
  final screen (12.7 and 12.2 min including the random pauses). No soft-lock found besides the
  Light Blade one fixed above.
- Clarity audit: controls are stated when they change (144p comms intro, the Ink Baron's comms line,
  the brawler's bottom line and counter tip, the library's explore prompt, each arena's first wave),
  and retries already restart in about 2 s with progress kept. The missing piece was objectives in
  arena waves without a boss bar: they now show "CLEAR THE STAGE (n left)" at the top.
- Targeted edge tests (`scripts/tools/edge_test.tscn`, the playtime bot plus two set-ups; both runs reach
  the final screen):
  1. Pause the moment the street fight is won (the game is still pausable while the page turn to the
     Twins is pending), hold 6 s, unpause: the game held still (the swap waits for unpause) and the
     Twins started normally.
  2. The hero takes a lethal hit on the frame the Ink Baron takes his killing blow: it used to count as
     a death (retry, the kill lost), and an already-beaten enemy could still hurt the hero on the frame
     he fell. Now beaten enemies can't hit, and a blow that would kill the hero on the frame the boss
     falls leaves him on 1 heart: the win stands.
- Dying during a cutscene can't happen by design: fights are frozen ("retired") once won, and story
  pages, twists and the finale have no damage.

## Game feel pass (after the 8:20 reset)
- 2K controller checked: coyote time, jump buffer and variable jump height were already in.
- 144p rooms: dark by design even without the filter; the torch flickers; the colour banding in the
  torch glow is part of the cheap-edition look. Left as is.
- Story bug fixed: the level-intro card of the 144p level 2 showed the Noir Detective ("SHADOWS IN THE
  RAINY PRECINCT"), one of the captured heroes; the card picked the hero by level (old relay design).
  In the Editions it is always the pulp hero, with his painted portrait.

## Final polish pass (Monday morning; freeze is Tuesday 12 pm)
- Pause menu bugs fixed (found by reading the code, then tested):
  1. RESTART LEVEL during any fight reloaded the last 144p dark room (it called the world loader), so
     restarting the Opera dropped you into a 144p room under the 2K filter. Now it restarts the fight on
     screen (each fight's start is remembered by the director); in the rooms it still reloads the room.
  2. QUIT TO MENU left the abandoned run running: the edition filter (a pixelated menu after quitting in
     720p), the comms, the frozen fight behind the menu, and the director's timers and page turns, which
     could start the next scene over the menu or inside a new run. The director now has reset(): a run
     counter makes old timers and page turns do nothing, and the filter, audio, comms and fourth-wall
     windows are reset; the scene layer is cleared.
- New `scripts/tools/menu_restart_test.tscn`: RESTART in all six fights (Ink Baron, street, train,
  library, opera, Narrator) restarts that fight; quit to menu in the opera leaves a clean menu (no
  filter, no scene, quiet comms, nothing starts in 12 s); a new run then plays to the end. 11/11 pass.
- Pause menu was invisible in every fight and console task: the comic UI (and its pause menu) sits on
  canvas layer 10, the fights and tasks on 18. Pressing P froze the game with no menu: it looked like a
  hang. While paused the UI now moves to layer 110 (above the fights, the edition filter and the comms).
  The comms no longer keep typing while paused.
- Proofreading (every comms line, card, twist, finale, menu help, credits, score and death screens):
  the Editions lines read cleanly; fixed leftovers of the classic game: the death screen said "The
  station won this round" and always added "The bomb clock is still running!" (no bomb in the
  Editions); the pause screen's guide listed the classic chase controls of levels 3 and 4 and no fight
  controls: in the Editions it now lists the villain chase, the 720p brawl and the 2K fights. The
  library card's control line was unlike every other one ("X slash", no jump) and, once fixed, too long
  for the card: now "Z jump  X attack (+UP / +DOWN)  C dash  V blade  F heal". The fight intro cards
  draw the (taller) painted hero a little smaller so he no longer covers the title.
- Tests: flow 0 fails; menu/restart 0 fails and the run reaches the end.
- Final checks on 51797c4: chaos test reaches the end (11.4 min with random mashing), edge test reaches
  the end (same-frame clash: hero on 1 heart, the win stands), menu/restart 0 fails, flow 0 fails. Web
  build re-exported (index.pck about 10.2 MB). CREDITS.md and docs/AI_USAGE.md now also list the
  code-composed story panels and the sprite cleanup tool. Now waiting for Sankeerth's playtest.

## Antigravity's painted enemies (merged 4bb00e1)
- Merged anti/work: painted 2K lancer, paper bat, brass brute and Ink Baron, plus the Ink Baron and
  Static Twins comms portraits (conflicts in CREDITS.md and docs/AI_USAGE.md: kept both sides). The new
  reference sheets stay out of the game (`.gdignore`). The sprite cleanup found no trapped white in
  them; edge bleed is already handled for every sprite in Sprites.draw.
- In-game check (stage shots, a Baron/Twins probe `scripts/tools/baron_shot.tscn`, the tour): the new
  art is dark and drew small next to the hero, so the lancer nearly vanished on the dark stages.
  Decisions: draw heights raised (lancer 120 -> 160, bat 64 -> 96, brute 190 -> 220, Ink Baron
  230 -> 255; hitboxes unchanged), a warm aura behind every enemy (not the Narrator) so they read as
  hostile on dark backgrounds, and the library's foreground drapes are drawn see-through (55%) so no
  enemy hides behind them. Hit flashes and deaths still read (tint flash, paper burst).
- The two new portraits were loaded but never used: the Ink Baron now taunts on the comms when he lands
  ("Ah, fresh paper! I'll blot you out, hero!") and the Twins as they tune in ("Two channels. One
  signal. Zero chance.").
- Tests: flow 0 fails; bots: Ink Baron 31 s, opera 35 s, Narrator 55 s, street 50 s, Twins 26 s.
  Web build re-exported (index.pck 11.5 MB). Back to waiting for Sankeerth's playtest.

## Sankeerth's playtest feedback (Monday)
### 1. Renamed to "Glitched Out"
- Title changed in project.godot (config/name: window title and the web page title), the menu logo
  (now with cyan/magenta ghosts that jump apart in short glitch bursts), the in-game credits, the book
  cover, the fake credits roll, the final score card, README.md, docs/EDITIONS_PLAN.md,
  docs/ITCH_PAGE.md, code comments and the art pipeline scripts. Older planning docs (proposal, scope,
  concepts, round plans) are kept as written, as a historical record.
- config/name moves user:// (now `app_userdata/Glitched Out/`). The game saves nothing there (no
  settings or progress files; only the test tools write screenshots), so nothing is lost. The boot
  splash is Godot's default (no custom image to change).

### 2. Hero movement and animation (Sankeerth's top priority)
New `scripts/editions/hero_animator.gd` (HeroAnimator), used by the 2K fights and the 720p brawler:
- **Frame sets when they exist, current frames as the fallback.** Sets are found and counted when first
  needed, so partial deliveries work set by set. Names (the Antigravity prompt,
  build/prompts/ANTIGRAVITY_HERO_ANIMATION.md), all in assets/editions/sprites/, facing right, feet on
  the bottom edge, same canvas per set:
  - 2K (512x512): `hero_run_1..12` (14 fps, scaled with speed), `hero_runstart_1..3`, `hero_skid_1..3`,
    `hero_turn_1..3`, `hero_land_1..2` (these four play once as transitions), `hero_jump_1..6` (one
    arc: crouch, take-off, rising, apex, falling, about to land; picked by vertical speed),
    `hero_idle_1..6` (8 fps), `hero_attack1_1..3`, `hero_attack2_1..3`, `hero_attack3_1..4`,
    `hero_upslash_1..3`, `hero_downslash_1..3`, `hero_blade_1..4` (Light Blade) - attack frames follow
    the swing (wind-up, strike, recovery) - `hero_dash_1..3`, `hero_heal_1..3`, `hero_hurt_1..2`,
    `hero_ko_1..3` (while the fight resets after a knockout).
  - 720p (64x64): `px_hero_run_1..10`, `px_hero_runstart_1..2`, `px_hero_skid_1..2`, `px_hero_turn_1..2`,
    `px_hero_land_1..2`, `px_hero_jump_1..4` (take-off, rising, apex, falling), `px_hero_idle_1..4`,
    `px_hero_punch1_1..3`, `px_hero_punch2_1..3`, `px_hero_punch3_1..4`, `px_hero_roll_1..4`,
    `px_hero_counter_1..3`, `px_hero_hurt_1..2`, `px_hero_ko_1..3`.
  - With a turn set the turn frames show the turn (no squeeze through the edge). Any missing set falls
    back to today's single frames with the procedural motion below.
  - `scripts/tools/anim_sets_test.tscn` puts fake sets in the sprite cache and checks the names, the
    counts, the jump arc by speed, the once-only transitions, attacks following the swing and the
    fallbacks: 14/14 pass.
- **No hard swaps:** a 0.1 s crossfade between animations; a motion smear on each strike; the hero
  turns around by swinging through a thin edge-on frame (about 0.12 s) instead of flipping instantly.
- **Procedural motion on top of the frames** (the picture is drawn as a 6x6 mesh that bends): lean into
  the run and back on a skid; squash on landing and stretch on take-off (springs); breathing in idle;
  anticipation (lean back), strike (lunge) and follow-through on every attack, different for each hit of
  the combo; hit recoil; the cape (the back of the picture, most at the bottom) trails behind the motion
  on a damped spring and overshoots when he stops; it rises when he falls.
- A cut-out rig (head, torso, arms, cape cut out of the painting) was considered and not done: the
  painted frames have the cape and blade overlapping the body, so cutting them would leave holes and
  seams; bending the whole painting gives the secondary motion without them.
- **Physics:** speed now builds and runs out (accel 3000, a short slide when stopping) instead of the
  near-instant 4200; turning at speed skids (dust, back lean, 0.14 s); the air keeps the jump's
  momentum (little air drag); a hard landing (falling faster than 700) slows the first steps.
- **Always facing the enemy:** X, V (2K) and a punch (720p) turn the hero to the nearest enemy in reach,
  in front or behind, also on every hit of a combo (the counter already did). `scripts/tools/face_test.tscn`:
  enemy behind, X -> turned, in both editions.
- **Combo hits differ:** 2K slashes cut high, low backhand, then a big flat third hit with a step in;
  each has its own lean curve. **Enemies recoil away from the blow** (direction-aware; bosses barely budge).
- Captures (`scripts/tools/hero_strip.tscn`: run, stop, reverse, jump, land, three attacks):
  `docs/captures/hero_2k_before.png` / `hero_2k_after.png`, `hero_720p_before.png` / `hero_720p_after.png`.
  In the after strips: the lean into the run, the thin turn-around frame, the cape flying up in the
  jump, the squash on landing and the smears behind each strike.
- Tests: flow 0 fails; bots win (Ink Baron 23 s, opera 32 s, Narrator 53 s, street 44 s, Twins 25 s,
  a little faster than before since the hero no longer swings at empty air); face test 0 fails.
  Web build re-exported (page title "Glitched Out", index.pck 11.6 MB).

### 3. Controls: WASD, J/K/L, Space (Sankeerth)
- New InputMap actions in project.godot: move_left/right/up/down (arrows + WASD), jump (Z + Space),
  attack (J), dash (K), power (L), heal (F). The 2K fights and the 720p brawler read these actions
  (no hard-coded X/C/V left); X, C and V are in no action. 2K: J attack (W/Up up-slash, S/Down
  down-slash in the air, S/Down also drops through platforms), K dash, L Light Blade, F heal.
  720p: J punch combo, K roll, L counter.
- WASD everywhere arrows were used: the 144p rooms, the rolling chase, the dial and rain tasks
  already had it; added to the safe-code and Simon tasks, the settings window and the brightness
  slider (hold D).
- Clashes found and fixed: the vampire choice used X to strike: now J (and 2); console tasks also
  closed on X: now Esc only (the hint always said ESC). The classic shop and the classic web chase
  (not in the Editions) keep their keys. P, M, F, Tab, Esc unchanged; nothing else clashes (tasks use
  the mouse, arrows/WASD, Space or Enter).
- Every on-screen mention updated: fight and brawler control lines, the "PRESS L WHEN THE ENEMY'S
  EYES TURN RED" tip, the Ink Baron's comms line, the Twins briefing, the intro cards, the HUD
  ("L LIGHT BLADE (3)"), the pause-menu guide, the menu's How to Play, README, ITCH_PAGE (its control
  list was already wrong: rewritten), and the bots and capture tools (press J/K/L).
- New `scripts/tools/controls_test.tscn`: D/A move, Space jumps, W+J up-slash, K dash, L Light Blade,
  X/C/V do nothing (2K); D moves, J punch, K roll, L counter (720p): 11/11 pass. Flow test 0 fails,
  face test 0 fails, bots win with the new keys, chaos test reaches the end.
- Bug from Sankeerth's desktop run: "Invalid polygon data, triangulation failed" in the book's Earth
  panel. Clipping the drifting continents and clouds to the planet sometimes leaves slivers or
  repeated points the renderer cannot triangulate (that piece then was not drawn). Reproduced with
  `scripts/tools/earth_errors.tscn` (the panel at 4000 moments): 6 errors before, 0 after. Every
  clipped fill (continents, clouds, night side, the escape panel's light crack, the cover gleam) now
  goes through a guard that drops repeated points and skips slivers and shapes that do not
  triangulate. The panel looks the same.
- The "non-equal opposite anchors" warning came from the main menu: its root is anchored to the full
  screen in the scene and its _ready also set the size. The size call is gone (the anchors already fill
  1280x720); the warning no longer appears and the menu is unchanged.
- Flow test 0 fails; web build re-exported.

### 4. Antigravity's movement frames, group 1 (merged fff810d)
- Merged: 2K run 1-12, runstart 1-3, skid 1-3, turn 1-3, jump 1-6, land 1-2; 720p run 1-10,
  runstart 1-2, skid 1-2, turn 1-2, jump 1-4, land 1-2. Conflict: Antigravity also changed
  hero_run1/run2 (which I had cleaned): took theirs and re-ran `tools/fix_enclosed_white.py` on all
  new frames (specks removed from hero_jump_1, hero_run_5, hero_run_10).
- Checked in game and as cycle strips (`docs/captures/run_cycles_group1.png`, GIFs
  `docs/captures/hero_run_2k.gif`, `hero_run_720p.gif`, strips `hero_2k_group1.png`,
  `hero_720p_group1.png`):
  - Feet: the airborne jump frames (2K 3-5, 720p 2-4) are drawn higher in their canvas, so the hero
    popped up mid-jump. Fixed in HeroAnimator: every frame is placed by its lowest painted row (found
    once per texture), not by the canvas edge.
  - Popping: run frames 3 and 6 lose the glowing blade (and 6 is drawn smaller, in another style), in
    both editions, so the blade flickered twice per cycle. Those two are left out of the loop (2K
    10 frames, 720p 8) until they are redrawn; asked the watchdog to pass that to Antigravity.
  - The loop seam (last frame back to the first) is clean; the scale matches the other frames.
  - Stride: run playback raised from 14 to 16 fps (scaled with speed), which keeps the stride
    (about 0.8 of the hero's height per step) in line with the run speed.
- Tests: anim set test 14/14 (one check moved to a set not yet delivered), flow 0 fails, bots win.
  Web build re-exported (index.pck 15.0 MB with the new frames).

### 5. Antigravity's groups 2-4: idle, attacks, specials and reactions (merged 31b3d5b, e160ebd, 8e4d892)
- Merged: 2K idle 6, attack1 3, attack2 3, attack3 4, upslash 3, downslash 3, blade 4, dash 3,
  heal 3, hurt 2, ko 3; 720p idle 4, punch1 3, punch2 3, punch3 4, roll 4, counter 3, hurt 2, ko 3
  (plus 720p blade/dash/upslash/downslash/heal, not used by the brawler). Conflicts on hero_attack,
  hero_dash, hero_hurt and hero_idle (single frames Antigravity re-touched): took theirs.
- Cleanup: `tools/fix_enclosed_white.py` (trapped white in 10 frames) and a new
  `tools/remove_stray_marks.py`: the generator left label scraps and a bright bar floating above the
  figure in the blade, downslash, hurt, ko, dash and upslash frames (both editions); every piece of
  the picture lying wholly above the figure that is small or sits in the top fifth is removed. Effects
  over and beside the figure (blade flash, heal glow, sparks) are kept (checked on contact sheets).
- Wiring: every set plays through HeroAnimator. Attacks (2K attack1-3, upslash, downslash, blade;
  720p punch1-3, counter) follow the swing: a quick wind-up frame, the strike frame held through the
  hit window, then recovery. The hits now land exactly in that window (2K slash at swing 0.09-0.45,
  720p punch at 0.12-0.6), so the hit lands on the strike frame. Painted attack frames carry their own
  slash and effects, so the code-drawn slash arc and the motion smear are off while a painted set
  plays. Idle loops at 8 fps; ko plays while a fight resets after a knockout.
- Baselines: all sets stand on their lowest painted row (the jump arc, ko and roll frames sit higher
  in their canvas). Scales match within a few percent.
- run_3 / run_6 (both editions): run_6 now has its blade but is still drawn about 6% smaller than its
  neighbours; run_3's blade is now a thin gold stick instead of the glowing blade. Both stay out of the
  loop (2K 10 frames, 720p 8: smooth, no seam). **Still to redraw:** hero_run_3, hero_run_6,
  px_hero_run_3, px_hero_run_6 (glowing blade, same size and pose spacing as run_2/run_4 and run_5/run_7).
- Captures: `docs/captures/hero_moves_2k.gif`, `hero_moves_720p.gif` (run, skid and turn, jump, the
  three-hit combo, dash/roll, up-slash, Light Blade) and their strips `hero_moves_*_strip.png`.
- Tests: anim sets 17/17, flow 0 fails, face 0 fails, controls 11/11, bots win. Web build
  re-exported (index.pck 18.6 MB with all the frames).

### 6. Run frames 3 and 6 redrawn (merged 1294b30)
- Antigravity redrew hero_run_3 / hero_run_6 and px_hero_run_3 / px_hero_run_6: run_3 now has the
  glowing blade and run_6 is full size (2K figure heights now 424-440 px, 720p 53-55 px across the
  cycle). Cleanup tools found nothing. Both are back in the loop: full 12-frame (2K) and 10-frame
  (720p) runs. In-game GIFs re-captured (`docs/captures/hero_moves_2k.gif`, `hero_moves_720p.gif`,
  cycle strip `run_cycles_full.png`): no blade flicker, no size pop, no seam at the wrap.
- Tests: anim sets 18/18 (new check: 720p run uses all 10 frames), flow 0 fails. Web build re-exported.
  No frames left to redraw.

### 8. Parry reverted; parkour-driven 2K (Sankeerth's correction: "parkour", not "parry")
- The parry/posture/guard system (698d040) is reverted as a normal revert commit (ff0b588); L stays the
  Light Blade. `git revert ff0b588` brings it back in one step if it is ever wanted. Telegraphs will be
  folded into the parkour work where they help.
- Brief from the reference video (Silksong-style locked arena fight): the fight lives in the air: wall
  clings, wall jumps, pogo bounces, air dash, diagonal dive strikes, escalating waves.

**Stage 1: the hero's parkour moves (2K)**
- **Wall slide:** holding toward a wall in the air slides down it slowly (170 px/s), facing away.
- **Wall jump:** Z on a wall (or within 0.12 s of leaving it) pushes up and away; the push can't be
  steered for 0.15 s. Walls are the edges of a locked arena and any solid block (new `walls` on
  BossFight: land on top, bump your head below, cling to the sides).
- **One air dash** (K in the air), given back by landing, touching a wall or a pogo.
- **Pogo** (S + J in the air): bounces off enemies and now off falling ink too; it refreshes the air dash
  and one jump in the air.
- **Dive strike** (S + K in the air): fast diagonal strike down and forward; it damages and bounces off
  what it hits (enemy or falling ink), giving the air dash and a jump back; landing kicks up dust.
- Juice: a frame of pure white on every enemy hit, radial speed lines on dashes, dives and wall jumps,
  slow motion and a slight camera nudge when a wave is cleared and on dive hits.
- Animation names for Antigravity (fall back to existing frames until they arrive): `hero_wallslide`,
  `hero_walljump`, `hero_airdash`, `hero_dive` (_1..N).
- New `scripts/tools/parkour_test.tscn` (real key presses): wall slide, wall contact, wall jump, one
  air dash, pogo (bounce + jump back), dive strike (starts, hits, bounces): 8/8. Flow 0 fails,
  controls 11/11, arena bots win.

**Stage 2: the library as a vertical climb**
- BossFight gains a vertical camera (`level_top`; the painted hall slides slowly as you climb), solid
  `walls` (bookshelf blocks drawn with rows of books), encounters as areas with their own floor
  (`floor_y`: enemies, spawns, shockwaves, ink rain and corpses use it; a locked fight's floor is
  solid even where it is a drop-through ledge on the climb), stepping paper bats (harmless, pogo off
  them), falling books (hurt, pogo off them; warned by a red mark), move tips and an exit door.
- Layout (1280 wide, 2300 tall): a locked fight on the ground floor (2 lancers, a bat) -> a bookshelf
  chimney to wall-jump up (tip + comms) -> a gap to air-dash across (tip) -> two paper bats to pogo
  up (tip) -> falling books -> a locked fight in the upper reading room (3 lancers, 2 bats; the dive
  tip) -> ledges to the door at the top ("OPERA >>"). Beaten on the climb (books): back on the last
  safe ledge with full health.
- Can a player climb it? `scripts/tools/chimney_test.tscn` plays the chimney with a plain human input
  pattern (hold toward a wall, Z when sliding, hold toward the other wall): on top in about 6 s.
- The test bot (`scripts/tools/arena_bot.gd`, shared again by the arena and playtime tests) follows
  waypoints: it crosses the dash gap, pogoes up the bats and climbs to the door on its own; at the
  chimney and two other spots its input timing fails and it is moved on after 8 s (an "assist",
  reported: 4-5 per run). Bug found on the way: the bot's taps released Z every frame, which cut every
  jump to a short hop (that also made the old arena bot's jumps tiny).
- `scripts/tools/climb_bot_test.tscn`: the library as the game builds it, by the bot: finished in about
  60 s with 4 assists. Full game with bots 11.2 min (library 75 s). Flow 0 fails, parkour 8/8.

**Stage 3: the opera as a locked arena fought in the air**
- Climbable side walls (the arena edges), the inkwell podium, two chandeliers and a high one that
  swings (and carries the hero standing on it); chandeliers are drawn with chain, candles and glow
  (`chandeliers` on BossFight).
- New enemy, the aerial dancer: circles high under the ceiling (out of reach from the floor), winds up
  ("!") and spin-dives at the hero along a curling path, then swirls back up; it only hurts while
  spinning. Reach it with wall jumps, the air dash and pogos, or hit it as it comes down.
- The brass brute's front is armoured: plain slashes to its face "CLANG" off and push the hero back;
  pogo or dive onto it from above, hit it from behind, or use the Light Blade.
- Waves like the reference: lancers and a bat -> two aerial dancers -> a bat swarm while the
  armoured brute charges -> a final mix (brute, dancer, lancer). Shockwave slams send the player up
  into the air as before. Decision: no ink puddles (the shockwaves already do that job).
- The bot jumps over the armoured brute and pogoes it. Arena bots: Ink Baron 30 s, opera 68 s (4 waves),
  Narrator 57 s. Flow 0 fails.

**Stage 4: the Narrator as a parkour fight**
- Phase 1 (above 2/3 health): on the stage, as before. Phase 2: "THE STAGE FLOODS WITH INK!" A wavy
  ink layer covers the stage floor; standing in it hurts and throws the hero up, so the fight moves to
  the podium, three chandeliers (the middle one swings) and the walls. Phase 3 (below 1/3): "HE RISES
  ABOVE THE STAGE!" He hovers high, mostly raining ink (pogo off the drops to climb to him) and dashing;
  he still slams down and rests after, which is the moment to punish. The comms carry his taunts.
  The unmasking, the reveal and the brightness finale are unchanged.
- The bot leaves the flooded floor for the nearest ledge. Arena bots: Ink Baron 23 s, opera 69 s,
  Narrator 53 s (2 retries).
- Text: the fight control line ("Z jump (on a wall: wall jump)  S+J in the air: pogo  K dash  S+K in
  the air: dive"), the library and Narrator cards, the pause guide, How to Play, README, ITCH_PAGE.
  Flow 0 fails, controls 11/11, parkour 8/8, face 0, anim 18/18.
- GIFs: `docs/captures/library_climb.gif`, `opera_arena.gif`, `narrator_flood.gif` (the bot playing,
  via `scripts/tools/bot_gif.tscn`). Full game with bots 12.1 min (library 70 s with 5 assists, opera
  72 s, Narrator 61 s); a first-time player will take longer on the climb (estimate 2-3 min). Chaos
  test reaches the end. Web build re-exported.

### 9. Parry restored alongside the parkour (Sankeerth: keep both)
- `git revert ff0b588` conflicted in 12 files (the parkour work rewrote the same functions), so parry
  was ported by hand onto the parkour code instead (same behaviour as 698d040): tap L parry (0.18 s
  window, 0.32 s cooldown, reset on success), hold L Light Blade, gold/red telegraphs with the flaring
  glint, riposte, posture bars, critical strikes, guarding lancers / Ink Baron / Narrator, the parry
  hints, lancer thrust combos, brute gold punch, Ink Baron jab chains, Narrator quill chains.
- Working with the parkour: a parry in the air gives back the air dash and a jump and lifts the hero
  a little (parries chain into wall jumps and pogos); a pogo or a dive gets past any guard and rocks
  the posture like the Light Blade; the dancer's spin dive is parryable (gold); the brute keeps its
  armoured front (riposte, pogo, dive, behind or the Light Blade); the Narrator keeps his three phases
  and also throws quill chains from high above. A critical strike uses the parkour camera nudge.
- The library's ground-floor fight is the parry lesson (comms + steady prompt + a slow trainee lancer,
  then a normal one); the 144p Ink Baron has gold jabs but no guard (decision kept).
- Bots parry and pogo over guards: Ink Baron 33 s (3 parries), opera 53 s (3 parries, 2 criticals),
  Narrator 36 s (4 parries). Flow 0, controls 12/12, parkour 8/8, face 0, anim 18/18. Text updated:
  fight control line, HUD, pause guide, How to Play, README, ITCH_PAGE.

### 10. The first edition is now 240p (Sankeerth: too degraded to play)
- Renamed 144p -> 240p everywhere (filter preset, director, settings window options, menu badge,
  comms, cards, tests, README, ITCH_PAGE, EDITIONS_PLAN; code names after_240_levels, _start_boss_240).
- Filter: 400x225 (was 256x144), blur 0.4 (0.7), 16 colour levels (10), scanlines 0.22 (0.35), grain
  0.28 (0.6). Decision: a true 426x240 grid would be nearly the same as the 720p filter's 480x270, so
  720p is now a crisper 640x360 pixel grid (32 levels, lighter scanlines and grain): 225 -> 360 -> 2K
  stays a clear step each time. Audio lo-fi a little gentler (low-pass 3600 Hz, crush 0.25).
- The rooms were near-black outside the torch (ambient 0.03): in the Editions the ambient is 0.10 and
  the torch reaches further, so floors, walls, crates and consoles read; the darkness and the torch
  stay the point. Captures: `docs/captures/room_240p.png`, `ink_baron_240p.png`. Flow test 0 fails.

### 11. Story panel framing
- "One hero escaped": the composed panel drew the new dash frame large and tilted, so the hero's head
  left the top of the panel. It now uses the rising-jump frame (hero_jump_3), smaller and less tilted:
  the whole hero, cape and sword are inside the panel (`docs/captures/panel_escape_fixed.png`).
- Checked every other story page of the book, the reveal and the ending at their final moment: all
  heads and faces are inside their panels (the masked villain's and the unmasking close-ups are tight
  on purpose and keep the whole face).

### 12. Voice-overs (ElevenLabs, generated and approved by Sankeerth)
- New `scripts/story/vo_player.gd` (VoPlayer, in the main scene): plays the clip for a caption, a
  speech bubble or a comms line when it appears, queued (overlapping lines never cut each other off),
  looked up by line id (`book/3/1` = scene, page, line) or exact text in
  `assets/audio/vo/vo_lines.json`; a missing clip or file stays silent. The page holds until its voice
  ends; Z cuts the voice and turns the page, Esc skips the scene; the music dips under the voice; the
  pause menu has VOICE 100% / 50% / OFF.
- The 15 clips (book 5, reveal 6, ending 4) are in `assets/audio/vo/`. Sync: a voiced line waits for
  the voice before it, and lines spoken inside another clip appear when the speaker reaches them
  ("You fell into my trap perfectly." 5 s into vo_reveal_4). The Narrator's long laugh at the
  unmasking shakes the panel and glitches the picture. The friendly comms line is the storyteller
  voice; after the unmasking his lines use the villain voice (the twist is in the voice too).
- Probe (`scripts/tools/vo_probe.tscn`): every voiced line appears together with its clip; the book
  now runs 33 s, the reveal 38 s, the ending 23 s (about 38 s more in total). VO test (generated clip:
  hold, music dip, Z cut, VOICE OFF, missing file, comms wait): 9/9. Flow test 0 fails.
- Web: index.pck 20.2 MB (+1.6 MB of MP3); MP3 is decoded by the engine, so it works in the HTML5
  build; the browser's audio starts on the first click (Start Reading), checked in the browser with
  no console errors.
- Disclosed: CREDITS.md (voices George, a Voice Design original, Jett), docs/AI_USAGE.md, the itch
  page text (new "AI disclosure" section) and the in-game credits.

### 13. Antigravity's parkour frames (merged 23d4f2e)
- Merged hero_wallslide 1-3, walljump 1-3, airdash 1-3, dive 1-3, pogo 1-2 (2K and 720p);
  conflict in docs/AI_USAGE.md kept both sides; cleanup removed trapped white from two frames.
- Wired: HeroAnimator already finds wallslide/walljump/airdash/dive by name; new hook: the pogo
  frames play for 0.3 s after every pogo bounce (enemy, paper bat, book, ink). Decision: the slide
  frames show the hero facing the wall with a hand on it, so while sliding he now faces the wall
  (before: away from it). The 720p pixel versions are in the repo; the brawler has no parkour moves.
- In game (`docs/captures/parkour_frames_ingame.png`, from `scripts/tools/parkour_shot.tscn`):
  scale and baseline match the other frames, no popping. Parkour test 9/9 (new: the pogo frames
  play), anim 18/18, flow 0 fails, arena bots win (Ink Baron 34 s, opera 56 s, Narrator 73 s).
  Web build re-exported. Stopping here for Sankeerth's playtest.

### 14. Fights rebuilt after two reference fights (Sankeerth: "replicate these fights")
References: a Hollow Knight Soul Master fight (library) and a Hornet fight (final boss); mechanics and
fight structure replicated in our theme with our characters and art (no assets copied).
- **The light is gone** (both 2K and 720p): a darkness overlay (`scripts/editions/light_overlay.*`)
  leaves pools of light around the hero, hanging lanterns, chandelier candles, street lamps and the
  Twins' screens; the HUD bands stay clear; cards and flashes lift the dark.
- **The Narrator, a Hornet-style duel**: he drops from the balcony and fights on foot: gold lunge
  (parryable), red quill throw on an ink thread that flies out and is pulled back, a leap into a gold
  diving air-dash, a red spinning whirl of ink in the air, hops away (toward the middle when cornered);
  a run of hits (9% of his health) staggers him; below half health he is faster and chains moves. The
  ink flood / high phase is gone (a flat duel stage lit by four lanterns). Bot: 42 s.
- **The Ink Scribe, a Soul Master-style boss** (new, between the library climb and the opera; the
  library climb keeps only its parry-lesson fight): a floating ink sorcerer in the library's sealed
  sanctum who teleports between attacks: homing ink orbs (red; a slash pops them, a down-slash on
  one is a pogo), a charge across the room at the hero's height (gold, parryable), a slam from above
  with shockwaves (red, he is dazed after it: the moment to hit him). At half health he fakes his
  death ("THE INK SCRIBE IS DEFEATED!", music drops), laughs, and crashes through the floor: the
  second half is fought in the archive below (its own lanterns), faster, with spiral orb rings and
  double slams. Placeholder art: the villain sprite tinted ink-blue until Antigravity's frames land
  (prompts in `build/prompts/`). Opera trimmed to 3 waves to keep the run length.
- Checked in frames (`scripts/tools/duel_shot.tscn -- scribe late`): orbs, teleports, fake death,
  laugh, floor break, archive. Flow 0 fails; arena bots win (Ink Baron 31 s, opera 58 s, Ink Scribe
  45 s, Narrator 33 s).
