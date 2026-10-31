# The Etesian login screen, in SDDM's greeter test mode (no system install; install-sddm.sh does that with sudo).
source /src/test/check.sh
# a user picture, to check it is cut to the squircle too (a square photo)
python3 -c "from PIL import Image; Image.new(\"RGB\", (256, 256), (230, 120, 40)).save(\"$HOME/.face.icon\", \"PNG\")"
QT_FORCE_STDERR_LOGGING=1 sddm-greeter-qt6 --test-mode --theme /src/look/sddm/etesian >/out/sddm.log 2>&1 & sleep 6
expect "the greeter is running" "$(pgrep -c sddm-greeter)" 1
keys "sleep 0.5" "shot sddm"
# a wrong password says so (test mode has no real login, it fails)
keys "move 960 560" "click" "tap K" "tap ENTER" "sleep 1.5" "shot sddm-failed"
expect "no QML warnings from the theme" "$(grep -c 'etesian/Main.qml:[0-9]' /out/sddm.log)" 0
# the avatar is a squircle: the corners of its box show the background, its centre the accent (regression: it was a square picture)
avatar=$(python3 -c '
from PIL import Image; im = Image.open("/out/sddm.png").convert("RGB"); w, h = im.size
# the avatar: 104 px at the 1920x1080 design size, centred, its box from the centre up
k = w / 1920; cx = w // 2; top = h // 2 - round(200 * k)
box = [(x, y) for y in range(top - 40, top + 60) for x in range(cx - 70, cx + 70) if sum(im.getpixel((x, y))) > 300 ]
xs = [p[0] for p in box]; ys = [p[1] for p in box]
l, r, t, b = min(xs), max(xs), min(ys), max(ys)
corner = sum(im.getpixel((l + 2, t + 2)))
# N9 squircle (n = 2.8): the top edge is already ~2.7% of the width lower a quarter of the way in; n = 4 (a rounded square) only ~0.8%
q = l + (r - l) // 4; drop = next(y for y in range(t, b) if sum(im.getpixel((q, y))) > 300) - t
print("yes" if corner < 150 and r - l > 60 and drop >= 0.018 * (r - l) else "no corner=%d drop=%d box=%s" % (corner, drop, (l, t, r, b)))')
expect "the avatar is the N9 squircle (corners cut, every side curves)" "$avatar" yes
