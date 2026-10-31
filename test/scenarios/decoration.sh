# The native Etesian decoration: the header bar, and Kate's toolbar actions in it (its own toolbar hidden).
source /src/test/check.sh
expect "decoration plugin chosen" "$(cfg kwinrc org.kde.kdecoration2 library)" org.etesian.decoration
expect_has "KWin loaded the Etesian decoration" "$(qdbus6 org.kde.KWin /KWin supportInformation | grep -i 'Plugin:' | head -n 1)" org.etesian.decoration
# Installing again while KWin has the plugin loaded must not touch the loaded library (an in-place copy crashed KWin).
/src/install.sh >/out/install-again.log 2>&1
kate /src/README.md >/out/kate.log 2>&1 & sleep 7
expect "KWin survives a reinstall and the next window" "$(pgrep -c kwin_wayland)" 1
svc=$(qdbus6 | grep -i 'org.kde.kate' | head -n 1 | tr -d ' ')
expect "Kate's own toolbar is hidden (its actions are in the header)" "$(qdbus6 "$svc" /kate/MainWindow_1 org.kde.kate.KXmlGuiWindow.isToolBarVisible mainToolBar)" false
expect "Kate's hamburger row is hidden too (the header's … is the app menu)" "$(qdbus6 "$svc" /kate/MainWindow_1 org.kde.kate.KXmlGuiWindow.isToolBarVisible hamburgerBar)" false
keys "sleep 0.5" "shot decoration-kate"
# The header's first app action is New: right edge - 4 - 3 controls (90) - spacer (10) - app menu (30) - 5 actions (178) - 4.
g=$(active_geometry); x=${g%%,*}; rest=${g#*,}; y=${rest%% *}; size=${g#* }; w=${size%x*}
nx=$((x + w - 4 - 90 - 10 - 30 - 178 - 4 + 17)); ny=$((y + 7 + 15))
keys "move $nx $ny" "sleep 0.6" "shot decoration-hover" "click" "sleep 1.5"
expect_has "the header's New button ran Kate's New" "$(active_caption)" Untitled
# HeaderActions off: a new Kate window gets its own toolbar back.
kwriteconfig6 --file kwinrc --group Etesian --key HeaderActions false
kate -n >/out/kate2.log 2>&1 & sleep 7
svc2=$(qdbus6 | grep -i 'org.kde.kate' | grep -v "$svc" | head -n 1 | tr -d ' ')
expect "HeaderActions=false: Kate keeps its toolbar" "$(qdbus6 "$svc2" /kate/MainWindow_1 org.kde.kate.KXmlGuiWindow.isToolBarVisible mainToolBar)" true
keys "sleep 0.5" "shot decoration-off"
expect "no decoration errors" "$(grep -ci 'etesian.decoration.*\(error\|fail\)' /out/kwin.log)" 0
