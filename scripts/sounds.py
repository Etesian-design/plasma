"""The Etesian sound theme (freedesktop sound naming), made from scratch like the phone's startup sound
(etesian vendor sounds/startup.py): glassy bells and soft pads, additive synthesis, no recorded or Nokia material.

    python3 scripts/sounds.py        # writes look/sounds/Etesian/ (index.theme + stereo/*.wav)
"""
import os, wave
import numpy as np

SR = 48000
OUT = os.path.join(os.path.dirname(__file__), '..', 'look', 'sounds', 'Etesian')
rng = np.random.default_rng(7)


def hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


def env(t, start, attack, decay):
    x = t - start
    e = np.where(x < 0, 0.0, np.exp(-np.maximum(x - attack, 0) / decay))
    return e * (0.5 - 0.5 * np.cos(np.pi * np.clip(x / attack, 0, 1)))


def bell(t, f, start, amp, decay=0.5):
    """a pure fundamental plus inharmonic upper partials that die faster (the drop / glass sound)"""
    out = np.zeros_like(t)
    for ratio, a, d in ((1.0, 1.0, 1.0), (2.76, 0.3, 0.45), (5.4, 0.1, 0.25)):
        out += a * np.sin(2 * np.pi * f * ratio * t + rng.uniform(0, 6.28)) * env(t, start, 0.004, decay * d)
    return amp * out


def pad(t, f, start, amp, attack=0.15, decay=0.6):
    out = np.zeros_like(t)
    for det in (-0.1, 0.0, 0.1):
        ff = f * 2 ** (det / 12)
        out += np.sin(2 * np.pi * ff * t + rng.uniform(0, 6.28)) + 0.15 * np.sin(4 * np.pi * ff * t)
    return amp * out / 3 * env(t, start, attack, decay)


def write(name, dur, voices):
    """voices: (signal function of t, pan -1..1); normalised to -3 dBFS with a short fade at the end"""
    t = np.arange(int(SR * dur)) / SR
    left, right = np.zeros_like(t), np.zeros_like(t)
    for fn, pan in voices:
        s = fn(t)
        a = (pan + 1) * np.pi / 4
        left += s * np.cos(a)
        right += s * np.sin(a)
    fade = np.clip((dur - t) / 0.05, 0, 1)
    peak = max(np.abs(left).max(), np.abs(right).max(), 1e-9)
    st = np.stack([left, right], 1) * fade[:, None] / peak * 0.7
    with wave.open(os.path.join(OUT, 'stereo', name + '.wav'), 'wb') as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((st * 32767).astype('<i2').tobytes())


def chord(notes, start=0.0, step=0.0, amp=1.0, decay=0.5, pan=0.0):
    return [(lambda t, n=n, i=i: bell(t, hz(n), start + i * step, amp, decay), pan + (i - len(notes) / 2) * 0.15) for i, n in enumerate(notes)]


os.makedirs(os.path.join(OUT, 'stereo'), exist_ok=True)
with open(os.path.join(OUT, 'index.theme'), 'w') as f:
    f.write('[Sound Theme]\nName=Etesian\nComment=Etesian desktop sounds (made from scratch)\nInherits=freedesktop\nDirectories=stereo\n\n[stereo]\nOutputProfile=stereo\n')

# a new message or notification: two rising drops
write('message-new-instant', 0.9, chord([79, 86], step=0.11, decay=0.45))
write('message', 0.9, chord([79, 86], step=0.11, decay=0.45))
write('dialog-information', 0.8, chord([84], decay=0.5))
# warnings and errors: lower, a falling pair
write('dialog-warning', 0.9, chord([76, 72], step=0.12, decay=0.5))
write('dialog-error', 1.0, chord([72, 67], step=0.13, decay=0.55))
write('bell', 0.6, chord([88], decay=0.35))
# something finished: three rising drops
write('complete', 1.1, chord([79, 83, 86], step=0.08, decay=0.45))
# volume change: one short tick
write('audio-volume-change', 0.25, [(lambda t: bell(t, hz(91), 0, 1, 0.12), 0)])
# devices and power: rising when something arrives, falling when it leaves
write('device-added', 0.8, chord([74, 81], step=0.09, decay=0.4))
write('device-removed', 0.8, chord([81, 74], step=0.09, decay=0.4))
write('power-plug', 0.8, chord([72, 79], step=0.09, decay=0.4))
write('power-unplug', 0.8, chord([79, 72], step=0.09, decay=0.4))
write('battery-low', 1.0, chord([72, 72], step=0.25, decay=0.35))
write('trash-empty', 0.7, [(lambda t: bell(t, hz(67), 0, 1, 0.25) + 0.3 * rng.standard_normal(t.size) * env(t, 0, 0.003, 0.05), 0)])
# login and logout: the startup chord's colours, short
write('desktop-login', 2.4, [(lambda t, n=n, i=i: pad(t, hz(n), 0.05 * i, 0.6, 0.25, 0.9), (i - 1.5) * 0.4) for i, n in enumerate([60, 67, 71, 76])]
      + chord([84, 88], start=0.3, step=0.12, amp=0.5, decay=0.7))
write('desktop-logout', 1.8, [(lambda t, n=n, i=i: pad(t, hz(n), 0.05 * i, 0.6, 0.2, 0.6), (i - 1.5) * 0.4) for i, n in enumerate([76, 71, 67, 60])])
print('wrote', len(os.listdir(os.path.join(OUT, 'stereo'))), 'sounds to', os.path.normpath(OUT))
