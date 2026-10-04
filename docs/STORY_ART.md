# Story cutscene art: panel list and image prompts

The story cutscenes (`opening`, `bomb_room`, `earth_blast`) are comic pages built from named panels
(`new-game-project/scripts/story/story_scenes.gd`). Every panel is drawn in code
(`scripts/story/story_panels.gd`, `comic_art.gd`). **If a picture named `<key>.png` is put in
`new-game-project/assets/story/`, the game shows it instead**, with a slow push-in, so drawn,
CC0 and AI-generated art can be compared without touching code. Delete the file to go back.

Captions, speech bubbles and sound-effect words are drawn by the game on top of the panel,
so **images must contain no text, no speech bubbles and no lettering**.

Before any image ships: log it in `docs/AI_USAGE.md` (AI images) or `CREDITS.md` (CC0 packs),
and check that the jam rules allow AI-generated art.

## Style guide (paste before every prompt)

> Bold-ink American comic book panel, thick black outlines, flat bright colours with Ben-Day halftone
> dots, dramatic lighting, clean shapes, no text, no letters, no speech bubbles, no watermark, no border.

Characters (keep identical in every panel):
- **Pulp hero** (level 1): blue suit, red cape, yellow diamond chest emblem with a red lightning bolt, black slicked hair, black domino mask.
- **Noir detective** (level 2): tan trench coat, grey fedora with a black band, white shirt, red tie, stubble.
- **Ninja** (level 3): dark navy outfit and hood covering the face except the eyes, orange headband with flowing tails, orange sash.
- **Space hero** (level 4): pink suit, teal collar ring, gold star badge, round glass helmet with a red-tipped antenna, orange hair.
- **Masked villain**: dark purple hooded tailcoat with gold trim, white theatre mask with slanted black eye holes.
- **The Narrator** (the villain unmasked): pale face, black top hat with a red band, gold monocle, thin curled moustache, wide sharp grin, purple tailcoat with gold trim, red bow tie.

## Panels (size = how it appears at 1280x720; generate at 2x)

| Key | Size (aspect) | What it shows |
|---|---|---|
| `earth_peace` | 1228x392 (3.1:1) | Starry deep-blue space, the Earth on the right, the four heroes flying around it in an orbit. Peaceful. |
| `hero_portrait_0` | 307x262 (1.2:1) | Pulp hero, head and shoulders, determined, red sunburst background. |
| `hero_portrait_1` | 307x262 (1.2:1) | Noir detective, head and shoulders, determined, tan sunburst background. |
| `hero_portrait_2` | 307x262 (1.2:1) | Ninja, head and shoulders, determined, orange sunburst background. |
| `hero_portrait_3` | 307x262 (1.2:1) | Space hero, head and shoulders, determined, teal sunburst background. |
| `villain_rise` | 688x654 (1:1) | The masked villain rising from below, looming, purple night sky with lightning. |
| `earth_darkening` | 540x327 (1.65:1) | The Earth in space being swallowed by purple-black tendrils of darkness. |
| `heroes_shock` | 540x327 (1.65:1) | The four heroes side by side, shocked faces, speed lines, pale yellow background. |
| `bomb_closeup` | 1228x327 (3.75:1) | *Keep code-drawn*: the bomb shows the live 17:00 timer. |
| `door_locked` | 553x327 (1.7:1) | A heavy steel vault door with four keyholes and a yellow-black hazard stripe, dark corridor. |
| `hero_ready` | 675x327 (2:1) | Pulp hero, determined, holding up a burning torch in the dark (torch upper right). |
| `door_unlock` | *keep code-drawn* | Animated: the four keys turn and the door opens. |
| `bomb_room_bomb` | *keep code-drawn* | The bomb with the live remaining time. |
| `masked_closeup` | 614x327 (1.9:1) | The masked villain, head and shoulders, purple halftone background, menacing. |
| `unmask` | *keep code-drawn* | Animated: the mask flies off. |
| `narrator_reveal` | 1228x314 (3.9:1) | The Narrator unmasked, centre, grinning, purple and gold sunburst. Leave space left and right for bubbles. |
| `grab` | 675x340 (2:1) | A huge white-gloved hand in a purple sleeve grabbing the scared pulp hero. |
| `caged` | 553x340 (1.6:1) | The pulp hero, scared, inside a hanging purple ink cage, dark purple background. |
| `bomb_zero` | *keep code-drawn* | The bomb at 0:00, flashing. |
| `heroes_too_late` | 1228x294 (4.2:1) | The four heroes running fast to the right toward the distant vault door, dark corridor, speed lines. |
| `boom` | *keep code-drawn* | Animated explosion. |

## Example prompt

> [style guide] Wide 3:1 panel. Starry deep-blue space with the Earth on the right. Four superheroes
> fly in an orbit around it: [the four hero descriptions]. Peaceful, heroic mood.

## Checking a panel

Put the PNG in `new-game-project/assets/story/`, then from `new-game-project/` run
`godot --path . --resolution 1280x720 --script scripts/tools/cutscene_shots.gd`.
It saves a frame of every page so drawn and image versions can be compared.
