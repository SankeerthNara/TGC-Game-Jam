# Glitched Out

A comic book about light, told three times, each time in a better "edition". Made for the TGC Game
Jam (themes: **Comic, Twist, Light**) in Godot 4.7.

A masked villain has drained the light from the world, and without light the world loses its detail.
Your hero escapes, and a friendly voice on his comms machine, the Narrator, guides him to rescue the
three captured heroes. The story starts in a cheap **144p** edition, gets reprinted in **720p** pixel
art and ends in a **2K** deluxe edition... and sometimes the story needs *you*, the reader.

## Play on itch.io

[itch.io page — link to be added]

## Setup and run

1. Install [Godot 4.7](https://godotengine.org/download/) (the standard build, not .NET).
2. Open Godot and import `new-game-project/project.godot`.
3. Click **Run Project** (or press **F5** in the editor).

The web build is exported with the preset "Web" (Project > Export) to `build/web/`.

## Controls

**144p edition (the dark-room levels)**
- **WASD** or the **arrow keys** move (hold two for diagonals). Your torch lights the way. **M** opens the map.
- **Z** at a console starts a task (tasks use the mouse and the keys shown in each task). **Esc** leaves a task.
- Run to the fix console when the villain sabotages something.
- Keep your torch on a vampire to catch him, then choose **Reveal** or **Kill**. A revealed friend
  helps: stand at a console and press **F** to give him that task.

**720p edition (the brawler)**
- **WASD / arrows** move, **Z** or **Space** jump, **J** punch (3-hit combo), **K** roll, **L** counter when an enemy's eyes
  or laser sight turn **red**.

**2K edition (the deluxe fights)**
- **WASD / arrows** move, **Z** or **Space** jump, **J** attack (hold **W / Up** for an up-slash, **S / Down** in the air for a
  down-slash that bounces off enemies), **K** dash, **L** parry (tap as an attack flashes **gold**;
  **red** attacks can't be parried: dash or jump), hold **L** for the Light Blade (3 ink), **F** heal (6 ink).
  A parry earns ink and makes your next hit a riposte; guarding enemies only open up to parries, hits
  from behind or above, and a full posture bar opens a **critical strike** (J).
  Hits fill the ink meter.

**Everywhere**
- **P** pauses. **Z** skips / continues story pages, **Esc** skips a whole cutscene.
- When a window from the "real world" appears, use the **mouse**.

## Team

Sankeerth Nara — solo developer, team "Game it" (IndieConnect: [@sankeerthnara](https://indieconnect.in/@sankeerthnara))

## AI use

AI tools were used and are disclosed in [docs/AI_USAGE.md](docs/AI_USAGE.md): Claude Code (game code,
cutscenes, music scripts), Antigravity (2K and 720p background art and character sprites, UI), and
ChatGPT/Codex (sound effects, synthwave, tests). The story and design are the developer's own.

## License

This project is licensed under the [MIT License](LICENSE).

## Credits

See [CREDITS.md](CREDITS.md).
