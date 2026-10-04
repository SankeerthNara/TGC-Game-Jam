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
