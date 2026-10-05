# Glitched Out (final plan, 2026-10-04)

Deadline: **Tuesday 2026-10-06, 4 pm IST.** Feature freeze Tuesday 12 pm, web build on itch.io by 3 pm.
Built on branch `editions`; `main` keeps the classic game until the editions build is approved (roll back = don't merge).

## Story

The light gives the world its detail. A masked villain drains it: the world loses resolution.

| Part | What happens | Look | Length |
|---|---|---|---|
| Book opening | A comic book opens: Earth in peace, four heroes. The masked villain drains the light and captures three heroes in ink; our hero escapes. A friendly voice calls on his comms machine: the Narrator, who promises to guide him. The page glitches and pixelates. | painted comic panels | 1 min |
| **144p** | 2 levels of the dark-room game (tasks, vampires, friend), then boss 1: **the Ink Baron**, a subordinate. The Narrator helps on comms the whole time. Then: "Reader, this picture is dreadful, raise the settings!" and the player clicks 720p. | crushed 144p, choppy, muffled audio | 5 min |
| **720p** | 1 brawler level (neon street), then boss 2: **the Static Twins**, subordinates, on a train roof in the rain. Fake "THE END" credits roll... then the cursor moves by itself to 2k. | REPLACED-style pixel art, neon, fog, rain, synthwave | 4-5 min |
| **2k** | Level 1: a gothic library hall (platforming + a fight). Level 2: the opera arena (waves). The comms crackle and die. The masked villain unmasks: it is the Narrator. *"This is the perfect ending I've been waiting for all these years. You fell into my trap perfectly."* Final boss: the Narrator. | Silksong-style painted gothic, warm glow, opera music | 7 min |
| Finale | The three freed heroes give their light; the player drags a brightness slider to 100%; the Solar Flare. Fading, the Narrator: *"I guess this is how it was always meant to happen."* Light glows on Earth; the book closes on the broken quill. | | 1 min |

The hero is the **pulp hero** all the way: aggressive and stunning. Lean, forward-leaning, long torn
crimson cape, high collar, navy suit, gold lightning emblem, black domino mask with **glowing white
eyes**, a **blade of light**. The Narrator is his "friendly" voice on comms until the reveal.

## Ownership (one owner per file)

| Owner | Files |
|---|---|
| Claude | all game code (`scripts/`), `project.godot`, the `editions` branch, merges |
| Antigravity | `new-game-project/assets/editions/` (all art), `docs/ITCH_PAGE.md` |
| Codex | `tools/make_synthwave.py`, `assets/audio/music_synth_*.wav`, new `assets/audio/sfx_*.wav` + their entries in `scripts/audio/sfx_player.gd`, `tests/` |

## Art list for Antigravity (`new-game-project/assets/editions/`)

Original art only (no copying of Hollow Knight / Silksong / REPLACED assets, no real brands, **no text
or lettering in any image**; the game draws all text). AI-generated art is allowed by our rules if logged.

### `book/` painted comic panels, 1600x900 PNG, dramatic comic-book painting, ink outlines, halftone
| File | Shows |
|---|---|
| `book_cover.png` | a closed, worn comic book lying on a dark wooden desk, lit by a warm lamp; mysterious |
| `op_peace.png` | Earth from space, glowing, four small heroes flying around it in light trails |
| `op_heroes.png` | the four heroes posing: the pulp hero centre (see hero description), a noir detective (tan trench coat, grey fedora), a ninja (navy, orange headband), a space hero (pink suit, round glass helmet) |
| `op_villain.png` | the masked villain (dark purple hooded tailcoat with gold trim, white theatre mask with slanted eye holes) holding a giant quill that drinks the light out of the sky; the world turns grey |
| `op_capture.png` | three heroes (detective, ninja, space hero) trapped in hanging cages made of black ink |
| `op_escape.png` | the pulp hero leaping through a crack of light, cape torn, eyes glowing |
| `op_comms.png` | the pulp hero in the dark holding a glowing retro comms device; a soft voice wave on its screen |

### `portraits/` for the comms dialogue, 512x512 PNG, transparent background, comic painting
`hero.png` (aggressive, glowing eyes), `narrator_friendly.png` (warm smile, top hat, monocle, curled
moustache, NO mask), `narrator_evil.png` (same face, furious grin), `ink_baron.png` (a hulking ink
creature in a ringmaster coat), `static_twins.png` (two identical lanky TV-headed brawlers).

### `720/` pixel art, REPLACED-like mood but original. **Native 480x270 pixels**, crisp pixels, no anti-aliasing, limited palette (deep blacks, neon red, teal, a little warm yellow). The game scales it up x3 with sharp pixels.
| File | Size | Shows |
|---|---|---|
| `neon_far.png` | 480x270, opaque | rainy night skyline, distant towers with red neon glow, fog |
| `neon_mid.png` | 1440x270, transparent | a street of shop fronts, invented neon signs (shapes and glow, no readable words), fire escapes, windows; the ground line is at **y = 236** (nothing below it) |
| `neon_near.png` | 1920x270, transparent | foreground props: lamp posts, cables, steam vents, crates, puddle reflections at the bottom edge |
| `train_far.png` | 480x270, opaque | stormy night city seen from a moving train, lightning, rain |
| `train_mid.png` | 960x270, transparent | bridges, signal towers and power lines passing by (they scroll fast); keep below **y = 200** clear |

### `2k/` painted, Silksong-like gothic atmosphere but our own comic style (ink outlines). 1920x1080.
| File | Size | Shows |
|---|---|---|
| `hall_far.jpg` | 1920x1080 | a gothic library cathedral, huge warm glowing window in the centre, teal shadows, dust in the light |
| `hall_mid.png` | 3840x1080, transparent | arches, giant bookshelves, hanging chains and lanterns (decoration only; the game places the platforms) |
| `hall_near.png` | 3840x1080, transparent | dark foreground silhouettes at the edges and bottom: drapes, broken statues, chains |
| `arena_far.jpg` | 1920x1080 | an opera house: a giant glowing comic mask carved in the back wall, balconies of shadowy ink spectators, warm backlight, teal haze |
| `arena_mid.png` | 1920x1080, transparent | tall pillars, side curtains, a giant inkwell podium in the centre whose **rim is at y = 760**; the stage floor is at **y = 900** |
| `arena_near.png` | 1920x1080, transparent | a heavy curtain valance at the top and dark foreground silhouettes at the bottom corners |
| `arena_dark.jpg` | 1920x1080 | the same opera house after the reveal: lights out, purple storm light, cracked mask |

### Key art
`hero_key.png` 1920x1080: the pulp hero in an aggressive pose, light blade drawn, cape whipping, glowing
eyes, the masked villain looming behind (title screen and itch.io page).

## Audio list for Codex
- `tools/make_synthwave.py` (numpy, like `tools/make_music.py`) creating the 720p music in 4 synced layers of one loop, dark 80s synth, about 100 BPM, A minor: `music_synth_pad.wav`, `music_synth_bass.wav`, `music_synth_drums.wav`, `music_synth_lead.wav` (same length, seamless loop, 22050 Hz mono 16-bit).
- New sounds (add to `tools/make_sfx.py` and `sfx_player.gd`): `punch`, `punch_heavy`, `kick`, `counter_flash` (an enemy's eye flashes: counter now), `counter_hit` (big parry impact), `enemy_grunt`, `glitch` (digital tear), `static` (radio static burst), `comms_beep` (incoming call), `comms_dead` (signal lost), `resolution_change` (whoosh + digital sweep up), `cursor_click`, `typewriter` (one key), `credits_whoosh`, `light_swell` (the final light).
