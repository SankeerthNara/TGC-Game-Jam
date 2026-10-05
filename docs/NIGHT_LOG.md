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
- **Frame sets when they exist, current frames as the fallback.** Animations are looked up as
  `<prefix>_<anim>_1..N`: 2K prefix `hero`, 720p prefix `px_hero`. Names the system asks for:
  `idle, run, jump, fall, attack1, attack2, attack3, attack_up, attack_down, dash, hurt, skid, land, heal`
  (2K) and `idle, run, jump, fall, attack1, attack2, attack3, roll, hurt, skid, land, counter` (720p),
  e.g. `hero_run_1.png ... hero_run_8.png`, `hero_attack2_1.png ... _5.png`, `px_hero_roll_1.png ...`.
  Same canvas as now (2K 512x512, pixel 64x64), facing right, feet on the bottom edge, same scale in
  every frame. Missing sets fall back to today's single frames, so frames can land one set at a time.
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
