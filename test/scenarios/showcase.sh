# The README pictures: a lived-in desktop (five notifications, a feed with pictures, four windows) shown through the
# Overview, Events, the windows carousel and grid, and snapping. Frame sequences (anim-*) become the README's animations
# (scripts/readme-anim.py). Checks only that each view opened; the views themselves have their own scenarios.
source /src/test/check.sh
notify() { python3 -c 'import dbus, sys; n = dbus.Interface(dbus.SessionBus().get_object("org.freedesktop.Notifications", "/org/freedesktop/Notifications"), "org.freedesktop.Notifications"); n.Notify(sys.argv[1], 0, sys.argv[2], sys.argv[3], sys.argv[4], [], {}, 1500)' "$@"; }
notify Messages mail-message "Anna Virtanen" "Are we still on for lunch? I can be there by 12:30."
notify Mail mail-unread "Design weekly" "Why squircles feel softer than rounded rectangles"
notify Messages mail-message "Liisa Niemi" "Sent you a voice note (0:42)"
notify Calendar view-calendar "Design review in 15 minutes" "Room Etesian"
notify Discover system-software-update "Updates are ready" "4 apps can be updated"
# Pictures for Dolphin's thumbnails and the feed: soft gradients, no real photos.
mkdir -p ~/Pictures/Lapland /tmp/feed
python3 - <<'PY'
from PIL import Image, ImageDraw
import os
pal = [((32, 64, 120), (220, 140, 90)), ((20, 90, 80), (170, 220, 200)), ((70, 30, 90), (240, 170, 200)), ((15, 40, 70), (90, 200, 160)),
       ((90, 50, 20), (250, 210, 120)), ((30, 30, 60), (150, 160, 230))]
for i, (a, b) in enumerate(pal):
    im = Image.new("RGB", (640, 420)); d = ImageDraw.Draw(im)
    for y in range(420):
        t = y / 419; d.line([(0, y), (640, y)], fill=tuple(int(a[k] + (b[k] - a[k]) * t) for k in range(3)))
    d.polygon([(0, 420), (200, 250 + 20 * i % 60), (380, 330), (640, 220), (640, 420)], fill=tuple(c // 3 for c in a))
    im.save(os.path.expanduser(f"~/Pictures/Lapland/northern-{i + 1}.jpg"), quality=88)
    im.resize((160, 105)).save(f"/tmp/feed/p{i}.png")
PY
cat > /tmp/feed/feed.xml <<RSS
<?xml version="1.0"?><rss version="2.0" xmlns:media="http://search.yahoo.com/mrss/"><channel><title>Etesian journal</title>
<item><title>A calm desktop for the swipe generation</title><link>http://127.0.0.1:6199/a</link><pubDate>$(date -R -d '-1 hours')</pubDate><media:thumbnail url="http://127.0.0.1:6199/p0.png"/></item>
<item><title>Northern lights expected again tonight</title><link>http://127.0.0.1:6199/b</link><pubDate>$(date -R -d '-3 hours')</pubDate><media:thumbnail url="http://127.0.0.1:6199/p3.png"/></item>
<item><title>Why every icon is a squircle</title><link>http://127.0.0.1:6199/c</link><pubDate>$(date -R -d '-5 hours')</pubDate><media:thumbnail url="http://127.0.0.1:6199/p2.png"/></item>
</channel></rss>
RSS
(cd /tmp/feed && python3 -m http.server 6199 --bind 127.0.0.1 >/out/feed-server.log 2>&1 &)
for i in $(seq 20); do python3 -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:6199/')" 2>/dev/null && break; sleep 0.2; done
kwriteconfig6 --file etesianrc --group Events --key feeds "http://127.0.0.1:6199/feed.xml"
# The weather: Open-Meteo's answer for Helsinki, served locally (the forecaster setting; no internet in tests).
mkdir -p /tmp/feed/v1 && echo '{"current":{"temperature_2m":4.2,"weather_code":2}}' > /tmp/feed/v1/forecast
kwriteconfig6 --file etesianrc --group Events --key forecaster "http://127.0.0.1:6199"
kwriteconfig6 --file etesianrc --group Events --key weatherLat 60.17
kwriteconfig6 --file etesianrc --group Events --key weatherLon 24.94
kwriteconfig6 --file etesianrc --group Events --key weatherCity Helsinki
cat > /tmp/Trip.md <<'MD'
# Trip to Lapland

- Fly to Rovaniemi on Friday, 07:40
- Cabin by the lake: two nights
- Northern lights forecast: good after midnight
- Pack: wool socks, the good camera, a thermos

## Saturday

Snowshoes in the morning, sauna at six.
MD
kate /tmp/Trip.md >/out/kate.log 2>&1 & sleep 3
dolphin ~/Pictures/Lapland >/out/dolphin.log 2>&1 & sleep 4
konsole --hold -e bash -c 'cd ~/Pictures/Lapland; echo "$ ls -lh"; ls -lh --color=always; echo; echo "$ cat /tmp/Trip.md"; cat /tmp/Trip.md' >/out/konsole.log 2>&1 & sleep 3
systemsettings >/out/systemsettings.log 2>&1 & sleep 5
dolphin --new-window ~ >/out/dolphin2.log 2>&1 & sleep 3
# A tidy arrangement: four windows overlapping a little, each one's content in view.
place() { kwin_eval "(() => { for (const w of workspace.windowList()) if (w.caption.includes('$1')) { w.frameGeometry = {x: $2, y: $3, width: $4, height: $5}; return 1 } return 0 })()" >/dev/null; }
place "Settings" 860 360 680 600; place "Konsole" 330 520 640 440; place "Kate" 110 70 720 560; place "Home — Dolphin" 420 200 620 420; place "Lapland — Dolphin" 760 60 780 520
kwin_eval "(() => { for (const w of workspace.windowList()) if (w.caption.includes('Dolphin')) workspace.activeWindow = w; return 1 })()" >/dev/null
keys "move 800 500" "sleep 2"
shot readme-desktop
# The Overview (tap Super): the lead picture; then typing, as frames.
keys "tap LEFTMETA" "sleep 2.5" "shot readme-overview"
keys "tap K" "sleep 0.25" "shot anim-overview-01" "tap A" "sleep 0.25" "shot anim-overview-02" "tap T" "sleep 0.6" "shot anim-overview-03" "tap ESC" "sleep 1"
# A self-hosted forecast is asked for once its address loads, even after the place (it once went to Open-Meteo first).
expect_has "weather from the forecaster setting" "$(cat /out/feed-server.log)" "GET /v1/forecast?latitude=60.17"
expect_has "Overview opened" "$(ls /out)" readme-overview.png
# Events (Super+N)
keys "down LEFTMETA" "tap N" "up LEFTMETA" "sleep 2" "shot readme-events" "tap ESC" "sleep 1"
# The windows carousel (Super+Tab), stepping through: frames
keys "down LEFTMETA" "tap TAB" "sleep 1.2" "shot anim-windows-01" "tap TAB" "sleep 0.8" "shot anim-windows-02" "tap TAB" "sleep 0.8" "shot anim-windows-03" \
  "wheel 1" "sleep 1" "shot anim-windows-04" "wheel 1" "sleep 1" "shot anim-windows-05" "up LEFTMETA" "sleep 0.8" "shot readme-windows-grid" "tap ESC" "sleep 1"
keys "down LEFTMETA" "tap TAB" "sleep 1.2" "shot readme-windows" "up LEFTMETA" "sleep 1"
# Snap layouts (Super+Z) on the active window
keys "down LEFTMETA" "tap Z" "up LEFTMETA" "sleep 1" "shot readme-snap" "tap ESC" "sleep 0.8"
expect_has "all views captured" "$(ls /out | tr '\n' ' ')" "readme-snap.png"
grep -iE "etesian" /out/plasma.log | head -n 20 >/out/plasma-qml.txt || true
expect "no QML errors from the Etesian widgets" "$(grep -c . /out/plasma-qml.txt)" 0
