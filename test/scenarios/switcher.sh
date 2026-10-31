# Alt+Tab: KWin's switcher drawn as the Etesian carousel, then Down twice zooms to 3 per row, then releasing Alt switches window.
source /src/test/check.sh
active() { qdbus6 org.kde.KWin /KWin org.kde.KWin.queryWindowInfo 2>/dev/null | grep -m1 caption; }
kate /src/README.md >/out/kate.log 2>&1 & sleep 3
konsole >/out/konsole.log 2>&1 & sleep 3
dolphin /src >/out/dolphin.log 2>&1 & sleep 4
expect_has "Dolphin active before switching" "$(active_caption)" Dolphin
expect "carousel layout configured" "$(cfg kwinrc TabBox LayoutName)" etesian_carousel
keys "move 800 500" "down LEFTALT" "tap TAB" "sleep 1.2" "shot switcher-carousel" \
  "tap TAB" "sleep 0.8" "shot switcher-carousel-next" \
  "tap DOWN" "tap DOWN" "sleep 0.8" "shot switcher-grid" \
  "up LEFTALT" "sleep 1" "shot switcher-after"
grep -iE 'tabbox|etesian_carousel|qml' /out/kwin.log | head -n 20 >/out/kwin-qml.txt || true
# Two Tabs from Dolphin (most recent first: Dolphin, Konsole, Kate) select Kate; releasing Alt activates it.
expect_has "releasing Alt switched to the selected window" "$(active_caption)" Kate
