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
