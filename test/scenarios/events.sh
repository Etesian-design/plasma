# Events (Super+N): a notification arrives, the bubble counts it, Super+N opens the panel with it, the date unfolds the month.
source /src/test/check.sh
python3 -c 'import dbus; n = dbus.Interface(dbus.SessionBus().get_object("org.freedesktop.Notifications", "/org/freedesktop/Notifications"), "org.freedesktop.Notifications"); n.Notify("Messages", 0, "mail-message", "Anna Virtanen", "Are we still on for lunch? I can be there by 12:30.", [], {}, 3000)'
sleep 7 # the popup times out into the history
expect "Events shortcut is Super+N" "$(plasma_eval 'print(panels().map(p => p.widgets("org.etesian.events").map(w => w.globalShortcut).join()).join(""))')" "Meta+N"
# A feed served from inside the container (no internet in tests): one item with a picture.
mkdir -p /tmp/feed && cd /tmp/feed
python3 -c 'from PIL import Image; Image.new("RGB", (96, 96), (230, 120, 40)).save("photo.png")'
cat > feed.xml <<RSS
<?xml version="1.0"?><rss version="2.0" xmlns:media="http://search.yahoo.com/mrss/"><channel><title>Etesian journal</title>
<item><title>A tablet for the swipe generation</title><link>http://127.0.0.1:6199/a</link><pubDate>$(date -R -d '-2 hours')</pubDate>
<media:thumbnail url="http://127.0.0.1:6199/photo.png"/></item></channel></rss>
RSS
python3 -m http.server 6199 --bind 127.0.0.1 >/out/feed-server.log 2>&1 &
for i in $(seq 20); do python3 -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:6199/')" 2>/dev/null && break; sleep 0.2; done # up before Events asks
cd - >/dev/null
# the feeds are shared by the Events sidebar and the Overview (~/.config/etesianrc)
kwriteconfig6 --file etesianrc --group Events --key feeds "http://127.0.0.1:6199/feed.xml"
keys "sleep 0.5" "shot events-bar"
keys "down LEFTMETA" "tap N" "up LEFTMETA" "sleep 1.5" "shot events-open"
keys "sleep 1" "shot events-open"
# Right under the Notifications header comes the notification's blue icon, not a grey "No notifications" line.
expect "no 'No notifications' over a notification" "$(python3 -c '
from PIL import Image
im = Image.open("/out/events-open.png").convert("RGB")
blue = sum(1 for x in range(1145, 1189) for y in range(240, 256) if (lambda p: p[2] > 150 and p[2] - p[0] > 60)(im.getpixel((x, y))))
print("icon" if blue > 100 else "text")')" icon
expect_has "Events fetched the feed" "$(cat /out/feed-server.log)" "GET /feed.xml"
expect_has "and its picture" "$(cat /out/feed-server.log)" "GET /photo.png"
keys "tap ESC" "sleep 0.5" "tap LEFTMETA" "sleep 2" "shot events-overview"
expect "the Overview's Events column shows the same feed" "$( [ "$(grep -c 'GET /feed.xml' /out/feed-server.log)" -ge 2 ] && echo yes)" yes
keys "tap ESC" "sleep 0.5"
keys "move 1300 60" "click" "sleep 1" "shot events-month" "tap ESC"
grep -iE "etesian" /out/plasma.log | head -n 20 >/out/plasma-qml.txt || true
expect "no QML errors from the Etesian widgets" "$(grep -c . /out/plasma-qml.txt)" 0
