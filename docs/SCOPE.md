# Scope - "Mirror Page" (DRAFT for the Hour 12 submission)

> **Current build (levels):** 4 levels, each a generated dark comic-studio floor of 8 rooms in a random layout (not a grid). Difficulty rises per level (more tasks, harder mini-games, more sabotage, shorter timers). Finishing a level saves a checkpoint: running out of hearts respawns you at the start of the current level. A top-right timer shows this-level and total time, with a summary at the end.
>
> Previous note: a dark comic-studio station. Only the area around the hero's torch is lit. 15 interactive tasks fill a progress bar (wires, fuse box, lantern code, torch charge, telescope dial, ink spills, card swipe, and 4 light-puzzle pages). Story hook: someone sabotaged the lights; the saboteur twist comes later. The town, items, shop and keys described below still exist in the code (`data/world/town.json`) but are not the default map.


**One line:** a comic-book adventure where you walk a dark town with a torch, hunt hidden items, trade them for keys, and open "page doors" that lead to light-routing puzzles, while an unreliable narrator breaks the rules and lets you walk through the wrong door.

## Themes
- **Comic:** the town is a comic page world: inked outlines, halftone paper, narrator caption boxes, comic sound words (WHOOSH!, ZAP!, PLOT TWIST!), and every puzzle is a comic page made of swappable panels.
- **Light:** the whole town is dark. Your torch, street lamps and braziers push the darkness back, solved pages switch their district's lights on, and every puzzle is about steering a beam of light with mirrors.
- **Twist:** the narrator twists the game three ways:
  1. **Goal twist:** after you solve a page, the hero turns out to be the villain: good and bad targets swap and you re-solve the same page.
  2. **Rule twists:** later pages change how light works (lying mirrors, light that bends at panel borders).
  3. **Wrong key, wrong door:** the shop sells cheap lookalike keys. If you trade for the wrong key and open the wrong door, you stumble into a page from some other comic (romance, cooking), and the narrator has to admit it was the wrong page.

## Game flow (about 15 minutes)
1. **Explore** the seamless town (Pokemon-style walking with the arrow keys, no screen segmentation).
2. **Collect** hidden items (ink drops, gears, star shards). They glint in the dark.
3. **Trade** them at the Trade Shop for keys. Each key has a shape; each page door has a keyhole with the same shape.
4. **Open a door** with the right key to enter a light puzzle page. Solve it to light up that part of town and open the next ink-gate.
5. Repeat through four districts until all six real pages are read.

## Unique hook (what makes it ours)
The page is the puzzle piece: panels move, so the emitter, walls and targets move with them. The town around it is the same comic world, so light is both how you explore (torch, lamps) and how you solve (beams). Wrong keys make mistakes part of the story rather than a failure state.

## Characters
- **The hero:** a small caped comic hero with a torch. He walks, thinks (?), cheers (!), looks scared, and turns into the villain after the twist.
- **The narrator** ("Mr. Caption" in town, caption boxes everywhere) and **Mr. Barter**, the shopkeeper.

## Story, vampires and the choice (planned)
- A fixed **Narrator** frames four comic stories. Each level is built for one original comic hero (superhero pulp, noir detective, manga ninja, pop-art space hero) whom you play; the map is themed to that comic.
- Each level has two identical **vampires** that flee from torchlight: the hero's **friend** and the comic's **villain**. They look and behave the same, so which is which is pure chance. Catch one in the light to choose **REVEAL** or **KILL**.
  - Reveal friend: he becomes an ally who no longer fears light. His help grows each level (task arrow, finishes small tasks, extends sabotage timers, fixes a sabotage and shields you). Reveal villain: the hero is teleported into a 30 to 60 second parkour chase (platforms, gaps, spikes, checkpoints, time limit); catch him and sabotage stops, plus a heart; fail and you lose a heart and he escapes.
  - Kill villain: he dies at once and sabotage stops, no reward. Kill friend: he dies, and the ending and boss fight get harder.
- **Villain-started sabotage:** the villain vampire himself walks to a spot and starts each sabotage (tasks never trigger it). Level 1: 1 sabotage; level 2: 2; levels 3 and 4: 2 big sabotages (2 hearts, harder fix, shorter timer); level 4 also has a hidden task that undoes one of your finished tasks.
- **No repeated tasks:** 26 distinct mini-game types plus 6 light-puzzle pages; every task in a run is a different one, easy ones in early levels and hard ones later.
- **Par times:** about 2, 3, 4 and 5 minutes for levels 1 to 4 (4, 6, 8 and 10 tasks), shown on the HUD.
- **Adaptive difficulty:** finishing a level over par makes the next one a little easier (1 or 2 steps: fewer tasks, easier mini-games, longer sabotage timers), so total playtime stays steady. Finishing on time changes nothing.
- **Score (independent of time):** per level, tasks x100 (x1, 1.25, 1.5, 2 by level), +150 per sabotage stopped in time (+250 big), -100 per sabotage that hit you (-200 big), -50 per tampered task, +100 per heart left, +300 for no deaths (-250 per death), and up to +300 for finishing under par (never a penalty for being slow). Ranks S/A/B/C from the share of the level maximum; the vampire choices will add points. Shown on the HUD and on the level-complete card.
- After level 4: the final boss fight against the **Narrator**, lasting **at least 3 minutes** (three phases of about a minute; a phase ends only when its timer and its damage target are both met), with torch and mirrors, surviving allies helping and three endings.

## Content
| Page | District | Teaches | Rule |
|---|---|---|---|
| 1 | Start plaza | Panel swapping | normal |
| 2 | Start plaza | Mirrors + panels | normal |
| 3 | East streets | The goal twist (hero becomes villain) | normal + flip |
| 4 | North-east | Mirrors lie | lying |
| 5 | North-west | Light bends at panel borders | bend |
| 6 | North-west | Everything, with a locked panel and a final flip | bend + flip |
| Decoy A, B | East and north-east | Wrong-key wrong-door pages (romance comic, cooking comic) | normal |

Also in the game: 37 hidden items, 8 keys (6 real, 2 lookalike decoys), 4 ink-gates that need 2, 3 and 4 finished pages, 12 street lamps and 16 braziers that light up as districts open.

## In scope
Walkable town with torch and lighting, hidden items, trade shop, keys and locked doors, wrong-key decoy pages, six puzzle pages with the panel-swap/mirror mechanic, three rule types, the goal-flip twist, narrator captions, menu, pause, end screen, sound and music, comic-style art, itch.io web build.

## Out of scope (cut first if time runs short)
Level editor, save system, controller support, mobile touch, more than six real pages, NPC side quests.

## Success criteria
A new player can finish the game in 15 to 20 minutes with no instructions beyond the in-game captions and signs, and the web build runs in a browser without errors.
