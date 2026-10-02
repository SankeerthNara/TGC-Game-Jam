# Ideas to make Mirror Page stand out (ranked)

Judging compares the finished game with the plan, rewards a complete stable 10-15 minute loop, and looks at how well the three themes (Comic, Twist, Light) are used and how original the idea is. These ideas are ranked by impact for the effort.

| # | Idea | Why it stands out | Effort | Theme |
|---|---|---|---|---|
| 1 | **A visible Saboteur** (the "imposter"): an ink creature that roams the level, runs from your torchlight, freezes in your beam, and triggers sabotage when it reaches a console. Catch it in the light to stop the timer. | Turns darkness from a gimmick into the core tension (like Among Us, but the light is your weapon). Makes the world feel alive. | High | Light, Twist |
| 2 | **Each level is a different comic genre**: superhero pulp, noir black and white, manga, pop-art. Palette, font, caption style, onomatopoeia and music change per level. | Instant visual identity and variety for a 12 minute game. Cheap (palette and style swaps). Great screenshots. | Medium | Comic |
| 3 | **Fourth-wall twists**: the narrator attacks the interface. The caption box lies, the progress bar drops, the map shows the wrong rooms, controls swap for a level, the HUD glitches. Final reveal: the narrator cut the lights because the comic is being cancelled; you rewrite the last page. | The Twist theme used in the mechanics, not only the story. Memorable and shareable. Mostly script and UI work. | Medium | Twist, Comic |
| 4 | **Comic look shader**: ink outline and halftone dots over the whole screen, page-turn and panel-split transitions between levels, onomatopoeia on every action, speech-bubble narrator with text blips. | The first 10 seconds decide the impression. Makes every screenshot look like a comic. | Medium | Comic |
| 5 | **Light puzzle rooms in the world**: rotate real mirrors in a room to send a beam to a door (reuses `BeamSolver`). | Ties the original panel-and-mirror idea into exploration, so the world and the puzzles share one mechanic. | Medium | Light |
| 6 | **Torch as a resource**: the torch dims over time and recharges at lamps and when you finish tasks; the light cone reveals hidden ink clues and secret passages. | More tension and a reason to explore. | Low-Medium | Light |
| 7 | **Rank and replay**: S/A/B medals per level from time and hearts lost, best-time splits saved locally, a "seed" shown on the end screen so runs can be compared. | The timers already exist, so this is cheap and adds replay value. | Low | - |
| 8 | **Reactive audio**: music speeds up while a sabotage timer runs, a heartbeat at 1 heart, comic SFX words. | Makes pressure feel real. | Low-Medium | - |
| 9 | **First-minute polish**: a 30 second tutorial that teaches movement, torch, tasks and risky tasks inside level 1, plus an itch.io page with GIFs. | Judges often play only a few minutes. | Low | - |

## Recommendation
Commit to 1, 2, 3, 4, 7 and 9. Treat 5, 6 and 8 as stretch, in that order. Ideas 1 and 3 are the heart of the pitch: **"In a comic, the light is your weapon, and the narrator is cheating."**

## What not to do
- No new engine features or networking.
- No more than 4 levels. Make them better instead of adding more.
- Do not start stretch work until the committed features are playable end to end.
