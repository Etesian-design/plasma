# The Windows view effect (Super+Tab): quick switch on Super release, Super+wheel zoom that locks the view open, Esc, Enter.
source /src/test/check.sh
kate /src/README.md >/out/kate.log 2>&1 & sleep 3
konsole >/out/konsole.log 2>&1 & sleep 3
dolphin /src >/out/dolphin.log 2>&1 & sleep 4
expect "Windows effect enabled" "$(cfg kwinrc Plugins etesian_windowsEnabled)" true
expect "effect loaded" "$(qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.isEffectLoaded etesian_windows)" true
expect_has "Dolphin active before switching" "$(active_caption)" Dolphin
# Quick switch: Super+Tab selects the previous window (Konsole); releasing Super activates it.
keys "move 800 500" "down LEFTMETA" "tap TAB" "sleep 1.2" "shot windows-carousel" "up LEFTMETA" "sleep 1"
expect_has "Super+Tab, release: switched to the previous window" "$(active_caption)" Konsole
# Super+Tab, Super+wheel down twice: 3 per row and locked; releasing Super keeps the view open, the active window is unchanged.
keys "down LEFTMETA" "tap TAB" "sleep 0.6" "wheel 1" "wheel 1" "sleep 1" "shot windows-grid-held" "up LEFTMETA" "sleep 1" "shot windows-grid-locked"
expect_has "locked viewer: releasing Super does not switch" "$(active_caption)" Konsole
# Tab moves on (selection was Dolphin at index 1, now Kate), Enter switches.
keys "tap TAB" "sleep 0.5" "shot windows-grid-next" "tap ENTER" "sleep 1"
expect_has "locked viewer: Tab then Enter switched" "$(active_caption)" Kate
# Esc closes without switching.
keys "down LEFTMETA" "tap TAB" "sleep 0.4" "wheel 1" "up LEFTMETA" "sleep 0.5" "tap ESC" "sleep 1"
expect_has "Esc closes the viewer without switching" "$(active_caption)" Kate
keys "sleep 0.5" "shot windows-after"
grep -iE 'etesian_windows|qml|\.qml' /out/kwin.log | head -n 30 >/out/kwin-qml.txt || true
