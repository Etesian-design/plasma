# Overview (Super, Desktop v1 A kept by v2): a Super tap opens it full screen with Events, Windows and Apps; typing searches;
# Enter opens the first match; Esc closes. Then Super+Space: the separate spotlight search.
source /src/test/check.sh
expect_has "Overview button is first in the dock" "$(plasma_eval 'print(panels().map(p => p.widgets().map(w => w.type).join()).join("|"))')" "org.etesian.launcher,org.etesian.dock"
python3 -c 'import dbus; n = dbus.Interface(dbus.SessionBus().get_object("org.freedesktop.Notifications", "/org/freedesktop/Notifications"), "org.freedesktop.Notifications"); n.Notify("Messages", 0, "mail-message", "Anna Virtanen", "Are we still on for lunch?", [], {}, 2000)'
kate /src/README.md >/out/kate.log 2>&1 &
sleep 5
keys "move 800 500" "tap LEFTMETA" "sleep 2" "shot overview"
keys "tap K" "tap O" "tap N" "sleep 1.5" "shot overview-search" "tap ENTER"
for i in $(seq 20); do case "$(active_caption)" in *Konsole*) break ;; esac; sleep 0.5; done # a cold start can take seconds
expect_has "Overview: typing kon + Enter opened Konsole" "$(active_caption)" Konsole
# Super+Space: the spotlight
keys "down LEFTMETA" "tap SPACE" "up LEFTMETA" "sleep 1.5" "shot spotlight" "tap D" "tap O" "sleep 1" "shot spotlight-search" "tap ENTER"
for i in $(seq 20); do case "$(active_caption)" in *Dolphin*) break ;; esac; sleep 0.5; done
expect_has "Spotlight: typing do + Enter opened Dolphin" "$(active_caption)" Dolphin
grep -iE "etesian" /out/plasma.log | head -n 20 >/out/plasma-qml.txt || true
expect "no QML errors from the Etesian widgets" "$(grep -c . /out/plasma-qml.txt)" 0
