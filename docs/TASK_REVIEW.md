# Mini-game quality review

Reviewed all 25 task scripts and ran each registered task at difficulties 0–3 in the headless smoke scene. Each instance processed 60 frames without finishing on its own, fit its title and hint within the panel, and left once on Escape. The fixes below focus on clear instructions, feedback, solvability, and difficulty scaling. Fun scores are design estimates; they are not measured player-study results.

| Task | What the player does | Problems found and fixes | Fun (1–5) | Decision |
|---|---|---|---:|---|
| Wires | Drag coloured wires to matching sockets. | Difficulty only changed 4 to 5 wires; now scales 3–6, has six distinct colours, keeps sockets in the panel, and flashes on a wrong socket or release. | 4 | Keep |
| Switches | Toggle a switch that flips its neighbours until every bulb is lit. | Difficulty did not change at level 0 vs 1 and the key hint always said 1–7; now scales 4–7 switches and shows the correct key range. | 4 | Keep |
| Simon | Repeat the lantern sequence with clicks or arrow keys. | No blocking issue found; rounds and flash speed already scale with difficulty. | 4 | Keep |
| Charge | Hold/release to keep a moving gauge in its green zone. | No blocking issue found; target time, zone width, speed, and timer already scale. The accumulated charge allows recovery after missed windows. | 3 | Keep |
| Dial | Aim the telescope at a moving star and lock observations. | It previously completed by holding aim for several seconds without an action; now the player clicks or presses Space/Enter to lock each of 2–5 observations, with miss feedback. | 4 | Keep |
| Swipe | Drag a card through the reader at a steady speed. | No blocking issue found; drag, reader crossing, and speed feedback are explicit, and the allowed speed window tightens with difficulty. | 4 | Keep |
| Panels | Swap four comic panels into story order. | Random shuffles could be nearly solved at any difficulty and swaps gave no feedback; now the scramble scales by displaced panels and worsening swaps flash a message. | 3 | Keep |
| Bubbles | Match word chips to comic speech bubbles. | Fixed three prompts at every level and the five-chip row was cramped; now uses 2–5 prompts, adds only two distractors, and lays choices out in centered rows. | 4 | Keep |
| SFX lettering | Type the onomatopoeia before it fades. | No blocking issue found; number of words and time limit scale, and a wrong letter restarts the current word. | 4 | Keep |
| Debug | Find the bad line in short comic-themed programs. | No blocking issue found; every incorrect pick gives feedback and the number of snippets scales. | 4 | Keep |
| Logic | Toggle circuit inputs to light the output lamp. | No blocking issue found; higher levels add circuits while each circuit remains solvable by its displayed expression. | 3 | Keep |
| Sort | Swap library books into ascending call-number order. | Wrong swaps had no signal; swaps that increase the number of inversions now flash feedback. Book count already scales. | 3 | Keep |
| Dots | Click numbered dots in order to complete a drawing. | Clicking an earlier dot was silently ignored; it now explains that the dot is already connected. Dot count scales and errors do not block progress. | 3 | Keep |
| Whack | Click each lantern while it is lit. | Clicking away from an active lantern gave no signal; misses in the play area now flash a short prompt. Hit and miss budgets already scale. | 3 | Keep |
| Memory | Flip cards two at a time and find matching sticker pairs. | It always used six pairs and mismatches were silent; now uses 3–6 pairs and calls out mismatches. The board fits up to three rows. | 4 | Keep |
| Unscramble | Click letter tiles in order to spell comic words. | No blocking issue found; higher difficulties add a round, wrong letters flash, and the longest word fits the tile row. | 4 | Keep |
| Math | Answer short arithmetic questions before the timer ends. | No blocking issue found; question count, number range, and time limit scale. Wrong answers and timeouts reduce progress but cannot dead-end the task. | 3 | Keep |
| Ink mix | Add coloured drops until the swatch matches the target. | No blocking issue found; target mixtures vary and the visible Clear button plus automatic overflow reset prevent a dead end. Tolerance tightens with difficulty. | 4 | Keep |
| Rain | Move a bucket to catch blue ink and avoid red drops. | No blocking issue found; left/right and mouse input work, and speed, spawn rate, and catch target scale. | 3 | Keep |
| Needle | Stop a moving needle in the green zone. | No blocking issue found; misses reduce progress and every round remains repeatable. Needle speed and zone width scale. | 4 | Keep |
| Proofread | Find the misspelled words in a comic or college paragraph. | It used one paragraph at every difficulty; it now serves 1–4 distinct pages. Paragraphs wrap within the paper panel, wrong clicks flash, and each page has a visible progress count. | 4 | Keep |
| Lights Out | Flip a bulb and its neighbours until all are lit. | No invalid move exists; every board is generated from a solved board, so reversing the presses solves it. Grid size and scramble work scale with difficulty. | 3 | Keep |
| Pipes | Rotate pieces to connect the ink tap to the drain. | It used only 4×4 or 5×5 boards and flow regressions were silent; now scales 3×3 through 6×6, keeps the board clear of the footer, and reports lost flow. Boards are generated from a guaranteed route. | 4 | Keep |
| Slide | Slide adjacent panels into numbered order. | Scramble length made the level-1 first play unnecessarily long and non-adjacent clicks were silent; shuffle length is shorter and scales steadily, and invalid clicks flash. Legal shuffles preserve solvability. | 4 | Keep |
| Safe | Deduce a three-digit code from exact-position and misplaced-digit clues. | Wrong guesses with partial information were silent and clue history did not scale; every guess now responds and higher levels show fewer recent clues. Guesses remain unlimited, so it cannot lock out a solution. | 4 | Keep |

## Weakest tasks and replacement concepts

These are recommendations for a future design pass only. Keep all current tasks for this jam build; do not remove any without Sankeerth's decision.

1. **Lights Out (3/5):** the neighbour-flip puzzle is clear but visually generic. Consider a comic stage-light board where the player reveals specific panels while keeping the villain silhouette dark.
2. **Charge (3/5):** holding a key in a moving zone is a familiar timing loop. Consider stabilising a campus neon sign by matching a sequence of short voltage pulses to comic sound-effect beats.
3. **Math (3/5):** the pop quiz feels closest to a conventional worksheet. Consider turning it into a comic lab repair where arithmetic selects the right wire or component, preserving quick, readable choices.
4. **Rain (3/5):** catching coloured drops has limited story identity. Consider catching the correct assignment pages before they hit a puddle while dodging the professor's red-ink corrections.
5. **Panels (3/5):** ordering four pictures is legible but has little interaction beyond swapping. Consider adding one visible caption clue per strip so the player reconstructs a comic gag as well as its event order.

## Verification limits

The smoke test covers construction, four difficulty values, 60 idle frames, title/hint width, unexpected completion, and Escape. Source inspection covered the mouse/key paths and puzzle reset or guaranteed-solution logic. It does not replace timed first-time playtests with people; the under-30-second level-1 target should be checked during the next browser playtest.
