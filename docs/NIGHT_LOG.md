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
