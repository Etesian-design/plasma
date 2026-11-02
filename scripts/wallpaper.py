"""The Etesian wallpaper: the Etesian desktop background (etesian-design desktop/XDesktop.vue .x-desktop): black (--hd-surface-home)
with the accent (#4591FF) glowing at 22 % in a 1200 x 700 ellipse at 70 % / 30 % (of 1920 x 1080), fading out by 70 % of it.
Lightly dithered so the gradient does not band.  python3 scripts/wallpaper.py  ->  look/wallpapers/Etesian/
"""
import json, os, zlib, struct
import numpy as np

OUT = os.path.join(os.path.dirname(__file__), '..', 'look', 'wallpapers', 'Etesian')
ACCENT = np.array([0x45, 0x91, 0xFF], float)


def png(path, rgb):
    h, w, _ = rgb.shape
    raw = b''.join(b'\0' + rgb[y].tobytes() for y in range(h))
    chunk = lambda t, d: struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d) & 0xFFFFFFFF)
    with open(path, 'wb') as f:
        f.write(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b''))


os.makedirs(os.path.join(OUT, 'contents', 'images'), exist_ok=True)
rng = np.random.default_rng(3)
for w, h in ((1920, 1080), (2560, 1440), (3840, 2160), (1080, 1920)):
    k = max(w / 1920, h / 1080)
    y, x = np.mgrid[0:h, 0:w].astype(float)
    # CSS radial-gradient(1200px 700px at 70% 30%, accent 22%, transparent 70%): distance in ellipse radii
    d = np.hypot((x - 0.7 * w) / (1200 * k), (y - 0.3 * h) / (700 * k))
    a = 0.22 * np.clip(1 - d / 0.7, 0, 1)
    img = a[..., None] * ACCENT + rng.uniform(-0.5, 0.5, (h, w, 1))
    png(os.path.join(OUT, 'contents', 'images', f'{w}x{h}.png'), np.clip(np.round(img), 0, 255).astype(np.uint8))
json.dump({'KPlugin': {'Id': 'Etesian', 'Name': 'Etesian', 'Authors': [{'Name': 'Etesian'}], 'License': 'CC-BY-SA-4.0'}},
          open(os.path.join(OUT, 'metadata.json'), 'w'), indent=1)
print('wrote', os.path.normpath(OUT))
