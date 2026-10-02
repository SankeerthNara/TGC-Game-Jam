# Concept Options (Comic + Twist + Light)

All options are 2D, GDScript, Compatibility renderer, web-safe, and designed for a **15-minute first playthrough** (20 max).
Each has 5 short levels (about 2-3 min each) plus an intro and an ending.
Pick one (or mix) and tell Claude. The pick is the human's design decision, so note why in `docs/DESIGN_LOG.md`.

## A. "Inkwell" - Light-reveal puzzle platformer

- **Comic:** the world is a comic page. Levels are panels, speech bubbles are platforms, gutters are gaps, "POW/BAM" text is the sound feedback.
- **Light:** the page is dark ink. You carry a lantern whose cone reveals hidden platforms and erases ink monsters. No light means no ground.
- **Twist:** at the midpoint the narrator's captions turn on you: the "villain" you have been chasing is the artist's eraser trying to save the page, and *you* are the stain. From then on the lantern hurts the world, so light becomes a liability and you must play in the dark.
- **Loop:** explore panel, reveal path, solve, reach exit. Five levels, the twist at level 3.
- **Scope risk:** low. One mechanic (light cone + visibility mask) and one rule flip.

## B. "Flashbulb" - Top-down stealth in a noir comic city

- **Comic:** black-and-white inked city, colour only appears where light hits. Enemies announce themselves with comic captions.
- **Light:** you are a photographer. Camera flash stuns enemies and reveals colour and clues. Streetlights are safe zones.
- **Twist:** the case you are solving turns out to be about you. The last levels replay earlier ones with roles reversed, so you are the hunted.
- **Loop:** investigate district, take photos as evidence, evade, reach the next district.
- **Scope risk:** medium. Enemy AI and stealth need more testing time.

## C. "Mirror Page" - Light-routing puzzle with a rule-breaking narrator

- **Comic:** each level is one page of panels. You can drag panels to rearrange the page.
- **Light:** you rotate mirrors and prisms to route a beam to a target. Panel order changes where the beam goes.
- **Twist:** every few levels the narrator "rewrites" one rule: beams bounce differently, panels get swapped, a mirror becomes a window. The player has to re-learn the rules each act.
- **Loop:** read the page, rearrange panels, route the light, solve.
- **Scope risk:** low-medium. Pure puzzle, so little combat, but each level needs careful design to stay fun.

## Claude's recommendation

**A, "Inkwell".** It has the best mix of feel and scope: one core mechanic, a twist that changes how the player uses it, and strong comic presentation that Antigravity can build in UI and art without touching core logic. C is the best fallback if you want puzzles over action.
