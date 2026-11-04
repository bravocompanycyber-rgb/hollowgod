# Generates the HOLLOWGOD music loops (original, made with code) into assets/audio/music_*.wav
# Run:  python3 tools/make_music.py
import numpy as np, wave, os, math

SR = 22050
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'audio')
rng = np.random.RandomState(7)

def note(name):
    names = {'C': 0, 'C#': 1, 'Db': 1, 'D': 2, 'Eb': 3, 'D#': 3, 'E': 4, 'F': 5, 'F#': 6, 'Gb': 6, 'G': 7, 'G#': 8, 'Ab': 8, 'A': 9, 'Bb': 10, 'A#': 10, 'B': 11}
    if len(name) >= 3 and name[1] in '#b':
        n, o = name[:2], int(name[2:])
    else:
        n, o = name[0], int(name[1:])
    return 440.0 * 2 ** ((names[n] + 12 * (o + 1) - 69) / 12.0)

class Track:
    def __init__(self, bpm, beats):
        self.bpm = bpm
        self.beat = 60.0 / bpm
        self.beats = beats
        self.N = int(round(beats * self.beat * SR))
        self.buf = np.zeros(self.N)

    def add(self, t_beats, sig, vol=1.0):
        s = int(round(t_beats * self.beat * SR)) % self.N
        idx = (s + np.arange(len(sig))) % self.N
        self.buf[idx] += sig * vol

    # --- instruments ---
    def pad(self, freqs, beats, vol=0.1, attack=1.0, release=1.5):
        n = int((beats * self.beat + release) * SR)
        t = np.arange(n) / SR
        env = np.minimum(1.0, t / attack) * np.minimum(1.0, np.maximum(0.0, (beats * self.beat + release - t)) / release)
        env = env * env * (3 - 2 * env)
        sig = np.zeros(n)
        for f in freqs:
            for det in (-0.004, 0.0, 0.005):
                ff = f * (1 + det)
                sig += np.sin(2 * np.pi * ff * t) + 0.35 * np.sin(2 * np.pi * 2 * ff * t) + 0.12 * np.sin(2 * np.pi * 3 * ff * t)
        lfo = 0.85 + 0.15 * np.sin(2 * np.pi * 0.15 * t + rng.rand() * 6)
        return sig * env * lfo * vol / max(1, len(freqs))

    def bell(self, f, vol=0.12, decay=2.6, length=3.0):
        n = int(length * SR)
        t = np.arange(n) / SR
        sig = np.sin(2 * np.pi * f * t) + 0.5 * np.sin(2 * np.pi * f * 2.76 * t) * np.exp(-t * 2.0) + 0.25 * np.sin(2 * np.pi * f * 5.4 * t) * np.exp(-t * 4.0)
        a = np.minimum(1.0, t / 0.004)
        return sig * np.exp(-t * decay) * a * vol

    def pluck(self, f, vol=0.12, length=1.2):
        n = int(length * SR)
        t = np.arange(n) / SR
        sig = np.zeros(n)
        for h in range(1, 8):
            sig += np.sin(2 * np.pi * f * h * t) / (h ** 1.4) * np.exp(-t * (3.0 + h * 2.5))
        return sig * np.minimum(1.0, t / 0.003) * vol

    def flute(self, f, beats, vol=0.1):
        n = int(beats * self.beat * SR)
        t = np.arange(n) / SR
        vib = 1 + 0.006 * np.sin(2 * np.pi * 5.2 * t) * np.minimum(1.0, t / 0.4)
        env = np.minimum(1.0, t / 0.08) * np.minimum(1.0, (t[-1] - t) / 0.25 + 0.0)
        env = np.clip(env, 0, 1)
        sig = np.sin(2 * np.pi * f * vib * t) + 0.12 * np.sin(2 * np.pi * 2 * f * vib * t)
        breath = rng.randn(n) * 0.02
        return (sig + breath) * env * vol

    def kick(self, vol=0.5, f0=110.0, f1=42.0, length=0.45):
        n = int(length * SR)
        t = np.arange(n) / SR
        ph = 2 * np.pi * (f1 * t + (f0 - f1) * (1 - np.exp(-t * 28)) / 28.0)
        return np.sin(ph) * np.exp(-t * 9.0) * vol

    def tom(self, f=140.0, vol=0.35, length=0.5):
        n = int(length * SR)
        t = np.arange(n) / SR
        ph = 2 * np.pi * (f * t + 30 * (1 - np.exp(-t * 20)) / 20.0)
        return (np.sin(ph) * np.exp(-t * 7.0) + rng.randn(n) * 0.04 * np.exp(-t * 40)) * vol

    def rattle(self, vol=0.08, length=0.18):
        n = int(length * SR)
        t = np.arange(n) / SR
        sig = rng.randn(n)
        sig = sig - np.convolve(sig, np.ones(6) / 6, mode='same')
        return sig * np.exp(-t * 22) * vol

    def hat(self, vol=0.04, length=0.08):
        n = int(length * SR)
        t = np.arange(n) / SR
        sig = rng.randn(n)
        sig = sig - np.convolve(sig, np.ones(4) / 4, mode='same')
        return sig * np.exp(-t * 60) * vol

    def drone(self, f, vol=0.12):
        t = np.arange(self.N) / SR
        # whole cycles over the loop so it wraps seamlessly
        cyc = max(1, int(round(f * self.N / SR)))
        ff = cyc * SR / self.N
        return (np.sin(2 * np.pi * ff * t) + 0.4 * np.sin(2 * np.pi * 2 * ff * t)) * vol * (0.85 + 0.15 * np.sin(2 * np.pi * 2 * t * (1.0 / (self.N / SR)) * 2))

    # --- effects ---
    def echo(self, taps, feedback=0.45, mix=0.5, passes=4):
        dry = self.buf.copy()
        wet = np.zeros_like(dry)
        cur = dry
        for p in range(passes):
            nxt = np.zeros_like(dry)
            for d_beats, g in taps:
                nxt += np.roll(cur, int(d_beats * self.beat * SR)) * g
            cur = nxt * feedback
            wet += cur
        self.buf = dry + wet * mix

    def reverb(self, mix=0.25):
        # cheap circular "room": several delayed, softened copies
        wet = np.zeros_like(self.buf)
        k = np.ones(40) / 40
        sm = np.convolve(self.buf, k, mode='same')
        for d, g in [(0.029, 0.5), (0.043, 0.4), (0.067, 0.32), (0.101, 0.26), (0.157, 0.2), (0.233, 0.14), (0.347, 0.1)]:
            wet += np.roll(sm, int(d * SR)) * g
        self.buf = self.buf + wet * mix

    def save(self, name, peak=0.55):
        b = self.buf - np.mean(self.buf)
        b = np.tanh(b * 1.2)
        b = b / max(1e-6, np.max(np.abs(b))) * peak
        # tiny fade so the first and last samples match (already circular)
        data = (b * 32767).astype(np.int16)
        path = os.path.join(OUT, name)
        with wave.open(path, 'wb') as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes(data.tobytes())
        print(name, round(self.N / SR, 1), 's', os.path.getsize(path) // 1024, 'KB')

def chord(names):
    return [note(n) for n in names]

# ---------------- HUB: warm, calm, hopeful-sad ----------------
def hub():
    T = Track(70, 32)
    prog = [(['A2', 'E3', 'A3', 'C4'], ['A4', 'C5', 'E5', 'C5']), (['F2', 'C3', 'F3', 'A3'], ['A4', 'C5', 'F5', 'C5']),
            (['C3', 'G3', 'C4', 'E4'], ['G4', 'C5', 'E5', 'C5']), (['G2', 'D3', 'G3', 'B3'], ['G4', 'B4', 'D5', 'B4'])]
    for i, (pc, arp) in enumerate(prog):
        T.add(i * 8, T.pad(chord(pc), 8, 0.14, 1.4, 2.0))
        for j in range(8):
            T.add(i * 8 + j * 1.0, T.pluck(note(arp[j % 4]), 0.07, 1.4))
        T.add(i * 8, T.bell(note(arp[2]), 0.07, 1.6, 3.0))
    T.add(0, T.drone(note('A1'), 0.10))
    T.echo([(0.75, 0.5), (1.5, 0.35)], 0.45, 0.45)
    T.reverb(0.3)
    T.save('music_hub.wav')

# ---------------- SUNKEN HALL: Phrygian-dominant, drums, bells ----------------
def sunken():
    T = Track(84, 32)
    D = [note(n) for n in ['D4', 'Eb4', 'F#4', 'G4', 'A4', 'Bb4', 'C#5', 'D5']]
    mel = [0, 2, 1, 0, 4, 3, 2, 1,   0, 1, 2, 4, 5, 4, 2, 1,   0, 2, 4, 5, 6, 5, 4, 2,   3, 2, 1, 0, 1, 2, 0, 0]
    for b in range(32):
        T.add(b, T.bell(D[mel[b]] * (1 if b % 8 < 6 else 1), 0.09, 2.2, 2.4))
    for i, root in enumerate(['D2', 'D2', 'Eb2', 'D2']):
        T.add(i * 8, T.pad(chord([root, 'A2', 'D3', 'F#3' if i != 2 else 'G3']), 8, 0.13, 1.5, 2.0))
    T.add(0, T.drone(note('D1'), 0.12))
    for b in range(32):
        if b % 4 == 0:
            T.add(b, T.tom(105, 0.32))
        if b % 4 == 2:
            T.add(b + 0.5, T.tom(150, 0.18))
        if b % 2 == 1:
            T.add(b + 0.25, T.rattle(0.05))
    T.echo([(0.5, 0.5), (1.0, 0.3)], 0.4, 0.4)
    T.reverb(0.3)
    T.save('music_sunken.wav')

# ---------------- RIME ROAD: icy, sparse, deep heartbeat ----------------
def rime():
    T = Track(72, 32)
    prog = [['E2', 'B2', 'E3', 'G3'], ['C3', 'G3', 'C4', 'E4'], ['D3', 'A3', 'D4', 'F#4'], ['B2', 'F#3', 'B3', 'D4']]
    hi = [['B5', 'G5', 'E5', 'B4'], ['G5', 'E5', 'C5', 'G4'], ['A5', 'F#5', 'D5', 'A4'], ['F#5', 'D5', 'B4', 'F#4']]
    for i in range(4):
        T.add(i * 8, T.pad(chord(prog[i]), 8, 0.14, 2.0, 2.5))
        for j in range(4):
            T.add(i * 8 + j * 2 + 0.0, T.bell(note(hi[i][j]), 0.09, 1.3, 3.5))
    T.add(0, T.drone(note('E1'), 0.13))
    for b in range(0, 32, 2):
        T.add(b, T.kick(0.55, 90, 38, 0.6))
        T.add(b + 0.5, T.kick(0.25, 90, 38, 0.5))
    T.echo([(1.0, 0.55), (2.0, 0.4)], 0.5, 0.55, 5)
    T.reverb(0.4)
    T.save('music_rime.wav')

# ---------------- OBSIDIAN ROAD: ritual drums, flute, drone ----------------
def obsidian():
    T = Track(96, 32)
    sc = [note(n) for n in ['A3', 'C4', 'D4', 'E4', 'G4', 'A4', 'C5', 'D5']]
    phrase = [(0, 1.5, 5), (1.5, 0.5, 4), (2, 2, 3), (4, 1, 2), (5, 1, 3), (6, 2, 1),
              (8, 1.5, 5), (9.5, 0.5, 6), (10, 2, 7), (12, 1, 6), (13, 1, 5), (14, 2, 3)]
    for rep in range(2):
        for (st, du, deg) in phrase:
            T.add(rep * 16 + st, T.flute(sc[deg], du * 0.95, 0.1))
    T.add(0, T.pad(chord(['A2', 'E3', 'A3']), 16, 0.12, 1.2, 2.0))
    T.add(16, T.pad(chord(['G2', 'D3', 'G3']), 16, 0.12, 1.2, 2.0))
    T.add(0, T.drone(note('A1'), 0.12))
    pat = [0, 0.75, 1.5, 2.0, 3.0, 3.5]
    for bar in range(8):
        for p in pat:
            T.add(bar * 4 + p, T.tom(95 if p in (0, 2.0) else 130, 0.34 if p in (0, 2.0) else 0.2))
        T.add(bar * 4 + 1.0, T.rattle(0.06))
        T.add(bar * 4 + 3.0, T.rattle(0.06))
    T.echo([(0.75, 0.4), (1.5, 0.25)], 0.4, 0.35)
    T.reverb(0.25)
    T.save('music_obsidian.wav')

# ---------------- THE HOLLOW: dread, clusters, slow heartbeat ----------------
def hollow():
    T = Track(60, 32)
    T.add(0, T.pad(chord(['F#2', 'G2', 'C#3', 'D3']), 16, 0.16, 3.0, 3.0))
    T.add(16, T.pad(chord(['E2', 'F2', 'B2', 'C3']), 16, 0.16, 3.0, 3.0))
    T.add(0, T.pad(chord(['F#4', 'G4']), 32, 0.05, 6.0, 6.0))
    T.add(0, T.drone(note('F#1'), 0.14))
    for b in range(0, 32, 4):
        T.add(b, T.kick(0.6, 80, 34, 0.8))
        T.add(b + 0.7, T.kick(0.35, 80, 34, 0.7))
    shimmer = ['C#6', 'F#5', 'A5', 'D6', 'G5', 'B5', 'E6', 'C6']
    for i, nme in enumerate(shimmer):
        T.add(i * 4 + 1.5, T.bell(note(nme), 0.06, 1.0, 4.0))
    T.echo([(1.0, 0.6), (2.5, 0.45), (4.0, 0.3)], 0.55, 0.6, 5)
    T.reverb(0.5)
    T.save('music_hollow.wav')

if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    hub(); sunken(); rime(); obsidian(); hollow()
