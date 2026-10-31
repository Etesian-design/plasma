# Capture the whole virtual screen through KWin's org.kde.KWin.ScreenShot2 and save it as a PNG.
import os, sys, dbus
from PIL import Image
r, w = os.pipe()
bus = dbus.SessionBus()
o = bus.get_object('org.kde.KWin', '/org/kde/KWin/ScreenShot2')
meta = o.CaptureWorkspace({'native-resolution': True}, dbus.types.UnixFd(w), dbus_interface='org.kde.KWin.ScreenShot2')
os.close(w)
data = b''
while chunk := os.read(r, 1 << 20): data += chunk
W, H, S, F = int(meta['width']), int(meta['height']), int(meta['stride']), int(meta['format'])
# QImage formats: 4-6 are 32-bit ARGB words (BGRA bytes on little-endian); 16-18 are RGBA bytes. KWin 6.6 sends 6, 6.8 sends 16.
RAW = {4: 'BGRX', 5: 'BGRA', 6: 'BGRA', 16: 'RGBX', 17: 'RGBA', 18: 'RGBA'}
if F not in RAW: sys.exit(f'unknown QImage format {F}')
Image.frombuffer('RGBA', (W, H), data, 'raw', RAW[F], S, 1).convert('RGB').save(sys.argv[1])
print('saved', W, H, 'format', F)
