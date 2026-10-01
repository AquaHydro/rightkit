"""RightKit v2 score: 60s, 120 BPM, A major. Code-original, no samples. Derived from ../audio/score.py.
Adapted from the guizang skill's CodePilot example. Bright, warm, light on its feet.
Sections follow v2/plan.json: brand 0-3 (motif over a pad), Riko 3-7 (groove lands on the press at 4.5),
features 7-49, safe (breakdown) 49-52, build 52-54, end 54-60.
Usage: python3 v2/score.py  ->  v2/assets/music.wav (+ v2/assets/music-raw.wav)
"""
import array, math, wave, random, subprocess, sys
from pathlib import Path

OUT = Path(__file__).resolve().parent / 'assets'
RATE = 48000; BPM = 120; BEAT = 60 / BPM; BAR = 4 * BEAT
DURATION = 60; N = int(RATE * DURATION)
left = array.array('f', [0]) * N; right = array.array('f', [0]) * N
rng = random.Random(2026)

def hz(note): return 440 * 2 ** ((note - 69) / 12)

def add(start, dur, note, amp, kind='keys', pan=0.0):
    off = round(start * RATE); freq = hz(note)
    lg = math.sqrt((1 - pan) / 2); rg = math.sqrt((1 + pan) / 2)
    for j in range(max(0, min(round(dur * RATE), N - off))):
        t = j / RATE; p = 2 * math.pi * freq * t
        if kind == 'pad':
            env = min(1, t / .3) * min(1, (dur - t) / .5)
            v = (math.sin(p) + .18 * math.sin(2 * p + .3) + .06 * math.sin(3 * p)) * env
        elif kind == 'bass':
            env = min(1, t / .008) * math.exp(-3.2 * t) * min(1, (dur - t) / .05)
            v = (math.sin(p) + .3 * math.sin(2 * p) + .08 * math.sin(3 * p)) * env
        elif kind == 'bell':
            env = min(1, t / .003) * math.exp(-2.6 * t) * min(1, (dur - t) / .1)
            v = (math.sin(p) + .35 * math.sin(2 * p) * math.exp(-3 * t) + .18 * math.sin(3.01 * p) * math.exp(-7 * t)) * env
        else:  # soft plucked keys
            env = min(1, t / .004) * math.exp(-5 * t) * min(1, (dur - t) / .08)
            v = (math.sin(p) + .28 * math.sin(2 * p) * math.exp(-6 * t) + .12 * math.sin(3 * p) * math.exp(-10 * t)) * env
        v *= amp
        left[off + j] += v * lg; right[off + j] += v * rg

def kick(start, amp=.22):
    off = round(start * RATE)
    for j in range(min(round(.2 * RATE), N - off)):
        t = j / RATE; ph = 2 * math.pi * (50 * t + 60 * .03 * (1 - math.exp(-t / .03)))
        v = amp * math.sin(ph) * math.exp(-20 * t) * min(1, t / .001)
        left[off + j] += v * .707; right[off + j] += v * .707

def snap(start, amp=.06):  # brushed backbeat
    off = round(start * RATE)
    for j in range(min(round(.12 * RATE), N - off)):
        t = j / RATE; v = (rng.uniform(-1, 1) * amp + math.sin(2 * math.pi * 190 * t) * amp * .4) * math.exp(-34 * t)
        left[off + j] += v * .7; right[off + j] += v * .75

def shaker(start, amp=.013, pan=0):
    off = round(start * RATE); prev = 0
    for j in range(min(round(.045 * RATE), N - off)):
        t = j / RATE; x = rng.uniform(-1, 1); v = (x - prev) * amp * math.exp(-80 * t); prev = x
        left[off + j] += v * (1 - pan) / 2 * 1.4; right[off + j] += v * (1 + pan) / 2 * 1.4

# A(add9), E(add9), F#m7, D6/9: shared A/C#/E on top keeps it warm and smooth.
CHORDS = [[45, 57, 61, 64, 71], [40, 56, 59, 64, 66], [42, 57, 61, 64, 69], [38, 57, 61, 64, 66]]
BREAK, BUILD, END = 49, 52, 54

for bar in range(math.ceil(DURATION / BAR)):
    start = bar * BAR; chord = CHORDS[bar % 4]
    if start >= 56: break
    for i, note in enumerate(chord[1:]):
        add(start, BAR + .2, note, .02, 'pad', (i - 1.5) * .3)
    if start < 4.5: continue
    # Keys: busier in the features, sparse in the breakdown.
    steps = [0, 3, 6] if BREAK <= start < BUILD else ([0, 2, 3, 5, 6] if bar % 2 == 0 else [0, 1, 3, 4, 6, 7])
    for step in steps:
        n = chord[1 + [0, 2, 1, 3, 2, 0, 3, 1][step]] + 12
        add(start + step * BEAT / 2, 1.0, n, .075 if step % 2 == 0 else .05, 'keys', -.3 if step % 2 == 0 else .3)
    if not BREAK <= start < BUILD:
        for t, n in [(0, chord[0]), (1.5, chord[0]), (3, chord[0] + 12)]:
            add(start + t * BEAT, .45, n, .15, "bass")

# Rhythm: in from the title card (beat 7), halftime in the breakdown, stops under the end chord.
for beat in range(9, round(56 / BEAT)):
    t = beat * BEAT
    breakdown = BREAK <= t < BUILD
    if not breakdown or beat % 4 == 0: kick(t, .2 if breakdown else .22)
    if beat % 2 and not breakdown: snap(t)
    shaker(t, pan=-.4); shaker(t + BEAT / 2, pan=.4)
    if BUILD <= t < END: shaker(t + BEAT / 4, .01, .1); shaker(t + 3 * BEAT / 4, .01, -.1)

# Signature motif: rises with the app icon, returns to close the film.
for t, n in [(0.15, 69), (0.27, 76), (0.39, 81), (0.51, 85)]: add(t, 2.2, n, .08, 'bell', .15)
for t, n in [(54.5, 76), (55.0, 78), (55.5, 81), (56.0, 85)]: add(t, 1.6, n, .085, 'bell', .1)
for i, n in enumerate([45, 57, 61, 64, 69, 76]): add(56.5, 3.4, n, .05 if n > 50 else .12, 'pad' if n > 50 else 'bass', (i - 2.5) * .2)
add(56.5, 3.3, 88, .06, 'bell', .2)
# Opening: a low A pad under the brand and Riko's wind-up; the groove starts on her press (4.5s).
for i, n in enumerate([33, 45, 52, 57]): add(0.0, 4.7, n, .05 if n > 40 else .09, 'pad', (i - 1.5) * .3)

def save(path):
    pcm = array.array('h')
    for i in range(N):
        t = i / RATE; env = min(1, t / .02) * min(1, max(0, (DURATION - t) / 1.2))
        pcm.extend([int(max(-.98, min(.98, left[i] * env)) * 32767), int(max(-.98, min(.98, right[i] * env)) * 32767)])
    if sys.byteorder != 'little': pcm.byteswap()
    with wave.open(str(path), 'wb') as f:
        f.setnchannels(2); f.setsampwidth(2); f.setframerate(RATE); f.writeframes(pcm.tobytes())

OUT.mkdir(exist_ok=True)
save(OUT / 'music-raw.wav')
subprocess.run(['ffmpeg', '-y', '-v', 'error', '-i', str(OUT / 'music-raw.wav'), '-af', 'loudnorm=I=-17.5:TP=-2:LRA=8', '-ar', str(RATE), str(OUT / 'music.wav')], check=True)
print(f'assets/music.wav: {DURATION}s, {BPM} BPM, first beat at 0.0s')
