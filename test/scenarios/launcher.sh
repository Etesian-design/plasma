# Overview (Super): a Super tap opens it full screen with Events, Windows and Apps; typing searches;
# Enter opens the first match; Esc closes. Then Super+Space: Search, the separate compact search.
source /src/test/check.sh
expect_has "Overview button is first in the dock" "$(plasma_eval 'print(panels().map(p => p.widgets().map(w => w.type).join()).join("|"))')" "org.etesian.launcher,org.etesian.dock"
python3 -c 'import dbus; n = dbus.Interface(dbus.SessionBus().get_object("org.freedesktop.Notifications", "/org/freedesktop/Notifications"), "org.freedesktop.Notifications"); n.Notify("Messages", 0, "mail-message", "Anna Virtanen", "Are we still on for lunch?", [], {}, 2000)'
kate /src/README.md >/out/kate.log 2>&1 &
sleep 5
keys "move 800 500" "tap LEFTMETA" "sleep 2" "shot overview"
keys "tap K" "tap O" "tap N" "sleep 1.5" "shot overview-search"
# N9: the search field's ends are a squircle as tall as the field (n = 2.8): its focused rim, two rows below the top,
# sits ~0.34 of the half-height in from the side (a pill ~0.6, Breeze's small radius ~0.05).
ends=$(python3 -c '
from PIL import Image; im=Image.open("/out/overview-search.png").convert("RGB"); w,h=im.size
b=lambda p: p[2]>150 and p[0]<120 and p[2]-p[0]>80
pts=[(x,y) for y in range(30,160) for x in range(w-620,w-300) if b(im.getpixel((x,y)))]
ys=sorted({y for _,y in pts}); t=ys[0]; bot=t
while bot+1 in ys: bot+=1
r=(bot-t+1)/2; mx=min(x for x,y in pts if y<=bot)
print(round((min(x for x,y in pts if y==t+2)-mx)/r*100))')
expect_has "Overview search field has squircle-half ends (rim at ${ends}% of the half-height in; 25-45)" "$([ "$ends" -ge 25 ] && [ "$ends" -le 45 ] && echo yes)" yes
keys "tap ENTER"
for i in $(seq 20); do case "$(active_caption)" in *Konsole*) break ;; esac; sleep 0.5; done # a cold start can take seconds
expect_has "Overview: typing kon + Enter opened Konsole" "$(active_caption)" Konsole
# Super+Space: Search
keys "down LEFTMETA" "tap SPACE" "up LEFTMETA" "sleep 1.5" "shot search" "tap D" "tap O" "sleep 1" "shot search-typed" "tap ENTER"
for i in $(seq 20); do case "$(active_caption)" in *Dolphin*) break ;; esac; sleep 0.5; done
expect_has "Search: typing do + Enter opened Dolphin" "$(active_caption)" Dolphin
grep -iE "etesian" /out/plasma.log | head -n 20 >/out/plasma-qml.txt || true
expect "no QML errors from the Etesian widgets" "$(grep -c . /out/plasma-qml.txt)" 0
