"""Generate the short, comic sound effects used by Mirror Page.

All sounds are synthesised here from elementary oscillators and noise. No samples or
audio packages are used; NumPy is the only dependency. The output is CC0.

Run from the repository root: python tools/make_sfx.py
Writes 32 mono 16-bit WAVs at 22050 Hz to new-game-project/assets/audio/.
"""

from __future__ import annotations

import os
import wave

import numpy as np


SR = 22050
OUT = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "new-game-project", "assets", "audio",
)
RNG = np.random.default_rng(104)


def envelope(n: int, attack: float = 0.006, release: float = 0.08) -> np.ndarray:
    e = np.ones(n, dtype=np.float64)
    a = min(n, int(attack * SR))
    r = min(max(0, n - a), int(release * SR))
    if a:
        e[:a] = np.linspace(0.0, 1.0, a, endpoint=False)
    if r:
        e[n - r:] = np.linspace(1.0, 0.0, r)
    return e


def tone(freq: float, seconds: float, level: float = 1.0, shape: str = "sine",
         attack: float = 0.006, release: float = 0.08, decay: float | None = None,
         vibrato: float = 0.0) -> np.ndarray:
    n = max(1, int(seconds * SR))
    t = np.arange(n) / SR
    phase = 2.0 * np.pi * freq * t
    if vibrato:
        phase += vibrato * np.sin(2.0 * np.pi * 5.0 * t)
    if shape == "square":
        y = sum(np.sin(phase * k) / k for k in (1, 3, 5, 7))
    elif shape == "soft":
        y = sum(np.sin(phase * k) / (k ** 1.7) for k in range(1, 7))
    elif shape == "metal":
        y = (np.sin(phase) + 0.42 * np.sin(phase * 2.71) +
             0.22 * np.sin(phase * 5.13))
    else:
        y = np.sin(phase)
    e = envelope(n, attack, release)
    if decay is not None:
        e *= np.exp(-t / decay)
    return y * e * level


def sweep(start: float, end: float, seconds: float, level: float = 1.0,
          shape: str = "sine", attack: float = 0.002, release: float = 0.08) -> np.ndarray:
    n = max(1, int(seconds * SR))
    t = np.arange(n) / SR
    f = np.linspace(start, end, n)
    phase = 2.0 * np.pi * np.cumsum(f) / SR
    if shape == "square":
        y = sum(np.sin(phase * k) / k for k in (1, 3, 5))
    else:
        y = np.sin(phase)
    return y * envelope(n, attack, release) * level


def noise(seconds: float, level: float = 1.0, release: float = 0.12,
          soft: bool = True) -> np.ndarray:
    n = max(1, int(seconds * SR))
    y = RNG.uniform(-1.0, 1.0, n)
    if soft:
        # Short moving average takes the harsh edge off while retaining a paper/swish sound.
        y = np.convolve(y, np.ones(9) / 9.0, mode="same")
    return y * envelope(n, 0.001, release) * level


def place(parts: list[tuple[float, np.ndarray]]) -> np.ndarray:
    end = max((int(at * SR) + len(sound) for at, sound in parts), default=1)
    out = np.zeros(max(1, end), dtype=np.float64)
    for at, sound in parts:
        i = int(at * SR)
        out[i:i + len(sound)] += sound
    return out


def chord(notes: tuple[float, ...], seconds: float, level: float = 0.35,
          attack: float = 0.02, release: float = 0.18) -> np.ndarray:
    return place([(0.0, tone(n, seconds, level / len(notes), "soft", attack, release)) for n in notes])


def sounds() -> dict[str, np.ndarray]:
    fx: dict[str, np.ndarray] = {}

    fx["task_success"] = place([(0, tone(660, .16, .75, "metal", decay=.24)),
                                 (.13, tone(880, .24, .72, "metal", decay=.32))])
    fx["task_mistake"] = place([(0, sweep(190, 72, .22, .86, "sine", release=.16)),
                                (0, noise(.13, .17, .12))])
    fx["vampire_spotted"] = place([(0, noise(.28, .35, .24)),
                                   (.06, sweep(980, 260, .34, .65, "sine", release=.27))])
    fx["reveal_friend"] = place([(0, chord((523, 659, 784), .62, .6, .12, .32)),
                                 (.08, tone(1047, .38, .42, "metal", decay=.48))])
    fx["reveal_villain"] = place([(0, sweep(310, 95, .44, .62, "square", release=.32)),
                                  (.04, tone(233, .52, .45, "metal", decay=.62)),
                                  (.12, noise(.24, .14, .22))])
    fx["kill"] = place([(0, sweep(850, 110, .32, .55, release=.22)),
                        (.18, sweep(115, 48, .28, .9, release=.24)),
                        (.16, noise(.2, .32, .18))])
    fx["key_get"] = place([(0, tone(1047, .12, .48, "metal", decay=.35)),
                           (.09, tone(1397, .14, .48, "metal", decay=.4)),
                           (.18, tone(1760, .34, .5, "metal", decay=.58))])
    fx["explosion"] = place([(0, sweep(105, 34, .78, .92, release=.66)),
                             (0, noise(.82, .52, .72)),
                             (.12, tone(58, .9, .35, "sine", release=.82))])
    fx["friend_assigned"] = place([(0, tone(620, .09, .62, "square", decay=.14)),
                                   (.1, tone(830, .12, .62, "square", decay=.19))])
    fx["friend_done"] = place([(0, tone(740, .12, .55, "metal", decay=.24)),
                               (.1, tone(988, .2, .58, "metal", decay=.3))])
    fx["page_turn"] = place([(0, noise(.32, .5, .3)),
                             (.02, sweep(520, 170, .34, .24, release=.28))])
    fx["comic_pop"] = place([(0, sweep(280, 105, .16, .78, "square", release=.12)),
                             (.015, noise(.07, .18, .06, False))])
    fx["key_click"] = place([(0, tone(1450, .075, .62, "metal", decay=.14)),
                             (.025, tone(730, .11, .52, "metal", decay=.18))])
    fx["chase_jump"] = place([(0, sweep(180, 620, .19, .58, "square", release=.15)),
                              (.14, tone(520, .11, .38, "metal", decay=.16))])
    fx["chase_bounce"] = place([(0, sweep(95, 770, .32, .76, "sine", release=.24)),
                                (.21, tone(890, .22, .45, "metal", decay=.3))])
    fx["chase_fall"] = place([(0, sweep(900, 150, .48, .66, release=.42)),
                              (.08, noise(.34, .15, .3))])
    fx["chase_checkpoint"] = place([(0, tone(587, .12, .5, "metal", decay=.2)),
                                    (.11, tone(784, .14, .48, "metal", decay=.22)),
                                    (.22, tone(988, .28, .52, "metal", decay=.38))])
    fx["chase_hit"] = place([(0, noise(.18, .5, .15, False)),
                             (.01, sweep(180, 58, .23, .82, release=.18))])
    fx["chase_vault"] = place([(0, sweep(260, 740, .22, .55, release=.19)),
                               (.12, noise(.13, .18, .1))])
    fx["chase_slide"] = place([(0, noise(.28, .42, .25)),
                               (0, sweep(300, 190, .23, .19, release=.2))])
    fx["chase_win"] = place([(0, chord((523, 659, 784), .42, .65)),
                             (.3, tone(1047, .36, .6, "metal", decay=.42))])
    fx["chase_lose"] = place([(0, sweep(480, 190, .48, .72, "square", release=.4)),
                              (.14, tone(155, .42, .26, "soft", decay=.5))])
    fx["web_attach"] = place([(0, sweep(380, 1200, .13, .48, release=.1)),
                              (.08, tone(890, .09, .32, "metal", decay=.14))])
    fx["web_shoot"] = sweep(980, 260, .19, .58, "square", release=.16)
    fx["web_hit"] = place([(0, noise(.12, .52, .1)),
                            (.01, tone(210, .18, .58, "soft", decay=.24))])

    # EventBus signal mappings in docs/SOUNDS.md.
    fx["task_open"] = place([(0, tone(530, .08, .45, "square", decay=.12)),
                              (.085, tone(790, .11, .45, "square", decay=.16))])
    t = np.arange(int(.95 * SR)) / SR
    siren_f = 610 + 240 * np.sin(2 * np.pi * 1.65 * t)
    siren_phase = 2 * np.pi * np.cumsum(siren_f) / SR
    fx["sabotage_alarm"] = (np.sin(siren_phase) + .22 * np.sin(2 * siren_phase)) * envelope(len(t), .015, .15) * .68
    fx["sabotage_fixed"] = chord((523, 659, 784, 1047), .48, .66, .025, .35)
    fx["heart_lost"] = place([(0, sweep(165, 48, .31, .86, release=.26)),
                              (0, noise(.14, .15, .13))])
    fx["death"] = place([(0, sweep(560, 95, .72, .65, release=.65)),
                         (.16, tone(130, .62, .28, "soft", decay=.75))])

    # Retained town hooks, even though the current station build does not emit them.
    fx["item_collected"] = place([(0, tone(880, .1, .52, "metal", decay=.2)),
                                  (.075, tone(1320, .15, .48, "metal", decay=.26))])
    fx["trade_made"] = place([(0, tone(390, .1, .38, "metal", decay=.15)),
                              (.1, tone(780, .18, .58, "metal", decay=.28))])
    fx["door_unlocked"] = place([(0, tone(1200, .08, .56, "metal", decay=.13)),
                                 (.07, tone(620, .15, .54, "metal", decay=.23)),
                                 (.17, tone(980, .26, .52, "metal", decay=.34))])
    return fx


def write(name: str, data: np.ndarray) -> None:
    # Equal peak keeps the pack coherent; the player applies a small per-effect mix trim.
    peak = float(np.max(np.abs(data))) if data.size else 0.0
    if peak < 1e-9:
        data = np.zeros(int(.1 * SR), dtype=np.float64)
    else:
        data = data / peak * 0.78
    pcm = (np.clip(data, -1.0, 1.0) * 32767.0).astype("<i2")
    path = os.path.join(OUT, f"sfx_{name}.wav")
    with wave.open(path, "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(SR)
        wav.writeframes(pcm.tobytes())
    print(f"wrote {os.path.basename(path)} ({len(pcm) / SR:.2f}s)")


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for name, audio in sounds().items():
        write(name, audio)
