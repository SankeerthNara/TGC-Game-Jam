import asyncio
import os
import json
import shutil
import edge_tts

LINES = [
    {
        "file": "vo_comms_intro_0.mp3",
        "text": "There you are, hero! It's dark, I know. WASD or the ARROW KEYS move, your torch lights the way. Walk to a glowing console and press Z to fix it. Fix them all and the door opens. M shows the map. I'll be right here on comms.",
        "voice": "en-GB-RyanNeural",
        "rate": "+0%",
        "pitch": "+0Hz"
    },
    {
        "file": "vo_comms_intro_1.mp3",
        "text": "Careful. Two vampires in here: one is a friend, one works for the masked villain. Hold your light on one to catch him, then REVEAL or KILL. A revealed friend helps: stand at a console and press F.",
        "voice": "en-GB-RyanNeural",
        "rate": "+0%",
        "pitch": "+0Hz"
    },
    {
        "file": "vo_comms_baron_intro.mp3",
        "text": "That door leads to the Ink Baron, one of the masked villain's lieutenants. Beat him and we're one step closer to your friends!",
        "voice": "en-GB-RyanNeural",
        "rate": "+0%",
        "pitch": "+0Hz"
    },
    {
        "file": "vo_comms_baron_tip.mp3",
        "text": "Light him up, hero! Z or SPACE jump, J attack, K dash, F heals. Tap L as his cane flashes GOLD to parry; hold L for your light blade.",
        "voice": "en-GB-RyanNeural",
        "rate": "+0%",
        "pitch": "+0Hz"
    },
    {
        "file": "vo_comms_ink_baron.mp3",
        "text": "Ah, fresh paper! I'll blot you out, hero!",
        "voice": "en-GB-ThomasNeural",
        "rate": "+0%",
        "pitch": "+0Hz"
    },
    {
        "file": "vo_comms_post_baron.mp3",
        "text": "You did it! But hero... I can barely see you. This picture is dreadful!",
        "voice": "en-GB-RyanNeural",
        "rate": "+0%",
        "pitch": "+0Hz"
    },
    {
        "file": "vo_comms_raise_settings.mp3",
        "text": "Reader - yes, YOU, holding the controls. Raise the settings! Please!",
        "voice": "en-GB-RyanNeural",
        "rate": "+0%",
        "pitch": "+0Hz"
    },
    {
        "file": "vo_comms_wow_hero.mp3",
        "text": "WOW. Look at you! Now THAT is a hero.",
        "voice": "en-GB-RyanNeural",
        "rate": "+0%",
        "pitch": "+0Hz"
    },
    {
        "file": "vo_comms_twins_street.mp3",
        "text": "New look, same mission. The Static Twins guard the line to the villain's tower. Their goons are on this street. Watch their eyes: when they glow RED, hit L and turn it around!",
        "voice": "en-GB-RyanNeural",
        "rate": "+0%",
        "pitch": "+0Hz"
    },
    {
        "file": "vo_comms_train_prompt.mp3",
        "text": "Nice moves! The Twins are on the train. Hold on tight!",
        "voice": "en-GB-RyanNeural",
        "rate": "+0%",
        "pitch": "+0Hz"
    },
    {
        "file": "vo_comms_twins_fight.mp3",
        "text": "Two of them, one of you. They take turns: dodge the eye beams, counter the dashes!",
        "voice": "en-GB-RyanNeural",
        "rate": "+0%",
        "pitch": "+0Hz"
    },
    {
        "file": "vo_comms_twins_1.mp3",
        "text": "Two channels. One signal. Zero chance.",
        "voice": "en-US-GuyNeural",
        "rate": "+0%",
        "pitch": "+15Hz"
    },
    {
        "file": "vo_comms_twins_2.mp3",
        "text": "Half the signal... is still ALL the signal!",
        "voice": "en-US-GuyNeural",
        "rate": "+0%",
        "pitch": "+15Hz"
    },
    {
        "file": "vo_comms_fake_credits.mp3",
        "text": "That's it... we did it! Roll the credits, hero!",
        "voice": "en-GB-RyanNeural",
        "rate": "+0%",
        "pitch": "+0Hz"
    },
    {
        "file": "vo_comms_hijack_2k.mp3",
        "text": "...wait. Who clicked that? Never mind! Look how sharp everything is. Let's go, hero.",
        "voice": "en-GB-RyanNeural",
        "rate": "+0%",
        "pitch": "+0Hz"
    },
    {
        "file": "vo_comms_tower_intro.mp3",
        "text": "The villain's tower. A library first, then his opera. Your friends are close, hero. I can feel it.",
        "voice": "en-GB-RyanNeural",
        "rate": "+0%",
        "pitch": "+0Hz"
    },
    {
        "file": "vo_comms_sealed_door.mp3",
        "text": "A sealed door... someone is waiting in there. Careful, hero.",
        "voice": "en-GB-RyanNeural",
        "rate": "+0%",
        "pitch": "+0Hz"
    },
    {
        "file": "vo_comms_scribe_intro.mp3",
        "text": "The villain's archivist! He teleports, hero. Watch where he appears.",
        "voice": "en-GB-RyanNeural",
        "rate": "+0%",
        "pitch": "+0Hz"
    },
    {
        "file": "vo_comms_parry_tip.mp3",
        "text": "He's guarding, hero: hitting his front just bounces off. When his spear flashes GOLD, tap L to parry, then strike back with J!",
        "voice": "en-GB-RyanNeural",
        "rate": "+0%",
        "pitch": "+0Hz"
    },
    {
        "file": "vo_comms_opera_entrance.mp3",
        "text": "Beautiful! Through those doors: his opera house. Stay sharp.",
        "voice": "en-GB-RyanNeural",
        "rate": "+0%",
        "pitch": "+0Hz"
    },
    {
        "file": "vo_comms_opera_choir.mp3",
        "text": "The masked villain is close. Clear his choir and he'll have to show himself!",
        "voice": "en-GB-RyanNeural",
        "rate": "+0%",
        "pitch": "+0Hz"
    },
    {
        "file": "vo_comms_signal_dying.mp3",
        "text": "Hero, wait... something's wrong with the sig-",
        "voice": "en-GB-RyanNeural",
        "rate": "+0%",
        "pitch": "+0Hz"
    },
    {
        "file": "vo_comms_evil_reveal.mp3",
        "text": "I wrote every page of you, hero. Even this one.",
        "voice": "en-GB-RyanNeural",
        "rate": "-8%",
        "pitch": "-15Hz"
    },
    {
        "file": "vo_comms_evil_down.mp3",
        "text": "Did you think a story ends that easily? Down we go!",
        "voice": "en-GB-RyanNeural",
        "rate": "-5%",
        "pitch": "-12Hz"
    },
    {
        "file": "vo_comms_evil_drown.mp3",
        "text": "Drown in my ink, hero! Stay off my stage!",
        "voice": "en-GB-RyanNeural",
        "rate": "-5%",
        "pitch": "-12Hz"
    },
    {
        "file": "vo_comms_evil_uphere.mp3",
        "text": "Up here, the story is mine. You'll never reach me!",
        "voice": "en-GB-RyanNeural",
        "rate": "-5%",
        "pitch": "-12Hz"
    },
    {
        "file": "vo_comms_finale_reader.mp3",
        "text": "Reader... you wouldn't.",
        "voice": "en-GB-RyanNeural",
        "rate": "-10%",
        "pitch": "-15Hz"
    },
    {
        "file": "vo_comms_ink_gate.mp3",
        "text": "The ink-gate dissolves into light! New streets are open.",
        "voice": "en-GB-RyanNeural",
        "rate": "+0%",
        "pitch": "+0Hz"
    },
    {
        "file": "vo_comms_vampire_light.mp3",
        "text": "A vampire! Hold him in the light...",
        "voice": "en-GB-RyanNeural",
        "rate": "+0%",
        "pitch": "+0Hz"
    }
]

async def generate_all():
    target_dirs = [
        os.path.abspath('D:/Infinium/wt-claude/new-game-project/assets/audio/vo'),
        os.path.abspath('D:/Infinium/TGC-Game-Jam/new-game-project/assets/audio/vo')
    ]
    for d in target_dirs:
        os.makedirs(d, exist_ok=True)

    print(f"Generating {len(LINES)} VO lines...")
    for i, item in enumerate(LINES):
        filename = item["file"]
        text = item["text"]
        voice = item["voice"]
        rate = item["rate"]
        pitch = item["pitch"]
        out_path = os.path.join(target_dirs[0], filename)
        print(f"[{i+1}/{len(LINES)}] Generating {filename}: {text[:40]}...")
        communicate = edge_tts.Communicate(text, voice, rate=rate, pitch=pitch)
        await communicate.save(out_path)
        # copy to second directory
        out_path2 = os.path.join(target_dirs[1], filename)
        shutil.copy2(out_path, out_path2)

    # Update vo_lines.json in both locations
    for d in target_dirs:
        json_path = os.path.join(d, "vo_lines.json")
        data = {}
        if os.path.exists(json_path):
            with open(json_path, "r", encoding="utf-8") as f:
                data = json.load(f)
        for item in LINES:
            data[item["text"]] = item["file"]
            # also add NARRATOR: prefix version if not evil/twins/baron
            data["NARRATOR: " + item["text"]] = item["file"]
        with open(json_path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=4)
        print(f"Updated {json_path} (total entries: {len(data)})")

if __name__ == "__main__":
    asyncio.run(generate_all())
