"""Turns test/out (test/run.sh showcase) into the README pictures in .github/readme: the stills as optimised PNGs and
the frame sequences as animated WebP (GitHub shows them inline). Run after the showcase scenario."""
from PIL import Image
import os, sys

src, dst = "test/out", ".github/readme"
os.makedirs(dst, exist_ok=True)
STILLS = {"readme-overview": "overview", "readme-events": "events", "readme-windows": "windows-carousel",
          "readme-windows-grid": "windows-grid", "readme-snap": "snap-layouts", "readme-desktop": "desktop"}
for a, b in STILLS.items():
    Image.open(f"{src}/{a}.png").convert("RGB").save(f"{dst}/{b}.png", optimize=True)

def anim(name, frames, hold):
    """frames: test/out names; hold: how long each shows, in ms"""
    ims = [Image.open(f"{src}/{f}.png").convert("RGB").resize((1200, 750), Image.LANCZOS) for f in frames]
    ims[0].save(f"{dst}/{name}.webp", save_all=True, append_images=ims[1:], duration=hold, loop=0, quality=82, method=6)

# Super+Tab: the carousel, Tab steps through it, then scrolling shows three per row (frame 4 is mid-zoom: left out)
anim("windows", ["anim-windows-01", "anim-windows-02", "anim-windows-03", "anim-windows-05"], [1400, 1100, 1100, 2200])
# the Overview: tap Super, just type
anim("overview-search", ["readme-overview", "anim-overview-01", "anim-overview-02", "anim-overview-03"], [1800, 500, 500, 2000])
for f in sorted(os.listdir(dst)):
    print(f, os.path.getsize(f"{dst}/{f}") // 1024, "KiB")
