# Belle widgets on the desktop: the flip clock, the word clock and the feed widget (the Events feeds) placed on the wallpaper.
source /src/test/check.sh
mkdir -p /tmp/feed && cd /tmp/feed
cat > feed.xml <<RSS
<?xml version="1.0"?><rss version="2.0"><channel><title>Etesian journal</title>
<item><title>A tablet for the swipe generation</title><link>http://127.0.0.1:6199/a</link><pubDate>$(date -R -d '-2 hours')</pubDate></item>
<item><title>Swipe, don't press: why the edges matter more than buttons on a touch phone</title><link>http://127.0.0.1:6199/b</link><pubDate>$(date -R -d '-5 hours')</pubDate></item>
<item><title>Winter tyres: the week to change them</title><link>http://127.0.0.1:6199/c</link><pubDate>$(date -R -d '-1 day')</pubDate></item>
</channel></rss>
RSS
python3 -m http.server 6199 --bind 127.0.0.1 >/out/feed-server.log 2>&1 &
for i in $(seq 20); do python3 -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:6199/')" 2>/dev/null && break; sleep 0.2; done
cd - >/dev/null
kwriteconfig6 --file etesianrc --group Events --key feeds "http://127.0.0.1:6199/feed.xml"
added="$(plasma_eval 'const d = desktops()[0]; d.addWidget("org.etesian.flipclock", 120, 80, 360, 180); d.addWidget("org.etesian.wordclock", 120, 300, 360, 180);
  d.addWidget("org.etesian.feed", 560, 80, 360, 270); print(d.widgets().map(w => w.type).filter(t => t.indexOf("org.etesian.") === 0).sort().join(","))')"
expect "the three widgets are on the desktop" "$added" "org.etesian.feed,org.etesian.flipclock,org.etesian.wordclock"
keys "sleep 3" "shot desktop-widgets"
expect_has "the feed widget fetched the Events feeds" "$(cat /out/feed-server.log)" "GET /feed.xml"
grep -iE "etesian" /out/plasma.log | head -n 20 >/out/plasma-qml.txt || true
expect "no QML errors from the Etesian widgets" "$(grep -c . /out/plasma-qml.txt)" 0
