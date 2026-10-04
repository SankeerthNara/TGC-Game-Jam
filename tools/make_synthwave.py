"""Generate four synced layers for the 720p Synthwave edition.

The 16-bar A-minor loop is an original composition, synthesised from oscillators
and noise. NumPy is the only dependency; the generated audio is CC0.

Run from the repository root: python tools/make_synthwave.py
Writes four 22050 Hz mono 16-bit looping WAVs to new-game-project/assets/audio/.
"""

from __future__ import annotations

import os
import wave

import numpy as np


SR = 22050
BPM = 100.0
BEAT = 60.0 / BPM
BARS = 16
SAMPLES = int(BARS * 4 * BEAT * SR)
LOOP_SECONDS = SAMPLES / SR
OUT = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "new-game-project", "assets", "audio",
)
RNG = np.random.default_rng(721)
TAU = 2.0 * np.pi

# One harmony per bar, all rooted in A minor. The last bar returns to Am so the
# sustained pad also has a natural harmonic seam when the file loops.
PROGRESSION = [
    (45, [57, 60, 64, 69]),  # Am
    (45, [57, 60, 64, 69]),
    (41, [53, 57, 60, 65]),  # F
    (41, [53, 57, 60, 65]),
    (36, [48, 52, 55, 60]),  # C
    (36, [48, 52, 55, 60]),
    (43, [55, 59, 62, 67]),  # G
    (43, [55, 59, 62, 67]),
    (45, [57, 60, 64, 69]),  # Am
    (45, [57, 60, 64, 69]),
    (41, [53, 57, 60, 65]),  # F
    (41, [53, 57, 60, 65]),
    (38, [50, 53, 57, 62]),  # Dm
    (38, [50, 53, 57, 62]),
    (40, [52, 56, 59, 62]),  # E7, harmonic-minor tension
    (45, [57, 60, 64, 69]),  # Am, loop resolution
]

MELODIES = {
    45: [69, 72, 76, 72, 79, 76, 72, 69],  # A C E C G E C A
    41: [69, 72, 77, 72, 81, 77, 72, 69],  # A C F C A F C A
    36: [67, 72, 76, 72, 79, 76, 72, 67],  # G C E C G E C G
    43: [67, 71, 74, 71, 79, 74, 71, 67],  # G B D B G D B G
    38: [69, 74, 77, 74, 81, 77, 74, 69],  # A D F D A F D A
    40: [68, 71, 76, 71, 80, 76, 71, 68],  # G# B E B G# E B G#
}

SAW = [(k, 1.0 / k) for k in range(1, 8)]
SOFT_SAW = [(k, 1.0 / (k ** 1.65)) for k in range(1, 9)]
PULSE = [(k, 1.0 / k) for k in (1, 3, 5, 7, 9)]
TRIANGLE = [(k, (-1.0) ** ((k - 1) // 2) / (k * k)) for k in (1, 3, 5, 7)]


def midi(note: int) -> float:
    return 440.0 * 2.0 ** ((note - 69) / 12.0)


def envelope(n: int, attack: float, release: float) -> np.ndarray:
    env = np.ones(n, dtype=np.float64)
    a = min(n, max(0, int(attack * SR)))
    r = min(max(0, n - a), max(0, int(release * SR)))
    if a:
        env[:a] = np.linspace(0.0, 1.0, a, endpoint=False)
    if r:
        env[n - r:] = np.linspace(1.0, 0.0, r)
    return env


def add_wrap(track: np.ndarray, sound: np.ndarray, start: int) -> None:
    """Add a short sound at a sample offset, wrapping across the loop seam."""
    start %= SAMPLES
    first = min(len(sound), SAMPLES - start)
    track[start:start + first] += sound[:first]
    if first < len(sound):
        track[:len(sound) - first] += sound[first:]


def soften_loop_edge(track: np.ndarray, duration: float = 0.02) -> None:
    """Fade both sides of the loop boundary to a shared, click-free zero."""
    count = min(int(duration * SR), len(track) // 2)
    phase = np.linspace(0.0, np.pi / 2.0, count, endpoint=True)
    track[:count] *= np.sin(phase) ** 2
    track[-count:] *= np.cos(phase) ** 2


def oscillator(freq: float, start: int, n: int,
               harmonics: list[tuple[int, float]], detune: float = 0.0,
               vibrato: float = 0.0) -> np.ndarray:
    idx = (start + np.arange(n, dtype=np.int64)) % SAMPLES
    global_t = idx / SR
    phase_mod = vibrato * np.sin(TAU * 5.0 * global_t) if vibrato else 0.0
    signal = np.zeros(n, dtype=np.float64)
    for cents in ((-detune, detune) if detune else (0.0,)):
        tuned = freq * 2.0 ** (cents / 1200.0)
        cycles = round(tuned * LOOP_SECONDS)
        phase = TAU * cycles * idx / SAMPLES + phase_mod
        for harmonic, gain in harmonics:
            signal += gain * np.sin(phase * harmonic)
    voices = 2 if detune else 1
    return signal / voices


def note(track: np.ndarray, pitch: int, start_beat: float, duration_beats: float,
         gain: float, harmonics: list[tuple[int, float]], attack: float = 0.004,
         release: float = 0.07, decay: float | None = None,
         detune: float = 0.0, vibrato: float = 0.0) -> None:
    start = int(round(start_beat * BEAT * SR))
    n = max(1, int(round(duration_beats * BEAT * SR)))
    t = np.arange(n) / SR
    sound = oscillator(midi(pitch), start, n, harmonics, detune, vibrato)
    sound *= envelope(n, attack, release)
    if decay is not None:
        sound *= np.exp(-t / decay)
    add_wrap(track, sound * gain, start)


def kick_sound() -> np.ndarray:
    n = int(0.34 * SR)
    t = np.arange(n) / SR
    f = 48.0 + 108.0 * np.exp(-t * 25.0)
    phase = TAU * np.cumsum(f) / SR
    body = np.sin(phase) * np.exp(-t * 10.0)
    click = np.sin(TAU * 1750.0 * t) * np.exp(-t * 115.0) * 0.08
    return (body + click) * envelope(n, 0.001, 0.12)


def snare_sound() -> np.ndarray:
    n = int(0.24 * SR)
    t = np.arange(n) / SR
    raw = RNG.uniform(-1.0, 1.0, n + 1)
    hiss = np.diff(raw)
    body = np.sin(TAU * 188.0 * t) * np.exp(-t * 23.0)
    return (hiss * np.exp(-t * 27.0) * 0.52 + body * 0.42) * envelope(n, 0.001, 0.13)


def hat_sound(length: float = 0.055, gain: float = 1.0) -> np.ndarray:
    n = int(length * SR)
    t = np.arange(n) / SR
    raw = RNG.uniform(-1.0, 1.0, n + 1)
    hiss = np.diff(raw)
    # A short moving average smooths the noise without dulling the pulse.
    hiss = np.convolve(hiss, np.ones(3) / 3.0, mode="same")
    return hiss * np.exp(-t * 75.0) * envelope(n, 0.001, length * 0.72) * gain


def pad_layer() -> np.ndarray:
    track = np.zeros(SAMPLES, dtype=np.float64)
    fade = 0.38
    for bar, (_root, chord) in enumerate(PROGRESSION):
        start = bar * 4.0 - fade / BEAT
        length = 4.0 + 2.0 * fade / BEAT
        for voice, pitch in enumerate(chord):
            level = 0.105 if voice < 3 else 0.075
            note(track, pitch, start, length, level, SOFT_SAW,
                 attack=fade, release=fade, detune=6.0, vibrato=0.003)
    # Slow, low stereo-less pulse gives the pad a moving analog breath.
    t = np.arange(SAMPLES) / SR
    swell = 0.84 + 0.16 * np.sin(TAU * (BPM / 60.0 / 2.0) * t - np.pi / 2.0) ** 2
    track *= swell
    # The pad sustains through the loop seam; taper only 20 ms at each edge
    # so its strongest partials do not click when Godot wraps the WAV.
    soften_loop_edge(track)
    return track


def bass_layer() -> np.ndarray:
    track = np.zeros(SAMPLES, dtype=np.float64)
    pattern = [0, 12, 7, 12, 0, 12, 7, 10]
    for bar, (root, _chord) in enumerate(PROGRESSION):
        for step, interval in enumerate(pattern):
            beat = bar * 4.0 + step * 0.5
            pitch = root + interval
            dur = 0.40 if step % 2 == 0 else 0.31
            note(track, pitch, beat, dur, 0.24, SOFT_SAW,
                 attack=0.003, release=0.055, decay=0.28)
            note(track, pitch - 12, beat, dur, 0.16, [(1, 1.0)],
                 attack=0.002, release=0.045, decay=0.25)
    return track


def drums_layer() -> np.ndarray:
    track = np.zeros(SAMPLES, dtype=np.float64)
    kick = kick_sound()
    snare = snare_sound()
    for bar in range(BARS):
        bar_beat = bar * 4.0
        for beat in range(4):
            add_wrap(track, kick * (0.8 if beat % 2 == 0 else 0.67),
                     int(round((bar_beat + beat) * BEAT * SR)))
            if beat in (1, 3):
                add_wrap(track, snare * (0.66 if bar % 4 else 0.75),
                         int(round((bar_beat + beat) * BEAT * SR)))
        for eighth in range(8):
            strength = 0.20 if eighth % 2 == 0 else 0.14
            if eighth in (3, 7):
                strength *= 1.3
            add_wrap(track, hat_sound(0.045, strength),
                     int(round((bar_beat + eighth * 0.5) * BEAT * SR)))
        if bar in (3, 7, 11, 15):
            # A restrained noise lift at four-bar boundaries, with the last
            # one landing exactly on the next loop's downbeat.
            roll = hat_sound(0.18, 0.20)
            add_wrap(track, roll, int(round((bar_beat + 3.5) * BEAT * SR)))
    return track


def lead_layer() -> np.ndarray:
    track = np.zeros(SAMPLES, dtype=np.float64)
    for bar, (root, _chord) in enumerate(PROGRESSION):
        phrase = MELODIES[root]
        if bar % 2:
            phrase = phrase[2:] + phrase[:2]
        for step, pitch in enumerate(phrase):
            beat = bar * 4.0 + step * 0.5
            length = 0.39 if step not in (3, 7) else 0.30
            note(track, pitch, beat, length, 0.12, PULSE,
                 attack=0.003, release=0.065, decay=0.48,
                 detune=4.0, vibrato=0.002)
            # Short, quiet dotted echo adds a warm retro width while remaining
            # in the same mono mix and on the same clock.
            note(track, pitch, beat + 0.30, length * 0.72, 0.035, TRIANGLE,
                 attack=0.002, release=0.08, decay=0.34)
    return track


def write(name: str, data: np.ndarray) -> None:
    pcm = (np.clip(data, -1.0, 1.0) * 32767.0).astype("<i2")
    path = os.path.join(OUT, name)
    with wave.open(path, "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(SR)
        wav.writeframes(pcm.tobytes())
    print(f"wrote {name}: {len(pcm) / SR:.2f}s, peak={np.max(np.abs(data)):.3f}")


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    raw_layers = {
        "music_synth_pad.wav": pad_layer(),
        "music_synth_bass.wav": bass_layer(),
        "music_synth_drums.wav": drums_layer(),
        "music_synth_lead.wav": lead_layer(),
    }
    solo_peaks = {
        "music_synth_pad.wav": 0.46,
        "music_synth_bass.wav": 0.50,
        "music_synth_drums.wav": 0.46,
        "music_synth_lead.wav": 0.44,
    }
    layers: dict[str, np.ndarray] = {}
    for name, data in raw_layers.items():
        peak = float(np.max(np.abs(data))) or 1.0
        layers[name] = data * (solo_peaks[name] / peak)
    combined = sum(layers.values())
    peak = float(np.max(np.abs(combined))) or 1.0
    # Leave headroom for the game's music bus when all four layers are up.
    headroom = min(1.0, 0.94 / peak)
    print(f"{BPM:.0f} BPM, A minor, {BARS} bars, {LOOP_SECONDS:.2f}s loop, mix headroom={headroom:.3f}")
    for name, data in layers.items():
        write(name, data * headroom)


if __name__ == "__main__":
    main()
