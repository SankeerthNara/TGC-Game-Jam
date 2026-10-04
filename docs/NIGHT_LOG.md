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
