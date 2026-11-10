"""Generate a short, rough, breathy creature shriek without external tools."""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 32000
DURATION = 1.34
random.seed(4419)
out = Path(__file__).resolve().parents[1] / "audio" / "scream_distorted.wav"
frames = int(RATE * DURATION)
raw = []
breath_lp = 0.0
throat_lp = 0.0
phase = 0.0
subphase = 0.0
for n in range(frames):
    t = n / RATE
    progress = t / DURATION
    # Sudden intake, voiced midrange shriek, then a rough falling breath.
    attack = min(1.0, t / 0.012)
    release = min(1.0, max(0.0, (DURATION - t) / 0.25))
    envelope = attack * release * (0.84 + 0.16 * math.sin(math.pi * progress))
    pitch = 205 + 430 * math.sin(min(1.0, progress * 1.25) * math.pi * 0.53)
    pitch += 26 * math.sin(2 * math.pi * 5.2 * t) + 11 * math.sin(2 * math.pi * 8.7 * t)
    phase += 2 * math.pi * pitch / RATE
    subphase += 2 * math.pi * (pitch * 0.503) / RATE
    vocal = (math.sin(phase) * 0.48 + math.sin(phase * 2.0 + 0.2) * 0.19
             + math.sin(phase * 3.01 + 0.8) * 0.12 + math.sin(phase * 4.98) * 0.055
             + math.sin(subphase) * 0.13)
    noise = random.uniform(-1.0, 1.0)
    breath_lp = breath_lp * 0.88 + noise * 0.12
    throat_lp = throat_lp * 0.66 + noise * 0.34
    rasp = (noise - breath_lp) * 0.24 + (throat_lp - breath_lp) * 0.20
    inhale = noise * (0.42 if t < 0.075 else 0.08)
    grit = math.tanh((vocal + rasp) * 1.8) * 0.84
    low = math.sin(2 * math.pi * 58 * t) * 0.13
    raw.append((grit + inhale + low) * envelope)

# Two quiet, short reflections create a close, enclosed-room tail.
delay = int(RATE * 0.047)
delay2 = int(RATE * 0.091)
samples = bytearray()
for n, value in enumerate(raw):
    if n >= delay:
        value += raw[n - delay] * 0.20
    if n >= delay2:
        value += raw[n - delay2] * 0.11
    value = math.tanh(value * 1.25)
    samples.extend(struct.pack("<h", int(max(-1.0, min(1.0, value)) * 32767)))

out.parent.mkdir(parents=True, exist_ok=True)
with wave.open(str(out), "wb") as wav:
    wav.setnchannels(1)
    wav.setsampwidth(2)
    wav.setframerate(RATE)
    wav.writeframes(samples)
print(out)
