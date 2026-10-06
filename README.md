# Glitched Out

A comic book about light, told three times, each time in a better "edition". Made for the TGC Game
Jam (themes: **Comic, Twist, Light**) in Godot 4.7.

A masked villain has drained the light from the world, and without light the world loses its detail.
Your hero escapes, and a friendly voice on his comms machine, the Narrator, guides him to rescue the
three captured heroes. The story starts in a cheap **240p** edition, gets reprinted in **720p** pixel
art and ends in a **2K** deluxe edition... and sometimes the story needs *you*, the reader.

## Play on itch.io

itch.io: <link to be added>

Play in the browser (Chrome, Edge or Firefox). Keep playing until you see the **THE END** card: the
story has false endings on the way. A full run takes about 12-15 minutes.

## Setup and run

1. Install [Godot 4.7](https://godotengine.org/download/) (the standard build, not .NET).
2. Open Godot and import `new-game-project/project.godot`.
3. Click **Run Project** (or press **F5** in the editor).

The web build is exported with the preset "Web" (Project > Export) to `build/web/`. To play a
local web build, serve that folder with any local web server (for example `python -m http.server`
inside `build/web/`, then open http://localhost:8000). The playtest zip has a `PLAY.bat` that does
this for you.

## Controls

**240p edition (the dark-room levels)**
- **WASD** or the **arrow keys** move (hold two for diagonals). Your torch lights the way. **M** opens the map.
- **Z** at a console starts a task (tasks use the mouse and the keys shown in each task). **Esc** leaves a task.
- Run to the fix console when the villain sabotages something.
- Keep your torch on a vampire to catch him, then choose **Reveal** or **Kill**. A revealed friend
  helps: stand at a console and press **F** to give him that task.

**720p edition (the brawler)**
- **WASD / arrows** move, **Z** or **Space** jump, **J** punch (3-hit combo), **K** roll, **L** counter when an enemy's eyes
  or laser sight turn **red**.

**2K edition (the deluxe fights)**
- **WASD / arrows** move, **Z** or **Space** jump, **J** attack (hold **W / Up** for an up-slash), **K** dash,
  **L** parry (tap as an attack flashes **gold**; **red** attacks can't be parried: dash or jump), hold **L**
  for the Light Blade (3 ink), **F** heal (6 ink). A parry earns ink and makes the next hit a riposte;
  guarding enemies open up to parries and to blows from behind or above (pogo, dive); a full posture
  bar opens a **critical strike** (J). Hits fill the ink meter.
- Parkour: hold toward a wall in the air to **wall slide**, **Z** on a wall to **wall jump**; **K** in the air
  is one **air dash** (landing, a wall or a pogo gives it back); **S + J** in the air **pogoes** off enemies,
  paper bats, books and falling ink; **S + K** in the air is a **dive strike**. The brass brute's front is
  armoured: hit it from above, from behind, or with the Light Blade.

**Everywhere**
- **P** pauses (the pause menu lists every control, and has music, SFX and voice volume).
  **Z** / **Space** / **Enter** continue story pages, **Esc** skips a whole cutscene or leaves a task.
  **M** opens the map in the 240p levels.
- When a window from the "real world" appears, use the **mouse**.

## Team

Sankeerth Nara — solo developer, team "Game it" (IndieConnect: [@sankeerthnara](https://indieconnect.in/@sankeerthnara))

## AI use

AI tools were used and are disclosed in [docs/AI_USAGE.md](docs/AI_USAGE.md): Claude Code (game code,
cutscenes, boss fights, music scripts, tests), Antigravity (2K and 720p background art, character
sprites and animation frames, UI), ChatGPT/Codex (sound effects, synthwave, tests) and ElevenLabs
(the cutscene voice-overs). The story and design are the developer's own.

## License

This project is licensed under the [MIT License](LICENSE).

## Credits

See [CREDITS.md](CREDITS.md).
