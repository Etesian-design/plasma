# Dock: right-click opens Edit dock (banner, settings, handle); dragging the handle to an edge moves the dock there;
# with previews on, hovering a running app shows its live window.
source /src/test/check.sh
dock_cfg() { plasma_eval "const w = panels().filter(p => p.widgets('org.etesian.dock').length)[0].widgets('org.etesian.dock')[0]; w.currentConfigGroup = ['General']; $1"; }
kate /src/README.md >/out/kate.log 2>&1 &
sleep 4
keys "move 38 460" "rclick" "sleep 1.5" "shot dock-edit"
panel() { plasma_eval 'print(panels().filter(p => p.widgets("org.etesian.dock").length).map(p => p.location + "/" + p.hiding).join())'; }
# Visibility: Auto-hide (the middle segment of the popover).
keys "move 265 540" "click" "sleep 1.5"
expect "Auto-hide in the settings hides the dock" "$(panel)" "left/autohide"
keys "move 152 540" "click" "sleep 1.5"
expect "Always visible shows it again" "$(panel)" "left/none"
# The move handle: drag it to the right edge.
keys "move 42 667" "press" "move 600 600" "move 1590 500" "release" "sleep 2"
expect "dragging the handle to the right edge moves the dock there" "$(panel)" "right/none"
keys "tap ESC" "sleep 1" "shot dock-right"
expect "Esc leaves Edit dock" "$(plasma_eval 'print(panels().filter(p => p.widgets("org.etesian.dock").length)[0].widgets().length)')" 2
# Previews on: hovering the running editor shows its live window.
dock_cfg 'w.writeConfig("previews", true)' >/dev/null
keys "sleep 1" "move 1557 200" "move 1557 485" "sleep 2.5" "shot dock-preview"
grep -iE "etesian" /out/plasma.log | head -n 20 >/out/plasma-qml.txt || true
expect "no QML errors from the Etesian widgets" "$(grep -c . /out/plasma-qml.txt)" 0
