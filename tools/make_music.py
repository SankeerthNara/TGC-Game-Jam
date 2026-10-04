"""Generates the game's adaptive music: four layers of one 8-bar loop (calm pad, pulse, tension,
danger) that the game crossfades live, a separate chase loop and two short stingers.
Everything is synthesised from scratch here (no samples), so it is ours and free to use (CC0).

Usage (from the repo root):  python tools/make_music.py
Writes new-game-project/assets/audio/music_*.wav and sting_*.wav (22.05 kHz mono, 16 bit).
"""
import os
import wave
import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "new-game-project", "assets", "audio")
rng = np.random.default_rng(7)


def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12.0)


def env(n, attack, release, total):
    """Linear attack, hold, linear release over `total` samples."""
    e = np.ones(total)
    a = min(int(attack * SR), total)
    r = min(int(release * SR), total - a)
    if a > 0:
        e[:a] = np.linspace(0, 1, a)
    if r > 0:
        e[total - r:] = np.linspace(1, 0, r)
    return e


def additive(freq, dur, harmonics, decay=None, attack=0.01, release=0.05, vib=0.0):
    n = int(dur * SR)
    t = np.arange(n) / SR
    ph = 2 * np.pi * freq * t
    if vib:
        ph += vib * np.sin(2 * np.pi * 5.0 * t)
    out = np.zeros(n)
    for k, amp in harmonics:
        out += amp * np.sin(ph * k)
    e = env(n, attack, release, n)
    if decay:
        e *= np.exp(-t / decay)
    return out * e


SAW = [(k, 1.0 / k) for k in range(1, 8)]
SOFT_SAW = [(k, 1.0 / (k * k ** 0.5)) for k in range(1, 7)]
SQUARE = [(k, 1.0 / k) for k in (1, 3, 5, 7)]
SINE = [(1, 1.0)]


def kick(strength=1.0):
    n = int(0.35 * SR)
    t = np.arange(n) / SR
    f = 50 + 110 * np.exp(-t * 28)
    ph = 2 * np.pi * np.cumsum(f) / SR
    return strength * np.sin(ph) * np.exp(-t * 9)


def snare(strength=1.0):
    n = int(0.22 * SR)
    t = np.arange(n) / SR
    noise = rng.uniform(-1, 1, n)
    noise = np.diff(noise, prepend=0)  # brighter
    return strength * (0.6 * noise * np.exp(-t * 18) + 0.4 * np.sin(2 * np.pi * 190 * t) * np.exp(-t * 25))


def hat(strength=1.0, length=0.05):
    n = int(length * SR)
    t = np.arange(n) / SR
    noise = np.diff(rng.uniform(-1, 1, n + 1))
    return strength * noise * np.exp(-t * 70)


def clap(strength=1.0):
    n = int(0.25 * SR)
    t = np.arange(n) / SR
    noise = np.diff(rng.uniform(-1, 1, n + 1))
    e = np.exp(-t * 22)
    for d in (0.0, 0.012, 0.024):
        s = int(d * SR)
        e[s:s + 40] += 0.8
    return strength * noise * e * 0.6


def tick(strength=1.0):
    n = int(0.03 * SR)
    t = np.arange(n) / SR
    return strength * np.sin(2 * np.pi * 2400 * t) * np.exp(-t * 200)


class Track:
    def __init__(self, bpm, bars):
        self.bpm = bpm
        self.beat = 60.0 / bpm
        self.length = int(bars * 4 * self.beat * SR)
        self.buf = np.zeros(self.length + SR * 3)

    def add(self, sound, beat_pos, gain=1.0):
        s = int(beat_pos * self.beat * SR)
        self.buf[s:s + len(sound)] += sound * gain

    def finish(self, peak=0.8):
        out = self.buf[:self.length].copy()
        tail = self.buf[self.length:]
        out[:len(tail)] += tail  # wrap the tail so the loop is seamless
        m = np.max(np.abs(out)) or 1.0
        return out / m * peak


# D minor: Dm - Bb - F - A, two bars each (8 bars)
CHORDS = [[50, 53, 57], [46, 50, 53], [53, 57, 60], [45, 49, 52]]
ROOTS = [38, 34, 41, 33]


def layer_pad():
    tr = Track(100, 8)
    for i, ch in enumerate(CHORDS):
        for n in ch + [ch[0] + 12]:
            tr.add(additive(midi(n), 8 * tr.beat + 0.6, SOFT_SAW, attack=0.9, release=1.4, vib=0.004), i * 8, 0.22)
        # a soft bell on top every two bars
        tr.add(additive(midi(ch[2] + 24), 1.6, [(1, 1), (2.76, 0.3), (5.4, 0.1)], decay=0.6, attack=0.005, release=0.3), i * 8 + 0.5, 0.18)
    return tr.finish(0.55)


def layer_pulse():
    tr = Track(100, 8)
    for i, r in enumerate(ROOTS):
        for e in range(16):
            note = r + (12 if e % 4 == 3 else 0)
            tr.add(additive(midi(note), tr.beat * 0.45, SAW, decay=0.18, attack=0.004, release=0.04), i * 8 + e * 0.5, 0.5)
        for b in (0, 2, 4, 6):
            tr.add(kick(0.9), i * 8 + b)
        for e in range(16):
            tr.add(hat(0.18 if e % 2 else 0.1, 0.04), i * 8 + e * 0.5)
    return tr.finish(0.6)


def layer_tension():
    tr = Track(100, 8)
    for i, ch in enumerate(CHORDS):
        tones = [n + 12 for n in ch] + [ch[0] + 24, ch[1] + 24]
        seq = tones + tones[-2:0:-1]
        for s in range(32):
            n = seq[s % len(seq)]
            tr.add(additive(midi(n), tr.beat * 0.24, SQUARE, decay=0.09, attack=0.002, release=0.02), i * 8 + s * 0.25, 0.3)
        for s in range(32):
            tr.add(hat(0.22 if s % 2 == 0 else 0.12), i * 8 + s * 0.25)
        for b in (1, 3, 5, 7):
            tr.add(snare(0.5), i * 8 + b)
        for b in range(8):
            tr.add(tick(0.35), i * 8 + b)  # the bomb's clock
    return tr.finish(0.55)


def layer_danger():
    tr = Track(100, 8)
    for i, (r, ch) in enumerate(zip(ROOTS, CHORDS)):
        for b in range(8):
            tr.add(kick(1.0), i * 8 + b)
        for b in (1, 3, 5, 7):
            tr.add(clap(0.8), i * 8 + b)
        for s in range(32):
            n = r + 12 * (s % 2)
            tr.add(additive(midi(n), tr.beat * 0.22, SAW, decay=0.07, attack=0.002, release=0.02), i * 8 + s * 0.25, 0.4)
        for off in (1.5, 3.5, 5.5, 7.5):
            for n in ch:
                tr.add(additive(midi(n + 12), tr.beat * 0.3, SAW, decay=0.08, attack=0.003, release=0.03), i * 8 + off, 0.2)
        # a rising alarm every two bars
        n = int(tr.beat * 2 * SR)
        t = np.arange(n) / SR
        f = 600 + 500 * (t / t[-1])
        alarm = np.sin(2 * np.pi * np.cumsum(f) / SR) * env(n, 0.05, 0.2, n) * 0.25
        tr.add(alarm, i * 8 + 6)
    return tr.finish(0.6)


def chase():
    tr = Track(140, 8)
    melody = [62, 65, 69, 67, 65, 64, 62, 57, 58, 62, 65, 62, 60, 64, 67, 64]
    for bar in range(8):
        i = (bar // 2) % 4
        r = ROOTS[i]
        for b in range(4):
            tr.add(kick(1.0), bar * 4 + b)
        for b in (1, 3):
            tr.add(snare(0.7), bar * 4 + b)
        for s in range(8):
            tr.add(hat(0.2), bar * 4 + s * 0.5 + 0.25)
            tr.add(additive(midi(r + (12 if s % 2 else 0)), tr.beat * 0.4, SAW, decay=0.1, attack=0.002, release=0.02), bar * 4 + s * 0.5, 0.45)
        for k in range(2):
            n = melody[(bar * 2 + k) % len(melody)]
            tr.add(additive(midi(n + 12), tr.beat * 1.8, SQUARE, decay=0.5, attack=0.005, release=0.1, vib=0.006), bar * 4 + k * 2, 0.32)
    return tr.finish(0.7)


# ---------------------------------------------------------------- the final battle: a comic opera
# 3/4 at 138 BPM, 16 bars, D minor. Four layers that build with the fight:
# 1 strings and pizzicato, 2 the ink choir and timpani, 3 brass and snare, 4 the frenzy (the Narrator).
OPERA_BARS = 16
OPERA_PROG = [(38, [50, 53, 57]), (38, [50, 53, 57]), (34, [46, 50, 53]), (34, [46, 50, 53]),
              (36, [48, 52, 55]), (36, [48, 52, 55]), (33, [45, 49, 52]), (33, [45, 49, 52]),
              (38, [50, 53, 57]), (41, [53, 57, 60]), (34, [46, 50, 53]), (31, [43, 46, 50]),
              (33, [45, 49, 52]), (33, [45, 49, 52]), (38, [50, 53, 57]), (33, [45, 49, 52])]


class Track3(Track):
    def __init__(self, bpm, bars):
        super().__init__(bpm, bars)
        self.length = int(bars * 3 * self.beat * SR)
        self.buf = np.zeros(self.length + SR * 3)


def vowel(freq, dur, attack=0.25, release=0.5):
    """A sung 'aah': harmonics shaped by two formants, with vibrato."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    vib = 1 + 0.006 * np.sin(2 * np.pi * 5.2 * t)
    out = np.zeros(n)
    for k in range(1, 16):
        f = freq * k
        if f > SR / 2.2:
            break
        amp = np.exp(-((f - 750) / 260) ** 2) + 0.6 * np.exp(-((f - 1150) / 300) ** 2) + 0.15 / k
        out += amp * np.sin(2 * np.pi * f * np.cumsum(vib) / SR)
    return out * env(n, attack, release, n)


def timpani(note, strength=1.0):
    n = int(0.9 * SR)
    t = np.arange(n) / SR
    f = midi(note) * (1 + 0.04 * np.exp(-t * 20))
    s = np.sin(2 * np.pi * np.cumsum(f) / SR) + 0.3 * np.sin(2 * np.pi * np.cumsum(f * 1.5) / SR)
    return strength * s * np.exp(-t * 4.5)


def cymbal(strength=1.0, length=1.2):
    n = int(length * SR)
    t = np.arange(n) / SR
    noise = np.diff(rng.uniform(-1, 1, n + 1))
    return strength * noise * np.exp(-t * 3.0) * 0.5


def opera_strings():
    tr = Track3(138, OPERA_BARS)
    for bar, (root, ch) in enumerate(OPERA_PROG):
        b0 = bar * 3
        # oom-pah-pah: low pizzicato root, then two chord stabs
        tr.add(additive(midi(root), tr.beat * 0.5, SAW, decay=0.12, attack=0.003, release=0.05), b0, 0.7)
        for k in (1, 2):
            for n in ch:
                tr.add(additive(midi(n + 12), tr.beat * 0.35, SOFT_SAW, decay=0.1, attack=0.004, release=0.04), b0 + k, 0.22)
        for n in ch:
            tr.add(additive(midi(n), 3 * tr.beat + 0.3, SOFT_SAW, attack=0.3, release=0.4, vib=0.004), b0, 0.12)
    return tr.finish(0.6)


def opera_choir():
    tr = Track3(138, OPERA_BARS)
    for bar, (root, ch) in enumerate(OPERA_PROG):
        if bar % 2 == 0:
            for n in ch + [ch[0] + 12]:
                tr.add(vowel(midi(n + 12), 6 * tr.beat + 0.3), bar * 3, 0.16)
        tr.add(timpani(root + 12, 0.8), bar * 3)
        if bar % 4 == 3:
            for k in range(6):
                tr.add(timpani(root + 12, 0.25 + 0.1 * k), bar * 3 + 1.5 + k * 0.25)
    return tr.finish(0.6)


def opera_brass():
    tr = Track3(138, OPERA_BARS)
    motif = [74, 72, 69, 70, 69, 67, 65, 64]
    for bar, (root, ch) in enumerate(OPERA_PROG):
        b0 = bar * 3
        n = motif[bar % len(motif)] - (0 if bar < 8 else 12)
        tr.add(additive(midi(n), tr.beat * 2.2, SAW, decay=0.9, attack=0.03, release=0.15, vib=0.005), b0, 0.42)
        tr.add(additive(midi(n - 7), tr.beat * 0.6, SAW, decay=0.2, attack=0.01, release=0.05), b0 + 2.5, 0.3)
        tr.add(snare(0.45), b0 + 1)
        tr.add(snare(0.45), b0 + 2)
        tr.add(kick(0.8), b0)
    return tr.finish(0.6)


def opera_frenzy():
    tr = Track3(138, OPERA_BARS)
    for bar, (root, ch) in enumerate(OPERA_PROG):
        b0 = bar * 3
        tones = [n + 24 for n in ch] + [ch[1] + 12]
        for s in range(12):
            tr.add(additive(midi(tones[s % len(tones)]), tr.beat * 0.22, SQUARE, decay=0.06, attack=0.002, release=0.02), b0 + s * 0.25, 0.22)
        for b in range(3):
            tr.add(kick(0.9), b0 + b)
        if bar % 2 == 0:
            tr.add(cymbal(0.7), b0)
        for n in ch:
            tr.add(vowel(midi(n + 24), 3 * tr.beat, attack=0.1, release=0.3), b0, 0.08)
    return tr.finish(0.6)


def sting(notes, step, last_len, wave_shape=SQUARE):
    total = int((len(notes) * step + last_len + 0.5) * SR)
    buf = np.zeros(total)
    for k, n in enumerate(notes):
        d = last_len if k == len(notes) - 1 else step * 1.5
        s = additive(midi(n), d, wave_shape, decay=d * 0.6, attack=0.004, release=0.08)
        st = int(k * step * SR)
        buf[st:st + len(s)] += s
    return buf / (np.max(np.abs(buf)) or 1) * 0.7


def write(name, data):
    path = os.path.join(OUT, name)
    pcm = (np.clip(data, -1, 1) * 32767).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print("wrote", name, round(len(data) / SR, 1), "s")


if __name__ == "__main__":
    write("music_pad.wav", layer_pad())
    write("music_pulse.wav", layer_pulse())
    write("music_tension.wav", layer_tension())
    write("music_danger.wav", layer_danger())
    write("music_chase.wav", chase())
    write("music_opera_strings.wav", opera_strings())
    write("music_opera_choir.wav", opera_choir())
    write("music_opera_brass.wav", opera_brass())
    write("music_opera_frenzy.wav", opera_frenzy())
    write("sting_win.wav", sting([62, 66, 69, 74], 0.11, 0.9))
    write("sting_fail.wav", sting([62, 61, 60, 55], 0.16, 1.0, SAW))
