"""Synthesises Smriti's original notification sounds (no samples, royalty-free).

Writes 16 kHz mono WAV files into android/app/src/main/res/raw/:
  <sound>.wav            short sound for reminders
  midnight_<sound>.wav   10 seconds of tick-tock, then the sound at 12:00
Run: python3 tools/make_sounds.py
"""
import math
import os
import random
import struct
import wave

RATE = 16000
OUT = os.path.join(os.path.dirname(__file__), "..", "android", "app", "src", "main", "res", "raw")


def silence(sec):
    return [0.0] * int(sec * RATE)


def mix(base, add, at):
    start = int(at * RATE)
    if len(base) < start + len(add):
        base.extend([0.0] * (start + len(add) - len(base)))
    for i, v in enumerate(add):
        base[start + i] += v
    return base


def bell(freq, dur, partials, decay, amp=0.5):
    """Struck bell: inharmonic partials, each with its own decay."""
    n = int(dur * RATE)
    out = []
    for i in range(n):
        t = i / RATE
        v = 0.0
        for ratio, weight, dmul in partials:
            v += weight * math.sin(2 * math.pi * freq * ratio * t) * math.exp(-t * decay * dmul)
        attack = min(1.0, t / 0.004)
        out.append(amp * attack * v)
    return out


def tick(freq, amp):
    """Short woody click: a decaying tone with a little noise."""
    n = int(0.045 * RATE)
    rnd = random.Random(int(freq))
    return [amp * math.exp(-i / (0.006 * RATE)) * (0.7 * math.sin(2 * math.pi * freq * i / RATE) + 0.3 * (rnd.random() * 2 - 1))
            for i in range(n)]


def chime():
    notes = [1046.5, 1318.5, 1568.0, 2093.0]  # C6 E6 G6 C7
    s = []
    for k, f in enumerate(notes):
        mix(s, bell(f, 2.2, [(1, 1.0, 1), (2.0, 0.35, 1.6), (3.0, 0.15, 2.2)], 2.2, 0.32), k * 0.16)
    return s


def soft_bell():
    s = []
    for at in (0.0, 1.1):
        mix(s, bell(880, 2.6, [(1, 1.0, 1), (2.76, 0.25, 1.8), (5.4, 0.08, 2.6)], 1.6, 0.4), at)
    return s


def temple_bell():
    s = []
    for at in (0.0, 2.2):
        mix(s, bell(196, 4.5, [(1, 1.0, 1), (1.005, 0.6, 1), (2.0, 0.5, 1.4), (2.76, 0.4, 1.6), (5.4, 0.2, 2.4), (8.93, 0.1, 3)],
                    0.75, 0.42), at)
    return s


def birthday_tune():
    """An original, cheerful 12-note melody (not "Happy Birthday to You")."""
    melody = [(523.3, .22), (659.3, .22), (784.0, .22), (1046.5, .44), (880.0, .22), (784.0, .22),
              (698.5, .22), (880.0, .44), (784.0, .22), (659.3, .22), (587.3, .22), (1046.5, .8)]
    s, t = [], 0.0
    for f, d in melody:
        mix(s, bell(f, d + 0.6, [(1, 1.0, 1), (2, 0.3, 1.5), (3, 0.12, 2)], 3.2, 0.3), t)
        t += d
    return s


def tick_tock(seconds, crescendo=True):
    s = []
    for k in range(seconds):
        amp = (0.25 + 0.5 * k / max(1, seconds - 1)) if crescendo else 0.45
        mix(s, tick(2100 if k % 2 == 0 else 1500, amp), k)
    return s


def write(name, samples):
    peak = max(1e-9, max(abs(v) for v in samples))
    scale = 0.89 / peak if peak > 0.89 else 1.0
    tail = samples + silence(0.3)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, v * scale)) * 32767)) for v in tail))
    print(name, f"{len(tail) / RATE:.1f}s")


def main():
    os.makedirs(OUT, exist_ok=True)
    sounds = {
        "chime": chime(),
        "soft_bell": soft_bell(),
        "temple_bell": temple_bell(),
        "birthday_tune": birthday_tune(),
    }
    sounds["tick_tock"] = mix(tick_tock(3, crescendo=False), chime(), 3.0)
    for name, s in sounds.items():
        write(name, s)
        # Midnight: ticks at 11:59:50 … 11:59:59, then the sound exactly at 12:00.
        finale = chime() if name == "tick_tock" else s
        write("midnight_" + name, mix(tick_tock(10), finale, 10.0))


if __name__ == "__main__":
    main()
