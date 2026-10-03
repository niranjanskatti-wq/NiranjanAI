"""Generates Deepwork's ambient loops and chimes as Ogg Vorbis files (assets/sounds).

Everything is synthesized, so the sounds ship with the app and need no downloads.
Each sound is rendered to WAV, then encoded with ffmpeg to keep the APK small.
Run: python3 tool/generate_sounds.py   (needs ffmpeg with libvorbis)
"""
import math
import os
import random
import struct
import subprocess
import tempfile
import wave

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'sounds')


def write(name, data):
    peak = max(1e-9, max(abs(x) for x in data))
    path = os.path.join(OUT, name)
    with tempfile.NamedTemporaryFile(suffix='.ogg') as tmp:
        with wave.open(tmp.name, 'wb') as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, x / peak * 0.85)) * 32000)) for x in data))
        subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', tmp.name, '-c:a', 'libvorbis', '-q:a', '3', path], check=True)
    print('wrote', path, len(data) / SR, 's')


def seamless(data, fade_s=0.5):
    """Crossfade the tail into the head so the loop has no click."""
    n = int(fade_s * SR)
    out = data[: len(data) - n]
    for i in range(n):
        a = i / n
        out[i] = data[i] * a + data[len(data) - n + i] * (1 - a)
    return out


def white(seconds, rng):
    return [rng.uniform(-1, 1) * 0.6 for _ in range(int(seconds * SR))]


def brown(seconds, rng):
    out, last = [], 0.0
    for _ in range(int(seconds * SR)):
        last = (last + 0.02 * rng.uniform(-1, 1)) / 1.02
        out.append(last * 3.5)
    # Remove slow drift so the loop stays centered.
    mean = sum(out) / len(out)
    return [x - mean for x in out]


def rain(seconds, rng):
    n = int(seconds * SR)
    out = []
    b0 = b1 = b2 = hp = last_w = 0.0
    for i in range(n):
        w = rng.uniform(-1, 1)
        b0 = 0.99765 * b0 + w * 0.099046
        b1 = 0.963 * b1 + w * 0.2965164
        b2 = 0.57 * b2 + w * 1.0526913
        pink = (b0 + b1 + b2 + w * 0.1848) * 0.11
        hp = 0.85 * (hp + w - last_w)
        last_w = w
        swell = 0.85 + 0.15 * math.sin(i / SR * 0.35 * 2 * math.pi)
        out.append((pink * 0.9 + hp * 0.18) * swell)
    for _ in range(int(seconds * 140)):
        start = rng.randrange(n)
        amp = 0.05 + rng.random() * rng.random() * 0.35
        freq = 1800 + rng.random() * 4200
        dur = int(SR * (0.004 + rng.random() * 0.018))
        for k in range(dur):
            if start + k >= n:
                break
            env = math.exp(-k / (dur * 0.25))
            out[start + k] += math.sin(2 * math.pi * freq * k / SR) * env * amp
    return out


def cafe(seconds, rng):
    n = int(seconds * SR)
    out = []
    br = bp1 = bp2 = 0.0
    env, target = 0.5, 0.5
    step = int(SR * 0.09)
    for i in range(n):
        w = rng.uniform(-1, 1)
        br = (br + 0.02 * w) / 1.02
        bp1 += 0.12 * (w - bp1)
        bp2 += 0.02 * (bp1 - bp2)
        voice = bp1 - bp2
        if i % step == 0:
            target = 0.25 + rng.random() * 0.9
        env += (target - env) * 0.0012
        out.append(br * 2.2 + voice * env * 1.6)
    for _ in range(int(seconds * 0.7)):
        start = rng.randrange(n)
        f = 2400 + rng.random() * 2600
        amp = 0.04 + rng.random() * 0.08
        for k in range(int(SR * 0.35)):
            if start + k >= n:
                break
            e = math.exp(-k / (SR * 0.06))
            out[start + k] += (math.sin(2 * math.pi * f * k / SR) + 0.5 * math.sin(2 * math.pi * f * 2.7 * k / SR)) * e * amp
    return out


def chime(notes):
    n = int(SR * 2.6)
    out = [0.0] * n
    for idx, f in enumerate(notes):
        t0 = int(idx * 0.18 * SR)
        for k in range(n - t0):
            t = k / SR
            env = min(1, t / 0.01) * math.exp(-t * 2.4)
            s = sum(amp * math.sin(2 * math.pi * f * mult * t) for mult, amp in ((1, 1), (2.01, 0.35), (3.02, 0.12)))
            out[t0 + k] += s * env * 0.4
    return out


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    rng = random.Random(42)
    write('white.ogg', seamless(white(6, rng)))
    write('brown.ogg', seamless(brown(8, rng)))
    write('rain.ogg', seamless(rain(14, rng)))
    write('cafe.ogg', seamless(cafe(16, rng)))
    write('chime_complete.ogg', chime([659.25, 987.77]))
    write('chime_break.ogg', chime([523.25, 783.99]))
